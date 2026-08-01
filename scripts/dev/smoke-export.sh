#!/usr/bin/env bash
# Native bundle smoke — confirms the Expo Router shell bundles for iOS + Android.
# Does not require an emulator. Safe for agents / CI-like local checks.
#
# Why native (not web): the Expo app is iOS + Android only. Marketing lives in
# apps/web/ (static lander). Native modules (e.g. expo-sqlite/kv-store) pull web wasm
# workers that the web bundler cannot handle, so `expo export --platform web`
# is the wrong smoke for this template.
#
# Usage:
#   npm run smoke:export
#   bash scripts/dev/smoke-export.sh --keep
#   bash scripts/dev/smoke-export.sh --out=/tmp/my-export
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/apps/mobile"

OUT="${SMOKE_EXPORT_DIR:-$(mktemp -d -t expo-export-smoke.XXXXXX)}"
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --out=*) OUT="${1#--out=}"; KEEP=1; mkdir -p "$OUT"; shift ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

cleanup() {
  if [[ "$KEEP" -eq 0 && -d "$OUT" ]]; then
    rm -rf "$OUT"
  fi
}
trap cleanup EXIT

echo "expo export (ios + android) → $OUT"
npx expo export --platform ios --platform android --output-dir "$OUT"

if [[ ! -f "$OUT/metadata.json" ]]; then
  echo "FAIL: missing metadata.json under $OUT" >&2
  exit 1
fi
echo "OK metadata.json"

missing=0
for platform in ios android; do
  # Hermes bytecode (.hbc) is the default; allow .js if --no-bytecode is ever used.
  bundle="$(find "$OUT/_expo/static/js/${platform}" -type f \( -name 'entry-*.hbc' -o -name 'entry-*.js' \) 2>/dev/null | head -1 || true)"
  if [[ -n "$bundle" ]]; then
    echo "OK bundle:${platform} ($(basename "$bundle"))"
  else
    echo "MISSING bundle:${platform} (expected _expo/static/js/${platform}/entry-*.hbc)" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Export tree:" >&2
  find "$OUT" -type f | head -80 >&2 || true
  exit 1
fi

echo "smoke:export OK"
