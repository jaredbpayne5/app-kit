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
#     hook's time budget runs low, then exit without a paid re-arm. The next
#     human or agent turn starts the stop hook again if .watching exists.
#   * Watching, new mail       -> hand Cursor the task via followup_message.
#
# "New mail" means .ai/mailbox-state.json has owner `cursor` AND status
# `ready-for-cursor`. The watcher re-delivers for as long as that remains
# true. Re-delivery is safe because implementation-workflow.mdc step 3
# requires Cursor to set status `in-progress` on pickup, so a retry can
# only happen while the task was never started.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE="$ROOT/.ai/mailbox-state.json"
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

# --- wait for the state file to say there is work -----------------------------
waited=0
while [ "$waited" -lt "$MAX_WAIT_SECONDS" ]; do
  # Switched off mid-wait: stand down without touching anything.
  [ -f "$WATCHING" ] || nothing

  owner="$(field owner || printf '')"
  status="$(field status || printf '')"

  if [ "$owner" = "cursor" ] \
    && [ "$status" = "ready-for-cursor" ]; then
    emit '{"followup_message":"New mail. Read .ai/current-task.md and carry out the task exactly as written, honouring AGENTS.md and the Mode set in the mailbox. When done, fill in the Implementation report, set Owner to `claude` and Status to `ready-for-review`, and stop."}'
  fi

  sleep "$POLL_SECONDS"
  waited=$((waited + POLL_SECONDS))
done

# --- out of time: stop without a paid re-arm ----------------------------------
# A followup_message here costs a Cursor turn just to say "still watching."
# The next human or agent turn starts the stop hook again if .watching exists.
nothing
