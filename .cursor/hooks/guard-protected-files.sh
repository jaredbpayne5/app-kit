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
rel="$path"
rel="${rel#file://}"
if [[ "$rel" == "$ROOT/"* ]]; then
  rel="${rel#"$ROOT"/}"
fi

protected=0
case "$rel" in
  .claude/hooks/* | */.claude/hooks/*) protected=1 ;;
  .githooks/* | */.githooks/*) protected=1 ;;
  eslint.config.js | */eslint.config.js) protected=1 ;;
  .github/workflows/ci.yml | */.github/workflows/ci.yml) protected=1 ;;
esac

if [[ "$protected" -eq 1 ]]; then
  cat <<'JSON'
{"permission":"deny","user_message":"This file is a factory guard (hooks, eslint, githooks, or CI). Editing it is denied so an agent cannot rewrite the safety net. Change it yourself in the editor if you really mean to.","agent_message":"Write denied: guard files are protected. Ask the human to edit them."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
