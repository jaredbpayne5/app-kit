# Maestro e2e (local only)

`npm run test:e2e` runs a **temporary** copy of `apps/mobile/maestro/smoke.yaml` when
the Maestro CLI is installed. The committed YAML is never rewritten (keeps
git clean). CI does **not** run Maestro (no emulator requirement).

Temp flows and Maestro failure dumps go under **`.maestro-debug/`** (gitignored).
Scripts also scrub accidental `commands-(maestro-…)` / `screenshot-❌-…` / `xctest_runner_*.log`
leaks from the repo root after each run — they should never land in your home folder
when you use `npm run test:e2e` / `npm run screenshots` (those scripts `cd` to the repo first).

## Modes × platforms

| Mode | Platform | `appId` | When |
|------|----------|---------|------|
| `native` (**preferred**) | `ios` (default) | `expo.ios.bundleIdentifier` from `apps/mobile/app.json` | Dev client / UI-floor modules / capabilities |
| `native` | `android` | `expo.android.package` from `apps/mobile/app.json` | Dev client / installed Android build |
| `expo-go` | `ios` | `host.exp.Exponent` (capital **E**) | Simulator-only convenience when **no** native UI-floor modules are required |
| `expo-go` | `android` | `host.exp.exponent` | Same for Android Expo Go |

```bash
npm run test:e2e -- --mode=native                 # preferred for this template
npm run test:e2e                                    # check scripts/dev/test-e2e.sh default; pass --mode=native when unsure
npm run test:e2e -- --platform=android --mode=native
npm run test:e2e -- --port 8082   # match Metro port
```

## Quirks (from first product builds)

- Prefer **`testID`s** over ActionSheet option text.
- Avoid `clearState` when it re-triggers Expo Dev Client “DEVELOPMENT SERVERS” sheets.
- Substitute Metro port via the e2e wrapper (`--port` / `EXPO_PORT`).
- After adding native modules, **rebuild** before e2e (`expo run:ios`).
- Privacy/Terms smoke: assert in-app `link-privacy` / `link-terms` only. Live Safari
  page titles need a deployed lander, so an undeployed URL is not a failure.
- Maestro may report **stale** simulator crash `.ips` files; correlate timestamps
  with the current run before blaming a fresh failure.
- Nested stacks often lack a back chevron from `/` — use iOS edge swipe or tap the
  previous title in the header.

## Prerequisites (iOS — Mac only, day-to-day default)

1. macOS with Xcode / Simulator (`xcrun simctl`). XcodeBuildMCP OK in Cursor.
2. `npm run doctor -- --tier=device` (defaults to `--platform=ios`)
3. Java **17+** and Maestro CLI: https://maestro.mobile.dev  
   Optional: `export MAESTRO_CLI_NO_ANALYTICS=true`
4. A **booted** iOS Simulator
5. For **native** mode: development build installed (`npm run dev:build:ios`), Metro
   with `--dev-client`, open via `npm run open:ios`
6. For **expo-go** mode (optional):
   - Expo Go installed on the simulator
   - Metro running (`npx expo start --port 8081`)
   - Project open: `npm run open:ios -- --go`

## Prerequisites (Android — parity / Play)

1. `npm run doctor -- --tier=device --platform=android`
2. Java **17+** (`java -version`)
3. Maestro CLI (same as iOS)
4. Android emulator or device (`adb devices`)
5. For **native** mode: app installed under `android.package`
6. For **expo-go** mode:
   - Expo Go installed on the device
   - Metro running (`npx expo start --port 8081`)
   - Project open: `npm run open:android`

If Maestro, Xcode/`simctl`, or a booted simulator is missing, `test:e2e`
(iOS default) prints help and **exits 0** (same soft skip as a missing Maestro install).

## Port conflicts

If another Expo project already owns **8081**, start this one on another port:

```bash
npx expo start --dev-client --port 8082
npm run open:ios -- --port 8082
npm run test:e2e -- --port 8082 --mode=native
```

Agents must pass `--port` explicitly — interactive “use 8082?” prompts fail in non-interactive mode.
