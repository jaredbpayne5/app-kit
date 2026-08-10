# Product pipeline (PRD → design → specs → code)

How a clone of this template becomes a real app. Agents follow the same order
via `AGENTS.md`. Fill the `docs/` placeholders before writing product UI.

The pipeline is specification-first: each step produces a document that the next
step treats as authority. `AGENTS.md` → *Authority hierarchy* is the tiebreaker
when two of them disagree.

**Factory shape (human):** finish `PRD.md` outside the repo with a strong model
→ hand **only the PRD** (plus an optional kickoff *prompt* that is never
committed) to the design tool → export artifacts → clone this template → drop
in PRD + exports → one strong-model pass compiles `design-spec.md`,
`screens-status.md`, `moonchild.md`, `build-spec.md`, and initializes
`build-status.md` → cheaper model implements tasks from the build spec.

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

1. **PRD** — Write `docs/PRD.md` (problem, user, MVP, flows, platform and
   design *constraints*, out of scope). Remove `<!-- TEMPLATE_PLACEHOLDER -->`.
   This is the only repo file given to the design tool.
2. **Design (outside the repo)** — In the design tool, create the design system
   and full journeys from the PRD. If the tool needs a kickoff prompt, write it
   in chat and paste it — **do not commit a design-brief file**. Export the
   artifacts (frames / system) into the clone (or keep them pullable via MCP).
3. **Design pointer & inventory** — Fill `docs/moonchild.md` (tool of record +
   project ids and/or path to committed exports) and `docs/screens-status.md`
   (`Designed` = yes/no per screen). Agents must not implement a screen until
   that column is `yes`.
4. **Design spec** — One strong-model pass **compiles** `docs/design-spec.md`
   from the PRD + exported artifacts (faithful transcription of approved UX/UI:
   IA, components, per-screen layout and states, accessibility). It must not
   invent or extend the design beyond the exports. Coding agents during
   implementation read it; they do not freestyle new screens from it alone.
5. **Build spec** — Same strong-model session (or immediately after) compiles
   `docs/build-spec.md` from PRD + design spec + this repo: architecture
   choices, data model, and phases broken into tasks with acceptance criteria.
   It must not add product requirements or redesign anything. Then initialize
   `docs/build-status.md`.
6. **Session handoff** — Keep `docs/build-status.md` current (phase, current
   task, where we left off, deviations). Read it at the start of every coding
   session.
7. **Implement** — Work the next incomplete task in `docs/build-spec.md`. For
   each designed screen: retrieve the artifact (MCP or committed export) → sync
   tokens into `apps/mobile/global.css` / `ui/` → adapt into Expo Router /
   NativeWind / seams. No freehand layouts.
8. **Data & ship** — Phase 4+ in `docs/build-status.md` (on-device logic,
   QA, polish, `npm run preflight`).

## Model tier per step

Tiers and the delegation rule live in `AGENTS.md` → *Delegate to a cheaper
model*; this is only which step needs which.

| Step | Tier | Why |
| --- | --- | --- |
| PRD (+ optional external kickoff prompt) | Strong | Product judgement; ask only questions that matter |
| Design system + screens | Design tool | Owns IA, visual language, layouts |
| Compile design-spec + build-spec | Strong, once | Faithful transcription + task decomposition — not redesign |
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

1. **`docs/moonchild.md`** — project pointer and/or export paths filled (doctor
   warns while still a template placeholder).
2. **`docs/design-spec.md`** — actually specifies the screen being built.
3. **In-session** — if the design tool’s MCP is missing, a pull fails, or
   returns nothing, and no committed export exists: **stop and tell the user**.
   Do not generate a layout.

Prefer leaving Moonchild tools on auto-allow when they are read/pull-only.

## Swapping design tools

The rules in `AGENTS.md` are written for "the design tool of record", not for
Moonchild specifically. To move to another tool: point `docs/moonchild.md` at
it (its connection checklist is per-tool), commit or link exports, keep
`docs/screens-status.md` as the implement/don't-implement gate, and compile
`docs/design-spec.md` from those exports. The artifact requirement is unchanged
— MCP pull if the tool has one, otherwise a committed export.

## Related

- Design authority: `docs/design-spec.md`
- Task breakdown: `docs/build-spec.md`
- Phase checklist: `docs/build-status.md`
- Brand palette catalog: `docs/recipes/brand-palette.md`
- Brand assets: `docs/recipes/brand-assets.md`
- Store compliance: `docs/recipes/store-compliance.md`
- Capability costs: `docs/CAPABILITIES.md`
