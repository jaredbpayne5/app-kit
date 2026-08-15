#!/usr/bin/env bash
# scripts/lib/mailbox-check.sh — validate mailbox-state.json and current-task.md.
# Does not change the mailbox file format.
#
# Usage:
#   bash scripts/lib/mailbox-check.sh --state FILE
#   bash scripts/lib/mailbox-check.sh --task FILE
#   # or source and call mailbox_check_state / mailbox_check_task
set -uo pipefail

mailbox_allowed_owner='^(none|claude|cursor)$'
mailbox_allowed_status='^(idle|ready-for-cursor|in-progress|ready-for-review)$'
mailbox_allowed_mode='^(none|product|template)$'

mailbox_check_state() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf 'mailbox-check: missing %s\n' "$file" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf 'mailbox-check: jq is required to validate %s\n' "$file" >&2
    return 1
  fi
  if ! jq -e . "$file" >/dev/null 2>&1; then
    printf 'mailbox-check: %s is not valid JSON\n' "$file" >&2
    return 1
  fi
  local owner status mode
  owner=$(jq -r '.owner // empty' "$file")
  status=$(jq -r '.status // empty' "$file")
  mode=$(jq -r '.mode // empty' "$file")
  if [[ ! "$owner" =~ $mailbox_allowed_owner ]]; then
    printf 'mailbox-check: %s has illegal owner %s\n' "$file" "${owner:-<empty>}" >&2
    return 1
  fi
  if [[ ! "$status" =~ $mailbox_allowed_status ]]; then
    printf 'mailbox-check: %s has illegal status %s\n' "$file" "${status:-<empty>}" >&2
    return 1
  fi
  if [[ ! "$mode" =~ $mailbox_allowed_mode ]]; then
    printf 'mailbox-check: %s has illegal mode %s\n' "$file" "${mode:-<empty>}" >&2
    return 1
  fi
  return 0
}

mailbox_task_field() {
  local file="$1"
  local label="$2"
  grep -E "\\*\\*${label}:\\*\\*" "$file" | head -n 1 | sed -n 's/.*`\([^`]*\)`.*/\1/p'
}

mailbox_premises_has_real_item() {
  local file="$1"
  local block
  block=$(awk '
    $0 ~ /^\*\*Premises/ {grab=1; next}
    grab && $0 ~ /^\*\*Scope:/ {exit}
    grab {print}
  ' "$file")
  echo "$block" | grep -E '^- \[[ xX]\] ' | grep -vE '_\(claim' >/dev/null
}

# Build the file that would land on disk after Write / Edit / StrReplace.
# Full-file writes pass `contents`. Edits pass `old_string` + `new_string` and
# are applied to `on_disk`. Do not treat `new_string` alone as the whole file —
# that false-denies a legal header or report edit.
# Returns 0 if dest is ready to validate, 1 if the hook should allow (cannot
# reconstruct).
mailbox_apply_patch() {
  local src="$1"
  local dest="$2"
  local old="$3"
  local new="$4"
  local replace_all="${5:-false}"
  local old_f new_f
  if ! command -v python3 >/dev/null 2>&1; then
    return 1
  fi
  old_f=$(mktemp)
  new_f=$(mktemp)
  printf '%s' "$old" >"$old_f"
  printf '%s' "$new" >"$new_f"
  if python3 - "$src" "$dest" "$old_f" "$new_f" "$replace_all" <<'PY'
from pathlib import Path
import sys

src, dest, old_f, new_f, replace_all = sys.argv[1:6]
text = Path(src).read_text()
old = Path(old_f).read_text()
new = Path(new_f).read_text()
if not old:
    sys.exit(1)
if replace_all in ("true", "True", "1"):
    if old not in text:
        sys.exit(1)
    Path(dest).write_text(text.replace(old, new))
else:
    idx = text.find(old)
    if idx < 0:
        sys.exit(1)
    Path(dest).write_text(text[:idx] + new + text[idx + len(old) :])
PY
  then
    rm -f "$old_f" "$new_f"
    return 0
  fi
  rm -f "$old_f" "$new_f"
  return 1
}

mailbox_prepare_candidate() {
  local dest="$1"
  local on_disk="$2"
  local contents="$3"
  local old_string="$4"
  local new_string="$5"
  local replace_all="${6:-false}"

  if [[ -n "$contents" ]]; then
    printf '%s\n' "$contents" >"$dest"
    return 0
  fi
  if [[ -n "$old_string" && -f "$on_disk" ]]; then
    mailbox_apply_patch "$on_disk" "$dest" "$old_string" "$new_string" "$replace_all"
    return $?
  fi
  if [[ -z "$new_string" && -f "$on_disk" ]]; then
    cp "$on_disk" "$dest"
    return 0
  fi
  return 1
}

mailbox_check_task() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    printf 'mailbox-check: missing %s\n' "$file" >&2
    return 1
  fi
  local owner status mode
  owner=$(mailbox_task_field "$file" Owner)
  status=$(mailbox_task_field "$file" Status)
  mode=$(mailbox_task_field "$file" Mode)
  if [[ ! "$owner" =~ $mailbox_allowed_owner ]]; then
    printf 'mailbox-check: %s has illegal Owner %s\n' "$file" "${owner:-<empty>}" >&2
    return 1
  fi
  if [[ ! "$status" =~ $mailbox_allowed_status ]]; then
    printf 'mailbox-check: %s has illegal Status %s\n' "$file" "${status:-<empty>}" >&2
    return 1
  fi
  if [[ ! "$mode" =~ $mailbox_allowed_mode ]]; then
    printf 'mailbox-check: %s has illegal Mode %s\n' "$file" "${mode:-<empty>}" >&2
    return 1
  fi
  if [[ "$status" == ready-for-cursor ]] && ! mailbox_premises_has_real_item "$file"; then
    printf 'mailbox-check: %s is ready-for-cursor but Premises is empty or still the placeholder\n' "$file" >&2
    return 1
  fi
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    --state)
      mailbox_check_state "$2"
      ;;
    --task)
      mailbox_check_task "$2"
      ;;
    --template)
      ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
      mailbox_check_task "$ROOT/.ai/current-task.template.md"
      ;;
    *)
      printf 'usage: mailbox-check.sh --state FILE | --task FILE | --template\n' >&2
      exit 2
      ;;
  esac
fi
