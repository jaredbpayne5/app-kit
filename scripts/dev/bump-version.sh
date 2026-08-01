#!/usr/bin/env bash
#
# scripts/factory/bump-version.sh — bump expo.version + android.versionCode (+ ios.buildNumber).
#
# Usage:
#   npm run bump-version                 # patch: 1.0.0 → 1.0.1, versionCode +1
#   npm run bump-version -- --minor      # 1.0.0 → 1.1.0
#   npm run bump-version -- --major      # 1.0.0 → 2.0.0
#   npm run bump-version -- --set 1.2.3  # set marketing version; still +1 native builds
#
set -euo pipefail
SCRIPT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Override for fixture smokes (`FACTORY_ROOT=/tmp/...`). Default: repo root.
ROOT="${FACTORY_ROOT:-$SCRIPT_ROOT}"
ROOT="$(cd "$ROOT" && pwd)"
cd "$ROOT"

MODE="patch"
SET_VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch) MODE="patch"; shift ;;
    --minor) MODE="minor"; shift ;;
    --major) MODE="major"; shift ;;
    --set) SET_VERSION="${2:-}"; shift 2 ;;
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

APP_JSON="$ROOT/apps/mobile/app.json"
MODE="$MODE" SET_VERSION="$SET_VERSION" APP_JSON="$APP_JSON" node <<'NODE'
const fs = require('fs');
const path = process.env.APP_JSON;
const mode = process.env.MODE;
const setVersion = process.env.SET_VERSION || '';
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
const expo = data.expo || (data.expo = {});
expo.android = expo.android || {};
expo.ios = expo.ios || {};

function bumpSemver(v, which) {
  const parts = String(v || '0.0.0').split('.').map((n) => parseInt(n, 10) || 0);
  while (parts.length < 3) parts.push(0);
  if (which === 'major') {
    parts[0] += 1;
    parts[1] = 0;
    parts[2] = 0;
  } else if (which === 'minor') {
    parts[1] += 1;
    parts[2] = 0;
  } else {
    parts[2] += 1;
  }
  return parts.join('.');
}

const prev = expo.version || '1.0.0';
expo.version = setVersion || bumpSemver(prev, mode);

const prevCode = typeof expo.android.versionCode === 'number' ? expo.android.versionCode : 1;
expo.android.versionCode = prevCode + 1;

const prevBuild = String(expo.ios.buildNumber || '1');
const buildNum = (parseInt(prevBuild, 10) || 0) + 1;
expo.ios.buildNumber = String(buildNum);

fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log(`version ${prev} → ${expo.version}`);
console.log(`android.versionCode ${prevCode} → ${expo.android.versionCode}`);
console.log(`ios.buildNumber ${prevBuild} → ${expo.ios.buildNumber}`);
NODE

cat <<'EOF'

OTA reminder (runtimeVersion policy: appVersion):
  • JS-only changes → can ship via: eas update --branch production --message "…"
  • Native-module / native-config changes → require a new store build (EAS Build + submit).
  • See docs/recipes/ota-updates.md
EOF
