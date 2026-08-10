<!-- TEMPLATE_PLACEHOLDER -->

# Product requirements

Fill this before generating screens in the design tool. Until the sentinel above
is removed, agents must not invent an MVP or product scope.

What to build and why — not how it looks and not how it is built. Do not
prescribe navigation, colors, typography, component shapes, spacing, or visual
style here unless a product requirement genuinely forces it; that belongs in
`docs/design-brief.md` and `docs/design-spec.md`. Implementation belongs in
`docs/build-spec.md`.

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

## Deviations from template defaults

This template already decides the technical shape: **no backend**, on-device
storage, RevenueCat for purchases, and the flags in
`apps/mobile/lib/app-config.ts` (`STORAGE`, `MONETIZATION`, `PURCHASES_MODE`).
Do not re-decide those here.

Record only where this product must depart from them, and why. A departure that
needs accounts, a server, or server-side sync is a **stop and discuss**, not a
requirement to write down (see `AGENTS.md`).

- _

## Success criteria

_(How you will know the product works — user-facing outcomes, not analytics
infrastructure.)_

- _

## Open decisions

Only decisions that materially affect the product. Minor ambiguities should be
resolved with reasonable judgement, not parked here.

- _
