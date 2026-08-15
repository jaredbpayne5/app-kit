---
name: pull-design
description: >-
  Fetches the approved screen artifact before writing UI. Use when
  implementing a new screen, writing a screen layout, pulling a design
  from Moonchild or docs/design-exports, or when screens-status,
  design-spec, or a freehand layout is in play.
---

# Pull design

Cursor-only. How to fetch an approved screen and build from it.
Constraints stay in `AGENTS.md` (no new freehand layout; stop if the
pull fails).

## When this applies

A new screen layout, or a first build of a screen listed in
`docs/screens-status.md`. Skip for non-UI work (storage, purchases,
copy) and for edits to already-built screens that only use already-synced
tokens — still no new freehand layouts or new screens.

## Before writing any UI code

1. Confirm the target screen is listed in `docs/screens-status.md` with
   Designed = `yes`. If not, stop and tell the user — do not implement it.
2. Confirm `docs/design-spec.md` actually specifies that screen. If it is
   missing or too thin to implement from, stop and tell the user.
3. Retrieve the screen's artifact — pull it from the design tool via MCP, or
   read an export committed to the repo.
4. If the pull fails, errors, returns nothing, or the design tool's MCP is not
   available in this session and no committed export exists: stop and tell the
   user. Do not generate a layout yourself under any circumstance.

## When implementing a pulled screen

- Sync tokens from the design system into `apps/mobile/global.css` and `ui/`
  as needed. Components must use those tokens — never invent colors, spacing,
  or type, and never leave design values only inlined on one screen.
  After changing color tokens, run `npm run gen-theme` — `lib/theme-tokens.ts`
  is generated from `global.css` and feeds the tab bar, navigation chrome,
  bottom sheets, and charts. `npm run check` fails if it is stale.
- Adapt into this repo's patterns (Expo Router, NativeWind, `ui/`
  primitives, `lib/` seams). Do not paste design-tool-generated code
  verbatim.
- The design tool is UI/UX only. Data modeling and on-device logic go through
  `lib/storage.ts` and the other seams as you implement each screen
  (Phase 4 in `docs/build-status.md`).
- Update `docs/build-status.md` (Where we left off / phase checkboxes).
  Update `docs/screens-status.md` only when the design inventory itself
  changes.

Design-tool MCP calls here are read/pull-only (fetch designs and tokens, not
modify anything external). Prefer leaving those tools on auto-allow rather
than confirming every pull during screen-by-screen builds.

## Source

`AGENTS.md` — stop + design authority. `docs/moonchild.md` — tool of
record / export path. `docs/screens-status.md` — Designed = `yes` is the
implement gate.
