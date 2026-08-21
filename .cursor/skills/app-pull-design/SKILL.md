---
name: app-pull-design
description: >-
  Fetches the approved screen artifact before writing UI. Use when
  implementing a new screen, writing a screen layout, or pulling a
  named export from docs/design-exports/.
---

# Pull design

Cursor-only. How to fetch an approved screen and build from it.
Constraints stay in `AGENTS.md` (no new freehand layout; stop if the
pull fails).

## When this applies

A new screen layout, or a first build of a screen that has a named
export in `docs/design-exports/`. Skip for non-UI work (storage,
purchases, copy) and for edits to already-built screens that only use
already-synced tokens — still no new freehand layouts or new screens.

## Before writing any UI code

1. Confirm a named export for this screen exists in
   `docs/design-exports/` (any file besides `README.md` that is this
   screen). If it is missing, stop and tell the user — do not implement
   it.
2. Retrieve that artifact — read the committed export, or pull the same
   screen from the design tool via MCP.
3. If the pull fails, errors, returns nothing, or the design tool's MCP
   is not available in this session and no committed export exists: stop
   and tell the user. Do not generate a layout yourself under any
   circumstance.

The only implement gate is a **named export in `docs/design-exports/`**.
Do not look for `docs/screens-status.md` or `docs/design-spec.md`. Those
files are gone.

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
  `lib/storage.ts` and the other seams as you implement each screen.

Design-tool MCP calls here are read/pull-only (fetch designs and tokens, not
modify anything external). Prefer leaving those tools on auto-allow rather
than confirming every pull during screen-by-screen builds.

## Source

`AGENTS.md` — stop + design authority. `docs/design-exports/` — the named
export is the implement gate.
