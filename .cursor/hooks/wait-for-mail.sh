#!/usr/bin/env bash
# Mailbox watcher for Cursor.
#
# Runs on Cursor's `stop` hook — that is, every time a chat turn ends. It exists
# so Claude can hand Cursor a task without a human relaying it.
#
# The wait is done by this script sleeping, NOT by a model. Idling is free.
#
# Behaviour:
#   * No `.ai/.watching` file  -> exit immediately, do nothing. Cursor behaves
#     normally. This is the on/off switch and the emergency stop.
#   * Watching, no new mail    -> sleep and re-check until mail lands or the
#     hook's time budget runs low, then hand Cursor a re-arm message so the
#     loop survives.
#   * Watching, new mail       -> hand Cursor the task via followup_message.
#
# "New mail" means .ai/mailbox-state.json carries a `seq` higher than the one
# recorded in .ai/.mailbox-seen, AND owner is `cursor`, AND status is
# `ready-for-cursor`. Claude writes mailbox-state.json last, atomically, so a
# bumped seq guarantees .ai/current-task.md is complete.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE="$ROOT/.ai/mailbox-state.json"
SEEN="$ROOT/.ai/.mailbox-seen"
WATCHING="$ROOT/.ai/.watching"

POLL_SECONDS=5
# Stay comfortably inside the 3600s timeout in hooks.json.
MAX_WAIT_SECONDS=3300

# Cursor writes JSON to stdin. Unused here, but drain it so we never block.
cat >/dev/null 2>&1 || true

emit() { printf '%s\n' "$1"; exit 0; }
nothing() { emit '{}'; }

# --- off switch ---------------------------------------------------------------
[ -f "$WATCHING" ] || nothing

# --- read a field out of the state file ---------------------------------------
# Deliberately dependency-free: no jq, no node. The state file is written by
# Claude in a fixed flat shape, one key per line.
field() {
  [ -f "$STATE" ] || return 1
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" "$STATE" \
    | head -n 1 | tr -d '[:space:]'
}

seen_seq() { [ -f "$SEEN" ] && tr -cd '0-9' <"$SEEN" || printf '0'; }

# --- wait for the state file to say there is work -----------------------------
waited=0
while [ "$waited" -lt "$MAX_WAIT_SECONDS" ]; do
  # Switched off mid-wait: stand down without touching anything.
  [ -f "$WATCHING" ] || nothing

  seq="$(field seq || printf '')"
  owner="$(field owner || printf '')"
  status="$(field status || printf '')"
  seen="$(seen_seq)"
  : "${seq:=0}" "${seen:=0}"

  if [ "$seq" -gt "$seen" ] 2>/dev/null \
    && [ "$owner" = "cursor" ] \
    && [ "$status" = "ready-for-cursor" ]; then
    # Record it before handing it over, so a crash mid-task cannot cause the
    # same task to be picked up twice.
    printf '%s\n' "$seq" >"$SEEN"
    emit '{"followup_message":"New mail. Read .ai/current-task.md and carry out the task exactly as written, honouring AGENTS.md and the Mode set in the mailbox. When done, fill in the Implementation report, set Owner to `claude` and Status to `ready-for-review`, and stop."}'
  fi

  sleep "$POLL_SECONDS"
  waited=$((waited + POLL_SECONDS))
done

# --- out of time: re-arm rather than dying silently ---------------------------
# Costs one Cursor request per idle stretch. Without this the watcher would
# quietly stop watching and the next handoff would sit unnoticed.
emit '{"followup_message":"Mailbox watcher re-arming. No mail yet. Reply with exactly: watching. Do not read or edit any files."}'
