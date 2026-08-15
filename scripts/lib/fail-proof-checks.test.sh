#!/usr/bin/env bash
# scripts/lib/fail-proof-checks.test.sh — prove secret hooks and design-lint
# sections 5/6 can fail. A check that only has a success path is decoration.
#
# Usage:
#   npm run fail-proof-check
#   bash scripts/lib/fail-proof-checks.test.sh
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

# Assemble detector-shaped strings at runtime so this file never contains a
# live-looking key or PEM header (gitleaks / the pre-commit fallback).
fake_akia() { printf 'AKIA'; printf 'A%.0s' {1..16}; }
fake_pem() { printf -- '-----BEGIN %s-----' 'RSA PRIVATE KEY'; }

echo "=== secret grep uses -e / -- ==="
for f in .claude/hooks/guard-secrets.sh .githooks/pre-commit; do
  if grep -Eqe 'grep[[:space:]]+(-Eqe|-E[[:space:]]+-q[[:space:]]+--|-Eq[[:space:]]+--)' "$f"; then
    ok "$f secret grep is dash-safe"
  else
    bad "$f secret grep is not dash-safe (need grep -Eqe or grep -E -q --)"
  fi
  if grep -nE 'grep[[:space:]]+-Eq[[:space:]]+' "$f" | grep -vE 'grep[[:space:]]+-Eqe|grep[[:space:]]+-Eq[[:space:]]+--' >/dev/null; then
    bad "$f still has grep -Eq without -e/-- (leading-dash patterns become flags)"
  else
    ok "$f has no dash-unsafe grep -Eq"
  fi
done

echo "=== guard-secrets deny / allow ==="
if ! command -v jq >/dev/null 2>&1; then
  bad "jq is required to exercise guard-secrets.sh"
else
  hook_decision() {
    local content="$1"
    local out
    out=$(jq -nc --arg c "$content" --arg p 'apps/mobile/lib/storage.ts' \
      '{tool_input:{file_path:$p,content:$c}}' \
      | bash "$ROOT/.claude/hooks/guard-secrets.sh")
    if [[ -z "$out" ]]; then
      printf 'allow'
      return
    fi
    printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"'
  }

  got=$(hook_decision "$(fake_akia)")
  if [[ "$got" == deny ]]; then
    ok "fake AWS key is denied"
  else
    bad "fake AWS key got $got (expected deny)"
  fi

  got=$(hook_decision "$(fake_pem)")
  if [[ "$got" == deny ]]; then
    ok "fake PEM header is denied"
  else
    bad "fake PEM header got $got (expected deny)"
  fi

  got=$(hook_decision 'const x = 1')
  if [[ "$got" == allow ]]; then
    ok "ordinary edit is allowed"
  else
    bad "ordinary edit got $got (expected allow)"
  fi
fi

echo "=== design-lint empty scan / planted miss ==="
empty_dir=$(mktemp -d)
planted_dir=$(mktemp -d)
cleanup() { rm -rf "$empty_dir" "$planted_dir"; }
trap cleanup EXIT

empty_out=$(DESIGN_LINT_APP_DIR="$empty_dir" bash "$ROOT/scripts/dev/design-lint.sh" 2>&1) || empty_ec=$?
empty_ec=${empty_ec:-0}
if [[ "$empty_ec" -ne 0 ]] && echo "$empty_out" | grep -q 'scan set is empty'; then
  ok "empty design-lint scan fails"
else
  bad "empty design-lint scan should fail with 'scan set is empty' (exit=$empty_ec)"
fi

printf '%s\n' 'export default function Planted() { return null }' >"$planted_dir/planted.tsx"
planted_out=$(DESIGN_LINT_APP_DIR="$planted_dir" bash "$ROOT/scripts/dev/design-lint.sh" 2>&1) || planted_ec=$?
planted_ec=${planted_ec:-0}
if [[ "$planted_ec" -ne 0 ]] && echo "$planted_out" | grep -q 'useSafeAreaInsets/SafeAreaView'; then
  ok "planted screen without safe-area fails section 5"
else
  bad "planted screen should fail section 5 (exit=$planted_ec)"
fi

echo
if [[ "$FAIL" -gt 0 ]]; then
  echo "fail-proof-checks: $PASS passed, $FAIL failed"
  exit 1
fi
echo "fail-proof-checks: $PASS passed, 0 failed"
exit 0
