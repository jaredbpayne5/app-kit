---
name: write-mailbox-task
description: >-
  Write a mailbox handoff for Cursor. Use when the user says send it to
  Cursor, when Claude is about to set Owner cursor / Status ready-for-cursor,
  or when writing .ai/current-task.md.
---

# Write a mailbox task

Claude-only. Cursor pickup is the `mailbox` skill. Constraints stay in
`AGENTS.md`.

## When this applies

Handing mechanical implementation to Cursor. Do not also implement the task.

Keep on Claude: architecture, unknown-cause bugs, purchase and entitlement
logic, design trade-offs, spec conflicts, and anything that is not yet
"change X to Y so that Z". Small one-line fixes may stay with Claude.

Do not put model-selection instructions in the task. Cursor picks its model.

## Write the task (this order — the hook enforces it)

A `ready-for-cursor` header is denied while Premises is still the
placeholder. Fill the body first. Set the header last.

1. Copy the template — never retype the whole file. Bypass any `cp` alias:
   `/bin/cp .ai/current-task.template.md .ai/current-task.md`
   Then edit the Task section only. Leave the header at Owner `none` /
   Status `idle` / Mode `none` until step 5.
2. Write Source, Goal, Scope, Out of scope, Notes.
3. **Premises:** a finding is a hypothesis until a command confirms it.
   Run the command, read the lines, put what Cursor will observe **at
   pickup** into Premises. Age and authorship do not make a claim true.
   The cited command must still be able to confirm the claim when Cursor
   runs it. Do not premise anything your own next step, or time passing,
   will change — the doorbell (you bump it after writing), "check
   currently passes" if more work may land, timestamps. The doorbell is
   the signal, not evidence about the repo; never cite
   `.ai/mailbox-state.json` as a premise.
   - Mark each verified item `[x]`. That means Claude ran the command
     while writing. Cursor still re-runs every command (confirmation).
     An empty or leftover `[ ] _(claim…)_` placeholder is a defect.
4. **Acceptance criteria:** a criterion you have not watched fail is
   decoration. Confirm it fails first, or do not write it.
   - Also reject criteria that **cannot pass**. Run `git status
     --porcelain` before writing any criterion that mentions the working
     tree. If the tree is already dirty, the criterion must name those
     paths (or not mention porcelain). A "clean tree" criterion plus
     "leave those files alone" is unsatisfiable — this repo has shipped
     that mistake more than once.
5. Set Owner `cursor`, Status `ready-for-cursor`, Mode `product` or
   `template` (always explicit). Do this only after Premises has real
   `[x]` items.
6. After the mailbox is completely written — never before — rewrite
   `.ai/mailbox-state.json` with `seq` +1, `owner` / `status` / `mode`
   copied from the mailbox. Bumping early hands Cursor a half-written task.

If either live mailbox file is missing, recreate it from the template /
the empty JSON shape. Do not invent a new format.

## Launch the waiter

Immediately after the signal bump, as a **background** command (not a hook):

```
bash .claude/hooks/wait-for-review.sh 1800    # run_in_background: true
```

One waiter per task. It exits when `owner` is `claude`, `status` is
`ready-for-review`, and `seq` exceeds `.ai/.review-seen`. Timeout 1800s:
re-arm if Cursor is still working.

**Fallback** (waiter timed out, session restarted, Cowork): read
`.ai/mailbox-state.json` before replying — the signal, never the mailbox.
Same condition.

Then stop. Do not also implement the task.

## Source

- Always-on residue: `CLAUDE.md`
- Shared invariants: `AGENTS.md`
- Review after the waiter fires: `review-cursor` skill
