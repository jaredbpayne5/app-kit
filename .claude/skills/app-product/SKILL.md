---
name: app-product
description: "Fills docs/PRD.md from the existing template. Use when starting a product, writing or revising the PRD, or when the file still has TEMPLATE_PLACEHOLDER. Does not write CONTRACT.md or app code."
user-invocable: true
argument-hint: "[product idea or PRD revision]"
---

# Product

Fill `docs/PRD.md` using the template already in that file. Say what to build
and why. Do not say how it looks or how it is built.

Thinker only. No app code. Do not write `docs/CONTRACT.md`. Do not invent
a design system, screen list, or build plan.

## Workflow

1. Read `AGENTS.md`, `docs/PRD.md`, and `apps/product.json`.
2. If the user has not named a product, stop and ask what this clone is for.
   Do not invent an MVP.
3. Fill every section the template already has. Use the headings in
   `docs/PRD.md`. Do not add a parallel product file.
4. Remove `<!-- TEMPLATE_PLACEHOLDER -->` only when the product is specified
   well enough that a design tool could work from this file alone.
5. Stop. Next allowed skill is Matt taking this file to a UI/UX tool, then a
   new Claude chat → `/app-contract`.

## What belongs here

- Problem, user, value, goals, non-goals
- Core user outcomes and MVP features with acceptance criteria
- User flows as intent and outcome, not screens
- Business rules, data/domain, edge cases, out of scope
- Platform constraints from the template defaults
- Product-imposed design constraints (required / prohibited)
- Deviations from template defaults, or `None`
- Success criteria and open decisions

## What does not

- Navigation, colors, type, spacing, or component shapes unless a product
  rule forces it
- Kickoff prompts for the design tool (chat paste only, outside the repo)
- `docs/design-brief.md` (it does not exist)
- Implementation planning, storage schemas, or task breakdown
- Accounts, a server, or server-side sync — stop and discuss (see `AGENTS.md`)

## Writing rules

- Write for a new teammate. Short sentences. Define a term the first time.
- Prefer desk research and public evidence. Do not prescribe talking to
  strangers.
- Record only material open decisions. Resolve minor ambiguity with judgement.
- Do not use em dashes.
