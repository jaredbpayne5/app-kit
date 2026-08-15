#!/usr/bin/env bash
# Claude PreToolUse adapter for identity-file pauses (ask, not deny).
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
