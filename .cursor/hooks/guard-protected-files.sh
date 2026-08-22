#!/usr/bin/env bash
# Cursor preToolUse: deny writes to guard files. Fail open on parse errors so
# a broken hook cannot block ordinary edits. afterFileEdit cannot reject.
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

if [[ -z "$path" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"

rel="$(guard_rel_path "$path" "$ROOT")"

if guard_is_protected "$rel"; then
  cat <<'JSON'
{"permission":"deny","user_message":"This file is a factory guard (hooks, matchers, eslint, githooks, or CI). Editing it via the agent is denied. Change it yourself in the editor if you really mean to.","agent_message":"Write denied: guard files are protected. Ask the human to edit them."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
