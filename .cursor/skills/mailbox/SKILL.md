---
name: mailbox
description: >-
  Implements one mailbox task from .ai/current-task.md. Use when Owner is
  cursor and Status is ready-for-cursor, or when the user says check your
  mail, check the mailbox, or new mail arrived.
---

# Mailbox

Pickup order for one agent-to-agent task. Constraints stay in `AGENTS.md`
and `.cursor/rules/implementation-workflow.mdc`.

## When this applies

Owner `cursor` and Status `ready-for-cursor` in `.ai/current-task.md`.
If Owner is `claude`, do not write source files.

## Pickup

1. Read the task. Ambiguous, contradicts `AGENTS.md`, or needs a decision →
   Status `ready-for-review` with the question; stop. Do not guess.
2. Verify every Premises command. False premise or empty Premises block →
   Status `ready-for-review` naming what you observed; stop.
3. Set Status `in-progress`.
4. Implement that scope only.
5. Run the checks the task names, plus `npm run check`.
6. Record: **product** → `docs/build-status.md`. **template** →
   `REPO-UPGRADE.md` (tick Progress only with the proof that file requires).
   Leave `<!-- TEMPLATE_PLACEHOLDER -->` docs untouched in template mode.
7. Fill the Implementation report. Owner `claude`, Status `ready-for-review`.
8. **Last** — rewrite `.ai/mailbox-state.json` (`seq` +1, `owner` `claude`,
   `status` `ready-for-review`, `mode` unchanged). Never bump before the
   report is complete.

## Propose; do not substitute

If the plan is wrong, stop before building and send it back. Do not silently
implement a different design.

## Do not touch

`.ai/.watching` and `.ai/.review-seen` belong to the watchers.

## Source

- Handoff rules: `.cursor/rules/implementation-workflow.mdc`
- Shared invariants: `AGENTS.md` → Task loop
