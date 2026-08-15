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
