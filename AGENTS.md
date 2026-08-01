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

Do **not** invent ad-hoc kill commands. Use the existing session script:

```bash
npm run session:down              # Metro, iOS sim, Android emu, Gradle, adb
npm run session:down -- --watch   # same + re-kill for ~20s if agents relaunch
npm run session:status            # what's still running
```

`session:down` stops Expo/Metro (ports 8081–8083), iOS Simulator, the
`pixel8` Android emulator, Gradle/Kotlin daemons, `adb`, and shell processes
whose command lines match known relaunchers (`nohup emulator -avd pixel8`,
`npm run dev -w mobile -- --port 8081`, etc.). It does **not** `killall node`
or kill unrelated Java.

## Verify

Run `npm run check` after edits (format, lint, typecheck, contrast, design
lint). Run `npm test` for logic changes. Run `npm run verify` before
considering work done. `npm run test:e2e` drives Maestro against a simulator.

## Delegate to a cheaper model

Most work in this repo is mechanical. Hand it to a cheaper subagent (Composer
2.5 or equivalent) by default rather than burning a frontier model on it:
running builds and test suites, applying a fix that has already been decided,
mechanical edits, searching for where something lives, reading logs, git and
dependency chores.

Keep the stronger model for diagnosing bugs whose cause is unknown, design
trade-offs, purchase and entitlement logic, and reading library internals.
Cheap models pattern-match to the common fix and start changing unrelated
things when it fails — ten guesses cost more than one correct diagnosis, and
leave workarounds baked into every app cloned from this template.

If you can phrase the task as "run X, then change Y to Z", delegate it. If it
starts with "figure out why", don't.
