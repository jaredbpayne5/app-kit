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
- **Current task:** _(task id + name from `docs/build-spec.md`, or None)_
- **Status:** _(Not started / In progress / Complete)_
- **Last updated:** _(date)_

## Where we left off

_(Specific enough that a fresh session can resume without re-reading the whole
repo. Example: "Finished onboarding screens 1–2 of 3. Screen 3 artifact
retrieved but not yet wired into the nav stack. Next: wire screen 3, then move
to core-feature flow.")_

## Blockers

_(None, or: the specific blocker and the decision/information needed.)_

## Deviations

_(None, or: where the implementation knowingly departs from `docs/PRD.md`,
`docs/design-spec.md`, or `docs/build-spec.md`, and why. A deviation recorded
here is a decision; an unrecorded one is a bug.)_

## Verification (last run)

- `npm run check`: _(NOT RUN / pass / fail)_
- `npm test`: _(NOT RUN / pass / fail)_
- `npm run verify`: _(NOT RUN / pass / fail)_
- `npm run test:e2e`: _(NOT RUN / pass / fail)_
- Visual check on a device or simulator: _(NOT RUN / done — light + dark)_

---

## Phases

### Phase 0 — Foundation & planning

- [ ] `docs/PRD.md` written and reviewed (sentinel removed)
- [ ] Product clone / branch from this template
- [ ] Design artifacts exported into the clone and/or design-tool MCP available
- [ ] `docs/moonchild.md` filled (tool + project ids and/or export paths;
      sentinel removed)
- [ ] This file’s sentinel removed; Current status filled
- [ ] `docs/screens-status.md` filled from exports (`Designed` column; sentinel
      removed)
- [ ] `docs/design-spec.md` compiled from PRD + artifacts (sentinel removed)
- [ ] `docs/build-spec.md` compiled from PRD + design spec + repo (sentinel
      removed) — before Phase 2

### Phase 1 — Design system & screens (design tool)

Done mostly **before** coding. Artifacts come from the design tool; prose specs
are compiled in Phase 0. Phase 2 onward works from the build-spec task list.

- [ ] Design system generated in the design tool from the PRD
- [ ] All MVP flows generated in the design tool
- [ ] Design reviewed and approved; artifacts exported (or MCP-linked)
- [ ] `docs/screens-status.md` matches those flows
- [ ] `docs/moonchild.md` points at the live project and/or export paths

### Phase 2 — Repo scaffolding

Template already ships `ui/` primitives and NativeWind tokens. This phase is
product-specific wiring, not inventing a component library.

- [ ] Product navigation shell (routes for MVP screens)
- [ ] Design tokens synced into `apps/mobile/global.css` / `ui/`
- [ ] Identity set via `npm run init-app` (not still `com.example.*`)

### Phase 3 — Screen-by-screen UI build

UI only — layout/nav against approved design artifacts. No data wiring yet.

For each row in `docs/screens-status.md` with **Designed** = `yes`: retrieve
the artifact (MCP or committed export), adapt into Expo Router / NativeWind /
`ui/`, then note progress under **Where we left off**. Do not freehand layouts.

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
- [ ] Dark mode (if in the design spec)
- [ ] Final audit — implementation walked against `docs/PRD.md`,
      `docs/design-spec.md`, and the Global acceptance criteria in
      `docs/build-spec.md`; gaps fixed or recorded under Deviations
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

---

## Phase vocabulary (build-status vs preflight)

`docs/build-status.md` phases (0–8) are the **product build** checklist.
`npm run preflight` uses a different numbering for **store gates**:

| Store command | Meaning | Roughly maps to build-status |
| --- | --- | --- |
| `npm run preflight -- --phase=4` | Harden / store-readiness (some checks deferred) | Late Phase 6 → early Phase 7 |
| `npm run preflight` (default) | Full launch gate (phase 6) | Phase 7 before submit |
| `npm run store:push` | Runs full preflight (phase 6), then submit | Phase 7 |

Do not confuse “Phase 4 — On-device data” in this file with
`preflight --phase=4`.
