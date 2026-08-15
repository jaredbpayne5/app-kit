<!-- TEMPLATE_PLACEHOLDER -->

# Build specification

How this product gets built: architecture decisions, data model, and a task
breakdown with verifiable acceptance criteria.

Compiled **once** by a strong model from `docs/PRD.md` + `docs/design-spec.md` +
this repo, acting as a technical build planner — not a product owner and not a
visual designer. It must not add product requirements (that is the PRD) or
redesign the experience (that is the design spec).

Phase numbering matches `docs/build-status.md` (0–8). Do not introduce a
different scheme, and do not confuse these with `npm run preflight --gate=N`
store gates — see the *Phase vs gate* table in `docs/build-status.md`.

Until the sentinel above is removed, there is no build plan; agents must not
invent one.

---

## 1. Build principles

- Implement the PRD.
- Implement the approved design specification.
- Prefer existing repo patterns over new ones.
- Work in dependency order.
- Every task has acceptance criteria someone else could check.

---

## 2. Architecture

Most of this is already decided by the template. Record **choices within it**,
not a re-derivation — and never a choice that contradicts `AGENTS.md`.

### Fixed by the template

| Area | Decision | Where |
| --- | --- | --- |
| Stack | Expo SDK 56 · Expo Router · NativeWind v4 · React Native Reusables · Reanimated · TypeScript strict | `AGENTS.md` → Stack |
| Backend | None. On-device only. | `AGENTS.md` → What this is |
| Persistence | `lib/storage.ts` (never `expo-sqlite` directly) | `AGENTS.md` → Seams |
| Purchases | `lib/purchases.ts` → RevenueCat | `AGENTS.md` → Seams |
| Errors / haptics / reminders | `lib/report-error.ts`, `lib/haptics.ts`, `lib/local-notifications.ts` | `AGENTS.md` → Seams |
| Design tokens | `apps/mobile/global.css` + `npm run gen-theme` | `AGENTS.md` → Design system |
| Lists | `@shopify/flash-list` | `AGENTS.md` → Stack |

### Decided per product

- **`STORAGE`** (`kv` / `sql`) and why:
- **`MONETIZATION`** (`free` / `subscription` / `one-time`) and why:
- **`PURCHASES_MODE`** — stays `mock` until:
- **Navigation shape** (tabs / stack / modals, routes under `apps/mobile/app/`):
- **State management** beyond component state, if any:
- **Native capability added**, if any (each costs a permission prompt and an App
  Review question — see `docs/CAPABILITIES.md`):
- **Testing approach** (unit via `npm test`, e2e flows via `npm run test:e2e`):

---

## 3. Data model

Accessed through `lib/storage.ts`.

### Entity / table

**Purpose:**

**Fields:**

**Relationships:**

**Indexes / constraints:**

**Migration notes:**

---

## 4. Design implementation

How the approved design system maps onto this repo. Values come from the design
tool, not from here.

- **Color roles → `apps/mobile/global.css`** (then `npm run gen-theme`):
- **Type scale → `ui/text.tsx` variants:**
- **Components → existing `ui/` primitives vs new ones:**
- **Navigation chrome** (tab bar, headers — reads `lib/theme-tokens.ts`):
- **Assets** (icons, brand, splash):
- **Motion** (Reanimated; never the legacy `Animated` API):

---

## 5. Build phases

Task shape below. Repeat per task; keep tasks small enough to finish and verify
in one sitting.

#### Task N.M — [Name]

**Objective:**

**Files / areas:**

**Implementation:**

**Acceptance criteria:**

- [ ]

**Verification:**

- [ ]

**Dependencies:**

---

### Phase 0 — Foundation & planning

Specs written, design tool linked, identity set. Mostly done by reaching this
file; record anything product-specific left over.

### Phase 1 — Design system & screens in design tool

Owned by the design tool, not by code. Record what must exist before Phase 3 can
start.

### Phase 2 — Repo scaffolding

Navigation shell, token sync, `npm run init-app` identity.

#### Task 2.1 — [Name]

### Phase 3 — Screen-by-screen UI build

UI only, no data wiring. One task per screen, in the order a user meets them.
Each task must name the screen's row in `docs/screens-status.md`.

#### Task 3.1 — [Name]

### Phase 4 — On-device data & logic

Data model, screens wired to real data, purchases/entitlements if
`MONETIZATION` ≠ `free` (mock first).

#### Task 4.1 — [Name]

### Phase 5 — QA & edge cases

Empty, error, offline, and permission states. `npm test` / `npm run test:e2e`.

#### Task 5.1 — [Name]

### Phase 6 — Polish

Accessibility, loading states, motion, dark mode, final audit.

#### Task 6.1 — [Name]

### Phase 7 — Store prep & submission

Screenshots, metadata, legal/lander, compliance, preflight. See
`docs/recipes/app-store.md` and `play-store.md` — do not restate the recipes
here.

#### Task 7.1 — [Name]

### Phase 8 — Post-launch

Next iteration scoped back into the PRD.

---

## 6. Global acceptance criteria

Checked at the Phase 6 final audit, not per task.

- [ ] Every PRD requirement is implemented, or listed as a knowing deviation.
- [ ] Design spec implemented with no unexplained drift.
- [ ] Loading, empty, error, and offline states handled on every screen.
- [ ] Accessibility verified: Dynamic Type, VoiceOver/TalkBack, contrast, touch
      targets, Reduce Motion.
- [ ] Light and dark mode both checked on a real render.
- [ ] No hardcoded colors or type sizes — tokens only.
- [ ] All work goes through the `lib/` seams.
- [ ] `npm run verify` clean.
- [ ] No known blocking defects.
