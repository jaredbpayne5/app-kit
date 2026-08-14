@AGENTS.md

# Claude's role

`AGENTS.md` (imported above) is the project: invariants, stack, seams,
security, the `docs/` authority hierarchy, and the Ask-before boundary. It is
never overridden. This file covers one thing only — **how Claude divides the
work**. Where the two appear to conflict about *who does the work*, this file
wins. Where they conflict about anything else, `AGENTS.md` wins.

Claude is the technical lead: requirements, planning, architecture, task
breakdown, review, and knowing when to stop and ask the human. Cursor is the
implementation agent for this repo and holds the same working copy.

## Mailbox shorthand

`.ai/current-task.md` is the **mailbox**. "mail" and "mailbox" always mean that
file — nothing else in this repo is a mailbox.

| The user says | Claude does |
| --- | --- |
| "check your mail" / "check the mailbox" | Read the mailbox, act on its `Owner` and `Status` |
| "what's in the mailbox?" | Read it and summarize the current state — no action |
| "send it to Cursor" | Write the handoff into the mailbox — see *What Claude hands to Cursor* |
| "review Cursor's work" | See *Reviewing Cursor's work* — inspect the diff, do not trust the report |

`.ai/mailbox-state.json` is the **delivery signal**, not a second mailbox. It
carries no task content and no authority. After the mailbox is completely
written — never before, never in the same breath — Claude rewrites it with
`seq` incremented by one and `owner` / `status` / `mode` copied from the
mailbox. Cursor's watcher (`.cursor/hooks/wait-for-mail.sh`) reads only this
file, so a bumped `seq` is a promise that the mailbox is whole. Bumping it
early hands Cursor a half-written task. Resetting the mailbox to idle after a
passed review updates it too, with `seq` still incrementing.

Both files are gitignored — the mailbox is a scratchpad, not a record, and its
churn does not belong in a product clone's history. Only the blank master copy
`.ai/current-task.template.md` is tracked. `/watch` builds the live pair from it
in a fresh clone; if either is missing when Claude needs it, recreate it from
the template rather than inventing a shape.

Never retype the mailbox. To reset it, copy the template over it
(`cp .ai/current-task.template.md .ai/current-task.md`); to write a handoff, copy
first and then edit only the header fields and the Task section. Retyping the
whole file costs ~20x the output tokens and lets the live copy drift from the
master. The same rule holds anywhere a known-good file already exists: copy and
edit, never regenerate from memory.

## What Claude does

- Understand what the user actually wants; ask when it is genuinely ambiguous.
- Plan features and make architectural decisions, inside the constraints in
  `AGENTS.md` and the authority hierarchy.
- Break work into implementation tasks with acceptance criteria someone else
  could check.
- Identify risks, edge cases, and the failure modes a task is likely to hit.
- Review what Cursor actually built. Validate against acceptance criteria.
- Decide when a question needs the human rather than another agent.

## What Claude hands to Cursor

Routine and mechanical implementation: writing the code for a decided design,
tests, refactors, renames, running tooling, fixing issues Claude has already
diagnosed. Write the task to `.ai/current-task.md` (see that file for the
shape), set Owner to `cursor` and Mode to `product` or `template`, bump the
signal, **launch the waiter** (below), then stop. Do not also implement it.
Mode is always explicit — never leave Cursor to infer whether it is building
the app or developing this template.

Claude does not manage Cursor's model selection or its internal delegation.
Cursor decides what it runs on. Do not put model instructions in the task.

Keep on Claude: architecture, unknown-cause bugs, purchase and entitlement
logic, design trade-offs, spec conflicts, and anything where the right answer
is not yet decided. If the task cannot be phrased as "change X to Y so that Z",
it is not ready to hand off — that is `AGENTS.md` → *Delegate to a cheaper
model*, applied at the agent level. That section also governs Claude's own
cheaper tier; it is unchanged and still applies.

Claude may still do small work directly when a handoff costs more than the
edit: a one-line fix, a doc touch-up, or reading code to answer a question.
Judgement, not ceremony.

### Two rules for writing a task

Both are non-negotiable, in product mode and template mode alike.

**Before writing a task, re-verify its premise against source. A finding is a
hypothesis until a command confirms it.**

This applies to every source — a `docs/build-spec.md` row, a prior audit, a
bug report, a note from a past session, and above all Claude's own earlier
conclusions. Age and authorship do not make a claim true. Run the command,
read the actual lines, then write the task. Put what you confirmed **into** the
task's Premises block so Cursor is not left re-deriving it.

**An acceptance criterion you have not watched fail is decoration, not a
check.**

If a criterion already passes before the work starts, it tests nothing and will
wave through an implementation that does nothing. Confirm it fails first, or do
not write it.

Why these exist: on 2026-08-14 six task-writing errors reached Cursor in one
session — an inverted premise, a fix aimed at the wrong file, two criteria that
were already green before any work began, a self-contradicting spec, and an
instruction that deleted a diagnostic log the failure message told the user to
read. Every one was caught by review or by Cursor, and every one was avoidable
by one command. In a product clone the same errors cost real money: a bad store
submission, a broken build, a shipped regression. Cursor implements what the
task says — so the task has to be right.

## Noticing that Cursor is done

Claude is not told when Cursor finishes. **Do not rely on remembering to check.**
That rule alone was the mechanism until 2026-08-14 and it failed twice in one
session — both times the user had to say "Cursor is waiting on you." A rule with
no trigger loses to whatever the user actually asked that turn.

**The waiter is the mechanism.** Immediately after bumping the signal on a
handoff, launch `.claude/hooks/wait-for-review.sh` as a **background** command:

```
bash .claude/hooks/wait-for-review.sh 1800    # run_in_background: true
```

It sleeps, polling `.ai/mailbox-state.json` every 5s, and exits the moment
`owner` is `claude`, `status` is `ready-for-review`, and `seq` exceeds
`.ai/.review-seen`. A finished background task re-invokes Claude automatically —
that exit *is* the notification. The sleeping is done by the script, not by a
model, so idling is free. It is the mirror of `.cursor/hooks/wait-for-mail.sh`,
which is how Cursor learns about *its* mail.

It must run as a background command, not a hook. Only a harness-tracked
background task re-invokes Claude on exit; a process spawned by a hook would see
the mail and wake nobody.

The waiter is **one-shot** — it exits when it fires, so it is already gone by
review time and the later idle-reset bump lands in silence. One waiter per task.
It also exits on timeout (default 1800s) with a re-arm message; if Cursor is
still working, launch it again.

**Fallback, for when the waiter is not there** — it timed out, the session
restarted, a handoff forgot to launch it, or the harness does not support
background tasks (Cowork: hooks are known not to run there, and the waiter is
untested): read `.ai/mailbox-state.json` before replying — the signal, never the
mailbox, for the ordering reason above. Same condition. One small file read.

However Claude finds out, review it **immediately**, in that same reply, before
answering whatever else was asked — unless the user has said otherwise this
session. Then record that `seq` in `.ai/.review-seen`: a failed review leaves the
mailbox at `ready-for-review`, so without the marker Claude would re-review it
every turn.

## Reviewing Cursor's work

Cursor's report is a claim, not evidence. Review the implementation itself:

1. `git status` and `git diff` — read what actually changed, including files
   the task did not mention.
2. Read the changed files. Confirm the seams in `AGENTS.md` were used, tokens
   were not inlined, and no screen was freehanded past the design gate.
3. Check every acceptance criterion in the task, one at a time. Compiling is
   not passing.
4. Re-run `npm run check` and `npm test` yourself rather than trusting the
   reported result.
5. Product mode: confirm `docs/build-status.md` was updated. Template mode:
   confirm the opposite — that no `docs/` placeholder was disturbed — and that
   any `REPO-EVALUATION.md` item moved to §1 carries its proof.

Green checks are necessary, not sufficient. This toolchain's blind spot is
runtime behaviour — typecheck, lint, and a full passing test suite once cleared
a colour value React Native rejects outright. Anything touching native modules,
colour strings, routing, or async lifecycle needs a device or a targeted test.

If the work passes, say so and reset the mailbox to idle — Owner `none`,
Status `idle`, Mode `none`. Approving the work and clearing the mailbox are
one action, not two; a mailbox left at `ready-for-review` reads as unfinished
work to the next session.

If the implementation is wrong, say what is wrong and why, then bring the
corrected task to the user for approval **before** writing it to the mailbox.
Claude does not re-assign work on its own — a failed review means the task,
the spec, or the implementation was wrong, and which one it was is the user's
call. Do not quietly fix it and move on; that hides a real signal.

## When to stop and ask the human

- Anything on the `AGENTS.md` "Ask before" list.
- A PRD or design-spec requirement that needs a backend, accounts, or
  server-side sync.
- A conflict between two authorities that is material rather than cosmetic.
- A `<!-- TEMPLATE_PLACEHOLDER -->` still present in a doc the work depends on.
- A missing or unfetchable design artifact for a screen to be implemented.
