#!/usr/bin/env bash
# Cursor preToolUse: reject a mailbox write that is invalid JSON / illegal
# owner-status-mode, or ready-for-cursor with an empty Premises block.
# StrReplace/Edit is applied to the on-disk file before checking — new_string
# alone is not the whole mailbox. jq missing: allow (not secret detection).
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
contents=$(echo "$input" | jq -r '.tool_input.contents // .tool_input.content // empty')
old_string=$(echo "$input" | jq -r '.tool_input.old_string // empty')
new_string=$(echo "$input" | jq -r '.tool_input.new_string // empty')
replace_all=$(echo "$input" | jq -r '.tool_input.replace_all // "false"')

if [[ -z "$path" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/mailbox-check.sh
source "$ROOT/scripts/lib/mailbox-check.sh"

rel="$path"
rel="${rel#file://}"
if [[ "$rel" == "$ROOT/"* ]]; then
  rel="${rel#"$ROOT"/}"
fi

on_disk="$path"
on_disk="${on_disk#file://}"
if [[ "$on_disk" != /* ]]; then
  on_disk="$ROOT/$rel"
fi

check_file=""
cleanup() { [[ -n "${check_file:-}" && -f "$check_file" ]] && rm -f "$check_file"; }
trap cleanup EXIT

case "$rel" in
  .ai/mailbox-state.json | */.ai/mailbox-state.json)
    check_file=$(mktemp)
    if ! mailbox_prepare_candidate "$check_file" "$on_disk" "$contents" "$old_string" "$new_string" "$replace_all"; then
      echo '{"permission":"allow"}'
      exit 0
    fi
    if ! mailbox_check_state "$check_file"; then
      cat <<'JSON'
{"permission":"deny","user_message":"mailbox-state.json must be valid JSON with owner/status/mode in the allowed set.","agent_message":"Mailbox state write denied: invalid JSON or illegal owner/status/mode."}
JSON
      exit 0
    fi
    ;;
  .ai/current-task.md | */.ai/current-task.md)
    check_file=$(mktemp)
    if ! mailbox_prepare_candidate "$check_file" "$on_disk" "$contents" "$old_string" "$new_string" "$replace_all"; then
      echo '{"permission":"allow"}'
      exit 0
    fi
    if ! mailbox_check_task "$check_file"; then
      cat <<'JSON'
{"permission":"deny","user_message":"A ready-for-cursor mailbox must have a non-empty Premises block (not the placeholder). Owner/status/mode must be allowed values.","agent_message":"Mailbox task write denied: empty Premises or illegal header fields."}
JSON
      exit 0
    fi
    ;;
esac

echo '{"permission":"allow"}'
exit 0
