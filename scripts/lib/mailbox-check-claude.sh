#!/usr/bin/env bash
# Claude PreToolUse adapter for mailbox-check.sh. jq missing: allow.
# Edit/new_string is applied to the on-disk file before checking.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
contents=$(echo "$input" | jq -r '.tool_input.content // .tool_input.contents // empty')
old_string=$(echo "$input" | jq -r '.tool_input.old_string // empty')
new_string=$(echo "$input" | jq -r '.tool_input.new_string // empty')
replace_all=$(echo "$input" | jq -r '.tool_input.replace_all // "false"')

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

on_disk="$path"
if [[ "$on_disk" != /* ]]; then
  on_disk="$ROOT/$rel"
fi

tmp=""
cleanup() { [[ -n "$tmp" && -f "$tmp" ]] && rm -f "$tmp"; }
trap cleanup EXIT

case "$rel" in
  .ai/mailbox-state.json | */.ai/mailbox-state.json)
    tmp=$(mktemp)
    if ! mailbox_prepare_candidate "$tmp" "$on_disk" "$contents" "$old_string" "$new_string" "$replace_all"; then
      exit 0
    fi
    mailbox_check_state "$tmp" || {
      cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "mailbox-state.json must be valid JSON with owner/status/mode in the allowed set."}}
JSON
      exit 0
    }
    ;;
  .ai/current-task.md | */.ai/current-task.md)
    tmp=$(mktemp)
    if ! mailbox_prepare_candidate "$tmp" "$on_disk" "$contents" "$old_string" "$new_string" "$replace_all"; then
      exit 0
    fi
    mailbox_check_task "$tmp" || {
      cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "A ready-for-cursor mailbox must have a non-empty Premises block (not the placeholder). Owner/status/mode must be allowed values."}}
JSON
      exit 0
    }
    ;;
esac

exit 0
