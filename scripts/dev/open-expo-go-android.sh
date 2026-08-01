#!/usr/bin/env bash
# Open this Expo project in Expo Go on a connected Android emulator/device.
#
# Usage:
#   bash scripts/dev/open-expo-go-android.sh
#   bash scripts/dev/open-expo-go-android.sh --port 8082
#
# Uses the emulator loopback (10.0.2.2) + adb reverse so LAN IP / firewall
# issues do not block Metro. No Expo account required.
#
set -euo pipefail

PORT="${EXPO_PORT:-8081}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port=*) PORT="${1#--port=}"; shift ;;
    --port) PORT="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found — install Android platform-tools / Android Studio." >&2
  exit 1
fi

if ! adb devices | awk 'NR>1 && $2=="device" { found=1 } END { exit found?0:1 }'; then
  echo "No Android device/emulator in 'device' state. Start an AVD first." >&2
  adb devices -l >&2 || true
  exit 1
fi

# Map device localhost → host Metro. Without this, Expo Go often fails with:
# "Failed to download remote update" / java.io.IOException
adb reverse "tcp:${PORT}" "tcp:${PORT}"

# Prefer 127.0.0.1 *after* reverse (more reliable than 10.0.2.2 on some AVDs).
URL="exp://127.0.0.1:${PORT}"
echo "Opening $URL in Expo Go (adb reverse tcp:${PORT} → host)…"
adb shell am start -a android.intent.action.VIEW -d "$URL" >/dev/null
echo "If you still see download errors: confirm Metro is on port ${PORT}, then re-run this script."
