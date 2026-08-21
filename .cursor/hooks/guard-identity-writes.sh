#!/usr/bin/env bash
# Cursor preToolUse / beforeShellExecution: guard app identity writes.
# preToolUse ignores `ask`, so a tool write (file path present) is denied and
# the human edits the file directly. A shell command gets `ask`, which that
# event does enforce, so init-app and deliberate edits still work.
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
  # Tool writes (Write/StrReplace/Delete) arrive with a file path and go
  # through preToolUse, which enforces `deny` but ignores `ask`. Shell
  # commands arrive with .command through beforeShellExecution, which does
  # enforce `ask`. Emit whichever verdict the event actually honors.
  if [[ -n "$path" ]]; then
    cat <<'JSON'
{"permission":"deny","user_message":"This touches app identity (app.json / eas.json / data-practices / .env / generated ios or android). Agent tool writes to these files are denied because Cursor's preToolUse event ignores an ask verdict. Edit it yourself in the editor, or run it through init-app.","agent_message":"Write denied: app identity file. Ask Matt to edit it directly."}
JSON
    exit 0
  fi
  cat <<'JSON'
{"permission":"ask","user_message":"This touches app identity (app.json / eas.json / data-practices / .env / generated ios or android). Confirm before continuing. init-app is allowlisted.","agent_message":"Identity-file write needs confirmation."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
