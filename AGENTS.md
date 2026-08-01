# AGENTS.md

Instructions for AI coding agents working in this repo. This is the single
source of truth. `CLAUDE.md` is a one-line shim that imports this file, and
Cursor reads this file natively — do not duplicate rules into `.cursor/rules/`.

## What this is

A local-first Expo template that ships the same product to the App Store,
Google Play, and a marketing lander. Cloned per app.

- `apps/mobile` — Expo Router app (the product)
- `apps/web` — static marketing lander + hosted privacy/terms
- `apps/product.json` — shared identity (name, URLs, contact email)
- `scripts/` — dev, store, and lander automation

**No backend.** Data lives on-device via `expo-sqlite`. Purchases go through
RevenueCat. If a feature needs accounts or server-side sync, stop and discuss
it rather than adding a backend.

## Product & design reference

Build order for a product clone: fill `docs/PRD.md`, then
`docs/design-brief.md`, generate the design system and flows in Moonchild,
update `docs/screens-status.md`, then implement in this repo. Track session
progress in `docs/build-status.md`.

- `docs/PRD.md` — authoritative for *what* to build. If a request goes beyond
  it, flag rather than expanding scope.
- `docs/design-brief.md` — starting direction for Moonchild’s design-system
  prompt. Not final tokens.
- `docs/screens-status.md` — Moonchild inventory for this product. Treat
  **Designed in Moonchild** as fact. Do not infer design readiness from
  memory or a vague MCP reply alone.
- `docs/build-status.md` — phase checklist and session handoff. Read it at
  the start of every session before doing anything else. Update Current
  status and Where we left off before ending a session, or whenever a phase
  (or meaningful chunk) is completed.

If any of these files still contains `<!-- TEMPLATE_PLACEHOLDER -->`, stop
and tell the user. Do not invent an MVP, design system, or screen list.

## Design system & Moonchild

Moonchild (via MCP) is the source of truth for the **structured** design
system (color roles, type scale, spacing) and for screen/flow layouts.
`docs/design-brief.md` only sets direction; Moonchild specializes it. Repo
token files (`apps/mobile/global.css`, `ui/`) are the downstream sync of
that system for NativeWind — see Stack below.

### Before writing any UI code

1. Confirm the target screen is listed in `docs/screens-status.md` with
   Designed in Moonchild = `yes`. If not, stop and tell the user — do not
   implement it.
2. Attempt to pull that screen from Moonchild via MCP.
3. If the pull fails, errors, or returns nothing: stop and tell the user.
   Do not generate a layout yourself under any circumstance.
4. If Moonchild MCP tools are not available in this session: stop and tell
   the user. Do not generate a layout yourself under any circumstance.

### When implementing a pulled screen

- Sync tokens from Moonchild into `apps/mobile/global.css` and `ui/` as
  needed. Components must use those tokens — never invent colors, spacing,
  or type, and never leave Moonchild values only inlined on one screen.
- Adapt into this repo’s patterns (Expo Router, NativeWind, `ui/`
  primitives, `lib/` seams). Do not paste Moonchild-generated code
  verbatim.
- Moonchild is UI/UX only. Data modeling and on-device logic go through
  `lib/storage.ts` and the other seams as you implement each screen
  (Phase 4 in `docs/build-status.md`).
- Update `docs/build-status.md` (Where we left off / phase checkboxes).
  Update `docs/screens-status.md` only when the Moonchild inventory itself
  changes.

Moonchild MCP calls here are read/pull-only (fetch designs and tokens, not
modify anything external). Prefer leaving those tools on auto-allow rather
than confirming every pull during screen-by-screen builds.

Non-UI work (storage, purchases, copy) and edits to already-built screens
that only use already-synced tokens are allowed without a new Moonchild
pull — still no new freehand layouts or new screens.

## Stack

Expo SDK 56 · Expo Router · NativeWind v4 · React Native Reusables ·
Reanimated · RevenueCat · TypeScript strict.

- Styling is NativeWind classes. No `StyleSheet.create`.
- Colors come from CSS variables in `apps/mobile/global.css`. Never hardcode
  a hex value in a component.
- Type sizes come from `ui/text.tsx` variants. Never write `text-[15px]`.
- Prefer an existing `ui/` primitive over hand-rolling. Add new ones with
  `npx @react-native-reusables/cli@latest add <component>`.
- Animation is Reanimated. Do not use the legacy `Animated` API.
- Lists use `@shopify/flash-list`, not `FlatList`.
- Never call `cssInterop` on a component a library also renders (for example
  Reanimated's `Animated.View`). It mutates that component globally. Register
  a private copy instead — see `ui/motion.tsx`.

## Seams — use these, don't go around them

| Need | Use | Not |
| --- | --- | --- |
| Persistence | `lib/storage.ts` | `expo-sqlite` directly |
| Purchases / entitlements | `lib/purchases.ts` | `react-native-purchases` directly |
| Error reporting | `lib/report-error.ts` | `console.error`, Sentry directly |
| Haptics | `lib/haptics.ts` | `expo-haptics` directly |
| Local reminders | `lib/local-notifications.ts` | `expo-notifications` directly |

## Capability flags

`apps/mobile/lib/app-config.ts` holds the product's shape:

- `STORAGE`: `kv` (default) or `sql`
- `MONETIZATION`: `free` (default), `subscription`, or `one-time`
- `PURCHASES_MODE`: `mock` (default) or `live`
- `MOCK_ENTITLED`: drives locked/unlocked UI without any store account

`mock` mode means you can build and test the entire paywall before paying
Apple or Google anything. Keep it that way until the app is nearly done.

## Adding native capability

This template ships a deliberately small set of native modules. Camera,
location, microphone, motion, biometrics, and photo library are **not**
installed, because each one adds a permission prompt and an App Review
question. Add one only when the product actually needs it:

```
npx expo install expo-camera
```

Then add its config plugin to `app.json` and update
`apps/mobile/store/data-practices.json` if the data leaves the device.

See `docs/CAPABILITIES.md` for what each module costs in permissions.

## Security

- No secrets in source, commits, or `EXPO_PUBLIC_*` variables. Those are
  compiled into the app bundle and readable by anyone who downloads it.
- Never log tokens, keys, or purchase receipts.
- Keystores and Play service-account JSON stay out of the repo.
- On-device data stays on-device unless the product explicitly adds a
  network feature.

## Ask before

- `eas build`, `eas submit`, `eas update`, `npx expo prebuild` — these cost
  money or are irreversible
- `web:deploy`, `store:push`, `domain-attach`
- Adding a dependency, a config plugin, or any backend service
- Committing or editing `apps/mobile/android/` or `apps/mobile/ios/` — those
  are generated, never hand-maintained
- Changing `android.package` or `ios.bundleIdentifier` after a store upload
- `git push`
- Shutting down the local stack (`npm run session:down`) — Metro, sims, and
  emulators may be in use by another agent

## Session teardown

Do **not** invent ad-hoc kill commands. Use the existing session script
(details: `scripts/dev/session.sh`):

```bash
npm run session:down              # Metro, iOS sim, Android emu, Gradle, adb
npm run session:down -- --watch   # same + re-kill for ~20s if agents relaunch
npm run session:status            # what's still running
```

## Verify

Run `npm run check` after edits (format, lint, typecheck, contrast, design
lint). Run `npm test` for logic changes. Run `npm run verify` before
considering work done. `npm run test:e2e` drives Maestro against a simulator.

## Delegate to a cheaper model

Default: hand mechanical work to a cheaper subagent (Composer 2.5 or
equivalent) — builds, tests, decided fixes, renames, searches, logs, git,
deps. Keep the stronger model for unknown-cause bugs, design trade-offs,
purchase/entitlement logic, and library internals.

If you can phrase it as "run X, then change Y to Z", delegate. If it
starts with "figure out why", don't.
