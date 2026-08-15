@AGENTS.md

# Claude's role

`AGENTS.md` (imported above) is the project: invariants, stack, seams,
security, the `docs/` authority hierarchy, and the Ask-before boundary. It is
never overridden. This file covers one thing only — **how Claude divides the
work**. Where the two appear to conflict about *who does the work*, this file
wins. Where they conflict about anything else, `AGENTS.md` wins.

Claude plans, writes mailbox tasks, and reviews. Cursor implements. Both
hold the same working copy.

## Mailbox

Mailbox = `.ai/current-task.md`. Doorbell = `.ai/mailbox-state.json` (no
task content, no authority). Both are gitignored; the tracked master is
`.ai/current-task.template.md`.

| The user says | Claude does |
| --- | --- |
| "check your mail" / "check the mailbox" | Read it; act on `Owner` and `Status` |
| "what's in the mailbox?" | Summarize — no action |
| "send it to Cursor" | Open the `write-mailbox-task` skill and follow it |
| "review Cursor's work" | Open the `review-cursor` skill and follow it |

After a handoff signal bump, launch the waiter (background, not a hook):

```
bash .claude/hooks/wait-for-review.sh 1800    # run_in_background: true
```

When the waiter exits — or Status is `ready-for-review` — open
`review-cursor` **in that same reply**. Do not quietly fix a failed review.

## When to stop and ask the human

- Anything on the `AGENTS.md` "Ask before" list.
- A PRD or design-spec requirement that needs a backend, accounts, or
  server-side sync.
- A conflict between two authorities that is material rather than cosmetic.
- A `<!-- TEMPLATE_PLACEHOLDER -->` still present in a doc the work depends on.
- A missing or unfetchable design artifact for a screen to be implemented.
