#!/usr/bin/env bash
# Claude PreToolUse adapter: deny writes to guard files; ask on identity files.
# jq missing: warn and allow. Secrets stay in guard-secrets.sh (fail-closed).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"

if [[ -n "$file_path" ]] && guard_is_protected "$(guard_rel_path "$file_path" "$ROOT")"; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "This file is a factory guard. Editing it is denied so an agent cannot rewrite the safety net."}}
JSON
  exit 0
fi
if [[ -n "$command" ]] && guard_command_writes_protected "$command"; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "This command would rewrite a factory guard. Denied so an agent cannot hollow out the safety net."}}
JSON
  exit 0
fi

if [[ -n "$command" ]] && guard_is_init_app "$command"; then
  exit 0
fi

class=allow
if [[ -n "$file_path" ]]; then
  class="$(guard_path_class "$(guard_rel_path "$file_path" "$ROOT")")"
fi
if [[ "$class" == allow && -n "$command" ]]; then
  class="$(guard_command_class "$command")"
fi

if [[ "$class" == ask-identity ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "This touches app identity (app.json / eas.json / data-practices / .env / generated ios or android). Confirm before continuing. init-app is allowlisted."}}
JSON
  exit 0
fi

exit 0
