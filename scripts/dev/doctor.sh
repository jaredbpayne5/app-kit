#!/usr/bin/env bash
#
# scripts/dev/doctor.sh — read-only preflight for the local-first mobile template.
#
# Usage:
#   bash scripts/dev/doctor.sh                              # default tier: local, platform: ios
#   bash scripts/dev/doctor.sh --tier=core
#   bash scripts/dev/doctor.sh --tier=local
#   bash scripts/dev/doctor.sh --tier=device                 # require simulator (default platform ios)
#   bash scripts/dev/doctor.sh --tier=device --platform=ios
#   bash scripts/dev/doctor.sh --tier=device --platform=android
#   bash scripts/dev/doctor.sh --tier=launch --platform=both
#   bash scripts/dev/doctor.sh --quiet
#
# Tiers (a failed check is FATAL only if its level <= the selected tier):
#   1 core    node / npm / git
#   2 local   apps/mobile/app.json / apps/mobile/eas.json / identity hygiene
#   3 device  Java 17+, Maestro, + platform device (adb emu and/or iOS sim),
#             plus iOS Xcode/CocoaPods + development-build state (primary loop)
#   4 launch  eas-cli + non-placeholder package / bundle id (Store launch)
#
# Platform (default ios): android | ios | both — gates which device/launch
# checks run. Day-to-day default is iOS (Xcode Simulator). Use --platform=both
# (or android) when preparing Android / full store-launch lanes.
#
set -uo pipefail

TIER="local"
PLATFORM="ios"
QUIET=0
for arg in "$@"; do
  case "$arg" in
    --tier=*) TIER="${arg#--tier=}" ;;
    --platform=*) PLATFORM="${arg#--platform=}" ;;
    --quiet|-q) QUIET=1 ;;
    *) printf 'Unknown arg: %s\n' "$arg" >&2; exit 2 ;;
  esac
done
case "$TIER" in
  core)   THRESHOLD=1 ;;
  local)  THRESHOLD=2 ;;
  device) THRESHOLD=3 ;;
  launch) THRESHOLD=4 ;;
  all)    THRESHOLD=4 ;;
  *) printf 'Invalid --tier: %s (use core|local|device|launch|all)\n' "$TIER" >&2; exit 2 ;;
esac
case "$PLATFORM" in
  android|ios|both) ;;
  *) printf 'Invalid --platform: %s (use android|ios|both)\n' "$PLATFORM" >&2; exit 2 ;;
esac

want_android=0
want_ios=0
case "$PLATFORM" in
  android) want_android=1 ;;
  ios) want_ios=1 ;;
  both) want_android=1; want_ios=1 ;;
esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; cd "$ROOT" || exit 1

if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else GREEN=""; YELLOW=""; RED=""; DIM=""; BOLD=""; RESET=""; fi
FAIL=0
ok()   { [[ "$QUIET" == 1 ]] || printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()  {
  local level="$1"; shift
  if [[ "$level" -le "$THRESHOLD" ]]; then printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; FAIL=1
  else warn "$* ${DIM}(not required for tier=$TIER)${RESET}"; fi
}
have() { command -v "$1" >/dev/null 2>&1; }

printf '%sEnvironment doctor%s  %s(tier=%s platform=%s)%s\n' "$BOLD" "$RESET" "$DIM" "$TIER" "$PLATFORM" "$RESET"

printf '\n%score%s\n' "$BOLD" "$RESET"

if have node; then
  have_ver="$(node -v | tr -dc '0-9.')"; have_major="${have_ver%%.*}"
  if [[ -f .nvmrc ]]; then
    want_ver="$(tr -dc '0-9.' < .nvmrc)"; want_major="${want_ver%%.*}"
    if [[ -n "$want_major" && "$have_major" -ge "$want_major" ]]; then
      ok "node $have_ver (>= .nvmrc $want_ver)"
    else
      bad 1 "node $have_ver but .nvmrc wants >= $want_ver — run: nvm use / fnm use"
    fi
  else
    warn "node $have_ver present, but no .nvmrc found"
  fi
else
  bad 1 "node missing"
fi

have npm && ok "npm ($(npm -v))" || bad 1 "npm missing"
have git && ok "git ($(git --version | awk '{print $3}'))" || bad 1 "git missing"
if have jq; then
  ok "jq ($(jq --version 2>/dev/null | head -1))"
else
  bad 1 "jq missing — required for Claude hooks, screenshots, deploy scripts (brew install jq)"
fi
if have gitleaks; then
  ok "gitleaks ($(gitleaks version 2>/dev/null | head -1 || echo installed))"
else
  warn "gitleaks missing — pre-commit falls back to a weaker grep (brew install gitleaks)"
fi
if have python3; then
  ok "python3 ($(python3 --version 2>/dev/null | awk '{print $2}'))"
else
  bad 1 "python3 missing — required for ensure-ios-sim, screenshots, deploy scripts"
fi

printf '\n%slocal%s\n' "$BOLD" "$RESET"

if [[ -f package.json ]]; then ok "package.json present"; else bad 2 "package.json missing"; fi
APP_JSON="apps/mobile/app.json"
EAS_JSON="apps/mobile/eas.json"
MOBILE_PKG="apps/mobile/package.json"
if [[ -f "$APP_JSON" ]]; then ok "apps/mobile/app.json present"; else bad 2 "apps/mobile/app.json missing"; fi
if [[ -f "$EAS_JSON" ]]; then ok "apps/mobile/eas.json present"; else bad 2 "apps/mobile/eas.json missing"; fi

if [[ -d apps/mobile/android ]] || [[ -d apps/mobile/ios ]]; then
  warn "apps/mobile/android/ or apps/mobile/ios/ exists locally — prefer CNG + EAS; do not commit these folders"
else
  ok "no committed native folders (apps/mobile android/ios absent)"
fi

if [[ -f "$APP_JSON" ]]; then
  if [[ "$want_android" -eq 1 ]]; then
    if grep -q '"package": "com.example' "$APP_JSON" 2>/dev/null; then
      warn "android.package still com.example.* — set a real package id in app.json before Play upload"
    elif grep -q 'com.anonymous' "$APP_JSON" 2>/dev/null; then
      bad 2 "android.package still com.anonymous.* — set a real package id in app.json"
    else
      ok "android.package does not look anonymous"
    fi
  fi
  if [[ "$want_ios" -eq 1 ]]; then
    if grep -q '"bundleIdentifier": "com.example' "$APP_JSON" 2>/dev/null; then
      warn "ios.bundleIdentifier still com.example.* — set a real bundle id in app.json before App Store upload"
    elif grep -q '"bundleIdentifier": "com.anonymous' "$APP_JSON" 2>/dev/null; then
      bad 2 "ios.bundleIdentifier still com.anonymous.* — set a real bundle id in app.json"
    else
      ok "ios.bundleIdentifier does not look anonymous"
    fi
  fi
  if grep -q 'REPLACE_WITH_EAS_PROJECT_ID' "$APP_JSON" 2>/dev/null; then
    warn "EAS projectId still placeholder — set during Store launch / eas build:configure"
  fi
fi

if grep -q 'REPLACE_WITH_COPYRIGHT_HOLDER' LICENSE 2>/dev/null; then
  warn "LICENSE still has REPLACE_WITH_COPYRIGHT_HOLDER — re-run init-app with --copyright-holder (or edit LICENSE by hand)"
elif [[ -f LICENSE ]]; then
  ok "LICENSE copyright holder is stamped"
fi

if compgen -G '*service-account*.json' >/dev/null 2>&1; then
  bad 2 "service-account JSON found in repo root — remove it (use EAS credentials)"
else
  ok "no service-account JSON in repo root"
fi

printf '\n%sproduct docs%s\n' "$BOLD" "$RESET"
if [[ ! -f docs/PRD.md ]]; then
  bad 2 "product doc missing: docs/PRD.md"
elif grep -q 'TEMPLATE_PLACEHOLDER' docs/PRD.md 2>/dev/null; then
  warn "docs/PRD.md still has TEMPLATE_PLACEHOLDER — Claude /app-product before building UI"
  ok "docs/PRD.md present (sentinel still template default — expected on a fresh clone)"
else
  ok "docs/PRD.md present and sentinel cleared"
fi
printf '  %sNext: Claude /app-product → pictures in docs/design-exports/ → Claude /app-design → Cursor /app-critic → Claude /app-plan → jobs.%s\n' "$DIM" "$RESET"

# Factory wiring — catches drift between what a config points at and what
# exists. A hook registered to a deleted script, a skill citing an npm script
# that was renamed, or a skill whose name no longer matches its folder all fail
# silently at the moment they are needed.
printf '\n%sfactory wiring%s\n' "$BOLD" "$RESET"

if have jq; then
  missing_hooks=""
  if [[ -f .cursor/hooks.json ]]; then
    while read -r hook_cmd; do
      [[ -z "$hook_cmd" ]] && continue
      hook_path="${hook_cmd##* }"
      [[ -f "$hook_path" ]] || missing_hooks="${missing_hooks} ${hook_path}"
    done < <(jq -r '.hooks | to_entries[] | .value[] | .command' .cursor/hooks.json 2>/dev/null)
  fi
  if [[ -f .claude/settings.json ]]; then
    while read -r hook_cmd; do
      [[ -z "$hook_cmd" ]] && continue
      hook_path="${hook_cmd/\$\{CLAUDE_PROJECT_DIR\}\//}"
      [[ -f "$hook_path" ]] || missing_hooks="${missing_hooks} ${hook_path}"
    done < <(jq -r '.hooks | to_entries[] | .value[] | .hooks[]? | .command' .claude/settings.json 2>/dev/null)
  fi
  if [[ -z "$missing_hooks" ]]; then
    ok "every registered hook script exists"
  else
    bad 2 "registered hook script(s) missing:${missing_hooks}"
  fi
else
  warn "jq missing — skipped hook wiring check"
fi

# npm scripts cited by a skill or recipe must exist, or the instruction is a
# dead end the moment an agent follows it.
if have jq && [[ -f package.json ]]; then
  missing_scripts=""
  cited="$(grep -rhoE 'npm run [a-z][a-z0-9:_-]*' \
    .cursor/skills .claude/skills AGENTS.md docs/recipes 2>/dev/null \
    | sed 's/^npm run //' | sort -u)"
  for s in $cited; do
    jq -e --arg s "$s" '.scripts[$s]' package.json >/dev/null 2>&1 \
      || missing_scripts="${missing_scripts} ${s}"
  done
  if [[ -z "$missing_scripts" ]]; then
    ok "every 'npm run' cited in a skill or recipe exists in package.json"
  else
    bad 2 "skill/recipe cites missing npm script(s):${missing_scripts}"
  fi
fi

# Skill frontmatter drives the / menu. A missing name or description makes a
# skill unlistable; a name that no longer matches its folder is silent drift.
skill_problems=""
skill_count=0
while IFS= read -r skill; do
  [[ -z "$skill" ]] && continue
  skill_count=$((skill_count + 1))
  dir_name="$(basename "$(dirname "$skill")")"
  head -1 "$skill" | grep -q '^---$' \
    || skill_problems="${skill_problems} ${skill}:no-frontmatter"
  grep -qE '^name:[[:space:]]*\S' "$skill" \
    || skill_problems="${skill_problems} ${skill}:no-name"
  # A description must carry real words. An empty quoted value ("" or '') is as
  # unlistable as a missing key. A folded scalar (>- or |) continues on the
  # next line, so follow it before judging.
  awk '
    /^description:/ {
      value = $0
      sub(/^description:[[:space:]]*/, "", value)
      if (value ~ /^[>|][-+]?$/) { getline value }
      if (value ~ /[A-Za-z]/) { found = 1 }
      exit
    }
    END { exit(found ? 0 : 1) }
  ' "$skill" || skill_problems="${skill_problems} ${skill}:no-description"
  declared="$(sed -nE 's/^name:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' "$skill" | head -1)"
  if [[ -n "$declared" && "$declared" != "$dir_name" ]]; then
    skill_problems="${skill_problems} ${skill}:name-is-${declared}-but-folder-is-${dir_name}"
  fi
  if grep -qE '^disable-model-invocation:' "$skill" \
    && ! grep -qE '^disable-model-invocation:[[:space:]]*true$' "$skill"; then
    skill_problems="${skill_problems} ${skill}:disable-model-invocation-not-true"
  fi
done < <(find .cursor/skills .claude/skills -name 'SKILL.md' 2>/dev/null | sort)

if [[ "$skill_count" -eq 0 ]]; then
  bad 2 "no SKILL.md files found under .cursor/skills or .claude/skills"
elif [[ -z "$skill_problems" ]]; then
  ok "$skill_count skill(s) have valid frontmatter and match their folder"
else
  bad 2 "skill frontmatter problem(s):${skill_problems}"
fi

printf '\n%slocal runtime%s\n' "$BOLD" "$RESET"
ok "backend: none (local-first — no Docker / hosted BaaS checks)"

printf '\n%sdevice / e2e%s\n' "$BOLD" "$RESET"
printf '  %sUse --tier=device when Maestro / simulator / development-build checks are required.%s\n' "$DIM" "$RESET"
printf '  %sPlatform=%s — Android adb and/or iOS simctl + CocoaPods / Xcode apply accordingly.%s\n' "$DIM" "$PLATFORM" "$RESET"
printf '  %sPrimary loop is the development build; Expo Go is only for the no-native path (--go).%s\n' "$DIM" "$RESET"

# Level 3: shared Maestro tooling (both platforms).
if have java; then
  java_ver="$(java -version 2>&1 | head -1 | tr -dc '0-9.' | cut -d. -f1)"
  if [[ -n "$java_ver" && "$java_ver" -ge 17 ]]; then
    ok "java $java_ver (>= 17 for Maestro)"
  else
    bad 3 "java present but < 17 — Maestro needs 17+ (Temurin/Zulu JDK)"
  fi
else
  bad 3 "java missing — install JDK 17+ before Maestro e2e"
fi

if have maestro; then
  ok "maestro ($(maestro --version 2>/dev/null | head -1 || echo installed))"
else
  bad 3 "maestro missing — https://maestro.mobile.dev (needed for npm run test:e2e)"
fi

if have watchman; then
  ok "watchman ($(watchman -v 2>/dev/null || echo installed))"
else
  warn "watchman missing — optional; Metro/Jest are happier with it (brew install watchman)"
fi

# Android device checks
if [[ "$want_android" -eq 1 ]]; then
  if have adb; then
    devices="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')"
    if [[ -n "$devices" ]]; then
      ok "adb device(s): $(echo "$devices" | tr '\n' ' ')"
      if adb shell pm path host.exp.exponent >/dev/null 2>&1; then
        ok "Expo Go installed on Android (host.exp.exponent)"
      else
        warn "Expo Go not on Android device — install for early UI smoke, or use a native build"
      fi
    else
      bad 3 "adb present but no device in 'device' state — start an Android emulator for Maestro"
    fi
  else
    bad 3 "adb missing — install Android platform-tools / Android Studio for Maestro"
  fi
fi

# iOS simulator + development-build checks (dev-build-first; Expo Go = no-native only)
if [[ "$want_ios" -eq 1 ]]; then
  if [[ "$(uname -s)" != "Darwin" ]]; then
    if [[ "$PLATFORM" == "ios" ]]; then
      # Explicit --platform=ios on non-Mac: fatal at device tier.
      bad 3 "iOS device checks require macOS (uname=$(uname -s)) — use a Mac for --platform=ios"
    else
      # Default platform=both: do not fail Android-only machines at device tier.
      warn "iOS device checks require macOS (skipped on $(uname -s); use --platform=android here, or --platform=ios on a Mac)"
    fi
  else
    printf '\n%sdev-build (ios)%s\n' "$BOLD" "$RESET"

    if [[ -d /Applications/Xcode.app ]]; then
      ok "Xcode.app present (/Applications/Xcode.app)"
    else
      bad 3 "Xcode.app missing — install Xcode from the App Store (needed for npm run dev:build:ios)"
    fi

    if xcode-select -p >/dev/null 2>&1; then
      ok "Xcode CLT present ($(xcode-select -p))"
    else
      bad 3 "Xcode Command Line Tools missing — run: xcode-select --install"
    fi

    if have xcrun && xcrun simctl help >/dev/null 2>&1; then
      ok "xcrun simctl available"
    else
      bad 3 "xcrun simctl unavailable — install Xcode / CLT for Simulator + open:ios"
    fi

    if have pod; then
      ok "CocoaPods ($(pod --version 2>/dev/null | head -1))"
    else
      bad 3 "CocoaPods missing — brew install cocoapods (needed for local expo run:ios)"
    fi

    if [[ -f "$MOBILE_PKG" ]] && node -e "const d=require('./apps/mobile/package.json').dependencies||{}; if(!d['expo-dev-client']) process.exit(1)" 2>/dev/null; then
      ok "expo-dev-client dependency present"
    else
      bad 3 "expo-dev-client missing from apps/mobile/package.json — npx expo install expo-dev-client"
    fi

    bundle_id=""
    if [[ -f "$APP_JSON" ]]; then
      bundle_id="$(node -e "const j=require('./apps/mobile/app.json'); process.stdout.write((j.expo&&j.expo.ios&&j.expo.ios.bundleIdentifier)||'')" 2>/dev/null || true)"
    fi

    booted=0
    if have xcrun && xcrun simctl help >/dev/null 2>&1; then
      booted="$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || true)"
    fi

    if [[ "${booted:-0}" -gt 0 ]]; then
      ok "iOS simulator booted ($booted)"
      if [[ -n "$bundle_id" ]] && xcrun simctl listapps booted 2>/dev/null | grep -Fq "\"$bundle_id\""; then
        ok "development build installed on simulator ($bundle_id)"
      else
        warn "development build not installed for ${bundle_id:-unknown} — run: npm run dev:build:ios"
        if [[ -d /Applications/Xcode.app ]] && have pod && have xcrun; then
          ok "development build compilable locally (npm run dev:build:ios)"
        else
          bad 3 "development build not installed and not compilable — fix Xcode/CocoaPods, then npm run dev:build:ios"
        fi
      fi
      if xcrun simctl listapps booted 2>/dev/null | grep -q host.exp.Exponent; then
        ok "Expo Go installed (optional — no-native path only: npm run open:ios -- --go)"
      else
        warn "Expo Go not on simulator — only needed for no-native UI via --go (primary loop uses the development build)"
      fi
    else
      warn "no booted iOS simulator — will auto-boot when you run open:ios / dev:build:ios / test:e2e"
      if [[ -d /Applications/Xcode.app ]] && have pod && have xcrun && xcrun simctl help >/dev/null 2>&1; then
        ok "development build compilable locally (npm run dev:build:ios)"
      else
        bad 3 "cannot compile development build — need Xcode.app + CocoaPods + xcrun simctl"
      fi
      warn "Expo Go check skipped (no booted simulator) — Expo Go is optional for the no-native path only"
    fi
  fi
fi

printf '\n%slaunch tools%s\n' "$BOLD" "$RESET"
if have eas; then
  ok "eas-cli ($(eas --version 2>/dev/null | head -1))"
else
  bad 4 "eas-cli missing — npm i -g eas-cli (needed for Store launch builds)"
fi

if [[ -f "$APP_JSON" ]]; then
  if [[ "$want_android" -eq 1 ]]; then
    if grep -q '"versionCode": 1' "$APP_JSON" 2>/dev/null; then
      warn "android.versionCode is still 1 — bump before each store release after the first (npm run bump-version)"
    fi
    if grep -q '"package": "com.example' "$APP_JSON" 2>/dev/null; then
      bad 4 "android.package still com.example.* — set a real package id in apps/mobile/app.json"
    fi
  fi
  if [[ "$want_ios" -eq 1 ]]; then
    if grep -q '"buildNumber": "1"' "$APP_JSON" 2>/dev/null; then
      warn "ios.buildNumber is still \"1\" — bump before each App Store / TestFlight upload after the first"
    fi
    if grep -q '"bundleIdentifier": "com.example' "$APP_JSON" 2>/dev/null; then
      bad 4 "ios.bundleIdentifier still com.example.* — set a real bundle id in apps/mobile/app.json"
    fi
  fi
fi

if [[ "$want_ios" -eq 1 && -f "$EAS_JSON" ]]; then
  if grep -q 'REPLACE_WITH_APP_STORE_CONNECT_APP_ID' "$EAS_JSON" 2>/dev/null; then
    warn "apps/mobile/eas.json ascAppId still REPLACE_WITH_APP_STORE_CONNECT_APP_ID — set before iOS submit"
  fi
fi

# Factory credentials — fatal only at launch tier (level 4).
printf '\n%sfactory credentials%s\n' "$BOLD" "$RESET"
AF_HOME="${HOME}/.app-factory"
if [[ "$want_ios" -eq 1 ]]; then
  if compgen -G "${AF_HOME}/asc/"*.p8 >/dev/null 2>&1; then
    ok "${HOME}/.app-factory/asc/*.p8 present"
  else
    bad 4 "${HOME}/.app-factory/asc/*.p8 missing — place App Store Connect API .p8 key"
  fi
fi
if [[ "$want_android" -eq 1 ]]; then
  if [[ -f "${AF_HOME}/play/service-account.json" ]]; then
    ok "${HOME}/.app-factory/play/service-account.json present"
  else
    bad 4 "${HOME}/.app-factory/play/service-account.json missing — place Play service account JSON"
  fi
fi
if [[ -f "${AF_HOME}/env" ]]; then
  if grep -q '^[[:space:]]*CLOUDFLARE_API_TOKEN=' "${AF_HOME}/env" 2>/dev/null; then
    ok "${HOME}/.app-factory/env defines CLOUDFLARE_API_TOKEN"
  else
    bad 4 "${HOME}/.app-factory/env missing CLOUDFLARE_API_TOKEN (values never printed)"
  fi
else
  bad 4 "${HOME}/.app-factory/env missing — create with CLOUDFLARE_API_TOKEN"
fi
if have eas; then
  if eas whoami >/dev/null 2>&1; then
    ok "eas whoami (logged in)"
  else
    bad 4 "eas whoami failed — run: eas login (or set EXPO_TOKEN)"
  fi
else
  bad 4 "eas-cli missing — cannot run eas whoami"
fi

# EAS production env names — never print values.
if [[ "$THRESHOLD" -ge 4 ]]; then
  printf '\n%seas production env%s\n' "$BOLD" "$RESET"
  if have eas || have npx; then
    eas_bin=(eas)
    have eas || eas_bin=(npx --yes eas-cli)
    eas_prod_env="$(cd apps/mobile && "${eas_bin[@]}" env:list production --non-interactive --format short 2>/dev/null || true)"
    if echo "$eas_prod_env" | grep -q 'EXPO_PUBLIC_APP_NAME'; then
      ok "eas env:list production has EXPO_PUBLIC_APP_NAME (values not printed)"
    else
      warn "eas production may be missing EXPO_PUBLIC_APP_NAME — set before store launch"
    fi
    unset eas_prod_env
  else
    bad 4 "eas-cli missing — cannot verify eas env:list production"
  fi
fi

# Network-heavy; only meaningful at launch tier (can fail the run via bad 4).
if [[ "$THRESHOLD" -ge 4 ]] && have npx; then
  if (cd apps/mobile && npx --yes expo-doctor >/dev/null 2>&1); then
    ok "expo-doctor clean"
  else
    bad 4 "expo-doctor reported issues — run: (cd apps/mobile && npx expo-doctor) (fix before Store launch builds)"
  fi
fi

if [[ "$FAIL" -eq 0 ]]; then
  printf '\n%sAll required checks passed for tier=%s platform=%s.%s\n' "$GREEN" "$TIER" "$PLATFORM" "$RESET"
  exit 0
fi
printf '\n%sDoctor found problems (tier=%s platform=%s).%s\n' "$RED" "$TIER" "$PLATFORM" "$RESET"
exit 1
