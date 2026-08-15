#!/usr/bin/env bash
#
# scripts/store/review-preflight.sh — store/review gate before store:push.
#
# Usage:
#   npm run preflight
#   bash scripts/store/review-preflight.sh [--gate=4|6] [--skip-heavy]
#
# --gate=4      Harden / store-readiness gate. Checks that cannot pass until
#               later in the store process report DEFERRED (non-failing): live
#               privacy URL HTTP 200, and REPLACE_WITH_EAS_PROJECT_ID /
#               eas.json REPLACE_WITH_*.
# --gate=6      Store-launch gate (default). Deferred checks become hard fails.
# --skip-heavy  Skip npm run verify. Useful for fast local iteration; store:push
#               should always run the full gate.
#
# Exit non-zero with named reasons. Runs all checks, then verify, then summarizes.
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

SKIP_HEAVY=0
GATE=6
for arg in "$@"; do
  case "$arg" in
    --skip-heavy) SKIP_HEAVY=1 ;;
    --gate=4|--gate=6) GATE="${arg#--gate=}" ;;
    --gate=*)
      printf 'Invalid --gate=%s (use 4 or 6)\n' "${arg#--gate=}" >&2
      exit 2
      ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else GREEN=""; YELLOW=""; RED=""; BOLD=""; DIM=""; RESET=""; fi

FAIL=0
DEFERRED=0
ok()     { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()   { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()    { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; FAIL=1; }
defer()  { printf '  %s○%s DEFERRED (gate %s): %s\n' "$DIM" "$RESET" "$GATE" "$*"; DEFERRED=$((DEFERRED + 1)); }

# Committed template placeholder hashes. Update only when the template
# intentionally ships new placeholder artwork.
ICON_PLACEHOLDER_SHA256="97f876fed8209b3d6a0e049dc3eb396a490d75c2b9eaec2c824fb9f55ad7a7b8"
SPLASH_PLACEHOLDER_SHA256="eee47afc2763a3b7b6b5835d9523ce8454dd4f32ce71d55b8e2b3c3a878bf4d3"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# Epoch seconds. Pick the correct `stat` flavor first — do not chain
# `stat -f … || stat -c …` (GNU `-f` is not a clean failure on Linux).
# shellcheck disable=SC2329 # kept for the stat portability note; see REPO-EVALUATION.md §3
mtime_file() {
  if [[ "$(uname -s)" == Darwin ]]; then
    stat -f %m "$1"
  else
    stat -c %Y "$1"
  fi
}

read_app_config() {
  # Prints STORAGE, MONETIZATION, PURCHASES_MODE (tab-separated).
  node <<'NODE'
const fs = require("fs");
const s = fs.readFileSync("apps/mobile/lib/app-config.ts", "utf8");
const storage = /STORAGE\s*[:=]\s*['"]([^'"]+)['"]/.exec(s);
const mon = /MONETIZATION\s*[:=]\s*['"]([^'"]+)['"]/.exec(s);
const mode = /PURCHASES_MODE\s*[:=]\s*['"]([^'"]+)['"]/.exec(s);
if (!storage || !mon || !mode) {
  console.error("could not parse app-config");
  process.exit(1);
}
console.log([storage[1], mon[1], mode[1]].join("\t"));
NODE
}

char_count() {
  # Character count without trailing newline (store limits are character-based).
  tr -d '\r\n' < "$1" | wc -m | tr -d ' '
}

png_info() {
  # Prints: width height bytes — or fails.
  python3 - "$1" <<'PY'
import struct, sys, os
path = sys.argv[1]
size = os.path.getsize(path)
with open(path, "rb") as f:
    sig = f.read(8)
    if sig != b"\x89PNG\r\n\x1a\n":
        sys.exit(1)
    length = struct.unpack(">I", f.read(4))[0]
    ctype = f.read(4)
    if ctype != b"IHDR" or length < 8:
        sys.exit(1)
    w, h = struct.unpack(">II", f.read(8))
print(f"{w} {h} {size}")
PY
}

printf '%spreflight%s  %s(gate=%s)%s\n' "$BOLD" "$RESET" "$DIM" "$GATE" "$RESET"

# --- 1. Identity placeholders -------------------------------------------------
# com.example.* always fails. REPLACE_WITH_EAS_PROJECT_ID is deferred at gate 4.
# Other REPLACE_WITH_* (e.g. Sentry org) always fail.
ID_BAD=0
if grep -Eq 'com\.example\.' apps/mobile/app.json; then
  bad "identity_placeholder: apps/mobile/app.json still has com.example.* (set a real name/slug/bundle id — see README)"
  ID_BAD=1
fi
OTHER_REPLACE="$(grep -E 'REPLACE_WITH' apps/mobile/app.json | grep -v 'REPLACE_WITH_EAS_PROJECT_ID' || true)"
if [[ -n "$OTHER_REPLACE" ]]; then
  bad "identity_placeholder: apps/mobile/app.json has REPLACE_WITH besides EAS project id"
  ID_BAD=1
fi
if grep -q 'REPLACE_WITH_EAS_PROJECT_ID' apps/mobile/app.json; then
  if [[ "$GATE" -eq 4 ]]; then
    defer "REPLACE_WITH_EAS_PROJECT_ID still in apps/mobile/app.json (set during Store launch)"
  else
    bad "identity_placeholder: REPLACE_WITH_EAS_PROJECT_ID still in apps/mobile/app.json"
    ID_BAD=1
  fi
fi
if [[ "$ID_BAD" -eq 0 ]]; then
  ok "identity_placeholder: package / bundle id look set"
fi

# --- 2. Metadata TBD / empty --------------------------------------------------
META_FAIL=0
if [[ -d apps/mobile/store/metadata ]]; then
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    [[ "$base" == "README.md" ]] && continue
    [[ "$f" == *.png ]] && continue
    if [[ ! -s "$f" ]]; then
      bad "metadata_tbd: empty file $f"
      META_FAIL=1
      continue
    fi
    if grep -Eq 'TBD' "$f"; then
      bad "metadata_tbd: TBD found in $f"
      META_FAIL=1
    fi
  done < <(find apps/mobile/store/metadata -type f -print0)
else
  bad "metadata_tbd: apps/mobile/store/metadata/ missing"
  META_FAIL=1
fi
if [[ "$META_FAIL" -eq 0 ]]; then
  ok "metadata_tbd: no TBD / empty metadata files"
fi

# --- 3. Store character limits ------------------------------------------------
check_limit() {
  local file="$1" limit="$2" label="$3"
  [[ -f "$file" ]] || return 0
  local n
  n="$(char_count "$file")"
  if [[ "$n" -gt "$limit" ]]; then
    bad "metadata_limit: $label is ${n} chars (limit ${limit}) — $file"
  fi
}
LIMIT_FAIL_BEFORE=$FAIL
check_limit apps/mobile/store/metadata/ios/en-US/name.txt 30 "iOS name"
check_limit apps/mobile/store/metadata/ios/en-US/subtitle.txt 30 "iOS subtitle"
check_limit apps/mobile/store/metadata/ios/en-US/keywords.txt 100 "iOS keywords"
check_limit apps/mobile/store/metadata/android/en-US/title.txt 30 "Android title"
check_limit apps/mobile/store/metadata/android/en-US/short_description.txt 80 "Android short_description"
check_limit apps/mobile/store/metadata/android/en-US/changelogs/default.txt 500 "Android changelog"
if [[ "$FAIL" -eq "$LIMIT_FAIL_BEFORE" ]]; then
  ok "metadata_limit: name/subtitle/keywords/short_description/changelog within limits"
fi

# --- 4. App config + data-practices purchases / RevenueCat --------------------
CFG_OK=1
CFG="$(read_app_config)" || { bad "app_config: could not parse apps/mobile/lib/app-config.ts"; CFG_OK=0; }
STORAGE=""
MONETIZATION=""
PURCHASES_MODE=""
if [[ "$CFG_OK" -eq 1 ]]; then
  STORAGE="$(printf '%s' "$CFG" | cut -f1)"
  MONETIZATION="$(printf '%s' "$CFG" | cut -f2)"
  PURCHASES_MODE="$(printf '%s' "$CFG" | cut -f3)"
  if [[ -z "$STORAGE" ]]; then
    bad "app_config: STORAGE is empty in apps/mobile/lib/app-config.ts"
    CFG_OK=0
  fi
  if [[ -z "$MONETIZATION" ]]; then
    bad "app_config: MONETIZATION is empty in apps/mobile/lib/app-config.ts"
    CFG_OK=0
  fi
  if [[ -z "$PURCHASES_MODE" ]]; then
    bad "app_config: PURCHASES_MODE is empty in apps/mobile/lib/app-config.ts"
    CFG_OK=0
  fi
fi
if [[ "$CFG_OK" -eq 0 ]]; then
  bad "purchases_declared: skipped — app-config could not be parsed"
  bad "purchases_mode: skipped — app-config could not be parsed"
fi

if [[ ! -f apps/mobile/store/data-practices.json ]]; then
  bad "data_practices: apps/mobile/store/data-practices.json missing"
else
  if [[ "$CFG_OK" -eq 1 ]]; then
    PURCHASES_OK="$(
      MONETIZATION="$MONETIZATION" node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("apps/mobile/store/data-practices.json", "utf8"));
const mon = process.env.MONETIZATION;
if (mon && mon !== "free") {
  if (p.collects_purchases !== true || p.data_shared_with_third_parties !== true) {
    process.stdout.write("fail");
    process.exit(0);
  }
}
process.stdout.write("ok");
NODE
    )"
    if [[ "$PURCHASES_OK" != "ok" ]]; then
      bad "purchases_declared: MONETIZATION=$MONETIZATION but data-practices.json must have collects_purchases: true and data_shared_with_third_parties: true (RevenueCat receives purchase history + app-user id)"
    else
      ok "purchases_declared: MONETIZATION=$MONETIZATION matches data-practices purchases/sharing flags"
    fi

    if [[ "$MONETIZATION" != "free" && "$PURCHASES_MODE" == "mock" ]]; then
      if [[ "$GATE" == "4" ]]; then
        defer "purchases_mode: PURCHASES_MODE=mock (flip to live before store launch)"
      else
        bad "purchases_mode: MONETIZATION=$MONETIZATION still has PURCHASES_MODE=mock — a mock paywall must not reach TestFlight"
      fi
    else
      ok "purchases_mode: PURCHASES_MODE=$PURCHASES_MODE"
    fi
  fi

  CONTACT_OK="$(
    node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("apps/mobile/store/data-practices.json", "utf8"));
const e = String(p.contact_email || "").trim();
if (!e) { process.stdout.write("empty"); process.exit(0); }
if (/example\.com/i.test(e)) { process.stdout.write("example"); process.exit(0); }
process.stdout.write("ok");
NODE
  )"
  case "$CONTACT_OK" in
    empty) bad "contact_email: data-practices.json contact_email is empty" ;;
    example) bad "contact_email: data-practices.json contact_email must not use example.com" ;;
    ok) ok "contact_email: set and not example.com" ;;
    *) bad "contact_email: could not validate" ;;
  esac
fi

# --- 5. Sentry DSN vs crash_reporting -----------------------------------------
SENTRY_CHECK="$(
  node <<'NODE'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("apps/mobile/package.json", "utf8"));
const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
const hasSentry = Object.keys(deps).some(
  (k) => k === "@sentry/react-native" || k.startsWith("@sentry/")
);
let dsn = "";
for (const envFile of ["apps/mobile/.env.local", "apps/mobile/.env", ".env.local", ".env"]) {
  if (!fs.existsSync(envFile)) continue;
  const raw = fs.readFileSync(envFile, "utf8");
  const m = /^EXPO_PUBLIC_SENTRY_DSN=(.*)$/m.exec(raw);
  if (m) {
    dsn = m[1].trim().replace(/^["]+|["]+$/g, "");
    if (dsn.length >= 2 && dsn[0] === String.fromCharCode(39) && dsn.at(-1) === String.fromCharCode(39)) {
      dsn = dsn.slice(1, -1);
    }
    break;
  }
}
if (!dsn && process.env.EXPO_PUBLIC_SENTRY_DSN) {
  dsn = String(process.env.EXPO_PUBLIC_SENTRY_DSN).trim();
}
const placeholder = !dsn || /REPLACE_WITH|your[_-]?dsn|example/i.test(dsn);
const practices = JSON.parse(fs.readFileSync("apps/mobile/store/data-practices.json", "utf8"));
const crash = String(practices.crash_reporting || "none").toLowerCase();
if (hasSentry && !placeholder && crash === "none") {
  process.stdout.write("fail");
} else if (hasSentry && !placeholder) {
  process.stdout.write("ok-live");
} else {
  process.stdout.write("ok-dormant");
}
NODE
)"
case "$SENTRY_CHECK" in
  fail)
    bad "sentry_undeclared: @sentry/react-native present with a non-placeholder EXPO_PUBLIC_SENTRY_DSN but data-practices.json crash_reporting is still none"
    ;;
  ok-live) ok "sentry_undeclared: Sentry DSN set; crash_reporting declared" ;;
  ok-dormant) ok "sentry_undeclared: Sentry dormant or undeclared (ok)" ;;
  *) bad "sentry_undeclared: could not validate" ;;
esac

# --- 6. product.json identity / legal URLs ------------------------------------
if [[ ! -f apps/product.json ]]; then
  bad "product_json: apps/product.json missing"
else
  PRODUCT_RC=0
  while IFS= read -r line; do
    case "$line" in
      FAIL:*) bad "product_json: ${line#FAIL:}" ; PRODUCT_RC=1 ;;
      WARN:*) warn "product_json: ${line#WARN:} (store links optional until listing live)" ;;
    esac
  done < <(
    node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("apps/product.json", "utf8"));
for (const k of ["privacyUrl", "termsUrl", "contactEmail"]) {
  const v = String(p[k] || "");
  if (/example\.com/i.test(v) || /\bTBD\b/i.test(v)) {
    console.log(`FAIL:${k} has example.com or TBD`);
  }
}
// Placeholder must stay in sync with apps/product.json and
// scripts/factory/init-app.sh — three languages, no shared constant.
const TAGLINE_PLACEHOLDER = "A short pitch for the marketing lander.";
if (String(p.tagline || "") === TAGLINE_PLACEHOLDER) {
  console.log("FAIL:tagline is still the template placeholder");
}
for (const k of ["iosUrl", "androidUrl"]) {
  if (String(p[k] || "") === "#") console.log(`WARN:${k} is still "#"`);
}
NODE
  )
  if [[ "$PRODUCT_RC" -eq 0 ]]; then
    ok "product_json: privacyUrl/termsUrl/contactEmail/tagline look real"
  fi
fi

# --- 7. Privacy URL HTTP 200 (deferred at gate 4) ----------------------------
PRIV_SEEN=0
while IFS= read -r -d '' urlfile; do
  PRIV_SEEN=1
  url="$(tr -d '\r\n' < "$urlfile")"
  if [[ -z "$url" || "$url" == *TBD* ]]; then
    bad "privacy_url_live: $urlfile is empty or still TBD"
    continue
  fi
  if [[ "$GATE" -eq 4 ]]; then
    defer "privacy_url_live: skipping HTTP 200 for $url (gate 4)"
    continue
  fi
  if curl -sfIL --max-time 15 "$url" >/dev/null 2>&1; then
    ok "privacy_url_live: $url → HTTP 200"
  else
    bad "privacy_url_live: $urlfile ($url) did not return HTTP 200"
  fi
done < <(find apps/mobile/store/metadata -type f -name 'privacy_url.txt' -print0 2>/dev/null)

if [[ "$PRIV_SEEN" -eq 0 ]]; then
  bad "privacy_url_live: no privacy_url.txt under apps/mobile/store/metadata/"
fi

# --- 8. eas.json REPLACE_WITH + android submit track --------------------------
if [[ ! -f apps/mobile/eas.json ]]; then
  bad "eas_json: apps/mobile/eas.json missing"
else
  if grep -Eq 'REPLACE_WITH' apps/mobile/eas.json; then
    if [[ "$GATE" -eq 4 ]]; then
      defer "eas.json still has REPLACE_WITH_* (set during Store launch)"
    else
      bad "eas_json: apps/mobile/eas.json still has REPLACE_WITH_*"
    fi
  else
    ok "eas_json: no REPLACE_WITH_* placeholders"
  fi
  TRACK="$(
    node <<'NODE'
const j = require("./apps/mobile/eas.json");
const t = j?.submit?.production?.android?.track;
process.stdout.write(t == null ? "" : String(t));
NODE
  )"
  if [[ -z "$TRACK" ]]; then
    bad "eas_track: submit.production.android.track missing"
  elif [[ "$TRACK" == "production" ]]; then
    bad "eas_track: submit.production.android.track is \"production\" — must stay internal/draft until human promote"
  else
    ok "eas_track: android submit track is \"$TRACK\" (not production)"
  fi
fi

# --- 9. Placeholder icon/splash hashes ----------------------------------------
ICON_HASH="$(sha256_file apps/mobile/assets/images/icon.png)"
SPLASH_HASH="$(sha256_file apps/mobile/assets/images/splash.png)"
if [[ "$ICON_HASH" == "$ICON_PLACEHOLDER_SHA256" || "$SPLASH_HASH" == "$SPLASH_PLACEHOLDER_SHA256" ]]; then
  bad "placeholder_assets: icon/splash SHA256 still matches template placeholders (run npm run brand:generate with a real master)"
else
  ok "placeholder_assets: icon/splash differ from template placeholders"
fi

# --- 10. Screenshots (valid PNGs under metadata per platform) -----------------
check_platform_shots() {
  local platform="$1"
  local dir="apps/mobile/store/metadata/${platform}"
  if [[ ! -d "$dir" ]]; then
    bad "screenshots: $dir missing"
    return
  fi
  local found=0
  while IFS= read -r -d '' png; do
    found=1
    if ! info="$(png_info "$png" 2>/dev/null)"; then
      bad "screenshots: $png is not a valid PNG"
      continue
    fi
    w="$(printf '%s' "$info" | awk '{print $1}')"
    h="$(printf '%s' "$info" | awk '{print $2}')"
    bytes="$(printf '%s' "$info" | awk '{print $3}')"
    if [[ "$w" -lt 1 || "$h" -lt 1 ]]; then
      bad "screenshots: $png has zero dimensions"
      continue
    fi
    # Solid-colour seeded PNGs are tiny relative to pixel count.
    min_bytes=$((w * h / 200))
    if [[ "$min_bytes" -lt 2048 ]]; then min_bytes=2048; fi
    if [[ "$bytes" -lt "$min_bytes" ]]; then
      warn "screenshots: $png is ${bytes}B for ${w}×${h} — implausibly small (likely a solid-colour seed); recapture before store:push"
    fi
  done < <(find "$dir" -type f -name '*.png' -print0 2>/dev/null)
  if [[ "$found" -eq 0 ]]; then
    bad "screenshots: no PNG under $dir — run npm run screenshots -- --platform=$platform"
  else
    ok "screenshots: at least one valid PNG under $dir"
  fi
}
check_platform_shots ios
check_platform_shots android

# --- 11. Compliance freshness (fingerprint vs data-practices) -----------------
# Compare the gen-compliance fingerprint embedded in privacy.md against current
# data-practices.json. This replaces the touch-defeatable mtime heuristic.
if [[ ! -f apps/mobile/store/data-practices.json ]]; then
  bad "compliance_stale: apps/mobile/store/data-practices.json missing"
elif [[ ! -d apps/mobile/store/compliance ]] || [[ -z "$(ls -A apps/mobile/store/compliance 2>/dev/null || true)" ]]; then
  bad "compliance_stale: apps/mobile/store/compliance/ empty — run npm run gen-compliance"
elif [[ ! -f apps/web/content/privacy.md ]]; then
  bad "compliance_stale: apps/web/content/privacy.md missing"
else
  EXPECTED_FP="$(
    node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("apps/mobile/store/data-practices.json", "utf8"));
process.stdout.write(
  `<!-- gen-compliance fingerprint: accounts=${p.collects_accounts} user_content=${p.collects_user_content} purchases=${p.collects_purchases} analytics=${p.analytics} crash=${p.crash_reporting} shared=${p.data_shared_with_third_parties} -->`
);
NODE
  )"
  if grep -Fq "$EXPECTED_FP" apps/web/content/privacy.md; then
    ok "compliance_stale: privacy.md fingerprint matches data-practices.json"
  else
    bad "compliance_stale: privacy.md fingerprint out of date vs data-practices.json — run npm run gen-compliance"
  fi
fi

# --- 12. Attribution SDK vs data-practices analytics (dormant guard) ----------
ATTR_HIT="$(
  node <<'NODE'
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("apps/mobile/package.json", "utf8"));
const names = [
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.devDependencies || {}),
];
const patterns = [
  /^react-native-appsflyer$/,
  /^react-native-fbsdk(-next)?$/,
  /^react-native-fbsdk-next$/,
  /^react-native-adjust$/,
  /^react-native-branch$/,
  /^react-native-fbads$/,
  /^facebook-nodejs-business-sdk$/,
  /^@react-native-firebase\/analytics$/,
];
const loose = [/fbsdk/i, /facebook-android-sdk/i, /fb-sdk/i, /meta-sdk/i];
const hits = names.filter(
  (n) => patterns.some((re) => re.test(n)) || loose.some((re) => re.test(n))
);
process.stdout.write(hits.join(","));
NODE
)"
ANALYTICS_NONE="$(
  node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("apps/mobile/store/data-practices.json", "utf8"));
process.stdout.write(p.analytics === "none" ? "yes" : "no");
NODE
)"
if [[ -n "$ATTR_HIT" && "$ANALYTICS_NONE" == "yes" ]]; then
  bad "attribution_undeclared: package.json has attribution SDK (${ATTR_HIT}) but data-practices.json analytics is still \"none\" — update data-practices + gen-compliance (see docs/recipes/ads-attribution.md)"
elif [[ -n "$ATTR_HIT" ]]; then
  ok "attribution_undeclared: attribution SDK present (${ATTR_HIT}); analytics is declared (not none)"
else
  ok "attribution_undeclared: no attribution SDK in package.json (dormant)"
fi

# --- 13. Leftover scaffold / demo wording (FAIL, not warn) --------------------
# "placeholder" is also a legitimate TextInput prop and a normal word in doc
# comments, so filter those out — otherwise every real app trips this forever.
# Also match the actual demo copy this template ships (generic words miss it).
SCAFFOLD_HITS="$(
  grep -rniE 'demo|placeholder|todo|lorem ipsum|example screen|Replace this screen with your product|Describe the core loop in one short sentence' \
    --include='*.ts' --include='*.tsx' \
    --exclude='*.test.ts' --exclude='*.test.tsx' \
    apps/mobile/app apps/mobile/components 2>/dev/null \
    | grep -viE 'placeholder[A-Za-z]*=|placeholder[A-Za-z]*\}|^[^:]+:[0-9]+: *(\*|//|/\*)' \
    || true
)"
if [[ -n "$SCAFFOLD_HITS" ]]; then
  bad "scaffold_text: leftover demo/placeholder/TODO wording in app/ or components/:"
  while IFS= read -r line; do
    [[ -n "$line" ]] && printf '      %s\n' "$line"
  done <<< "$SCAFFOLD_HITS"
else
  ok "scaffold_text: no demo/placeholder/TODO wording in app/ or components/"
fi

# --- 13b. Canonical legal markdown still template copy (launch only) ----------
LEGAL_PLACEHOLDER="$(
  grep -lE 'template placeholder|<!-- TBD:' apps/web/content/privacy.md apps/web/content/terms.md 2>/dev/null || true
)"
if [[ -n "$LEGAL_PLACEHOLDER" ]]; then
  if [[ "$GATE" == "4" ]]; then
    defer "legal_copy: privacy/terms markdown still has template placeholder text"
  else
    bad "legal_copy: replace template placeholder copy in: $LEGAL_PLACEHOLDER"
  fi
else
  ok "legal_copy: privacy/terms markdown is not the template placeholder"
fi

# --- 14. verify suite (always after checks, unless --skip-heavy) --------------
if [[ "$SKIP_HEAVY" -eq 1 ]]; then
  warn "verify_suite: skipped (--skip-heavy)"
else
  VERIFY_LOG="$(mktemp)"
  if npm run verify >"$VERIFY_LOG" 2>&1; then
    ok "verify_suite: npm run verify green"
    rm -f "$VERIFY_LOG"
  else
    # Deliberately NOT removed: this log is the only record of why verify
    # failed, and the message above tells the user to read it.
    bad "verify_suite: npm run verify failed (see $VERIFY_LOG)"
  fi
fi

printf '\n'
printf 'gate=%s deferred=%s\n' "$GATE" "$DEFERRED"
if [[ "$FAIL" -ne 0 ]]; then
  printf '%spreflight FAILED%s — fix named reasons above before store:push\n' "$BOLD" "$RESET"
  exit 1
fi
printf '%spreflight OK%s\n' "$BOLD" "$RESET"
exit 0
