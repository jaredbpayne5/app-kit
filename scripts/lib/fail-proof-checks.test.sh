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
  && grep -q 'Write(./.claude/hooks/\*\*)' .claude/settings.json \
  && grep -q 'Edit(./.cursor/hooks/\*\*)' .claude/settings.json \
  && grep -q 'Edit(./scripts/lib/guard-\*\.sh)' .claude/settings.json \
  && grep -q 'Edit(./scripts/lib/fail-proof-checks.test.sh)' .claude/settings.json \
  && grep -q 'Edit(./.githooks/\*\*)' .claude/settings.json \
  && grep -q 'Edit(./eslint.config.js)' .claude/settings.json \
  && grep -q 'Edit(./.github/workflows/ci.yml)' .claude/settings.json; then
  ok "Claude permissions.deny lists the guard paths (Edit and Write)"
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
  cursor_net_out=$(jq -nc '{tool_input:{path:".cursor/hooks/guard-secret-files.sh"}}' | bash "$cursor_hook")
  lib_net_out=$(jq -nc '{tool_input:{path:"scripts/lib/guard-sensitive-paths.sh"}}' | bash "$cursor_hook")
  allow_out=$(jq -nc '{tool_input:{path:"apps/mobile/lib/storage.ts"}}' | bash "$cursor_hook")
  deny_perm=$(echo "$deny_out" | jq -r '.permission // empty')
  cursor_net_perm=$(echo "$cursor_net_out" | jq -r '.permission // empty')
  lib_net_perm=$(echo "$lib_net_out" | jq -r '.permission // empty')
  allow_perm=$(echo "$allow_out" | jq -r '.permission // empty')
  if [[ "$deny_perm" == deny ]]; then
    ok "Cursor protected-files hook denies a guard path"
  else
    bad "Cursor protected-files hook got $deny_perm on a guard path (expected deny)"
  fi
  if [[ "$cursor_net_perm" == deny && "$lib_net_perm" == deny ]]; then
    ok "Cursor protected-files hook denies the new Cursor/lib net"
  else
    bad "Cursor protected-files hook got cursor=$cursor_net_perm lib=$lib_net_perm (expected deny)"
  fi
  if [[ "$allow_perm" == allow ]]; then
    ok "Cursor protected-files hook allows an ordinary path"
  else
    bad "Cursor protected-files hook got $allow_perm on an ordinary path (expected allow)"
  fi
  test_net_out=$(jq -nc '{tool_input:{path:"scripts/lib/fail-proof-checks.test.sh"}}' | bash "$cursor_hook")
  test_net_perm=$(echo "$test_net_out" | jq -r '.permission // empty')
  if [[ "$test_net_perm" == deny ]]; then
    ok "Cursor protected-files hook denies the fail-proof test"
  else
    bad "Cursor protected-files hook got $test_net_perm on fail-proof-checks.test.sh (expected deny)"
  fi
fi

echo "=== shellcheck globs hook dirs and cannot skip on CI ==="
if grep -q '.cursor/hooks/\*\.sh' scripts/dev/shellcheck-guards.sh \
  && grep -q '.claude/hooks/\*\.sh' scripts/dev/shellcheck-guards.sh \
  && grep -q '.githooks/\*' scripts/dev/shellcheck-guards.sh \
  && grep -q 'scripts/lib/\*\.sh' scripts/dev/shellcheck-guards.sh; then
  ok "shellcheck-guards globs hook and guard directories"
else
  bad "shellcheck-guards does not glob hook and guard directories"
fi
for f in .claude/hooks/guard-secrets.sh .githooks/pre-commit; do
  if [[ -f "$f" ]]; then
    ok "$f exists under a globbed hook dir"
  else
    bad "$f is missing from a globbed hook dir"
  fi
done
if grep -q 'not installed on CI' scripts/dev/shellcheck-guards.sh; then
  bad "shellcheck-guards still skips when CI=true"
else
  ok "shellcheck-guards has no CI skip"
fi
if command -v shellcheck >/dev/null 2>&1; then
  planted_sh=$(mktemp)
  printf '%s\n' '#!/bin/sh' 'if then fi' >"$planted_sh"
  if shellcheck -S warning "$planted_sh" >/dev/null 2>&1; then
    bad "planted invalid script should fail shellcheck"
  else
    ok "planted invalid script fails shellcheck"
  fi
  rm -f "$planted_sh"
  fake_bin=$(mktemp -d)
  hide_out=$(CI=true PATH="$fake_bin" /bin/bash "$ROOT/scripts/dev/shellcheck-guards.sh" 2>&1) || hide_ec=$?
  hide_ec=${hide_ec:-0}
  rm -rf "$fake_bin"
  if [[ "$hide_ec" -ne 0 ]] && echo "$hide_out" | grep -q 'not on PATH'; then
    ok "missing shellcheck fails under CI=true"
  else
    bad "missing shellcheck under CI=true should fail (exit=$hide_ec)"
  fi
fi

echo "=== common shell write shapes to guard files are denied (speed bump) ==="
if command -v jq >/dev/null 2>&1; then
  # shellcheck source=scripts/lib/guard-sensitive-paths.sh
  source "$ROOT/scripts/lib/guard-sensitive-paths.sh"
  if guard_command_writes_protected 'cat /dev/null > .claude/hooks/guard-secrets.sh' \
    && guard_command_writes_protected 'rm .cursor/hooks/guard-secret-files.sh' \
    && guard_command_writes_protected 'echo exit 0 > scripts/lib/guard-deploy-match.sh' \
    && ! guard_command_writes_protected 'echo hello' \
    && ! guard_command_writes_protected 'npm run check'; then
    ok "shell-write classifier: redirect/rm of guards vs ordinary"
  else
    bad "shell-write classifier returned unexpected results"
  fi
  shell_hook="$ROOT/.cursor/hooks/guard-shell.sh"
  sh_deny=$(jq -nc '{command:"cat /dev/null > .claude/hooks/guard-secrets.sh"}' | bash "$shell_hook")
  sh_rm=$(jq -nc '{command:"rm .cursor/hooks/guard-secret-files.sh"}' | bash "$shell_hook")
  sh_allow=$(jq -nc '{command:"echo hello"}' | bash "$shell_hook")
  sh_deny_perm=$(echo "$sh_deny" | jq -r '.permission // empty')
  sh_rm_perm=$(echo "$sh_rm" | jq -r '.permission // empty')
  sh_allow_perm=$(echo "$sh_allow" | jq -r '.permission // empty')
  if [[ "$sh_deny_perm" == deny && "$sh_rm_perm" == deny ]]; then
    ok "Cursor shell hook denies redirect/rm of a guard file"
  else
    bad "Cursor shell hook got redirect=$sh_deny_perm rm=$sh_rm_perm (expected deny)"
  fi
  if [[ "$sh_allow_perm" == allow ]]; then
    ok "Cursor shell hook allows an ordinary command"
  else
    bad "Cursor shell hook got $sh_allow_perm on echo hello (expected allow)"
  fi
  claude_writes="$ROOT/scripts/lib/guard-sensitive-writes-claude.sh"
  claude_write=$(jq -nc '{tool_input:{file_path:".claude/hooks/guard-secrets.sh",content:"exit 0"}}' | bash "$claude_writes")
  claude_bash=$(jq -nc '{tool_input:{command:"echo exit 0 > scripts/lib/guard-deploy-match.sh"}}' | bash "$claude_writes")
  claude_write_perm=$(echo "$claude_write" | jq -r '.hookSpecificOutput.permissionDecision // empty')
  claude_bash_perm=$(echo "$claude_bash" | jq -r '.hookSpecificOutput.permissionDecision // empty')
  if [[ "$claude_write_perm" == deny && "$claude_bash_perm" == deny ]]; then
    ok "Claude identity adapter denies Write/Bash to a guard file"
  else
    bad "Claude identity adapter got write=$claude_write_perm bash=$claude_bash_perm (expected deny)"
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
  if [[ "$app_perm" == deny ]]; then
    ok "identity hook denies a tool write to app.json"
  else
    bad "identity hook got $app_perm on an app.json tool write (expected deny — preToolUse ignores ask)"
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
  app_cmd_perm=$(jq -nc '{command:"printf x >> apps/mobile/app.json"}' \
    | bash "$ident_hook" | jq -r '.permission')
  if [[ "$app_cmd_perm" == ask ]]; then
    ok "identity hook asks on an app.json shell write"
  else
    bad "identity hook got $app_cmd_perm on an app.json shell command (expected ask)"
  fi

  # Every identity path must come back `deny` on a tool write. Asserting only
  # "not ask" was a hole: `allow` satisfied it, so the classifier entries for
  # eas.json, data-practices.json, and .env could be deleted outright while this
  # stayed green. Asserting the positive verdict covers both properties at once.
  not_denied=""
  for p in apps/mobile/app.json apps/mobile/eas.json \
    apps/mobile/store/data-practices.json .env; do
    v=$(jq -nc --arg p "$p" '{tool_input:{file_path:$p}}' \
      | bash "$ident_hook" | jq -r '.permission')
    [[ "$v" == deny ]] || not_denied="$not_denied $p($v)"
  done
  if [[ -z "$not_denied" ]]; then
    ok "identity hook denies a tool write to every identity path"
  else
    bad "identity hook did not deny tool writes to:$not_denied"
  fi

  # Count first. `all()` over an empty array is vacuously true, so a length check
  # is what makes deleting the registration detectable rather than invisible.
  secret_regs=$(jq '[.hooks.preToolUse[], .hooks.beforeReadFile[]]
    | map(select(.command | test("guard-secret-files")))' .cursor/hooks.json)
  if [[ "$(echo "$secret_regs" | jq 'length')" -eq 2 ]] \
    && [[ "$(echo "$secret_regs" | jq 'all(.failClosed == true)')" == true ]]; then
    ok "both secret-file hook registrations are present and failClosed"
  else
    bad "guard-secret-files.sh must be registered on preToolUse and beforeReadFile, both failClosed: true"
  fi

  # The suite proved the identity hook's verdict but never its wiring.
  # A correct guard that is not registered is the same fake gate one layer up.
  ident_events=$(jq -r '[
      (.hooks.beforeShellExecution[]? | select(.command | test("guard-identity-writes")) | "shell"),
      (.hooks.preToolUse[]? | select(.command | test("guard-identity-writes")) | "tool")
    ] | sort | join(",")' .cursor/hooks.json)
  if [[ "$ident_events" == "shell,tool" ]]; then
    ok "identity hook is registered on both preToolUse and beforeShellExecution"
  else
    bad "identity hook registration incomplete (got '$ident_events', want 'shell,tool')"
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

echo "=== U2 honesty / shellcheck / knip sentinel ==="
if grep -q 'speed bump' scripts/lib/guard-deploy-match.sh \
  && grep -q 'prose-only' AGENTS.md; then
  ok "matcher header and AGENTS.md say speed bump / prose-only"
else
  bad "honesty lines missing from matcher header or AGENTS.md"
fi
echo "=== knip:clone refuses on the PRD sentinel ==="
if grep -q 'TEMPLATE_PLACEHOLDER' docs/PRD.md; then
  knip_out=$(mktemp)
  if npm run --silent knip:clone >"$knip_out" 2>&1; then
    bad "knip:clone exited 0 while docs/PRD.md still has the template sentinel"
  else
    if grep -q 'TEMPLATE_PLACEHOLDER' "$knip_out"; then
      ok "knip:clone fails on the PRD sentinel"
    else
      bad "knip:clone failed but did not mention TEMPLATE_PLACEHOLDER"
    fi
  fi
  rm -f "$knip_out"
else
  ok "PRD sentinel absent — knip:clone PRD-sentinel proof skipped"
fi
if grep -q 'shellcheck-guards' package.json; then
  ok "package.json runs shellcheck-guards in check"
else
  bad "shellcheck-guards is not in package.json"
fi

echo "=== plan-lint can fail ==="
if bash scripts/dev/plan-lint.sh \
  --file=scripts/dev/fixtures/plan-lint/good.md --strict >/dev/null 2>&1; then
  ok "plan-lint accepts the good fixture under --strict"
else
  bad "plan-lint rejected the good fixture under --strict"
fi
if bash scripts/dev/plan-lint.sh \
  --file=scripts/dev/fixtures/plan-lint/bad.md --strict >/dev/null 2>&1; then
  bad "plan-lint passed the bad fixture under --strict — it has no failure path"
else
  ok "plan-lint rejects the bad fixture under --strict"
fi

echo
if [[ "$FAIL" -gt 0 ]]; then
  echo "fail-proof-checks: $PASS passed, $FAIL failed"
  exit 1
fi
echo "fail-proof-checks: $PASS passed, 0 failed"
exit 0
