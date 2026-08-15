#!/usr/bin/env bash
# Prove U4 mechanisms can fail. A check that only has a success path is
# decoration (REPO-UPGRADE.md class rule).
#
# Usage: npm run u4-check
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

FAIL=0
PASS=0

ok() {
  PASS=$((PASS + 1))
  printf 'ok    %s\n' "$*"
}
bad() {
  FAIL=$((FAIL + 1))
  printf 'FAIL  %s\n' "$*"
}

echo "=== knip:clone refuses on the PRD sentinel ==="
if npm run --silent knip:clone >/tmp/u4-knip-clone.out 2>&1; then
  bad "knip:clone exited 0 while docs/PRD.md still has the template sentinel"
else
  if grep -q 'TEMPLATE_PLACEHOLDER' /tmp/u4-knip-clone.out; then
    ok "knip:clone fails on the PRD sentinel"
  else
    bad "knip:clone failed but did not mention TEMPLATE_PLACEHOLDER"
  fi
fi

echo "=== lint-staged config is present and names eslint ==="
if ! python3 -c 'import json,sys; json.load(open(".lintstagedrc.json"))' 2>/dev/null; then
  bad ".lintstagedrc.json is missing or not valid JSON"
else
  if grep -q 'eslint' .lintstagedrc.json; then
    ok ".lintstagedrc.json is valid JSON and runs eslint"
  else
    bad ".lintstagedrc.json does not mention eslint"
  fi
fi

echo "=== eslint (lint-staged's gate) fails on a planted unused var ==="
plant="$ROOT/apps/mobile/lib/.u4-fail-proof-plant.ts"
trap 'rm -f "$plant"' EXIT
printf 'const unused = 1;\n' >"$plant"
if npx eslint --max-warnings 0 --no-warn-ignored "$plant" >/tmp/u4-eslint-plant.out 2>&1; then
  bad "eslint did not fail on an unused variable — lint-staged would wave it through"
else
  ok "eslint fails on a planted unused variable"
fi
rm -f "$plant"
trap - EXIT

echo "=== pre-commit calls lint-staged, not full check ==="
if grep -q 'npx lint-staged' .githooks/pre-commit \
  && ! grep -q 'npm run --silent check' .githooks/pre-commit; then
  ok "pre-commit runs lint-staged and not npm run check"
else
  bad "pre-commit does not match the U4 swap (lint-staged, no full check)"
fi

echo "=== Renovate freezes the Expo-managed set ==="
if python3 -c '
import json, sys
cfg = json.load(open("renovate.json"))
frozen = set()
for rule in cfg.get("packageRules", []):
    if rule.get("enabled") is False:
        frozen.update(rule.get("matchPackageNames", []))
need = {"expo", "react", "react-dom", "react-native"}
missing = need - frozen
if missing:
    print("missing:", ", ".join(sorted(missing)))
    sys.exit(1)
' 2>/tmp/u4-renovate.out; then
  ok "renovate.json disables expo, react, react-dom, react-native"
else
  bad "renovate.json does not freeze the Expo-managed set"
fi

echo "=== expo-sdk-check gates on install --check; doctor is a report ==="
if grep -q 'npx expo install --check' scripts/ci/expo-sdk-check.sh \
  && grep -q 'npx expo-doctor || true' scripts/ci/expo-sdk-check.sh; then
  ok "expo-sdk-check: --check is a gate, expo-doctor is a report"
else
  bad "expo-sdk-check.sh lost the --check gate or the doctor || true"
fi

echo "=== audit-report never runs audit fix --force ==="
if grep -Eqe '^[^#]*npm audit fix --force' scripts/ci/audit-report.sh; then
  bad "audit-report.sh runs npm audit fix --force"
else
  ok "audit-report.sh does not run npm audit fix --force"
fi

rm -f /tmp/u4-knip-clone.out /tmp/u4-eslint-plant.out /tmp/u4-renovate.out

echo
if [[ "$FAIL" -ne 0 ]]; then
  printf 'u4-fail-proof: %s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi
printf 'u4-fail-proof: %s passed, 0 failed\n' "$PASS"
