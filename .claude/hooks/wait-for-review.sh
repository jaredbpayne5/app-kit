#!/usr/bin/env bash
# Mailbox watcher for Claude — the mirror image of .cursor/hooks/wait-for-mail.sh.
#
# NOT wired as a Claude Code hook event. Claude launches it as a background
# command right after handing Cursor a task; when it exits, Claude is
# re-invoked automatically and reviews the work. That is the whole mechanism:
# Claude does not poll the mailbox turn by turn, it sleeps until woken.
#
# The wait is done by this script sleeping, NOT by a model. Idling is free.
#
# Usage (from the repo root, as a background command):
#   bash .claude/hooks/wait-for-review.sh [max_wait_seconds]
#
# Exits 0 in three cases, each with a different message on stdout:
#   * new mail      -> Cursor finished; review it now.
#   * timed out     -> nothing yet; re-arm if the task is still out.
#   * cannot read   -> state file missing, or malformed (when jq is present).
#
# Dependency-free: no jq, no node. The state file is read with the same sed
# field() helper as wait-for-mail.sh. jq is used only for an optional
# validity check when it is on PATH.
#
# "New mail" means .ai/mailbox-state.json carries a `seq` higher than the one
# recorded in .ai/.review-seen, AND owner is `claude`, AND status is
# `ready-for-review`. Cursor writes mailbox-state.json last, so a bumped seq
# guarantees the implementation report in .ai/current-task.md is complete.
#
# Reads only. `.ai/.review-seen` is written by Claude after a review, never
# here, and `.ai/.watching` belongs to Cursor's watcher — this script must not
# touch either. Its off switch is killing the background task.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE="$ROOT/.ai/mailbox-state.json"
SEEN="$ROOT/.ai/.review-seen"

POLL_SECONDS=5
MAX_WAIT_SECONDS="${1:-1800}"

# --- read a field out of the state file ---------------------------------------
# Deliberately dependency-free: no jq, no node. The state file is written by
# Claude in a fixed flat shape, one key per line.
field() {
  [ -f "$STATE" ] || return 1
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" "$STATE" \
    | head -n 1 | tr -d '[:space:]'
}

seen_seq() { [ -f "$SEEN" ] && tr -cd '0-9' <"$SEEN" || printf '0'; }

start=$SECONDS
while :; do
  if [ ! -f "$STATE" ]; then
    printf 'wait-for-review: %s is missing. Recreate the mailbox pair from\n' "$STATE"
    printf '.ai/current-task.template.md before handing off again.\n'
    exit 0
  fi

  # A half-written or malformed signal is not a reason to wedge — report and let
  # Claude look. jq exits non-zero on invalid JSON. Without jq, skip this check:
  # a malformed file fails the readiness predicate and we keep polling.
  if command -v jq >/dev/null 2>&1; then
    if ! jq -c '.' "$STATE" >/dev/null 2>&1; then
      printf 'wait-for-review: %s is not valid JSON. Inspect it by hand.\n' "$STATE"
      exit 0
    fi
  fi

  seq_now="$(field seq || printf '')"
  owner="$(field owner || printf '')"
  status="$(field status || printf '')"
  seen="$(seen_seq)"
  : "${seq_now:=0}" "${seen:=0}"

  if [ "$owner" = "claude" ] && [ "$status" = "ready-for-review" ] &&
    [ "$seq_now" -gt "$seen" ]; then
    printf 'wait-for-review: Cursor finished — mailbox seq %s (last reviewed %s).\n' \
      "$seq_now" "$seen"
    printf 'Review it NOW, before anything else: read the diff (not the report),\n'
    printf 'check every acceptance criterion, re-run npm run check and npm test\n'
    printf 'yourself, then record seq %s in .ai/.review-seen and reset the mailbox.\n' \
      "$seq_now"
    exit 0
  fi

  if [ $((SECONDS - start)) -ge "$MAX_WAIT_SECONDS" ]; then
    printf 'wait-for-review: no completion after %ss (mailbox seq %s, owner %s,\n' \
      "$MAX_WAIT_SECONDS" "$seq_now" "$owner"
    printf 'status %s). Cursor may still be working — re-arm this watcher if the\n' "$status"
    printf 'task is still out, or check on it if that seems too long.\n'
    exit 0
  fi

  sleep "$POLL_SECONDS"
done
