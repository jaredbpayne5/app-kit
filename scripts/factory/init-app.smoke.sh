#!/usr/bin/env bash
# scripts/factory/init-app.smoke.sh — FACTORY_ROOT coverage for init-app.sh.
#
# Usage:
#   npm run smoke:init
#   bash scripts/factory/init-app.smoke.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
INIT="$REPO/scripts/factory/init-app.sh"
REAL_APP_JSON="$REPO/apps/mobile/app.json"

PASS=0
FAIL=0
CLEANUPS=()

cleanup() {
  local d
  for d in "${CLEANUPS[@]+"${CLEANUPS[@]}"}"; do
    command rm -rf "$d"
  done
}
trap cleanup EXIT

ok() {
  PASS=$((PASS + 1))
  printf 'ok    %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf 'FAIL  %s\n' "$1"
}

assert_eq() {
  local label="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    ok "$label"
  else
    fail "$label (got $(printf '%q' "$got"), want $(printf '%q' "$want"))"
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$label"
  else
    fail "$label (missing $(printf '%q' "$needle"))"
  fi
}

assert_absent() {
  local label="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    ok "$label"
  else
    fail "$label (still contains $(printf '%q' "$needle"))"
  fi
}

# Parse JSON via read + JSON.parse. Do not require() a .storekit file — Node
# treats the unknown extension as JavaScript.
json() {
  node -e '
    const fs = require("fs");
    const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    let v = j;
    for (const k of process.argv[2].split(".")) {
      v = v == null ? undefined : v[k];
    }
    process.stdout.write(v == null ? "" : String(v));
  ' "$1" "$2"
}

storekit_ids() {
  node -e '
    const fs = require("fs");
    const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const ids = [];
    for (const g of j.subscriptionGroups || []) {
      for (const sub of g.subscriptions || []) {
        if (sub.productID) ids.push(sub.productID);
      }
    }
    process.stdout.write(ids.join("\n"));
  ' "$1"
}

seed_fixture() {
  local dest="$1"
  local rel
  mkdir -p "$dest"
  git -C "$REPO" archive HEAD | tar -x -C "$dest"
  for rel in \
    apps/mobile/app.json \
    apps/product.json \
    apps/mobile/store/storekit/Products.storekit \
    LICENSE
  do
    if [[ ! -f "$dest/$rel" ]]; then
      printf 'FAIL  fixture missing %s after git archive HEAD\n' "$rel"
      exit 1
    fi
  done
}

run_init() {
  local root="$1"
  shift
  FACTORY_ROOT="$root" bash "$INIT" "$@"
}

assert_refusal() {
  local label="$1"
  local want_ec="$2"
  local needle="$3"
  shift 3
  local out ec=0
  out="$(run_init "$REFUSE" "$@" 2>&1)" || ec=$?
  if [[ "$ec" -eq "$want_ec" && "$out" == *"$needle"* ]]; then
    ok "$label"
  else
    fail "$label (exit $ec, expected $want_ec; missing $(printf '%q' "$needle"))"
  fi
}

# --- checksum of the live tree before any run --------------------------------
BEFORE_SUM="$(cksum < "$REAL_APP_JSON")"

# --- refusals share one fixture (they exit before writing) -------------------
REFUSE="$(mktemp -d)"
CLEANUPS+=("$REFUSE")
seed_fixture "$REFUSE"

echo "=== refusals ==="

COMMON=(--name "Smoke App" --copyright-holder "Jane Doe")

assert_refusal \
  "email refusal: Refusing example.com contact email" \
  1 \
  "Refusing example.com contact email" \
  "${COMMON[@]}" --slug smoke-app --package com.smoke.app --contact-email hi@example.com

assert_refusal \
  "package refusal: Refusing com.anonymous.* package id" \
  1 \
  "Refusing com.anonymous.* package id" \
  "${COMMON[@]}" --slug smoke-app --package com.anonymous.app --contact-email hi@smoke.app

assert_refusal \
  "underscore package refusal: is valid for Android but not for iOS" \
  1 \
  "is valid for Android but not for iOS" \
  "${COMMON[@]}" --slug smoke-app --package com.x.my_app --contact-email hi@smoke.app

assert_refusal \
  "slug refusal: Invalid --slug \"My App\"" \
  2 \
  'Invalid --slug "My App"' \
  "${COMMON[@]}" --slug "My App" --package com.smoke.app --contact-email hi@smoke.app

# Control writes; run after refusals so it cannot leak into them.
control_ec=0
control_out="$(run_init "$REFUSE" \
  "${COMMON[@]}" --slug smoke-app --package com.x.my_app \
  --bundle-id com.x.myapp --contact-email hi@smoke.app 2>&1)" || control_ec=$?
if [[ "$control_ec" -eq 0 ]]; then
  ok "underscore package with --bundle-id exits 0"
else
  fail "underscore package with --bundle-id (exit $control_ec, expected 0)"
fi
: "${control_out:=}"

# --- happy path: own fixture -------------------------------------------------
HAPPY="$(mktemp -d)"
CLEANUPS+=("$HAPPY")
seed_fixture "$HAPPY"

echo "=== happy path ==="
happy_ec=0
happy_out="$(run_init "$HAPPY" \
  --name "Smoke App" \
  --slug smoke-app \
  --package com.smoke.app \
  --contact-email hi@smoke.app \
  --copyright-holder "Jane Doe" 2>&1)" || happy_ec=$?

if [[ "$happy_ec" -eq 0 ]]; then
  ok "happy path exits 0"
else
  fail "happy path exits 0 (exit $happy_ec)"
fi
assert_contains "happy path warns on StoreKit _developerTeamID placeholder" \
  "$happy_out" "_developerTeamID"

APP="$HAPPY/apps/mobile/app.json"
PRODUCT="$HAPPY/apps/product.json"
STOREKIT="$HAPPY/apps/mobile/store/storekit/Products.storekit"

assert_eq "app.json name" "$(json "$APP" expo.name)" "Smoke App"
assert_eq "app.json slug" "$(json "$APP" expo.slug)" "smoke-app"
assert_eq "app.json scheme" "$(json "$APP" expo.scheme)" "smokeapp"
assert_eq "app.json ios.bundleIdentifier" "$(json "$APP" expo.ios.bundleIdentifier)" "com.smoke.app"
assert_eq "app.json android.package" "$(json "$APP" expo.android.package)" "com.smoke.app"

assert_eq "product.json name" "$(json "$PRODUCT" name)" "Smoke App"
assert_eq "product.json slug" "$(json "$PRODUCT" slug)" "smoke-app"
assert_eq "product.json contactEmail" "$(json "$PRODUCT" contactEmail)" "hi@smoke.app"
assert_eq "product.json privacyUrl" "$(json "$PRODUCT" privacyUrl)" "https://smoke-app.pages.dev/privacy"
assert_eq "product.json termsUrl" "$(json "$PRODUCT" termsUrl)" "https://smoke-app.pages.dev/terms"

IDS="$(storekit_ids "$STOREKIT")"
assert_contains "StoreKit productID prefix com.smoke.app." "$IDS" "com.smoke.app."
assert_absent "StoreKit productID has no com.example." "$IDS" "com.example."

YEAR="$(date +%Y)"
LICENSE_LINE="$(grep -E '^Copyright \(c\)' "$HAPPY/LICENSE" || true)"
assert_eq "LICENSE copyright" "$LICENSE_LINE" "Copyright (c) ${YEAR} Jane Doe"

assert_eq "privacy_url.txt" "$(tr -d '\n' < "$HAPPY/apps/mobile/store/metadata/ios/en-US/privacy_url.txt")" \
  "https://smoke-app.pages.dev/privacy"
assert_eq "support_url.txt" "$(tr -d '\n' < "$HAPPY/apps/mobile/store/metadata/ios/en-US/support_url.txt")" \
  "https://smoke-app.pages.dev"

# --- live tree must be untouched --------------------------------------------
AFTER_SUM="$(cksum < "$REAL_APP_JSON")"
assert_eq "real apps/mobile/app.json checksum unchanged" "$AFTER_SUM" "$BEFORE_SUM"

echo
if [[ "$FAIL" -gt 0 ]]; then
  echo "init-app.smoke: $PASS passed, $FAIL failed"
  exit 1
fi
echo "init-app.smoke: $PASS passed, 0 failed"
exit 0
