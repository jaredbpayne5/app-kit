---
name: app-code
description: "Builder coding skill. Completes one job: code → test → improve → test. Ask before git push. Use to implement one unchecked job from docs/plan.md. Do not review this chat's own diff."
disable-model-invocation: true
---

# Code

Builder only. Complete **one** job. Do not start the next job. Do not
review this chat's own diff. `/app-review` is Claude-only.

One job is `code → test → improve → test`, then `npm run check`.

## Workflow

1. Read the next unchecked job in `docs/plan.md`, `AGENTS.md`,
   `docs/PRD.md`, `docs/design.md`, and the named export if the job is a
   screen. If `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`,
   stop. If the last `**Verdict:**` line in `docs/critic.md` is not
   `PASS`, stop unless Matt explicitly overrides in this chat. Note the
   job's `Deps:` — if a job it depends on is still unchecked, stop and say
   so.
2. If the job needs a new screen layout, run `app-pull-design` first. If the
   pull fails, stop. Do not invent a layout.
3. Create or reuse a branch from the latest default branch.
4. Write the code. Use `lib/` seams, `ui/` primitives, and NativeWind
   tokens. Do not rewrite `docs/PRD.md` or `docs/design.md`. The job's
   `Files:` field is its expected blast radius: if you need to touch
   something outside it, say so in the report rather than expanding scope
   quietly.
5. Use `/app-test` to prove the job works, affected failures are handled, and
   refactors preserve behavior. Run `npm run check`. Run `npm test` for
   logic changes. Simulator and Maestro only when the job changes a
   user-visible flow.
6. Use `/app-improve` on the code this job just wrote. Same behavior, clearer
   code. Then `/app-test` again.
7. Commit. Ask before `git push`. If the user said to push, push and create
   or update one pull request with a short summary and the current proof.
8. Stop. Do not check the box in `docs/plan.md`. Next allowed skill is
   Claude `/app-review` on this job. Do not run `/app-review` here. Do not merge
   unless the user asks.

## If something is wrong

- Job is unsound, or a higher authority contradicts it: stop and report.
  Do not silently implement a different design.
- A product or technical decision is missing: stop and report. Do not
  decide it in `/app-code`.
- You need a new dependency, config plugin, backend, `eas`, `prebuild`,
  or `session:down`: ask first.

## Boundaries

- One job, one focused change.
- No unrelated refactors. No reformatting untouched files.
- Do not invent a screen with no named export.
- Do not start `/app-ship`.
- Automatic skill selection is not merge authority and not push authority.
