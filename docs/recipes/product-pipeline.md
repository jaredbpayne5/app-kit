# Product pipeline (PRD → Moonchild → code)

How a clone of this template becomes a real app. Agents follow the same order
via `AGENTS.md`. Fill the `docs/` placeholders before spending Moonchild
credits or writing product UI.

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
3. **Moonchild** — Connect the Moonchild MCP in Cursor and/or Claude Code.
   Create the design system from the brief + PRD, then generate full journeys
   (not isolated screens). Record DS and scene ids in `docs/moonchild.md`.
4. **Screens inventory** — Fill `docs/screens-status.md` from Moonchild
   (`Designed in Moonchild` = yes/no). Agents must not implement a screen
   until that column is `yes`.
5. **Session handoff** — Keep `docs/build-status.md` current (phase, where
   we left off). Read it at the start of every coding session.
6. **Implement** — For each designed screen: pull via Moonchild MCP → sync
   tokens into `apps/mobile/global.css` / `ui/` → adapt into Expo Router /
   NativeWind / seams. No freehand layouts.
7. **Data & ship** — Phase 4+ in `docs/build-status.md` (on-device logic,
   QA, polish, `npm run preflight`).

## Moonchild MCP gates

Shell scripts cannot see whether MCP is attached. Two checks:

1. **`docs/moonchild.md`** — project pointer filled (doctor warns while still
   a template placeholder).
2. **In-session** — if Moonchild MCP tools are missing, a pull fails, or
   returns nothing: **stop and tell the user**. Do not generate a layout.

Prefer leaving Moonchild tools on auto-allow when they are read/pull-only.

## Related

- Phase checklist: `docs/build-status.md`
- Brand palette catalog: `docs/recipes/brand-palette.md`
- Brand assets: `docs/recipes/brand-assets.md`
- Store compliance: `docs/recipes/store-compliance.md`
- Capability costs: `docs/CAPABILITIES.md`
