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

echo "=== guard-file deny is configured ==="
if grep -q 'Edit(./.claude/hooks/\*\*)' .claude/settings.json \
  && grep -q 'Edit(./.githooks/\*\*)' .claude/settings.json \
  && grep -q 'Edit(./eslint.config.js)' .claude/settings.json \
  && grep -q 'Edit(./.github/workflows/ci.yml)' .claude/settings.json; then
  ok "Claude permissions.deny lists the four guard paths"
else
  bad "Claude permissions.deny is missing a guard path"
fi

if grep -q 'guard-protected-files.sh' .cursor/hooks.json; then
  ok "Cursor hooks.json registers guard-protected-files.sh"
else
  bad "Cursor hooks.json does not register guard-protected-files.sh"
fi

if grep -q 'gitleaks' scripts/dev/doctor.sh; then
  ok "doctor.sh mentions gitleaks"
else
  bad "doctor.sh does not mention gitleaks"
fi

if command -v jq >/dev/null 2>&1; then
  cursor_hook="$ROOT/.cursor/hooks/guard-protected-files.sh"
  deny_out=$(jq -nc '{tool_input:{path:".claude/hooks/guard-secrets.sh"}}' | bash "$cursor_hook")
  allow_out=$(jq -nc '{tool_input:{path:"apps/mobile/lib/storage.ts"}}' | bash "$cursor_hook")
  deny_perm=$(echo "$deny_out" | jq -r '.permission // empty')
  allow_perm=$(echo "$allow_out" | jq -r '.permission // empty')
  if [[ "$deny_perm" == deny ]]; then
    ok "Cursor protected-files hook denies a guard path"
  else
    bad "Cursor protected-files hook got $deny_perm on a guard path (expected deny)"
  fi
  if [[ "$allow_perm" == allow ]]; then
    ok "Cursor protected-files hook allows an ordinary path"
  else
    bad "Cursor protected-files hook got $allow_perm on an ordinary path (expected allow)"
  fi
fi

echo "=== secret / identity path hooks ==="
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"
if [[ "$(guard_path_class 'keys/AuthKey.p8')" == deny-secret ]] \
  && [[ "$(guard_path_class 'play/service-account.json')" == deny-secret ]] \
  && [[ "$(guard_path_class 'apps/mobile/app.json')" == ask-identity ]] \
  && [[ "$(guard_path_class 'apps/mobile/ios/Podfile')" == ask-identity ]] \
  && [[ "$(guard_path_class 'apps/mobile/lib/storage.ts')" == allow ]]; then
  ok "path classifier: secret / identity / allow"
else
  bad "path classifier returned unexpected classes"
fi

if guard_is_init_app 'npm run init-app -- --name Foo' \
  && ! guard_is_init_app 'echo init-app in a comment'; then
  ok "init-app allowlist matches the script, not a mention"
else
  bad "init-app allowlist is wrong"
fi

if command -v jq >/dev/null 2>&1; then
  secret_hook="$ROOT/.cursor/hooks/guard-secret-files.sh"
  ident_hook="$ROOT/.cursor/hooks/guard-identity-writes.sh"
  p8_out=$(jq -nc '{tool_input:{path:"keys/AuthKey.p8"}}' | bash "$secret_hook")
  app_out=$(jq -nc '{tool_input:{path:"apps/mobile/app.json"}}' | bash "$ident_hook")
  init_out=$(jq -nc '{command:"npm run init-app -- --name Demo"}' | bash "$ident_hook")
  ordinary_out=$(jq -nc '{tool_input:{path:"apps/mobile/lib/storage.ts"}}' | bash "$secret_hook")
  p8_perm=$(echo "$p8_out" | jq -r '.permission // empty')
  app_perm=$(echo "$app_out" | jq -r '.permission // empty')
  init_perm=$(echo "$init_out" | jq -r '.permission // empty')
  ordinary_perm=$(echo "$ordinary_out" | jq -r '.permission // empty')
  if [[ "$p8_perm" == deny ]]; then
    ok "secret hook denies a .p8 path"
  else
    bad "secret hook got $p8_perm on .p8 (expected deny)"
  fi
  if [[ "$app_perm" == ask ]]; then
    ok "identity hook asks on app.json"
  else
    bad "identity hook got $app_perm on app.json (expected ask)"
  fi
  if [[ "$init_perm" == allow ]]; then
    ok "identity hook allows init-app"
  else
    bad "identity hook got $init_perm on init-app (expected allow)"
  fi
  if [[ "$ordinary_perm" == allow ]]; then
    ok "secret hook allows an ordinary path"
  else
    bad "secret hook got $ordinary_perm on an ordinary path (expected allow)"
  fi

  claude_ident="$ROOT/scripts/lib/guard-sensitive-writes-claude.sh"
  claude_app=$(jq -nc '{tool_input:{file_path:"apps/mobile/app.json"}}' | bash "$claude_ident")
  claude_perm=$(echo "$claude_app" | jq -r '.hookSpecificOutput.permissionDecision // empty')
  if [[ "$claude_perm" == ask ]]; then
    ok "Claude identity adapter asks on app.json"
  else
    bad "Claude identity adapter got $claude_perm on app.json (expected ask)"
  fi
fi

echo
if [[ "$FAIL" -gt 0 ]]; then
  echo "fail-proof-checks: $PASS passed, $FAIL failed"
  exit 1
fi
echo "fail-proof-checks: $PASS passed, 0 failed"
exit 0
