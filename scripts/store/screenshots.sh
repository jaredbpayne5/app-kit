#!/usr/bin/env bash
#
# scripts/store/screenshots.sh — capture store screenshots via Maestro, then frame them.
#
# Usage:
#   npm run screenshots -- --platform=ios|android|both
#   bash scripts/store/screenshots.sh --platform=ios [--port=8081] [--frame-only]
#   bash scripts/store/screenshots.sh --platform=ios --seed-raw   # synthetic raws (no Maestro)
#
# iOS: boots named sims (6.9" Pro Max class + 6.1"; iPad only if supportsTablet),
#      overrides status bar to 9:41 / full battery, runs apps/mobile/maestro/screenshots.yaml.
# Android: Pixel-class emulator + adb demo mode for a clean status bar.
# Raw → apps/mobile/store/screenshots/raw/<device>/ ; framed → apps/mobile/store/metadata/{ios,android}/en-US/images…
#
# Requires (capture path): Maestro, booted Expo Go / Metro on --port, Xcode simctl / adb.
# Framing requires sharp (devDependency) via scripts/store/frame-screenshots.ts.
# iOS capture auto-boots store-sized sims (Pro Max / 6.1 / iPad) via simctl — same
# idea as scripts/lib/ensure-ios-sim.sh, but device-class-specific for ASC sizes.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/dev/maestro-hygiene.sh
source "$ROOT/scripts/dev/maestro-hygiene.sh"

PLATFORM=""
PORT="${EXPO_PORT:-8081}"
FRAME_ONLY=0
SEED_RAW=0
MODE="${E2E_MODE:-expo-go}"

for arg in "$@"; do
  case "$arg" in
    --platform=*) PLATFORM="${arg#--platform=}" ;;
    --port=*) PORT="${arg#--port=}" ;;
    --frame-only) FRAME_ONLY=1 ;;
    --seed-raw) SEED_RAW=1 ;;
    --mode=*) MODE="${arg#--mode=}" ;;
    -h|--help)
      cat <<'EOF'
Usage: npm run screenshots -- --platform=ios|android|both [--port=8081] [--frame-only] [--seed-raw]

  --platform=ios|android|both   Required.
  --port=<n>                    Metro / Expo Go port (default 8081).
  --frame-only                  Skip capture; frame existing apps/mobile/store/screenshots/raw/.
  --seed-raw                    Write synthetic phone-sized PNGs into raw/ (no Maestro).
                                Useful to prove framing dimensions without a device.
  --mode=expo-go|native         Maestro appId source (default expo-go).

Raw output:    apps/mobile/store/screenshots/raw/<device>/
Framed output: apps/mobile/store/metadata/{ios,android}/en-US/images/…
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
  "") bad "Missing --platform=ios|android|both (see --help)" ;;
  *) bad "Invalid --platform=$PLATFORM (use ios|android|both)" ;;
esac

want_ios=0
want_android=0
case "$PLATFORM" in
  ios) want_ios=1 ;;
  android) want_android=1 ;;
  both) want_ios=1; want_android=1 ;;
esac

RAW_ROOT="$ROOT/apps/mobile/store/screenshots/raw"
mkdir -p "$RAW_ROOT"

supports_tablet="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(String(!!j.expo?.ios?.supportsTablet))")"

# --- Status bar helpers -------------------------------------------------------
ios_status_bar() {
  local udid="$1"
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --dataNetwork wifi \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --operatorName '' \
    --batteryState charged \
    --batteryLevel 100 \
    >/dev/null 2>&1 || warn "status_bar override failed on $udid (continuing)"
}

android_demo_mode() {
  have adb || bad "adb not found — install Android platform-tools"
  adb shell settings put global sysui_demo_allowed 1 >/dev/null
  adb shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
  adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null
  adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 >/dev/null
  adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e level 4 >/dev/null
  adb shell am broadcast -a com.android.systemui.demo -e command battery -e plugged false -e level 100 >/dev/null
}

android_demo_mode_exit() {
  adb shell am broadcast -a com.android.systemui.demo -e command exit >/dev/null 2>&1 || true
}

# --- Simulator discovery ------------------------------------------------------
# Prefer named devices; fall back to fuzzy match. Never creates devices.
resolve_ios_udid() {
  local prefer_pattern="$1"
  local json udid
  json="$(xcrun simctl list devices available -j 2>/dev/null)" || return 1
  # Exact name match first among available iPhones / iPads.
  udid="$(printf '%s' "$json" | jq -r --arg p "$prefer_pattern" '
    .devices
    | to_entries[]
    | select(.key | test("SimRuntime\\.iOS-"))
    | .value[]
    | select(.isAvailable != false)
    | select(.name == $p)
    | .udid
  ' | head -1)"
  if [[ -n "$udid" && "$udid" != "null" ]]; then
    printf '%s' "$udid"
    return 0
  fi
  # Fuzzy: Pro Max for 6.9 class, plain iPhone N for 6.1 class, iPad for tablet.
  udid="$(printf '%s' "$json" | jq -r --arg p "$prefer_pattern" '
    def gen: (.name | capture("iPhone (?<n>[0-9]+)"; "i") | .n | tonumber) // 0;
    [
      .devices
      | to_entries[]
      | select(.key | test("SimRuntime\\.iOS-"))
      | .value[]
      | select(.isAvailable != false)
      | select(
          ($p | test("Pro Max")) and (.name | test("Pro Max"))
          or ($p | test("^iPhone [0-9]+$")) and (.name | test("^iPhone [0-9]+$"))
          or ($p | test("iPad")) and (.name | test("iPad"))
        )
    ]
    | sort_by(gen)
    | last
    | .udid // empty
  ')"
  if [[ -n "$udid" && "$udid" != "null" ]]; then
    printf '%s' "$udid"
    return 0
  fi
  return 1
}

boot_ios_udid() {
  local udid="$1"
  local state
  state="$(xcrun simctl list devices -j | jq -r --arg u "$udid" '
    .devices | to_entries[] | .value[] | select(.udid == $u) | .state
  ' | head -1)"
  if [[ "$state" != "Booted" ]]; then
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    open -a Simulator >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || bad "Timed out booting $udid"
  fi
}

sim_name_for_udid() {
  local udid="$1"
  xcrun simctl list devices -j | jq -r --arg u "$udid" '
    .devices | to_entries[] | .value[] | select(.udid == $u) | .name
  ' | head -1 | tr ' ' '_' | tr -cd 'A-Za-z0-9._-'
}

# --- Maestro ------------------------------------------------------------------
maestro_app_id() {
  if [[ "$MODE" == "native" ]]; then
    if [[ "$1" == "ios" ]]; then
      node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.ios.bundleIdentifier)"
    else
      node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.android.package)"
    fi
  else
    if [[ "$1" == "ios" ]]; then
      printf 'host.exp.Exponent'
    else
      printf 'host.exp.exponent'
    fi
  fi
}

# Deep-link a development build into Metro. Without this, Maestro launchApp
# lands on the Expo Dev Launcher ("No development servers found") and never
# reaches home/settings. Mirrors scripts/dev/open-expo-go-ios.sh — use simctl
# (Maestro openLink can bounce to SpringBoard on iOS).
native_dev_client_url() {
  local slug metro encoded
  slug="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write(j.expo.slug || '')")"
  [[ -n "$slug" ]] || bad "apps/mobile/app.json missing expo.slug (needed for native screenshot deep link)"
  # Simulator reaches the host via 127.0.0.1; LAN IP is for physical devices.
  metro="http://127.0.0.1:${PORT}"
  encoded="$(node -e "process.stdout.write(encodeURIComponent(process.argv[1]))" "$metro")"
  printf 'exp+%s://expo-development-client/?url=%s' "$slug" "$encoded"
}

attach_native_metro_ios() {
  local udid="$1"
  local app_id url
  app_id="$(maestro_app_id ios)"
  url="$(native_dev_client_url)"
  printf 'Attaching development build %s on %s → Metro :%s\n' "$app_id" "$udid" "$PORT"
  xcrun simctl launch "$udid" "$app_id" >/dev/null 2>&1 || true
  xcrun simctl openurl "$udid" "$url" >/dev/null 2>&1 \
    || bad "Failed to deep-link development build to Metro (url=$url)"
  # Give Metro + Expo Router a moment before Maestro asserts shell screens.
  sleep 8
}

run_maestro_screenshots() {
  local platform="$1"
  local out_dir="$2"
  local device_udid="${3:-}"
  local app_id flow_tmp maestro_args=() maestro_rc=0
  local debug_dir
  have maestro || bad "maestro not installed — https://maestro.mobile.dev"
  mkdir -p "$out_dir"
  debug_dir="$(maestro_debug_dir "$ROOT")"
  app_id="$(maestro_app_id "$platform")"
  # Keep the temp flow under the repo (gitignored), never $TMPDIR alone — Maestro
  # failure artifact names include the flow basename and can land in CWD.
  flow_tmp="${debug_dir}/screenshots-flow-$$.yaml"
  {
    echo "appId: ${app_id}"
    echo "---"
    if [[ "$MODE" == "native" && "$platform" == "ios" ]]; then
      # App already attached to Metro via simctl; do not stop/relaunch.
      echo "- launchApp:"
      echo "    stopApp: false"
    elif [[ "$MODE" == "native" && "$platform" == "android" ]]; then
      if have adb; then
        adb reverse "tcp:${PORT}" "tcp:${PORT}" >/dev/null 2>&1 || true
      fi
      echo "- launchApp"
      echo "- openLink: $(native_dev_client_url)"
    fi
    awk 'BEGIN{p=0} /^---$/{p=1; next} p{print}' "$ROOT/apps/mobile/maestro/screenshots.yaml" \
      | sed 's/timeout: 20000/timeout: 60000/'
  } > "$flow_tmp"
  printf 'Maestro screenshots platform=%s mode=%s port=%s appId=%s → %s\n' \
    "$platform" "$MODE" "$PORT" "$app_id" "$out_dir"
  if [[ -n "$device_udid" ]]; then
    maestro_args+=(--device "$device_udid")
  fi
  maestro "${maestro_args[@]}" test "$flow_tmp" --test-output-dir="$out_dir" --flatten-debug-output \
    || maestro_rc=$?
  rm -f "$flow_tmp"
  maestro_scrub_leaks "$ROOT"
  [[ "$maestro_rc" -eq 0 ]] || bad "Maestro screenshots failed (see $out_dir and .maestro-debug/)"
  # Normalize: ensure home.png / settings.png / privacy.png exist at out_dir root.
  local shot
  for shot in home settings privacy; do
    if [[ -f "$out_dir/${shot}.png" ]]; then
      continue
    fi
    local found
    found="$(find "$out_dir" -type f -name "${shot}.png" 2>/dev/null | head -1 || true)"
    if [[ -n "$found" ]]; then
      cp "$found" "$out_dir/${shot}.png"
    else
      bad "Missing Maestro screenshot ${shot}.png under $out_dir"
    fi
  done
  ok "captured home/settings/privacy → $out_dir"
}

# --- Seed synthetic raws (no device) ------------------------------------------
seed_raw_pngs() {
  local out_dir="$1"
  local w="$2"
  local h="$3"
  mkdir -p "$out_dir"
  # Minimal valid RGB PNG via Python (stdlib only) — no sharp needed for seed.
  python3 - "$out_dir" "$w" "$h" <<'PY'
import struct, zlib, sys, os
out_dir, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])

def png(path, width, height, rgb=(40, 44, 52)):
    r, g, b = rgb
    raw = b"".join(b"\x00" + bytes([r, g, b]) * width for _ in range(height))
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)

for name, color in (("home", (40, 44, 52)), ("settings", (30, 58, 95)), ("privacy", (45, 55, 40))):
    png(os.path.join(out_dir, f"{name}.png"), w, h, color)
print(f"seeded {out_dir} ({w}x{h})")
PY
  ok "seeded synthetic raws in $out_dir (${w}x${h})"
}

# --- Capture ------------------------------------------------------------------
printf '%sscreenshots%s  (platform=%s frame_only=%s seed_raw=%s)\n' \
  "$BOLD" "$RESET" "$PLATFORM" "$FRAME_ONLY" "$SEED_RAW"

if [[ "$FRAME_ONLY" -eq 0 ]]; then
  if [[ "$want_ios" -eq 1 ]]; then
    if [[ "$SEED_RAW" -eq 1 ]]; then
      # Approximate iPhone 16 Pro Max logical render; framing scales to store canvas.
      seed_raw_pngs "$RAW_ROOT/iphone_6_9" 1320 2868
      seed_raw_pngs "$RAW_ROOT/iphone_6_1" 1179 2556
      if [[ "$supports_tablet" == "true" ]]; then
        seed_raw_pngs "$RAW_ROOT/ipad_13" 2048 2732
      fi
    else
      [[ "$(uname -s)" == "Darwin" ]] || bad "iOS screenshots require macOS"
      have xcrun || bad "xcrun missing"
      have jq || bad "jq missing — brew install jq"

      # 6.9" / Pro Max class
      local_names=("iPhone 16 Pro Max" "iPhone 15 Pro Max" "iPhone 17 Pro Max")
      udid_69=""
      for n in "${local_names[@]}"; do
        if udid_69="$(resolve_ios_udid "$n")"; then break; fi
      done
      [[ -n "$udid_69" ]] || bad "No Pro Max-class simulator available (install iPhone 16 Pro Max or similar)"
      boot_ios_udid "$udid_69"
      ios_status_bar "$udid_69"
      device_dir="$RAW_ROOT/iphone_6_9"
      if [[ "$MODE" == "native" ]]; then
        attach_native_metro_ios "$udid_69"
      fi
      run_maestro_screenshots ios "$device_dir" "$udid_69"

      # 6.1" class
      local_names_61=("iPhone 16" "iPhone 15" "iPhone 17e" "iPhone 16e")
      udid_61=""
      for n in "${local_names_61[@]}"; do
        if udid_61="$(resolve_ios_udid "$n")"; then break; fi
      done
      if [[ -n "$udid_61" ]]; then
        boot_ios_udid "$udid_61"
        ios_status_bar "$udid_61"
        if [[ "$MODE" == "native" ]]; then
          attach_native_metro_ios "$udid_61"
        fi
        run_maestro_screenshots ios "$RAW_ROOT/iphone_6_1" "$udid_61"
      else
        warn "No 6.1\" iPhone simulator — skipping (6.9\" set is enough for ASC auto-scale)"
      fi

      if [[ "$supports_tablet" == "true" ]]; then
        udid_pad="$(resolve_ios_udid "iPad Pro 13-inch" || resolve_ios_udid "iPad Pro" || true)"
        if [[ -n "${udid_pad:-}" ]]; then
          boot_ios_udid "$udid_pad"
          ios_status_bar "$udid_pad"
          if [[ "$MODE" == "native" ]]; then
            attach_native_metro_ios "$udid_pad"
          fi
          run_maestro_screenshots ios "$RAW_ROOT/ipad_13" "$udid_pad"
        else
          warn "supportsTablet=true but no iPad simulator found"
        fi
      else
        ok "supportsTablet=false — skipping iPad screenshots"
      fi
    fi
  fi

  if [[ "$want_android" -eq 1 ]]; then
    if [[ "$SEED_RAW" -eq 1 ]]; then
      seed_raw_pngs "$RAW_ROOT/pixel_phone" 1080 1920
    else
      have adb || bad "adb not found"
      adb get-state >/dev/null 2>&1 || bad "No Android device/emulator (adb get-state failed)"
      android_demo_mode
      trap android_demo_mode_exit EXIT
      run_maestro_screenshots android "$RAW_ROOT/pixel_phone"
      android_demo_mode_exit
      trap - EXIT
    fi
  fi
else
  ok "skipping capture (--frame-only)"
fi

# --- Frame --------------------------------------------------------------------
if [[ ! -f "$ROOT/scripts/store/frame-screenshots.ts" ]]; then
  bad "scripts/store/frame-screenshots.ts missing"
fi
if ! node -e "require.resolve('sharp')" 2>/dev/null; then
  bad "sharp not installed — npm i -D sharp (already in template package.json)"
fi

printf '\n%sframe-screenshots%s\n' "$BOLD" "$RESET"
npx tsx "$ROOT/scripts/store/frame-screenshots.ts" --platform="$PLATFORM"
ok "framed store canvases written under apps/mobile/store/metadata/"
printf '\n%sdone%s — re-run is idempotent (overwrites framed outputs).\n' "$BOLD" "$RESET"
