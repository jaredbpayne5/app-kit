#!/usr/bin/env bash
#
# scripts/web/attach-domain.sh — attach <subdomain>.<studio-domain> to the Pages project.
#
# Deferred live use: run when marketing begins and a studio domain exists.
# <slug>.pages.dev is enough for store privacy URLs until then.
#
# Usage:
#   bash scripts/web/attach-domain.sh <subdomain>
#   bash scripts/web/attach-domain.sh <subdomain> --project-name=<slug>
#   bash scripts/web/attach-domain.sh <subdomain> --dry-run
#
# Env (from ~/.app-factory/env or process):
#   CLOUDFLARE_API_TOKEN      — Pages:Edit + Zone DNS:Edit
#   CLOUDFLARE_ACCOUNT_ID
#   CLOUDFLARE_ZONE_ID        — studio domain zone
#   CLOUDFLARE_STUDIO_DOMAIN  — e.g. yourstudio.com
#
# Verified API (Cloudflare Pages / DNS, 2026 — wrangler has no `pages domains` in v4):
#   POST /accounts/{id}/pages/projects/{name}/domains   { "name": "app.studio.com" }
#   POST /zones/{zone_id}/dns_records                   CNAME → {slug}.pages.dev (proxied)
#
# Idempotent (R6). Does not mutate store metadata — prints the reminder instead.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

AF_ENV="${HOME}/.app-factory/env"
SUBDOMAIN=""
PROJECT_NAME=""
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --project-name=*) PROJECT_NAME="${arg#--project-name=}" ;;
    -h|--help)
      sed -n '2,28p' "$0"
      exit 0
      ;;
    --*)
      printf 'Unknown arg: %s\n' "$arg" >&2
      exit 2
      ;;
    *)
      if [[ -z "$SUBDOMAIN" ]]; then
        SUBDOMAIN="$arg"
      else
        printf 'Unexpected arg: %s\n' "$arg" >&2
        exit 2
      fi
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

printf '%sAttach custom domain (Cloudflare Pages)%s\n' "$BOLD" "$RESET"

[[ -n "$SUBDOMAIN" ]] || bad "Usage: bash scripts/web/attach-domain.sh <subdomain> [--dry-run]"
[[ "$SUBDOMAIN" != *.* ]] || bad "Pass only the subdomain label (e.g. myapp), not a FQDN"

missing=0
load_cf_env CLOUDFLARE_API_TOKEN || missing=1
load_cf_env CLOUDFLARE_ACCOUNT_ID || missing=1
load_cf_env CLOUDFLARE_ZONE_ID || missing=1
load_cf_env CLOUDFLARE_STUDIO_DOMAIN || missing=1

if [[ "$missing" -eq 1 ]]; then
  bad "Missing credentials. Need CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_ZONE_ID, CLOUDFLARE_STUDIO_DOMAIN in ~/.app-factory/env (see docs/recipes/custom-domain.md). No changes made."
fi

if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(node -e "const p=require('./apps/mobile/app.json'); process.stdout.write(String(p.expo?.slug||''))")"
fi
[[ -n "$PROJECT_NAME" ]] || bad "Could not read expo.slug from apps/mobile/app.json"

FQDN="${SUBDOMAIN}.${CLOUDFLARE_STUDIO_DOMAIN}"
TARGET="${PROJECT_NAME}.pages.dev"
LIVE_URL="https://${FQDN}"

ok "project=${PROJECT_NAME}"
ok "domain=${FQDN} → ${TARGET}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  warn "dry-run — would POST Pages domain + ensure DNS CNAME (proxied); no API calls"
  printf '\nPlanned live URL: %s\n' "$LIVE_URL"
  exit 0
fi

api() {
  # usage: api METHOD URL [json-body]
  local method="$1" url="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" "$url" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "$body"
  else
    curl -sS -X "$method" "$url" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

# --- 1) Pages custom domain (idempotent) ---
DOMAINS_URL="https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains"
LIST_JSON="$(api GET "$DOMAINS_URL")"
if printf '%s' "$LIST_JSON" | python3 -c '
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
if not data.get("success", True) and data.get("success") is False:
    sys.exit(2)
rows = data.get("result") or []
for row in rows:
    if isinstance(row, dict) and row.get("name") == name:
        sys.exit(0)
sys.exit(1)
' "$FQDN"; then
  ok "Pages domain already attached"
else
  ADD_JSON="$(api POST "$DOMAINS_URL" "$(printf '{"name":"%s"}' "$FQDN")")"
  printf '%s' "$ADD_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
if not data.get("success"):
    errs = data.get("errors") or data
    print(errs, file=sys.stderr)
    sys.exit(1)
' || bad "Failed to add Pages domain (see errors above)"
  ok "Pages domain added"
fi

# --- 2) DNS CNAME (idempotent) ---
DNS_LIST_URL="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=CNAME&name=${FQDN}"
DNS_LIST="$(api GET "$DNS_LIST_URL")"
EXISTING_ID="$(
  printf '%s' "$DNS_LIST" | python3 -c '
import json, sys
target = sys.argv[1]
data = json.load(sys.stdin)
rows = data.get("result") or []
for row in rows:
    if not isinstance(row, dict):
        continue
    content = (row.get("content") or "").rstrip(".")
    if content == target.rstrip("."):
        print(row.get("id") or "")
        sys.exit(0)
# wrong target exists — surface id for update
if rows:
    print(rows[0].get("id") or "")
' "$TARGET"
)"

if [[ -n "$EXISTING_ID" ]]; then
  # Ensure content + proxied
  PATCH_URL="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${EXISTING_ID}"
  PATCH_JSON="$(api PUT "$PATCH_URL" "$(printf '{"type":"CNAME","name":"%s","content":"%s","ttl":1,"proxied":true}' "$FQDN" "$TARGET")")"
  printf '%s' "$PATCH_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
if not data.get("success"):
    print(data.get("errors") or data, file=sys.stderr)
    sys.exit(1)
' || bad "Failed to update DNS CNAME"
  ok "DNS CNAME ensured (id=${EXISTING_ID})"
else
  CREATE_URL="https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"
  CREATE_JSON="$(api POST "$CREATE_URL" "$(printf '{"type":"CNAME","name":"%s","content":"%s","ttl":1,"proxied":true}' "$FQDN" "$TARGET")")"
  printf '%s' "$CREATE_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
if not data.get("success"):
    print(data.get("errors") or data, file=sys.stderr)
    sys.exit(1)
' || bad "Failed to create DNS CNAME"
  ok "DNS CNAME created"
fi

printf '\n%sLive HTTPS URL:%s %s\n' "$BOLD" "$RESET" "$LIVE_URL"
printf 'TLS cert is automatic once the domain is Active in Pages.\n'
printf '\n%sNext (required):%s update store listings so they never point at a URL that later breaks:\n' "$BOLD" "$RESET"
printf '  1. Set apps/mobile/store/metadata/*/privacy_url.txt and support_url.txt → %s/privacy\n' "$LIVE_URL"
printf '  2. Update apps/web/lander.json contact/store URLs if needed\n'
printf '  3. npm run sync:legal && npm run web:build && npm run web:deploy\n'
printf 'Never delete the old pages.dev or subdomain record while stores still link to it.\n'
