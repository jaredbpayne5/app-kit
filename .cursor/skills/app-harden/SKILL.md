---
name: app-harden
description: "Adversarial runtime lens at the release gate. Try to break the running app. Reports findings; fixes land as jobs. Cursor only. Does not write app code or start /app-ship."
disable-model-invocation: true
---

# Harden

Builder only. Whole-app adversarial pass before Matt ships. Do not write
app code. Do not start `/app-ship`. Do not submit, pay, or publish.

Product-fit and architecture coherence are Claude whole-app `/app-review`.
Store-readiness is `npm run preflight` and `/app-ship`. This skill is the
runtime lens only.

## Outcome

A read-only verdict: the app holds under abuse and failure, or it does
not. Name every blocker. Do not implement the fixes. Fixes become jobs.

## Workflow

1. Read `AGENTS.md`, `docs/PRD.md`, `AC-n` / `INV-n` in `docs/design.md`,
   named exports, and the running source.
2. If `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`,
   verdict is `BLOCKED`. Stop.
3. Try to break the app. Use the simulator and Maestro when a flow is
   user-visible. You may run `npm run check`, `npm test`, and
   `npm run test:e2e` as evidence. Do not run `eas`, `store:push`,
   `web:deploy`, or `session:down`.
4. Return findings and one verdict. Do not plan a new feature or open
   shipper.

## Attack the app

Walk each main flow and try:

- No network, slow network, interrupted request
- Bad, empty, and huge input
- Double taps
- App restart, background / foreground
- Permission denied
- Storage failure
- Purchase and restore failure
- iOS vs Android differences
- Navigation edge cases
- Accessibility (Dynamic Type, contrast, hit targets)

## Findings

Report only flaws that can block ship or change user-visible safety:

- **Blocker:** unsafe, contradicts the product or `AGENTS.md`, or cannot
  recover from an important failure.
- **Important:** a meaningful risk in behavior, security, privacy,
  purchases, compatibility, or proof.

For each finding include location, concrete failure, impact, evidence, and
the smallest correction. Omit style preferences.

## Verdict

Use exactly `PASS`, `FAIL`, or `BLOCKED`.

- `PASS`: no blocker or important findings remain.
- `FAIL`: a fixable blocker or important finding remains. Fixes land as
  jobs for `/app-code`.
- `BLOCKED`: missing required context, or the PRD sentinel is still
  present.

State what remains unverified. Do not approve because the docs are long.
