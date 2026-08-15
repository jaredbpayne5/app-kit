---
name: review-cursor
description: >-
  Review Cursor's mailbox implementation. Use when the waiter exits, when
  Owner is claude and Status is ready-for-review, or when the user says
  review Cursor's work.
---

# Review Cursor's work

Claude-only. Cursor's report is a claim, not evidence. Review immediately
in the same reply, before answering anything else, unless the user said
otherwise this session.

## Review

1. `git status` and `git diff` — including files the task did not mention.
2. Read the changed files. Confirm `AGENTS.md` seams were used, tokens were
   not inlined, and no screen was freehanded past the design gate.
3. Check every acceptance criterion, one at a time. Compiling is not passing.
4. Re-run `npm run check` and `npm test` yourself. Do not trust the report.
   Do not pipe to `tail` — that hides a later failure and drops the exit
   code. Read the command's own exit status.
5. Product mode: `docs/build-status.md` updated. Template mode: no `docs/`
   placeholder disturbed, and any `REPO-UPGRADE.md` Progress tick has proof.

Green checks are necessary, not sufficient. Native modules, colour strings,
routing, or async lifecycle need a device or a targeted test.

Then record that `seq` in `.ai/.review-seen` so a mailbox left at
`ready-for-review` is not re-reviewed every turn. Do this on Pass, Fail,
and Rejected-on-premise.

## Pass

The implementation matches the task. Reset the mailbox to idle — Owner
`none`, Status `idle`, Mode `none` — and bump the signal. Approving and
clearing are one action.

## Fail

The implementation is wrong (or incomplete) relative to a sound task. Say
what is wrong and why. Bring the corrected task to the user for approval
**before** writing it to the mailbox. Do not re-assign on your own. Do
not quietly fix it and move on.

## Rejected-on-premise

Cursor stopped because a premise was false or the task was otherwise
unsatisfiable. Cursor did the right thing. The defect is in the task, not
the implementation. Do **not** call this a Fail in any durable record.

Bring the corrected task to the user for approval before writing it.
Record `.ai/.review-seen`. A reissue is a new handoff: new waiter after
the new bump.

## Source

- Always-on residue: `CLAUDE.md`
- Shared invariants: `AGENTS.md`
- Writing the next task: `write-mailbox-task` skill
