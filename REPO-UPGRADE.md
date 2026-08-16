# Factory leftover backlog

What is still left on this **template** (the factory you clone per app).
Not a product spec. Not a substitute for `AGENTS.md`.

The factory upgrade shipped to `main` on 2026-08-15 (fast-forward from
`factory-upgrade`, tip `6697ff5`). U0, U-zero, U2, U3, U4, U5, and U1a
are done. Do not redo them.

Local grades stay in gitignored `REPO-EVALUATION.md`. Template-mode
mailbox tasks cite a section here.

**Status:** on `main`. Remaining work waits for a real app (U6), then a
product-rule thin (U1b). U7 is optional.

---

## How to read this file

- **Always-on** — instructions an AI loads on every turn. Tokens here
  compete with the file it should be editing.
- **Mailbox** — `.ai/current-task.md` plus `.ai/mailbox-state.json`.
  Do not change that file format.

Do **not** implement the leftovers as one task.

---

## Still do not

These constraints still apply to leftover work:

- Thin `AGENTS.md` product/design rules before a first clone (U6).
- Change the mailbox file format.
- Install full pstack, or unslop as always-on.
- Put Maestro in default CI.
- Add a second ticket system (Taskmaster, Beads, Spec Kit, Conductor).
- Add a `Designed=yes` file-existence validator.
- Delete unused `ui/` / demo screens / dormant seams in *this* template.
- Rewrite `session.sh` / `doctor.sh`.
- Catch every `bash -c` wrapper.
- Gate ordinary `git commit` or `--no-verify`.
- Rearrange `apps/`.
- Run `npm audit fix --force`.
- Add Dependabot (Renovate is already the pick).

New checks still follow the class rule: if a check can pass vacuously,
it must prove it can fail in `npm run check`.

---

## Order (what is left)

```
U6     first product clone from main (separate repo; not a template commit)
U1b    thin product rules from those notes; re-measure; set a token cap
U7     optional /unslop on leftover docs (after U1b, on demand)
```

U1b without U6 notes is guessing. Extra tokens on the first app are
cheaper to undo than a paragraph you cut and later need. After U1b,
copy the thinner files into that product in one commit.

---

## U6 — First product clone (evidence)

- **What:** PRD → Moonchild → compile-specs → mailbox → `verify` →
  `preflight` on one real app, cloned from **`main`**. Write down which
  always-on rules actually fired (hit vs never-hit).
- **Why:** This factory has never produced a product. U1b needs that
  list. Without it, thinning `AGENTS.md` is a guess.
- **How:** Separate repo or folder. Do not thin this template first.
  Do not treat U6 as a commit on this factory.
- **Done when:** the clone has gone through that loop, and the hit vs
  never-hit notes exist.
- **Risks:** Temporary extra always-on tokens during the first build.
  Not lock-in.

---

## U1b — Product-rule thin (after U6 notes)

- **What:** Move unused *product* procedure out of always-on files.
  Keep what the clone actually hit. Cap repo always-on **bytes/tokens**
  from the post-thin measurement (not a 200–250 line guess). Add the
  context-budget script only after that measurement.
- **Why:** Extra rules compete with the open file. Cap lines reward
  long lines. A cap set before measuring fights itself.
- **How:** Thin from U6 hit vs never-hit notes. Do not guess. Do not
  thin from memory. User-level rules stay a separate budget in
  `~/.cursor/rules`. Skills and `docs/recipes/` stay on-demand.
- **Done when:** `AGENTS.md` (and only what the notes justify) is
  thinner, new `wc -l` / `wc -c` counts are recorded here, and a
  bytes/tokens cap exists from that measurement.
- **Risks:** Over-thinning. Mitigate with the clone notes, not a guess.

### Baseline to beat (U1a, 2026-08-15)

Rough tokens = bytes ÷ 4. Skills and `docs/recipes/` are not always-on.

Repo always-on after U1a: Cursor ≈ **4.0k** tokens (`AGENTS.md` +
implementation-workflow + sandbox = 15899 bytes). Claude ≈ **4.1k**
(`AGENTS.md` + `CLAUDE.md` = 16378 bytes). No cap yet.

| Path | Who | Lines | Bytes | Tokens | Always-on? |
| --- | --- | ---: | ---: | ---: | --- |
| `AGENTS.md` | both | 304 | 14646 | ~3662 | yes |
| `CLAUDE.md` | Claude | 43 | 1732 | ~433 | yes (Claude) |
| `.cursor/rules/implementation-workflow.mdc` | Cursor | 14 | 514 | ~129 | yes (Cursor) |
| `.cursor/rules/cursor-sandbox.mdc` | Cursor | 21 | 739 | ~185 | yes (Cursor) |
| `.claude/agents/runner.md` | Claude runner | 20 | 1032 | ~258 | when runner is used |
| `~/.cursor/rules/maestro-e2e-hygiene.mdc` | Cursor (user) | 40 | 1332 | ~333 | no — glob-scoped |
| `~/.cursor/rules/delegate-to-cheaper-model.mdc` | Cursor (user) | 40 | 1793 | ~448 | yes (machine) |
| `~/.cursor/rules/beginner-step-by-step.mdc` | Cursor (user) | 27 | 1243 | ~311 | yes (machine) |

User always-on (outside repo; count `beginner-step-by-step` once):
delegate + beginner ≈ **0.8k**. A second identical copy lives at
`~/Development/.cursor/rules/beginner-step-by-step.mdc`.

| Path | Who loads it | After U1a |
| --- | --- | --- |
| `AGENTS.md` | both, every turn | keep until U1b notes say otherwise |
| `CLAUDE.md` | Claude only | keep (role split; points at skills) |
| `.cursor/rules/implementation-workflow.mdc` | Cursor, every turn | pointer → `mailbox` skill |
| `.cursor/rules/cursor-sandbox.mdc` | Cursor, every turn | keep |
| `.claude/agents/runner.md` | Claude, when runner is used | pointer → `AGENTS.md` Ask-before |
| `.cursor/skills/` + `.claude/skills/` | on demand | skill |
| `docs/recipes/` | human / skill pointer | not always-on |
| `~/.cursor/rules/maestro-e2e-hygiene.mdc` | Cursor, Maestro / e2e files | keep, glob-scoped |
| `~/.cursor/rules/delegate-to-cheaper-model.mdc` | Cursor, every turn | keep (machine, not repo) |
| `~/.cursor/rules/beginner-step-by-step.mdc` | Cursor, every turn | keep (machine, not repo) |

---

## U7 — Optional unslop (after U1b, not instead)

- **What:** One on-demand `/unslop` pass on leftover README / recipes.
  Skip hooks and the mailbox template unless you read every line.
- **Why:** U1b decides which product rules stay. Unslop decides how
  leftover sentences sound.
- **How:** Do **not** install as always-apply. Do not “add soul” on
  agent contracts.
- **Risks:** A whole-repo rewrite of `AGENTS.md` can drop a load-bearing
  rule while `check` stays green.

---

## Progress

- [ ] U6 — first product clone from `main` (separate repo)
- [ ] U1b — thin from U6 notes; re-measure; cap
- [ ] U7 — optional unslop polish
