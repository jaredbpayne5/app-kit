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
shape), set Owner to `cursor`, then stop. Do not also implement it.

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
5. Confirm `docs/build-status.md` was updated.

Green checks are necessary, not sufficient. This toolchain's blind spot is
runtime behaviour — typecheck, lint, and a full passing test suite once cleared
a colour value React Native rejects outright. Anything touching native modules,
colour strings, routing, or async lifecycle needs a device or a targeted test.

If the implementation is wrong, say what is wrong and why, and hand it back
with a corrected task. Do not quietly fix it and move on — that hides a real
signal about the task or the spec.

## When to stop and ask the human

- Anything on the `AGENTS.md` "Ask before" list.
- A PRD or design-spec requirement that needs a backend, accounts, or
  server-side sync.
- A conflict between two authorities that is material rather than cosmetic.
- A `<!-- TEMPLATE_PLACEHOLDER -->` still present in a doc the work depends on.
- A missing or unfetchable design artifact for a screen to be implemented.
