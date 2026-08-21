---
name: app-contract
description: "Writes docs/CONTRACT.md for a proposed feature or the app. Use when product or technical choices must be settled before coding. Covers behavior, storage, purchases, failures, INV/AC, and tests. Use architecture for what the code is today."
user-invocable: true
argument-hint: "<feature, problem, or brief>"
---

# Contract

Thinker only. No app code. Stop with a proposed contract ready for Cursor
`/app-critic`. This chat must not critic its own contract.

## Workflow

1. Read `AGENTS.md`, `docs/PRD.md`, named exports in `docs/design-exports/`,
   relevant code, and any existing `docs/CONTRACT.md`. If a later chunk lives
   under `docs/<feature>/`, read that too — v1 itself is `docs/CONTRACT.md`.
2. If `docs/PRD.md` still contains `<!-- TEMPLATE_PLACEHOLDER -->`, stop.
3. If a screen is in scope and has no named export, stop. Do not invent a
   layout. The export is first-class.
4. Identify choices that would change behavior, interfaces, data, errors,
   security, operations, or tests.
5. Ask blocking questions before drafting. Ask only when the answer would
   change the contract, and recommend an answer. Record non-blocking questions
   and a recommended default under Open questions.
6. Write `docs/CONTRACT.md` using the numbered shape below. Cite export
   frames by name. Keep it short and in order. Omit only sections that do
   not apply.
7. Run the review pass. Fix what you can. List the rest under Open questions.
8. Stop. Do not write the backlog or implement. Next allowed skill is a
   **new Cursor chat** → `/app-critic`.

## Document shape

```markdown
# <Title>

> **Status:** Proposed for review

## 1. Executive summary
Say what is wrong today, who feels the problem, what will change, how we plan to fix it, and the main downside. Use simple words. Do not list sections or implementation details.

## 2. Context and scope
Describe the current behavior, why it is insufficient, what changes once this ships, and the boundary of this contract.

## 3. System context
Show where the change fits. Name the parts it touches and the boundaries it must preserve (no backend, `lib/` seams, named exports). Include a small diagram when it makes those relationships clearer.

## 4. Proposed contract

### How it works
Walk one real case from start to finish. Name the thing that arrives, what handles it, what gets written down, and what the user sees.

### Components and responsibilities
For each changed part, state what it owns, what it depends on, and what it does not own.

### Decisions
For each real choice, say what you chose, what you rejected, and what the choice costs. Use one short paragraph. Skip choices nobody would question.

## 5. Invariants and requirements

### Invariants
List rules that must always hold as `INV-1`, `INV-2`, and so on. A reviewer checks the code against these rules, so keep them short and testable.

### Requirements
- Observable behavior and constraints.

## 6. Interfaces and data
Storage keys or tables via `lib/storage.ts`, purchase/entitlement rules via `lib/purchases.ts`, config flags, compatibility, or migration.

### Naming and identity
How every stored name or ID is created, what happens when that fails, and what happens if its source changes after data exists.

## 7. Failure behavior and lifecycle
Say what can fail, what state follows, whether the system retries, and how it recovers. Cover startup, purchases, work in flight, and what the user sees.

## 8. Security, privacy, and operations
State the trust boundary (on-device unless the product adds a network feature), sensitive data handling, and operational impact. Name shared limits. Say what happens at each limit.

## 9. Acceptance criteria
- `AC-1`: Testable condition that proves the work is complete.

## 10. Test approach
How each `INV-n` and `AC-n` will be proved. Cite the IDs.

## 11. Risks and tradeoffs
- Risk and mitigation.

## 12. Open questions
- Question, and whether it blocks starting work.

## 13. Out of scope
- Related work this contract does not include.
```

## Writing rules

- Start with the simplest useful explanation. Write for a new teammate.
- Prose is the default. Use bullets only for real lists.
- A bullet cannot carry a decision by itself. Write the reason next to it.
- Define a term the first time you use it, or do not use it.
- Keep current architecture and proposed behavior distinct. Link to
  `ARCHITECTURE.md` when it exists.
- Give each changed component a positive and negative boundary.
- Once another artifact cites an `INV-n` or `AC-n`, keep that ID. Do not
  renumber or reuse it.
- Prefer one clear recommendation over a list of options.
- Do not repeat the same fact in several sections.
- Do not use em dashes.
- Do not prescribe freehand layouts. A named export beats prose.
- Do not put a job list in this file. Tracking work belongs in
  `docs/BACKLOG.md`.

## Review pass

Reread the draft once and check each category. Fix any gap you can resolve
from the available evidence.

1. **Executive summary.** Can a new teammate understand the problem, outcome,
   approach, and main downside without reading the rest?
2. **Fit.** Does the contract preserve no-backend, the `lib/` seams, and named
   export frames?
3. **Names and identity.** Where does every stored identifier come from?
4. **Failure and recovery.** What creates a bad state? What does the user see?
5. **Security and privacy.** On-device data stays on-device unless the product
   explicitly adds a network feature. No secrets in `EXPO_PUBLIC_*`.
6. **Purchases.** If monetized, is mock vs live explicit? What does a locked
   user see?
7. **Either/or acceptance criteria.** Do not allow both sides of
   "recovers or retains" to pass. Choose one observable behavior.

Put anything you cannot resolve under Open questions and state whether it
blocks task breakdown.
