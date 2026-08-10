<!-- TEMPLATE_PLACEHOLDER -->

# Design specification

The approved UX/UI for this product, written into the repo by the **design tool
of record** (see `docs/moonchild.md`) from `docs/PRD.md` + `docs/design-brief.md`.

Three rules about this file:

- **A coding agent does not author it.** It is the design tool's output. Agents
  read it; they do not invent or extend it. If it is missing something a task
  needs, stop and tell the user.
- **It does not replace fetching the artifact.** Prose is lossy next to a frame.
  A screen is implementable only once its actual artifact has been retrieved —
  MCP pull, or an export committed to the repo. See `AGENTS.md` → *Design system
  & design tool*.
- **It is not a second copy of the tokens.** Record color *roles*, type scale,
  and spacing steps. Final values live in `apps/mobile/global.css` (plus
  `npm run gen-theme` → `lib/theme-tokens.ts`).

Screens listed in §5 must match rows in `docs/screens-status.md`. Until the
sentinel above is removed, treat this product as having no approved design.

---

## 1. Design direction

### Product personality

<!-- What should the experience feel like? -->

### Design principles

1.
2.
3.

### Design goals

-

### Design anti-patterns

-

---

## 2. Information architecture

### Navigation model

### Primary destinations

### Screen inventory

Must agree with `docs/screens-status.md`.

| Screen | Purpose | Entry points | Exit / next actions |
| --- | --- | --- | --- |
| | | | |

---

## 3. Design system

Roles and scales, not final hex/px — those land in `apps/mobile/global.css`.

### Color

Color *roles* (background, foreground, primary, muted, destructive, border…)
and their light/dark intent.

### Typography

Type scale steps and their use. Implemented as `ui/text.tsx` variants.

### Spacing

### Sizing

### Radius

### Elevation

### Iconography

### Motion

Durations, easing, and what animates. Implemented with Reanimated.

---

## 4. Components

For each reusable component:

- Purpose
- Variants
- States
- Behavior
- Usage rules

Note where a component maps onto an existing `ui/` primitive rather than a new
one.

---

## 5. Screen specifications

For each screen:

### Screen name

**Purpose:**

**Primary user goal:**

**Information hierarchy:**

**Layout:**

**Components:**

**Interactions:**

**States:**

- Loading
- Empty
- Error
- Disabled
- Offline
- Success

**Accessibility:**

---

## 6. User flows

### Flow name

1.
2.
3.

---

## 7. Interaction rules

-

---

## 8. Accessibility

- Dynamic Type:
- VoiceOver / TalkBack:
- Contrast:
- Touch targets:
- Reduce Motion:

---

## 9. Platform conventions

### iOS

### Android

---

## 10. Assets

Required icons, illustrations, images, and fonts.

---

## 11. Implementation notes

Only what materially helps implementation. Do not prescribe code architecture
here — that belongs in `docs/build-spec.md`. Point at the repo's own seams where
relevant: `ui/` primitives, `lib/storage.ts`, `lib/purchases.ts`,
`lib/haptics.ts`.
