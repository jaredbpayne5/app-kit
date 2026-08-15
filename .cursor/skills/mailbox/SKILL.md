---
name: mailbox
description: >-
  Implements one mailbox task from .ai/current-task.md. Use when Owner is
  cursor and Status is ready-for-cursor, or when the user says check your
  mail, check the mailbox, or new mail arrived.
---

# Mailbox

Pickup order for one agent-to-agent task. Constraints stay in `AGENTS.md`
(Task loop, Ask-before, seams). This skill is the Cursor pickup procedure.

## When this applies

Owner `cursor` and Status `ready-for-cursor` in `.ai/current-task.md`.
If Owner is `claude`, do not write source files.

## Pickup

1. Read the task. Ambiguous, contradicts `AGENTS.md`, or needs a decision →
   Status `ready-for-review` with the question; stop. Do not guess.
2. **Verify every Premises command before writing anything.** Claude is
   required to have run them already — this is confirmation, not discovery.
   - **False** premise → Status `ready-for-review` naming which one and what
     you observed; **stop**. Do not adapt the task around it.
   - **Missing or empty** Premises block → report it as a defect and stop.
3. Set Status `in-progress`.
4. Implement that scope only. No unrelated refactors, no reformatting
   untouched files (`AGENTS.md` → Task loop).
5. Run the checks the task names, plus `npm run check`.
6. Record: **product** → `docs/build-status.md`. **template** →
   `REPO-UPGRADE.md` (tick Progress only with the proof that file requires).
   Leave `<!-- TEMPLATE_PLACEHOLDER -->` docs untouched in template mode
   unless the task explicitly changes the template's documentation structure.
7. Fill the Implementation report. Owner `claude`, Status `ready-for-review`.
   Report deviations and blockers honestly.
8. **Last, after the mailbox is completely written — never before —** rewrite
   `.ai/mailbox-state.json` with `seq` +1, `owner` `claude`, `status`
   `ready-for-review`, and `mode` unchanged. Never bump before the report is
   complete. Never read that file as task content. Write it only here, on
   completion.

## Propose; do not substitute

Claude writes the task and is not always right. Never silently implement a
different design. Claude owns architecture, purchase and entitlement logic,
and design trade-offs (`AGENTS.md` → *Delegate to a cheaper model*). Your
alternative is a recommendation until it is reissued as a task.

- **Plan is wrong, or yours is materially better** — Status `ready-for-review`
  **before building**, describe both, stop.
- **Minor preference, task is sound** — build as specified; note the
  alternative under Deviations.
- Make the case checkable ("fewer moving parts", "removes a failure mode"),
  not aesthetic ("cleaner").
- If you only realise after building, say so in the report.
- A small change the user asked for in chat: do it and run `npm run check`.
  If you are not sure it is small, ask first.

## Do not touch

`.ai/.watching` and `.ai/.review-seen` belong to the watchers. `/watch` and
`/stop` own `.watching`; the hooks own the rest.

## Source

Shared invariants: `AGENTS.md` → Task loop
