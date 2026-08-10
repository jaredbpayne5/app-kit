# Product pipeline (PRD → design → build spec → code)

How a clone of this template becomes a real app. Agents follow the same order
via `AGENTS.md`. Fill the `docs/` placeholders before spending design-tool
credits or writing product UI.

The pipeline is specification-first: each step produces a document that the next
step treats as authority. `AGENTS.md` → *Authority hierarchy* is the tiebreaker
when two of them disagree.

## Identity (set once, keep in sync)

Prefer one command so the four surfaces cannot drift:

```bash
npm run init-app -- --name "My App" --slug my-app --package com.yourname.myapp
```

| Field | File |
| --- | --- |
| App display name, slug, scheme, bundle IDs | `apps/mobile/app.json` |
| Shared name, slug, tagline, contact email, privacy/terms URLs | `apps/product.json` |
| Lander copy, features, store badge URLs | `apps/web/lander.json` |
| Local env (`EXPO_PUBLIC_*`) | `apps/mobile/.env.local` (from `.env.example`) |

Mismatch here is how you get “App Template” on device and “Example App” on
the lander. Bundle IDs are permanent after the first store upload. Script:
`scripts/factory/init-app.sh` (`npm run init-app`).

## Build order

1. **PRD** — Write `docs/PRD.md` (problem, user, MVP, flows, out of scope).
   Remove `<!-- TEMPLATE_PLACEHOLDER -->`.
2. **Design brief** — Write `docs/design-brief.md` as a *starting* direction
   for Moonchild (tone, rough color/type feel). Not final hex/px. Optionally
   pick a mood-matched palette from `docs/recipes/brand-palette.md` into the
   brief and `apps/mobile/assets/brand/brand.json` — do **not** treat those
   hex values as final `global.css` tokens (Moonchild owns that).
3. **Design** — Connect the design tool’s MCP in Cursor and/or Claude Code.
   Create the design system from the brief + PRD, then generate full journeys
   (not isolated screens). Record which tool and its ids in `docs/moonchild.md`.
   The tool also writes `docs/design-spec.md` — the approved UX/UI as prose:
   IA, components, per-screen layout and states, accessibility. A coding agent
   never authors that file.
4. **Screens inventory** — Fill `docs/screens-status.md` from the design tool
   (`Designed in Moonchild` = yes/no). Agents must not implement a screen
   until that column is `yes`.
5. **Build spec** — One strong-model pass over PRD + design spec + this repo
   produces `docs/build-spec.md`: architecture choices, data model, and phases
   broken into tasks with acceptance criteria. It is a build planner’s
   document — it must not add product requirements or redesign anything. Then
   initialize `docs/build-status.md`.
6. **Session handoff** — Keep `docs/build-status.md` current (phase, current
   task, where we left off, deviations). Read it at the start of every coding
   session.
7. **Implement** — Work the next incomplete task in `docs/build-spec.md`. For
   each designed screen: pull the artifact via MCP → sync tokens into
   `apps/mobile/global.css` / `ui/` → adapt into Expo Router / NativeWind /
   seams. No freehand layouts.
8. **Data & ship** — Phase 4+ in `docs/build-status.md` (on-device logic,
   QA, polish, `npm run preflight`).

## Model tier per step

Tiers and the delegation rule live in `AGENTS.md` → *Delegate to a cheaper
model*; this is only which step needs which.

| Step | Tier | Why |
| --- | --- | --- |
| PRD, design brief | Strong | Product judgement; ask only questions that matter |
| Design system + screens | Design tool | Owns IA, visual language, layouts |
| Build spec compilation | Strong, once | Architecture and task decomposition |
| Routine implementation | Cheaper | "Run X, change Y to Z" against a written task |
| Pulled screens, purchases, design trade-offs | Strong | Looks routine, isn’t |
| Final audit | Strong | Judging spec coverage, not executing a task |

## Final audit

After the last build phase, before shipping: walk the implementation against
`docs/PRD.md`, `docs/design-spec.md`, and the Global acceptance criteria in
`docs/build-spec.md`. Fix what is broken, record knowing departures under
**Deviations** in `docs/build-status.md`, then `npm run verify` and
`npm run preflight`.

This is a product-completeness check. `npm run preflight` is a store-readiness
check. Both are needed and neither substitutes for the other.

## Design tool gates

Shell scripts cannot see whether MCP is attached. Three checks:

1. **`docs/moonchild.md`** — project pointer filled (doctor warns while still
   a template placeholder).
2. **`docs/design-spec.md`** — actually specifies the screen being built.
3. **In-session** — if the design tool’s MCP is missing, a pull fails, or
   returns nothing, and no committed export exists: **stop and tell the user**.
   Do not generate a layout.

Prefer leaving Moonchild tools on auto-allow when they are read/pull-only.

## Swapping design tools

The rules in `AGENTS.md` are written for "the design tool of record", not for
Moonchild specifically. To move to another tool: point `docs/moonchild.md` at
it (its connection checklist is per-tool), have it write `docs/design-spec.md`,
and keep `docs/screens-status.md` as the implement/don't-implement gate. The
artifact requirement is unchanged — MCP pull if the tool has one, otherwise a
committed export.

## Related

- Design authority: `docs/design-spec.md`
- Task breakdown: `docs/build-spec.md`
- Phase checklist: `docs/build-status.md`
- Brand palette catalog: `docs/recipes/brand-palette.md`
- Brand assets: `docs/recipes/brand-assets.md`
- Store compliance: `docs/recipes/store-compliance.md`
- Capability costs: `docs/CAPABILITIES.md`
