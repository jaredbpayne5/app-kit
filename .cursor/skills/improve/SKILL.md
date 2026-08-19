---
name: improve
description: "Makes existing code easier to understand without changing behavior. Use inside a job after the first test pass. Do not add product behavior."
disable-model-invocation: true
---

# Improve

Builder only. Make existing code easier to understand without changing
behavior. This skill is **inside every job** (`code → test → improve →
test`). It is not an app-wide phase after the plan is done.

## Workflow

1. Identify the target from the request, current diff, or recently changed
   code.
2. Read the target, its tests, and relevant surrounding code. State the
   behavior that must not change.
3. If that behavior lacks tests, add focused coverage and run it against
   the unchanged code. Commit the passing test-only change before
   refactoring. If automated tests cannot exercise the behavior, explain
   why and give other evidence.
4. Find unnecessary complexity, duplication, dead code, weak names,
   awkward boundaries, and abstractions that cost more than they help.
5. Make focused improvements by deleting, deduplicating, renaming,
   simplifying, extracting, or inlining.
6. Preserve public interfaces, data shapes, errors, and user-visible
   behavior unless the user explicitly asks to change them.
7. Run `npm run check` and the tests that cover behavior the refactor can
   affect. Report what improved, what behavior was preserved, and the
   evidence.
8. Commit. Ask before `git push`. Do not review this chat's own diff.

## Boundaries

- Do not add product scope or absorb unrelated cleanup.
- Prefer a few clear edits over a broad rewrite.
- Preserve behavior even when a redesign would be easier.
- Tests must prove behavior was preserved.
- Do not rewrite `docs/PRD.md` or `docs/design.md`.
- Do not invent a screen. Do not start `/ship`.
