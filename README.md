# Expo App Template

A local-first Expo starter that ships one codebase to the App Store, Google
Play, and a marketing lander. No backend, no accounts, no server bill.

- `apps/mobile` — the app (Expo Router, NativeWind, React Native Reusables)
- `apps/web` — static marketing lander + hosted privacy/terms
- `apps/product.json` — shared identity used by the app and the lander
- `scripts/` — dev, store, and lander automation
- `AGENTS.md` — shared instructions for AI coding agents (Cursor reads it
  natively; `CLAUDE.md` imports it and adds Claude-specific operating
  instructions, and `.cursor/rules/` holds the Cursor-specific ones)

## Requirements

- **Node ≥ 24** — matches `.nvmrc` and `package.json` `engines` (`>=24.0.0`).
- **`jq`** — `brew install jq`. Claude and Cursor guard hooks fail closed
  without it.

## Starting a new app

v1 is one complete app: one PRD, one design, one critic, one plan, then
jobs. Matt is the doorbell. Paste one line into the right app.

1. Copy this repo to a new folder and `npm install`.
2. Set identity with one command (keeps the four surfaces in sync). Copy
   `.env.example` to `.env.local` first if you have not already:

   ```bash
   npm run init-app -- --name "My App" --slug my-app --package com.yourname.myapp
   ```

   That rewrites `apps/mobile/app.json`, `apps/product.json`,
   `apps/web/lander.json`, and `apps/mobile/.env.local` / `.env.example`
   together (plus StoreKit product ID prefixes). Use `--dry-run` to preview.
   Bundle identifiers are permanent once you upload to a store.

3. `npm run doctor` to check your toolchain.
4. Build the product (one PRD, one design, one critic, one plan, then jobs):
   1. Claude: `/product` — fills `docs/PRD.md`
   2. Matt: drop screen pictures in `docs/design-exports/`
   3. Claude, new chat: `/design` — writes `docs/design.md`
   4. Cursor, new chat: `/critic` — writes `docs/critic.md`
   5. On FAIL: new Claude chat fixes the design; Cursor critic again
   6. After PASS and Matt agrees: Claude, new chat: `/plan` — writes `docs/plan.md`
   7. Cursor: `/code next job` (`code → test → improve → test`)
   8. Claude, new chat: `/review job N` — checks the box on PASS
   9. Repeat 7–8 until the plan is done, then `npm run verify` and `npm run preflight`
5. `npm run dev` and press `i` for the iOS Simulator or `a` for Android.
   Prefer a development build (`npm run dev:build:ios` /
   `dev:build:android`) once you add native modules.

## Daily loop

```bash
npm run session:up     # boot iOS Simulator (optional start of day)
npm run dev            # Metro (+ press i / a for a device)
npm run check          # format, lint, typecheck, contrast, design lint
npm test               # unit tests
npm run verify         # check + test + a real bundle export
npm run session:down   # stop Metro, iOS sim, Android emu, Gradle, adb
npm run session:status # what's still running
```

When Cursor agents (or `nohup`) keep relaunching Metro or the emulator after
you stop them, hold the teardown open for a re-kill window:

```bash
npm run session:down -- --watch      # ~20s
npm run session:down -- --watch=30   # custom seconds
```

The development build (`npm run dev:build:ios` / `dev:build:android`) is the
primary target because native modules are compiled in. Expo Go works for quick
checks when you haven't added native code.

## What it costs

Everything below is free and needs no accounts:

- iOS Simulator (Xcode) and Android Emulator (Homebrew command-line tools; see
  [Android toolchain](#android-toolchain-macos) — Studio is optional)
- Running on your own iPhone via free personal-team provisioning (7-day certs)
- Running on any Android device over USB
- **Testing purchases** — with `PURCHASES_MODE: 'mock'` you can exercise lock →
  buy → unlock and restore without a store account. Accelerated renewal still
  needs `apps/mobile/store/storekit/Products.storekit` in a native Xcode run,
  not mock JS.
- Screenshots, compliance docs, and the lander build

You only need to pay when you publish: Google Play is $25 once, Apple is $99
per year. Shipping to Android first is the cheaper way to learn the pipeline.

## Android toolchain (macOS)

Android Studio is **not** required. The Homebrew `android-commandlinetools` cask
plus a few `sdkmanager` packages is enough (~6 GB vs ~15 GB for Studio).

**Temurin 17** is required — Android's Gradle toolchain rejects newer JDKs.

```bash
brew install --cask temurin@17 android-commandlinetools

# Accept licenses, then install the packages this template uses:
yes | sdkmanager --licenses
sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-36" \
  "build-tools;36.0.0" \
  "ndk;27.1.12297006" \
  "cmake;3.22.1" \
  "system-images;android-36;google_apis;arm64-v8a"
```

The Homebrew cask puts the SDK at `/opt/homebrew/share/android-commandlinetools`
(not `~/Library/Android/sdk`), so set `ANDROID_HOME` explicitly. Add to
`~/.zshrc`:

```bash
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
```

Create an AVD **without** `avdmanager`'s `-d` flag — the command-line-tools
install ships no `devices.xml`, and `-d` fails with
`Could not load devices from .../devices.xml`:

```bash
echo no | avdmanager create avd -n pixel8 \
  -k "system-images;android-36;google_apis;arm64-v8a"
```

Then: `emulator -avd pixel8` and `npm run dev:build:android`.

## Configuring the app

`apps/mobile/lib/app-config.ts` is the spine:

| Flag             | Values                               | Meaning                                    |
| ---------------- | ------------------------------------ | ------------------------------------------ |
| `STORAGE`        | `kv` · `sql`                         | Key-value or full SQLite                   |
| `MONETIZATION`   | `free` · `subscription` · `one-time` | `free` never loads the RevenueCat SDK      |
| `PURCHASES_MODE` | `mock` · `live`                      | `mock` needs no store account              |
| `MOCK_ENTITLED`  | boolean                              | Toggle locked/unlocked UI while developing |

## Adding native capability

The template ships a small set of native modules on purpose. Camera, location,
microphone, motion, biometrics, and photo library are **not** installed —
each adds a permission prompt and an App Review question. Add what you need:

```bash
npx expo install expo-camera
```

Then register its config plugin in `app.json` and rebuild the development
build. `docs/CAPABILITIES.md` lists what each module costs in permissions.

## Shipping

```bash
npm run screenshots      # capture + frame store screenshots on a simulator
npm run gen-compliance   # Apple privacy labels + Play data safety answers
npm run web:build        # build the lander
npm run preflight        # ~15 pre-submission checks
```

`npm run preflight` is the one to trust before you submit — it checks for
placeholder identity, metadata character limits, a reachable privacy URL,
icon/splash still being template defaults, and more.

Store submission (`npm run store:push`) and lander deploy (`npm run web:deploy`)
need paid accounts and are deliberately gated behind a confirmation prompt.

Credentials live **outside** the repo, in `~/.app-factory/`, so every app you
build from this template shares one copy and nothing sensitive can be committed:

```
~/.app-factory/env                        # CLOUDFLARE_API_TOKEN, etc.
~/.app-factory/asc/*.p8                   # App Store Connect API key
~/.app-factory/play/service-account.json  # Play publishing
```

## Testing

```bash
npm test           # Jest unit tests
npm run test:e2e   # Maestro against a locally built app (see below)
```

Default `npm run test:e2e` needs a locally built native app (`npx expo run:ios`
or a dev build already installed on the simulator). That is still free and
needs no paid Apple account. Expo Go is the exception:
`npm run test:e2e -- --mode=expo-go --flow=onboarding`.

Maestro drives the real app like a user. It is not in CI because GitHub's Linux
runners can't boot an iOS Simulator.

**CI known limitation:** GitHub Actions runs format, lint, typecheck, unit
tests, contrast/design lint, a JS bundle export (`smoke:export`), Expo SDK
drift (`expo install --check` is the gate; `expo-doctor` is a report on
SDK 56), and `npm audit` as a report (not a gate). It never compiles the
native iOS or Android project.
Before trusting a merge that adds a config plugin or native dependency, run
`npm run dev:build:ios` and/or `npm run dev:build:android` locally.

Pre-commit runs **lint-staged** on touched files (plus a secret scan), not
the full `check`+`test` suite — that stays in CI and `npm run verify`.
`npm run knip:clone` finds unused code after `docs/PRD.md` is filled; do not
run it on the blank template. Expo / React / React Native updates go through
`npx expo install --fix`, not Renovate.
