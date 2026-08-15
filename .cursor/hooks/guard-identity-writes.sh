#!/usr/bin/env bash
# Cursor preToolUse / beforeShellExecution: pause on app identity writes.
# Ask — do not deny — so init-app and a deliberate app.json edit can proceed.
# jq missing: warn and allow (not secret detection).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo '{"permission":"allow"}'
  exit 0
fi

input=$(cat)
path=$(echo "$input" | jq -r '
  .tool_input.file_path
  // .tool_input.path
  // .file_path
  // .path
  // empty
')
command=$(echo "$input" | jq -r '.command // .tool_input.command // empty')

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"

if [[ -n "$command" ]] && guard_is_init_app "$command"; then
  echo '{"permission":"allow"}'
  exit 0
fi

class=allow
if [[ -n "$path" ]]; then
  class="$(guard_path_class "$(guard_rel_path "$path" "$ROOT")")"
fi
if [[ "$class" == allow && -n "$command" ]]; then
  class="$(guard_command_class "$command")"
fi

if [[ "$class" == ask-identity ]]; then
  cat <<'JSON'
{"permission":"ask","user_message":"This touches app identity (app.json / eas.json / data-practices / .env / generated ios or android). Confirm before continuing. init-app is allowlisted.","agent_message":"Identity-file write needs confirmation."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
