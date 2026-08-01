#!/usr/bin/env bash
# Local Maestro e2e smoke. Not required in CI (no emulator tax).
#
# Modes:
#   expo-go (default) — Expo Go appId (platform-specific; see below)
#   native            — appId from app.json package / bundleIdentifier
#
# Platforms:
#   ios (default) — also honor E2E_PLATFORM; day-to-day on Mac / Xcode Simulator
#   android       — when exercising Play / emulator lanes
#
# Usage:
#   npm run test:e2e
#   npm run test:e2e -- --flow=onboarding
#   npm run test:e2e -- --mode=native
#   npm run test:e2e -- --platform=android
#   npm run test:e2e -- --mode=native --dev-client   # deep-link into Metro (dev builds)
#   npm run test:e2e -- --allow-skip   # humans only; unattended runway must never pass this
#   E2E_MODE=native E2E_PLATFORM=ios E2E_DEV_CLIENT=1 npm run test:e2e
#
# Valid flows: smoke (default), onboarding — tiny is no-account by design.
# Never mutates the committed apps/mobile/maestro/*.yaml — writes a temp flow instead.
# Missing Maestro / simulator tooling fails by default. --allow-skip exits 0 instead
# (not green for PROCESS — record the skip explicitly).
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/dev/maestro-hygiene.sh
source "$ROOT/scripts/dev/maestro-hygiene.sh"

MODE="${E2E_MODE:-expo-go}"
PLATFORM="${E2E_PLATFORM:-ios}"
PORT="${EXPO_PORT:-8081}"
FLOW="${E2E_FLOW:-smoke}"
NO_BOOT=0
ALLOW_SKIP=0
DEV_CLIENT="${E2E_DEV_CLIENT:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode=*) MODE="${1#--mode=}"; shift ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --platform=*) PLATFORM="${1#--platform=}"; shift ;;
    --platform) PLATFORM="${2:-}"; shift 2 ;;
    --port=*) PORT="${1#--port=}"; shift ;;
    --port) PORT="${2:-}"; shift 2 ;;
    --flow=*) FLOW="${1#--flow=}"; shift ;;
    --flow) FLOW="${2:-}"; shift 2 ;;
    --no-boot) NO_BOOT=1; shift ;;
    --allow-skip) ALLOW_SKIP=1; shift ;;
    --dev-client) DEV_CLIENT=1; shift ;;
    --dev-client=*) DEV_CLIENT="${1#--dev-client=}"; shift ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

# Normalize env-style truthy values (E2E_DEV_CLIENT=1).
case "$DEV_CLIENT" in
  1|true|yes|on) DEV_CLIENT=1 ;;
  *) DEV_CLIENT=0 ;;
esac

skip_or_fail() {
  cat
  if [[ "$ALLOW_SKIP" -eq 1 ]]; then
    echo "(--allow-skip: exiting 0; not green for PROCESS — record the skip in STATUS)"
    exit 0
  fi
  exit 1
}

case "$MODE" in
  expo-go|native) ;;
  *)
    echo "Invalid --mode: $MODE (use expo-go|native)" >&2
    exit 2
    ;;
esac

case "$PLATFORM" in
  android|ios) ;;
  *)
    echo "Invalid --platform: $PLATFORM (use android|ios)" >&2
    exit 2
    ;;
esac

if ! command -v maestro >/dev/null 2>&1; then
  skip_or_fail <<EOF
maestro is not installed.

Install: https://maestro.mobile.dev  (needs Java 17+)
Then start an emulator/simulator with Expo Go (or a native build), and re-run:
  npm run test:e2e
  npm run test:e2e -- --platform=ios
  npm run test:e2e -- --mode=native

Missing tooling fails the e2e gate. Humans may pass --allow-skip knowingly.
EOF
fi

if [[ "$PLATFORM" == "ios" ]]; then
  if [[ "$(uname -s)" != "Darwin" ]]; then
    skip_or_fail <<'EOF'
iOS e2e requires macOS + Xcode Simulator.

Record Skipped (platform) or run on a Mac:
  npm run test:e2e -- --platform=ios
EOF
  fi
  if ! xcrun simctl help >/dev/null 2>&1; then
    skip_or_fail <<'EOF'
xcrun simctl unavailable — install Xcode / Simulator, then re-run:
  npm run test:e2e -- --platform=ios

Missing tooling fails the e2e gate. Humans may pass --allow-skip knowingly.
EOF
  fi
  if [[ "$NO_BOOT" -eq 1 ]]; then
    booted="$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || true)"
    if [[ "${booted:-0}" -lt 1 ]]; then
      skip_or_fail <<'EOF'
No booted iOS Simulator.

1. Open Simulator.app (or: xcrun simctl boot <UDID>)
2. Install Expo Go on the simulator (expo-go mode)
3. Start Metro: npx expo start --port 8081
4. npm run open:ios
5. npm run test:e2e -- --platform=ios

Missing simulator fails the e2e gate. Humans may pass --allow-skip knowingly.
EOF
    fi
  else
    # shellcheck source=scripts/lib/ensure-ios-sim.sh
    source "$ROOT/scripts/lib/ensure-ios-sim.sh"
    if ! ensure_ios_sim; then
      skip_or_fail <<'EOF'
No booted iOS Simulator.

1. Open Simulator.app (or: xcrun simctl boot <UDID>)
2. Install Expo Go on the simulator (expo-go mode)
3. Start Metro: npx expo start --port 8081
4. npm run open:ios
5. npm run test:e2e -- --platform=ios

Missing simulator fails the e2e gate. Humans may pass --allow-skip knowingly.
EOF
    fi
  fi
fi

if [[ "$MODE" == "native" ]]; then
  if [[ "$PLATFORM" == "ios" ]]; then
    APP_ID="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.ios.bundleIdentifier)")"
  else
    APP_ID="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.android.package)")"
  fi
else
  # Expo Go bundle ids differ by platform (capital E on iOS).
  if [[ "$PLATFORM" == "ios" ]]; then
    APP_ID="host.exp.Exponent"
  else
    APP_ID="host.exp.exponent"
  fi
fi

SCHEME="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.scheme)")"

FLOW_SRC="$ROOT/apps/mobile/maestro/${FLOW}.yaml"
if [[ ! -f "$FLOW_SRC" ]]; then
  echo "Missing $FLOW_SRC (use --flow=smoke|onboarding or a apps/mobile/maestro/<name>.yaml)" >&2
  exit 1
fi

DEBUG_DIR="$(maestro_debug_dir "$ROOT")"
FLOW_TMP="${DEBUG_DIR}/e2e-${FLOW}-$$.yaml"
OUT_DIR="${DEBUG_DIR}/e2e-out-${FLOW}-$$"
mkdir -p "$OUT_DIR"
cleanup() {
  rm -f "$FLOW_TMP"
  maestro_scrub_leaks "$ROOT"
}
trap cleanup EXIT

{
  echo "appId: ${APP_ID}"
  echo "---"
  # Prefer launchApp from the flow YAML when present (e.g. clearState).
  if [[ "$MODE" == "native" ]] && ! grep -Eq '^[[:space:]]*-[[:space:]]*launchApp' "$FLOW_SRC"; then
    if [[ "$DEV_CLIENT" -eq 1 ]]; then
      # Cold-start via the Expo deep link so Metro is attached from process start.
      # launchApp-then-openLink is broken on Android here: openLink before the
      # Dev Launcher is ready only lands under Recently Opened; openLink after
      # the launcher has mounted has SIGSEGV'd in libreactnative Fabric remount.
      # openLink-only (and adb am start with the same URL) load the bundle cleanly.
      echo "- openLink: ${SCHEME}://expo-development-client/?url=http%3A%2F%2Flocalhost%3A${PORT}"
      if [[ "$PLATFORM" == "ios" ]]; then
        echo "- tapOn:"
        echo "    text: 'Open'"
        echo "    optional: true"
      fi
      echo "- extendedWaitUntil:"
      echo "    visible:"
      echo "      id: home-screen"
      echo "    timeout: 60000"
      echo "    optional: true"
    else
      echo "- launchApp"
    fi
  fi
  # Body after the YAML document separator in the committed flow.
  # Substitute ${EXPO_PORT} so deep-links hit the active Metro port.
  awk 'BEGIN{p=0} /^---$/{p=1; next} p{print}' "$FLOW_SRC" | sed "s/\${EXPO_PORT:-8081}/${PORT}/g; s/\${EXPO_PORT}/${PORT}/g"
} > "$FLOW_TMP"

echo "Maestro mode=$MODE platform=$PLATFORM flow=$FLOW appId=$APP_ID devClient=$DEV_CLIENT (temp flow; apps/mobile/maestro/${FLOW}.yaml untouched)"
echo "Maestro debug output → $OUT_DIR"

# iOS: disable password AutoFill so "Save Password?" does not interrupt e2e.
if [[ "$PLATFORM" == "ios" ]]; then
  SIM_UDID="$(xcrun simctl list devices booted 2>/dev/null | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*(Booted).*/\1/p' | head -1)"
  if [[ -n "${SIM_UDID:-}" ]]; then
    SIM_DATA="$HOME/Library/Developer/CoreSimulator/Devices/${SIM_UDID}/data"
    for plist in \
      "$SIM_DATA/Containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/UserSettings.plist" \
      "$SIM_DATA/Library/UserConfigurationProfiles/EffectiveUserSettings.plist" \
      "$SIM_DATA/Library/UserConfigurationProfiles/PublicInfo/PublicEffectiveUserSettings.plist"
    do
      if [[ -f "$plist" ]]; then
        plutil -replace restrictedBool.allowPasswordAutoFill.value -bool NO "$plist" 2>/dev/null || true
      fi
    done
    # Also flip the WebUI preference when present.
    if [[ -f "$SIM_DATA/Library/Preferences/com.apple.WebUI.plist" ]]; then
      plutil -replace AutoFillPasswords -bool false "$SIM_DATA/Library/Preferences/com.apple.WebUI.plist" 2>/dev/null || true
    fi
    echo "Disabled Simulator password AutoFill on $SIM_UDID (e2e hygiene)"
  fi
fi

# Emulator → host Metro: needed for expo-go and for native --dev-client.
if [[ "$PLATFORM" == "android" ]]; then
  if command -v adb >/dev/null 2>&1; then
    adb reverse "tcp:${PORT}" "tcp:${PORT}" >/dev/null 2>&1 || true
  fi
fi

if [[ "$MODE" == "expo-go" ]]; then
  if [[ "$PLATFORM" == "android" ]]; then
    cat <<EOF
Expo Go tips (Android):
  - Metro must be serving this app (e.g. npx expo start --port ${PORT})
  - Open the project on the emulator first:
      npm run open:android -- --port ${PORT}
      # or: bash scripts/dev/open-expo-go-android.sh --port ${PORT}
EOF
  else
    cat <<EOF
Expo Go tips (iOS Simulator):
  - Metro must be serving this app (e.g. npx expo start --port ${PORT})
  - Boot a simulator, install Expo Go, then:
      npm run open:ios -- --port ${PORT}
      # or: bash scripts/dev/open-expo-go-ios.sh --port ${PORT}
  - No adb reverse needed — simulator uses host localhost.
EOF
  fi
fi

BEFORE_STATUS="$(git status --porcelain -- "apps/mobile/maestro/${FLOW}.yaml" 2>/dev/null || true)"
maestro -p "$PLATFORM" test "$FLOW_TMP" --test-output-dir="$OUT_DIR" --flatten-debug-output
AFTER_STATUS="$(git status --porcelain -- "apps/mobile/maestro/${FLOW}.yaml" 2>/dev/null || true)"
if [[ "$BEFORE_STATUS" != "$AFTER_STATUS" ]]; then
  echo "ERROR: apps/mobile/maestro/${FLOW}.yaml was modified — test-e2e must not dirty the repo" >&2
  exit 1
fi
maestro_scrub_leaks "$ROOT"
