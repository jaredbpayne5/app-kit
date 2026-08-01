<!-- TEMPLATE_PLACEHOLDER -->

# Build status

> Read this file at the start of every session before doing anything else.
> Update it before ending a session, or whenever a phase (or meaningful chunk
> of one) is completed.
>
> `npm run session:status` is **dev environment** status (Metro / sims) — not
> this file.

## Current status

- **Phase:** _(e.g. Phase 0 — Foundation & Planning)_
- **Status:** _(Not started / In progress / Complete)_
- **Last updated:** _(date)_

## Where we left off

_(Specific enough that a fresh session can resume without re-reading the whole
repo. Example: "Finished onboarding screens 1–2 of 3. Screen 3 pulled from
Moonchild but not yet wired into the nav stack. Next: wire screen 3, then move
to core-feature flow.")_

---

## Phases

### Phase 0 — Foundation & planning

- [ ] `docs/PRD.md` written and reviewed (sentinel removed)
- [ ] `docs/design-brief.md` written and reviewed (sentinel removed)
- [ ] Product clone / branch from this template
- [ ] Moonchild MCP connected for this project
- [ ] This file’s sentinel removed; Current status filled
- [ ] `docs/screens-status.md` sentinel removed when the screen list is real

### Phase 1 — Design system & screens in Moonchild

- [ ] Design system generated in Moonchild from PRD + design-brief
- [ ] All MVP flows generated in Moonchild
- [ ] Design reviewed and approved
- [ ] `docs/screens-status.md` filled from those flows (`Designed` column)

### Phase 2 — Repo scaffolding

Template already ships `ui/` primitives and NativeWind tokens. This phase is
product-specific wiring, not inventing a component library.

- [ ] Product navigation shell (routes for MVP screens)
- [ ] Moonchild tokens synced into `apps/mobile/global.css` / `ui/`
- [ ] Identity set in `apps/mobile/app.json` (not still `com.example.*`)

### Phase 3 — Screen-by-screen UI build

UI only — layout/nav against Moonchild designs. No data wiring yet.

For each row in `docs/screens-status.md` with **Designed in Moonchild** = `yes`:
pull via MCP, adapt into Expo Router / NativeWind / `ui/`, then note progress
under **Where we left off**. Do not freehand layouts.

- [ ] All Designed screens pulled and built
- [ ] Navigation between built screens works

### Phase 4 — On-device data & logic

No accounts or backend unless explicitly discussed (see `AGENTS.md`).

- [ ] Data model via `lib/storage.ts` (kv or sql per `app-config`)
- [ ] Screens wired to on-device data
- [ ] Purchases / entitlements via `lib/purchases.ts` if `MONETIZATION` ≠ `free` (mock first)
- [ ] Other seams (haptics, local notifications) only if the PRD needs them

### Phase 5 — QA & edge cases

- [ ] Empty states
- [ ] Error states
- [ ] Permission flows (only if a native capability was added)
- [ ] `npm test` and `npm run test:e2e` as applicable

### Phase 6 — Polish

- [ ] Accessibility pass
- [ ] Loading states
- [ ] Animations / transitions (Reanimated)
- [ ] Dark mode (if in the design brief)
- [ ] `npm run check` / `npm run verify` clean

### Phase 7 — Store prep & submission

Point at existing tooling — don’t restate full recipes.

- [ ] `npm run screenshots` / brand assets as needed
- [ ] Store listing copy under `apps/mobile/store/metadata/`
- [ ] Privacy / terms + lander (`docs/recipes/privacy-policy-url.md`, `sync:legal`)
- [ ] `npm run gen-compliance`
- [ ] `npm run preflight` (and `doctor --tier=launch` as needed)
- [ ] TestFlight / Play internal via `store:push` (**ask before** EAS)
- [ ] Submitted

See `docs/recipes/app-store.md`, `play-store.md`, `store-compliance.md`.

### Phase 8 — Post-launch

- [ ] Next feature / iteration scoped (update PRD; loop toward Phase 0 / 1)
