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
- **`jq`** — `brew install jq`. All three `.claude/hooks` scripts fail closed
  without it, which makes Claude Code non-functional in this repo.

## Starting a new app

1. Copy this repo to a new folder and `npm install`.
2. Set identity with one command (keeps the four surfaces in sync — see
   `docs/recipes/product-pipeline.md`). Copy `.env.example` to `.env.local`
   first if you have not already:

   ```bash
   npm run init-app -- --name "My App" --slug my-app --package com.yourname.myapp
   ```

   That rewrites `apps/mobile/app.json`, `apps/product.json`,
   `apps/web/lander.json`, and `apps/mobile/.env.local` / `.env.example`
   together (plus StoreKit product ID prefixes). Use `--dry-run` to preview.
   Bundle identifiers are permanent once you upload to a store.

3. `npm run doctor` to check your toolchain.
4. Follow the product pipeline before writing UI:
   `docs/recipes/product-pipeline.md` (PRD → design tool → export into
   `docs/design-exports/` → Opus compile via `docs/recipes/compile-specs.md`
   → code). Track progress in `docs/build-status.md`.
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
- **Testing purchases** — `apps/mobile/store/storekit/Products.storekit` is an
  Xcode StoreKit configuration file. Combined with `PURCHASES_MODE: 'mock'` in
  `lib/app-config.ts`, you can build and test the whole paywall, including
  restore and renewal, without paying Apple anything.
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
npm run test:e2e   # Maestro flows against a simulator (free, local only)
```

Maestro drives the real app like a user. It is not in CI because GitHub's Linux
runners can't boot an iOS Simulator.

**CI known limitation:** GitHub Actions runs format, lint, typecheck, unit
tests, contrast/design lint, and a JS bundle export (`smoke:export`). It
never compiles the native iOS or Android project. Before trusting a merge that
adds a config plugin or native dependency, run
`npm run dev:build:ios` and/or `npm run dev:build:android` locally.
