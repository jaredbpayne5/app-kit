<!-- TEMPLATE_PLACEHOLDER -->

# Product requirements

Fill this before handing it to the UI/UX design tool. Until the sentinel above
is removed, agents must not invent an MVP or product scope.

**What to build and why** — not how it looks and not how it is built.

- Do not prescribe navigation, colors, typography, component shapes, spacing,
  or visual style here unless a product requirement genuinely forces it.
- Product-imposed limits belong in **Design constraints** (below), not in a
  separate design-brief file. Kickoff prompts for the design tool stay
  **outside the repo** (chat paste only).
- The only repo file you give the design tool is this PRD.
- After exports land in `docs/design-exports/`, Claude writes `docs/design.md`.
  Cursor writes `docs/critic.md`. Claude writes `docs/plan.md`. Those files
  do not exist yet and are not authorities for this PRD.

## Problem

_(What pain does this app solve?)_

## Target user

_(Who is this for?)_

## Value proposition

_(Why would this user care enough to install it?)_

## Goals

### Primary goals

- _

### Non-goals

- _

## Core user outcomes

What should users be able to accomplish?

- _

## MVP feature set

For each feature: what it is for, what it must do, and how you would know it
works.

### Feature — _

**Purpose:**

**Requirements:**

- _

**Acceptance criteria:**

- [ ]

## Core user flows

Intent and outcome, not screens.

### First-time user

1. _

### Returning user

1. _

## Business rules

_(Rules the product must enforce: limits, entitlement gating, what free vs paid
users get, retention/deletion rules.)_

- _

## Data / domain

What the app remembers. Modeled later through `lib/storage.ts`.

### Entities

- _

### Relationships

- _

### Important state transitions

- _

## Edge cases

- _

## Explicitly out of scope

- _

## Platform & technical constraints

Confirm or adjust. Prefills match this template’s defaults — change only when
the product genuinely requires it. A need for accounts, a server, or
server-side sync is a **stop and discuss** (see `AGENTS.md`), not something to
quietly require here.

- **Platform:** iOS + Android (Expo)
- **Offline:** Works fully offline (local-first)
- **Authentication:** None (template default)
- **Persistence:** On-device via `lib/storage.ts` (`STORAGE`: `kv` or `sql`)
- **Integrations:** None required for MVP (list any that are)
- **Monetization:** `free` / `subscription` / `one-time` (see `app-config.ts`)
- **Accessibility:** _(e.g. Dynamic Type, WCAG AA contrast, min touch targets)_
- **Performance:** _(e.g. cold start, list scroll expectations)_
- **Security / privacy:** On-device data stays on-device; no analytics by default

## Design constraints

Constraints imposed by the **product**, not visual design instructions for the
designer. The design tool owns look-and-feel within these bounds.

### Required

- _

### Prohibited

- _

Do not prescribe navigation, colors, typography, component shapes, spacing, or
visual style unless a product requirement genuinely requires it.

## Deviations from template defaults

This template already decides the technical shape: **no backend**, on-device
storage, RevenueCat for purchases, and the flags in
`apps/mobile/lib/app-config.ts` (`STORAGE`, `MONETIZATION`, `PURCHASES_MODE`).

Record only where this product must depart from them, and why — or write
“None.”

- _

## Success criteria

_(How you will know the product works — user-facing outcomes, not analytics
infrastructure.)_

- _

## Open decisions

Only decisions that materially affect the product. Minor ambiguities should be
resolved with reasonable judgement, not parked here.

- _
