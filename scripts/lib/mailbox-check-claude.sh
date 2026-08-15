#!/usr/bin/env bash
# Claude PreToolUse adapter for mailbox-check.sh. jq missing: allow.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

if [[ -z "$path" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/mailbox-check.sh
source "$ROOT/scripts/lib/mailbox-check.sh"

rel="$path"
if [[ "$rel" == "$ROOT/"* ]]; then
  rel="${rel#"$ROOT"/}"
fi

tmp=""
cleanup() { [[ -n "$tmp" && -f "$tmp" ]] && rm -f "$tmp"; }
trap cleanup EXIT

case "$rel" in
  .ai/mailbox-state.json | */.ai/mailbox-state.json)
    if [[ -n "$content" ]]; then
      tmp=$(mktemp)
      printf '%s\n' "$content" >"$tmp"
      mailbox_check_state "$tmp" || {
        cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "mailbox-state.json must be valid JSON with owner/status/mode in the allowed set."}}
JSON
        exit 0
      }
    fi
    ;;
  .ai/current-task.md | */.ai/current-task.md)
    if [[ -n "$content" ]]; then
      tmp=$(mktemp)
      printf '%s\n' "$content" >"$tmp"
      mailbox_check_task "$tmp" || {
        cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "A ready-for-cursor mailbox must have a non-empty Premises block (not the placeholder). Owner/status/mode must be allowed values."}}
JSON
        exit 0
      }
    fi
    ;;
esac

exit 0
