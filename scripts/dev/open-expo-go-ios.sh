#!/usr/bin/env bash
# Open this Expo project on a booted iOS Simulator.
#
# Default: prefer the installed development build (bundle id from app.json).
# Fall back to Expo Go when no native build is installed (no-native shell path).
#
# Usage:
#   bash scripts/dev/open-expo-go-ios.sh
#   bash scripts/dev/open-expo-go-ios.sh --port 8082
#   bash scripts/dev/open-expo-go-ios.sh --go          # force Expo Go (pure UI / R5)
#   bash scripts/dev/open-expo-go-ios.sh --no-boot     # require an already-booted sim
#   npm run open:ios
#   npm run open:ios -- --go
#
# Requires macOS + Xcode simctl. Boots a simulator if none is running (unless --no-boot).
# No adb reverse needed — the simulator shares the host network stack.
#
set -euo pipefail

PORT="${EXPO_PORT:-8081}"
NO_BOOT=0
FORCE_GO=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port=*) PORT="${1#--port=}"; shift ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --no-boot) NO_BOOT=1; shift ;;
    --go) FORCE_GO=1; shift ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "open-expo-go-ios.sh requires macOS (uname=$(uname -s))." >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1 || ! xcrun simctl help >/dev/null 2>&1; then
  echo "xcrun simctl unavailable — install Xcode (or full CLT with Simulator) first." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/lib/ensure-ios-sim.sh
source "$ROOT/scripts/lib/ensure-ios-sim.sh"

if [[ "$NO_BOOT" -eq 1 ]]; then
  booted="$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || true)"
  if [[ "${booted:-0}" -lt 1 ]]; then
    echo "No booted iOS Simulator. Open Simulator.app (or: xcrun simctl boot <UDID>), then re-run." >&2
    xcrun simctl list devices available 2>/dev/null | head -40 >&2 || true
    exit 1
  fi
else
  if ! ensure_ios_sim; then
    echo "No booted iOS Simulator. Open Simulator.app (or: xcrun simctl boot <UDID>), then re-run." >&2
    xcrun simctl list devices available 2>/dev/null | head -40 >&2 || true
    exit 1
  fi
fi

BUNDLE_ID="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.ios.bundleIdentifier || '')" 2>/dev/null || true)"
SLUG="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.slug || '')" 2>/dev/null || true)"

app_installed=0
if [[ -n "$BUNDLE_ID" ]] && xcrun simctl listapps booted 2>/dev/null | grep -Fq "\"$BUNDLE_ID\""; then
  app_installed=1
fi

open_expo_go() {
  local url="exp://127.0.0.1:${PORT}"
  echo "Opening $url in Expo Go on the booted simulator…"
  if ! xcrun simctl openurl booted "$url" 2>/dev/null; then
    echo "Failed to open $url — is Expo Go installed on this simulator?" >&2
    echo "Install Expo Go from the App Store inside Simulator, then re-run." >&2
    echo "Confirm Metro is serving this app on port ${PORT} (npx expo start --port ${PORT} --go)." >&2
    exit 1
  fi
  echo "Confirm Metro is serving this app on port ${PORT} (npx expo start --port ${PORT} --go)."
}

metro_host() {
  # Prefer a LAN address (matches `expo run:ios` deep links). Simulator can
  # also reach 127.0.0.1, but some Metro setups advertise the interface IP.
  local ip=""
  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  [[ -z "$ip" ]] && ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(scutil --nwi 2>/dev/null | awk '/address/ {print $3; exit}')"
  fi
  printf '%s\n' "${ip:-127.0.0.1}"
}

open_dev_client() {
  # Launch the installed binary first so the deep link is not claimed by Expo Go.
  # Format: exp+{slug}://expo-development-client/?url=<urlencoded http://HOST:PORT>
  local host metro encoded url
  host="$(metro_host)"
  metro="http://${host}:${PORT}"
  encoded="$(node -e "process.stdout.write(encodeURIComponent(process.argv[1]))" "$metro")"
  url="exp+${SLUG}://expo-development-client/?url=${encoded}"
  echo "Opening development build ($BUNDLE_ID) → $metro …"
  xcrun simctl launch booted "$BUNDLE_ID" >/dev/null 2>&1 || true
  if ! xcrun simctl openurl booted "$url" 2>/dev/null; then
    echo "Deep link failed; app launch alone may still reconnect to Metro." >&2
    if ! xcrun simctl launch booted "$BUNDLE_ID" >/dev/null 2>&1; then
      echo "Failed to open development build $BUNDLE_ID." >&2
      echo "Rebuild with: npm run dev:build:ios" >&2
      echo "Or force Expo Go: npm run open:ios -- --go" >&2
      exit 1
    fi
  fi
  echo "Confirm Metro is serving with: npm run dev:start -- --port ${PORT}"
}

if [[ "$FORCE_GO" -eq 1 ]]; then
  open_expo_go
  exit 0
fi

if [[ "$app_installed" -eq 1 && -n "$SLUG" ]]; then
  open_dev_client
  exit 0
fi

if [[ "$app_installed" -eq 0 ]]; then
  echo "No development build installed for ${BUNDLE_ID:-unknown} — falling back to Expo Go."
  echo "(Build with npm run dev:build:ios, or force Expo Go anytime with --go.)"
fi
open_expo_go
