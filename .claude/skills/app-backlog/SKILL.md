---
name: app-backlog
description: "Writes docs/BACKLOG.md as ordered jobs after the contract is frozen. Use after Cursor /app-critic returns PASS and Matt agrees. Jobs only. Do not use for one already-decided coding task."
user-invocable: true
argument-hint: "[optional focus]"
---

# Backlog

Thinker only. Split decided work into jobs the builder can run with `/app-code`.
Write `docs/BACKLOG.md`. Stop after writing the backlog. Do not implement.

Do not start if `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`.
Do not start if the last `**Verdict:**` line in `docs/CRITIC.md` is not
`PASS`, unless Matt explicitly overrides in this chat.

## Workflow

1. Read `docs/PRD.md`, `docs/CONTRACT.md`, `docs/CRITIC.md`, named exports,
   `AGENTS.md`, and relevant code.
2. Stop and return to `/app-contract` if an unresolved choice would change
   behavior, interfaces, data, security, compatibility, operations, or proof.
3. Split the work into jobs that each deliver working behavior and fit one
   Cursor chat and one review.
4. Keep shared contracts in one job. Do not make two jobs answer the same
   question independently.
5. Separate refactoring when it would hide a behavior change.
6. Order jobs by dependency.
7. Write `docs/BACKLOG.md` using the job shape below. Jobs only. No new
   screens, data rules, payment behavior, or architecture. If the backlog
   reveals a contract hole, stop and reopen the contract — do not patch it
   here.
8. Stop. Do not check any box. Only Claude checks a box, and only after
   `/app-review` returns PASS. Next allowed skill is builder `/app-code` on the
   first unchecked job.

## Write for two readers

Each job is read by a human and executed by an agent.

The first lines must let a human understand the job in under a minute.
State the concrete problem, the result, and why it matters in everyday words.
Do not use requirement IDs, implementation details, undefined project terms,
or unfamiliar acronyms there.

Put job-specific decisions, interfaces, failure rules, and security
constraints in Notes. Link `docs/CONTRACT.md`. Pin the decided version when
later edits could change the contract.

## Document shape

```markdown
# Backlog

Contract: docs/CONTRACT.md (frozen YYYY-MM-DD)

- [ ] 1. <Plain action and result>
      Done when: observable result; cite AC-n / INV-n where they apply.
      Files: apps/mobile/lib/reminders.ts, apps/mobile/app/(tabs)/index.tsx
      Tests: logic, screen
      Deps: none
      Check: npm run check, npm test
      Notes: seam to use, named export if UI, what to stay out of.
```

Each job carries:

- **Done when** — observable, cites `AC-n`/`INV-n` where they apply
- **Files** — repo-relative paths this job is expected to touch, including
  files it will create. This is the job's blast radius, not a guess.
- **Tests** — the required proof tier, from the table below. Comma-separate
  when a job needs more than one.
- **Deps** — `none`, or the job numbers that must land first
- **Check** — exact commands
- **Notes** — seam to use, named export if UI, what to stay out of

`scripts/dev/backlog-lint.sh` validates these fields, so keep the field names and
spelling exact.

### Test tiers

| Tier | Means | Proof |
| --- | --- | --- |
| `logic` | Behavior with no UI: seams, data rules, pure functions | Jest test under `apps/mobile/__tests__/` |
| `screen` | A screen or component renders and is reachable | React Native Testing Library render plus accessibility labels |
| `flow` | A user journey across screens | Maestro flow in `apps/mobile/maestro/` |
| `none` | No behavior change: copy, docs, config | State why in Notes |

Pick the tier by what the job actually changes. A job that adds a seam function
and shows it on a screen is `logic, screen`. Do not claim `flow` unless a
Maestro flow really covers it — `npm run test:e2e` is the only thing that
proves that tier, and `--allow-skip` does not.

## Writing rules

- Use a short title that names an action and result.
- Use familiar words and specific verbs.
- Define a necessary technical term where it first appears.
- Say `sending the same event twice creates one reply`, not `prove idempotency`.
- Preserve applicable `AC-n` and `INV-n` references in Done when or Notes
  without making a reader decode them to understand the job.
- Do not repeat a fact in several sections.
- Do not use slogans, metaphors, filler, or vague claims such as `robust`,
  `seamless`, `comprehensive`, and `future-proof`.
- Do not use em dashes.

## Boundaries

- Do not split one working behavior into separate file or technical-layer jobs.
- Do not create scaffolding or cleanup jobs without a checked outcome.
- Do not hide unresolved decisions inside implementation jobs.
- Keep each job small enough for one agent run and one focused review.
- A new screen needs a named export. If it is missing, stop.
- In Check, include `npm run check`, `npm test` when logic changes,
  and the exact Maestro or manual proof when automation cannot cover it.
- Every job needs `Files`, `Tests`, and `Deps`. Do not bury a target file or a
  dependency in Notes prose, and do not write `Files: TBD`.
- Do not decide anything this file is not allowed to decide.
- Do not append someday ideas. A hole in the contract goes back to
  `/app-contract`, not into this file.

Before returning the backlog, read each job twice:

1. Human pass: can someone explain what will change and why after reading
   only the title and Done when?
2. Agent pass: can a fresh builder find the source, identify dependencies
   and fixed decisions, implement the job, and prove it without asking a
   product or architecture question?

Delete repeated background after both passes succeed.
