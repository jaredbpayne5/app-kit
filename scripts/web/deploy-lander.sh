#!/usr/bin/env bash
#
# scripts/web/deploy-lander.sh — deploy apps/web/dist to Cloudflare Pages (Hard Stop).
#
# Usage:
#   npm run web:deploy
#   bash scripts/web/deploy-lander.sh [--skip-build] [--project-name <slug>]
#
# Env (from ~/.app-factory/env or process):
#   CLOUDFLARE_API_TOKEN   — required (Account → Cloudflare Pages → Edit)
#   CLOUDFLARE_ACCOUNT_ID  — required
#
# Verified CLI (wrangler 4.114 / Cloudflare docs 2026-07):
#   npx wrangler pages project create <name> --production-branch=main   # first run
#   CLOUDFLARE_ACCOUNT_ID=… CLOUDFLARE_API_TOKEN=… \
#     npx wrangler pages deploy <dir> --project-name=<name> --branch=main [--commit-dirty=true]
# Contract: deploy does NOT auto-create projects — ensure_pages_project() calls
# `pages project create` when `pages project list --json` misses the name.#
# Creates the Pages project on first deploy. Prints the live URL — that URL's
# /privacy.html is the hosted privacy policy both stores require.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

AF_ENV="${HOME}/.app-factory/env"
SKIP_BUILD=0
PROJECT_NAME=""

for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=1 ;;
    --project-name)
      echo "Use --project-name=<slug>" >&2
      exit 2
      ;;
    --project-name=*) PROJECT_NAME="${arg#--project-name=}" ;;
    -h|--help)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else GREEN=""; YELLOW=""; RED=""; BOLD=""; RESET=""; fi
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; exit 1; }

load_cf_env() {
  local key="$1" line val
  if [[ -n "${!key:-}" ]]; then
    return 0
  fi
  if [[ ! -f "$AF_ENV" ]]; then
    return 1
  fi
  line="$(grep -E "^[[:space:]]*${key}=" "$AF_ENV" | head -1 || true)"
  [[ -n "$line" ]] || return 1
  val="$(printf '%s\n' "$line" | sed -E "s/^[[:space:]]*${key}=//; s/^[\"']//; s/[\"']$//")"
  printf -v "$key" '%s' "$val"
  export "${key?}"
}

printf '%sDeploy lander (Cloudflare Pages)%s\n' "$BOLD" "$RESET"

load_cf_env CLOUDFLARE_API_TOKEN || bad "CLOUDFLARE_API_TOKEN missing (set in ~/.app-factory/env)"
load_cf_env CLOUDFLARE_ACCOUNT_ID || bad "CLOUDFLARE_ACCOUNT_ID missing (set in ~/.app-factory/env)"
ok "Cloudflare credentials loaded (values not printed)"

if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(node -e "const p=require('./apps/mobile/app.json'); process.stdout.write(String(p.expo?.slug||''))")"
fi
[[ -n "$PROJECT_NAME" ]] || bad "Could not read expo.slug from apps/mobile/app.json (pass --project-name=<slug>)"
ok "project-name=${PROJECT_NAME}"

ensure_pages_project() {
  # Wrangler 4+ no longer auto-creates Pages projects on deploy.
  local list_json
  list_json="$(npx --yes wrangler pages project list --json 2>/dev/null || true)"
  if printf '%s' "$list_json" | python3 -c '
import json, sys
name = sys.argv[1]
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(1)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(1)
rows = data if isinstance(data, list) else (data.get("result") or data.get("projects") or [])
for row in rows:
    if not isinstance(row, dict):
        continue
    # wrangler --json uses "Project Name"; API-shaped payloads use "name".
    row_name = row.get("name") or row.get("Project Name") or ""
    if row_name == name:
        sys.exit(0)
sys.exit(1)
' "$PROJECT_NAME"; then
    ok "Pages project already exists"
    return 0
  fi
  warn "Pages project missing — creating (production-branch=main)"
  if ! npx --yes wrangler pages project create "$PROJECT_NAME" --production-branch=main; then
    # Race / list miss: create may fail with "already exists" — treat as ok (R6).
    warn "project create returned non-zero; retrying deploy (idempotent)"
  else
    ok "Pages project created"
  fi
}

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  npm run sync:legal
  npm run web:build
else
  [[ -d apps/web/dist ]] || bad "apps/web/dist missing — run without --skip-build, or npm run web:build first"
  [[ -f apps/web/dist/index.html && -f apps/web/dist/privacy.html ]] || bad "apps/web/dist incomplete (need index.html + privacy.html)"
  ok "using existing apps/web/dist (--skip-build)"
fi

ensure_pages_project

# Production branch so the deployment is served at <slug>.pages.dev (not a preview URL).
# --commit-dirty=true: allow deploy from a dirty worktree (template maintenance / mid-Part).
DEPLOY_LOG="$(mktemp)"
cleanup() { rm -f "$DEPLOY_LOG"; }
trap cleanup EXIT

set +e
npx --yes wrangler pages deploy apps/web/dist \
  --project-name="$PROJECT_NAME" \
  --branch=main \
  --commit-dirty=true \
  2>&1 | tee "$DEPLOY_LOG"
deploy_rc=${PIPESTATUS[0]}
set -e
[[ "$deploy_rc" -eq 0 ]] || bad "wrangler pages deploy failed (exit ${deploy_rc})"

LIVE_URL="$(
  python3 - "$DEPLOY_LOG" "$PROJECT_NAME" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
project = sys.argv[2]
# Prefer the stable production host when present in output or as convention.
stable = f"https://{project}.pages.dev"
hosts = re.findall(r"https?://[a-zA-Z0-9.-]+\.pages\.dev", text)
if stable in hosts or re.search(re.escape(f"{project}.pages.dev"), text):
    print(stable)
    raise SystemExit(0)
if hosts:
    # Fall back to last printed host (may be a deployment subdomain).
    print(hosts[-1])
    raise SystemExit(0)
raise SystemExit(1)
PY
)" || true

if [[ -z "${LIVE_URL:-}" ]]; then
  LIVE_URL="https://${PROJECT_NAME}.pages.dev"
  warn "Could not parse wrangler URL — using conventional ${LIVE_URL}"
else
  # Always surface the production alias for store listings when branch=main.
  if [[ "$LIVE_URL" != "https://${PROJECT_NAME}.pages.dev" ]]; then
    warn "Deployment alias: ${LIVE_URL}"
    LIVE_URL="https://${PROJECT_NAME}.pages.dev"
    ok "using production URL ${LIVE_URL}"
  fi
fi

ok "deployed"
printf '\n%sLive lander:%s %s\n' "$BOLD" "$RESET" "$LIVE_URL"
printf 'Hosted privacy policy: %s/privacy\n' "$LIVE_URL"
printf '(Also: %s/privacy.html → redirects to /privacy on Pages)\n' "$LIVE_URL"

# Spec verify: privacy page reachable (follow Pages pretty-URL redirect).
if curl -sfIL "${LIVE_URL}/privacy.html" -o /dev/null; then
  ok "curl -sfIL ${LIVE_URL}/privacy.html → 200"
else
  bad "privacy URL check failed for ${LIVE_URL}/privacy.html"
fi

printf 'Paste that privacy URL into store listings (Stage 4 automates the paste).\n'
