---
name: test
description: "Proves that a code change meets its acceptance criteria. Uses npm run check, npm test, npm run verify, and Maestro for mobile UI. Cursor only. Use to test or verify a job, diff, branch, PR, or user flow."
disable-model-invocation: true
---

# Test

Cursor only. Prove a change meets its acceptance criteria. Use this on
the current job when you are the builder running `/code`.

## Workflow

1. Read the job in `docs/plan.md`, `docs/design.md` when present, changed
   code, existing tests, and `AGENTS.md`. Acceptance criteria come from
   the job or `docs/design.md`. Preserve their wording and `AC-n` or
   `INV-n` IDs. Never rewrite criteria to match the code.
2. Map every acceptance criterion, cited invariant, and affected failure
   path to proof by ID. Test changed behavior and behavior a refactor
   must preserve.
3. If automated tests cannot exercise the affected behavior, explain why
   and give other evidence.
4. Add or update focused tests where proof is missing and you are the
   builder on this job. Assertions should fail when the changed
   behavior breaks.
5. Assert behavior a user or caller can observe unless the test targets a
   documented internal contract. Keep setup and assertions no more complex
   than the scenario.
6. Run the narrowest checks that exercise the changed behavior:
   - `npm run check` after edits (format, lint, typecheck, contrast,
     design lint)
   - `npm test` for logic changes
   - `npm run verify` before considering work done
7. When a new or changed user-visible flow is in scope, prove it on a
   simulator with Maestro (`npm run test:e2e` or the `maestro-e2e`
   playbook). Reading source is not device proof. Maestro is required on
   the first implementation of a new screen or flow, not every job. When
   the web lander changes, check the required flows in a real browser.
8. Report each `AC-n`, `INV-n`, or job criterion as pass, fail, or
   unverified. Include the command, flow, or other evidence.

## Boundaries

- Do not weaken assertions to make a change pass.
- Do not fix unrelated failures.
- Do not review the change in this skill. `/review` is Claude-only and
  a different playbook. `/critic` is for product and design, not code.
- If required device or Maestro tooling is unavailable, report the check
  as blocked unless the user explicitly accepts a manual exception.
- Ask before `session:down`. Sims may be in use by another agent.
