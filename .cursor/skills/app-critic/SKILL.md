---
name: app-critic
description: "Writes docs/CRITIC.md, adversarially reviewing Claude's docs/CONTRACT.md before implementation. Cursor only. Judges the contract against docs/PRD.md and the named exports in docs/design-exports/. Finds material ambiguity and flaws. Round 2 appends; never overwrites. Does not review the PRD itself, and does not review code."
disable-model-invocation: true
---

# Critic

Cursor only. The target is `docs/CONTRACT.md`. Review the proposed choices, not
the document type or size. Stay read-only of `docs/CONTRACT.md`. Write
`docs/CRITIC.md`.

`docs/PRD.md` and the named exports in `docs/design-exports/` are the
yardstick, not the target. You need both to be adversarial: the PRD says what
the product must do, the frames say what the screens are. A contract that is
internally consistent but does not deliver the PRD outcome, or that describes a
screen the frames do not show, is a blocker. Do not write findings against the
PRD itself — a PRD problem is a `BLOCKED` verdict and a `/app-product` return.

This is not a code review. Use `/app-review` (Claude only) for implementation.

This chat must not have written the proposal. If it did, stop and say
independent review is blocked. A new Cursor chat should run `/app-critic`.

Do not implement in this chat.

## Workflow

1. Read `docs/PRD.md`, named exports in `docs/design-exports/`,
   `docs/CONTRACT.md`, `AGENTS.md`, relevant current code, tests, and any
   existing `docs/CRITIC.md`. Treat claims about the current system as
   unverified until code, tests, config, or runtime evidence supports them.
   Do not take Claude's explanation of why the contract is good — the
   committed file is the input.
2. If `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`,
   verdict is `BLOCKED`. Next step is `/app-product`, not a contract fix.
3. State the problem, affected user, intended outcome, success measure,
   scope, constraints, and main tradeoff. Report any that the proposal
   leaves unclear.
4. Trace one real case from input to observable outcome. Include ownership,
   validation, state changes, side effects, failure, retry, cleanup, and
   what the user sees where they matter.
5. Challenge the chosen design with the review focus below. Look for a
   simpler choice that reaches the same outcome and proof with less state,
   coupling, duplication, or operational work.
6. Surface material open questions. Recommend an answer when evidence
   supports one. Do not invent questions that cannot change the contract.
7. Write `docs/CRITIC.md`. Round 1 creates the file. Round 2 **appends**
   `# Critic — round 2` to the same file. Never overwrite round 1.
8. Stop after the verdict. Do not rewrite the proposal, write the backlog,
   review implementation code, or implement changes.

## Document shape

```markdown
# Critic — round 1

**Verdict:** FAIL

## What I checked
PRD.md, design-exports/ (named files), CONTRACT.md, relevant seams and routes.

## Findings

### 1. <Short title> (Blocker)
- Where: CONTRACT.md §n, INV-n or AC-n
- Failure: the concrete failure
- Why it matters: impact on the user or safety
- Must change: the smallest correction

## Open questions
- Blocking: …

## Not blocking
…
```

The first line of the verdict block is exactly `**Verdict:** PASS`,
`**Verdict:** FAIL`, or `**Verdict:** BLOCKED`.

## Review focus

- Check fit with no-backend, the `lib/` seams, named exports, ownership,
  boundaries, data, compatibility, and rollback.
- Trace partial failure, retry, cancellation, startup, and recovery where
  they affect the proposal (storage, purchases, notifications).
- Check identity, untrusted input, credentials, destructive authority, and
  sensitive data handling. Accounts or server-side sync is a stop-and-discuss.
- Require observable acceptance criteria and proof for important rules and
  failure paths. Do not let implementation invent user-visible behavior,
  interfaces, data rules, security policy, or failure behavior.
- A frame beats prose. If the contract describes a new screen with no named
  export, that is a blocker.

## Material questions

Report an open question only when two capable implementations could answer
it differently in a way that affects users, data, interfaces, security,
operations, cost, compatibility, or proof.

- **Blocking:** implementation should not start without the answer.
- **Important:** the proposal should record the answer, but the reviewer can
  recommend a safe default from available evidence.

Omit questions that are stylistic, safely local to implementation, outside
the stated scope, or speculative.

## Findings

Report only flaws that can change the contract or its safety:

- **Blocker:** the choice is unsafe, contradicts the goal, `AGENTS.md`, or
  the current system, or cannot recover from an important failure.
- **Important:** the proposal permits materially different implementations
  or leaves a meaningful risk in behavior, security, operations,
  compatibility, or proof.

For each finding or open question include its location, concrete failure or
ambiguity, impact, evidence, and the smallest correction or recommended
answer. Report unclear wording when it prevents a new teammate from
explaining, evaluating, or implementing the contract. Omit other writing
preferences.

## Verdict

- `PASS`: no blocker or important findings or open questions remain.
  Next allowed skill is Claude `/app-backlog` after Matt agrees. Do not start
  `/app-backlog` from this chat.
- `FAIL`: the proposal has a fixable blocker or important finding or
  open question. Next skill is a new Claude chat to fix `docs/CONTRACT.md`.
- `BLOCKED`: the review lacks required context, repository evidence, an
  independent reviewer, or the PRD sentinel is still present.

State what remains unverified. Do not approve because the document is
detailed or because every template section exists.
