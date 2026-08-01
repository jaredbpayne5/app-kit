#!/usr/bin/env bash
#
# scripts/store/store-push.sh — push binaries (EAS Submit) + listing metadata (fastlane).
#
# Usage:
#   npm run store:push -- --platform=ios|android|both [--metadata-only]
#   bash scripts/store/store-push.sh --platform=ios
#   bash scripts/store/store-push.sh --platform=both --metadata-only
#
# Hard Stop: never auto-promote. eas.json submit.production.android stays
# track=internal / releaseStatus=draft; iOS lands in TestFlight (manual release).
#
# Verified CLI (eas-cli 21.x / Expo docs 2026):
#   eas submit --platform ios|android --profile production --latest --non-interactive
# Metadata (R2): EAS Metadata is iOS-only and does not upload screenshots or
# Play listings — keep fastlane-compatible apps/mobile/store/metadata/ and run:
#   bundle exec fastlane ios metadata    # or: fastlane ios metadata
#   bundle exec fastlane android metadata
#
# Full live ASC/Play E2E is exercised on the first real app (not this template).
#
# Requires: scripts/store/review-preflight.sh exit 0 (Harden / store-readiness gate).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PLATFORM=""
METADATA_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --platform=*) PLATFORM="${arg#--platform=}" ;;
    --metadata-only) METADATA_ONLY=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: npm run store:push -- --platform=ios|android|both [--metadata-only]

  --platform=ios|android|both   Required. Which store lane(s) to push.
  --metadata-only               Skip eas submit; upload listing/screenshots only.

Gates:
  1. scripts/store/review-preflight.sh must exit 0 (npm run preflight).
  2. Binaries: eas submit --platform <p> --profile production --latest (from apps/mobile)
  3. Metadata: fastlane deliver (ios) / supply (android) via apps/mobile/fastlane/Fastfile
     reading ./store/metadata/{ios,android}/ relative to apps/mobile.

Credentials (outside repo):
  ASC API key via eas credentials / ~/.app-factory/asc/
  Play service account: ~/.app-factory/play/service-account.json
    (eas.json submit.production.android.serviceAccountKeyPath)

Full live upload E2E is deferred to the first real product app.
EOF
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
have() { command -v "$1" >/dev/null 2>&1; }

case "$PLATFORM" in
  ios|android|both) ;;
  "")
    bad "Missing --platform=ios|android|both (see --help)"
    ;;
  *)
    bad "Invalid --platform=$PLATFORM (use ios|android|both)"
    ;;
esac

want_ios=0
want_android=0
case "$PLATFORM" in
  ios) want_ios=1 ;;
  android) want_android=1 ;;
  both) want_ios=1; want_android=1 ;;
esac

printf '%sstore:push%s  (platform=%s metadata_only=%s)\n' "$BOLD" "$RESET" "$PLATFORM" "$METADATA_ONLY"

# --- Gate: android submit track must not be production -------------------------
TRACK="$(
  node <<'NODE'
const j = require("./apps/mobile/eas.json");
const t = j?.submit?.production?.android?.track;
process.stdout.write(t == null ? "" : String(t));
NODE
)"
if [[ -z "$TRACK" ]]; then
  bad "eas.json submit.production.android.track missing — refuse to push"
fi
if [[ "$TRACK" == "production" ]]; then
  bad "eas.json android submit track is \"production\" — Hard Stop; must stay internal/draft until human promote"
fi
ok "android submit track is \"$TRACK\" (not production)"

# --- Gate: review preflight -------------------------------------------------
if [[ ! -x "$ROOT/scripts/store/review-preflight.sh" && ! -f "$ROOT/scripts/store/review-preflight.sh" ]]; then
  bad "scripts/store/review-preflight.sh missing — cannot push"
fi
printf '\n%spreflight%s\n' "$BOLD" "$RESET"
if ! bash "$ROOT/scripts/store/review-preflight.sh"; then
  bad "store:push refused — preflight failed (fix listed above)"
fi
ok "preflight green"

# --- Helpers ----------------------------------------------------------------
run_eas_submit() {
  local p="$1"
  have eas || bad "eas CLI not found — npm i -g eas-cli (or use npx eas-cli)"
  printf '\n%seas submit --platform %s --profile production --latest%s\n' "$BOLD" "$p" "$RESET"
  (cd "$ROOT/apps/mobile" && eas submit --platform "$p" --profile production --latest --non-interactive)
  ok "eas submit ($p) finished"
}

fastlane_cmd() {
  if [[ -f "$ROOT/Gemfile" ]] && have bundle; then
    echo "bundle exec fastlane"
  elif have fastlane; then
    echo "fastlane"
  else
    return 1
  fi
}

run_metadata() {
  local p="$1"
  local fl
  if ! fl="$(fastlane_cmd)"; then
    bad "fastlane not found — install with: gem install fastlane (or add a Gemfile + bundle install). Metadata layout is apps/mobile/store/metadata/${p}/."
  fi
  printf '\n%s%s %s metadata%s\n' "$BOLD" "$fl" "$p" "$RESET"
  # shellcheck disable=SC2086
  (cd "$ROOT/apps/mobile" && $fl "$p" metadata)
  ok "fastlane $p metadata finished"
}

# --- Platforms --------------------------------------------------------------
if [[ "$want_ios" -eq 1 ]]; then
  if [[ "$METADATA_ONLY" -eq 0 ]]; then
    run_eas_submit ios
  else
    warn "skipping eas submit (ios) — --metadata-only"
  fi
  run_metadata ios
fi

if [[ "$want_android" -eq 1 ]]; then
  if [[ "$METADATA_ONLY" -eq 0 ]]; then
    run_eas_submit android
  else
    warn "skipping eas submit (android) — --metadata-only"
  fi
  run_metadata android
fi

printf '\n%sdone%s — review store consoles; promote is a human Hard Stop.\n' "$BOLD" "$RESET"
