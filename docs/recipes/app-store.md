# Apple App Store

Use this recipe when shipping to the App Store (iOS or both platforms).
Android/Play remains first-class too — see `docs/recipes/play-store.md`.

## Cost model (read first)

| Path | Needs Apple Developer Program ($99/yr)? |
|------|-----------------------------------------|
| iOS Simulator + Expo Go (`npm run open:ios`, `test:e2e -- --platform=ios`) | **No** |
| EAS `development` / `preview` **simulator** builds (`apps/mobile/eas.json` has `"ios": { "simulator": true }`) | **No** Apple listing fee (EAS credits still apply if you run cloud builds) |
| TestFlight / App Store / device-signed production | **Yes** — no free public listing path (unlike Play’s one-time fee) |

**Warn:** EAS iOS production builds burn credits and need an Apple Developer
account. Ask before `eas build` / `eas submit`.

## App Review 4.2 (minimum functionality)

Apple rejects thin “wrapper” / low-utility apps more readily than Play.
Sort this out early if you're targeting iOS — not at submit time.
Ship a real on-device job (clear value beyond a static website or single stub).

## Identity + App Store Connect

1. Set a real `ios.bundleIdentifier` in `apps/mobile/app.json`.  
   If the Android `--package` uses underscores, pass a separate `--bundle-id`
   (iOS ids cannot contain `_`).
2. Create the app in [App Store Connect](https://appstoreconnect.apple.com).
3. Note the numeric **Apple ID** of the app (App Information → General —
   this is `ascAppId`, not the bundle id).
4. Replace `REPLACE_WITH_APP_STORE_CONNECT_APP_ID` in `apps/mobile/eas.json`
   `submit.production.ios.ascAppId`.
5. Ask before changing submit config or running `eas submit`.

## Tablet support (template default)

This template sets `"supportsTablet": false` in `apps/mobile/app.json` so the product is
**phone-only** by default (fewer screenshot sizes and review obligations).
Opt into iPad later by setting `supportsTablet: true` and supplying iPad
screenshots / layout work.

## Export compliance

Template default: `ios.config.usesNonExemptEncryption: false` (HTTPS-only,
no custom crypto). That skips the ITSAppUsesNonExemptEncryption prompt on
TestFlight uploads. If you add custom crypto, revisit this flag.

## Credentials (never in-repo)

Use `eas credentials` for App Store Connect API keys / distribution certs /
provisioning. Never commit `.p8`, `.p12`, or keystores.

## Build

```bash
# bump ios.buildNumber in apps/mobile/app.json first (and expo.version if needed)
eas build --platform ios --profile production
```

Free/local testing without ASC:

```bash
# after EAS is configured — burns credits; simulator profiles only
eas build --platform ios --profile preview
```

## TestFlight vs App Store

| Lane | Review? | Use |
|------|---------|-----|
| TestFlight **internal** | No App Review | Your ASC team only — prefer first |
| TestFlight **external** | Beta App Review | Wider testers |
| App Store release | Full App Review | Public listing — promote by hand |

```bash
eas submit --platform ios --profile production
```

Prefer TestFlight internal first. Promoting to an App Store release is a manual step.

## Screenshots / listing assets

- Phone screenshots for the devices you support (required).
- iPad screenshots only if `supportsTablet: true`.
- App icon: **1024×1024**, **no alpha channel** (no transparency) — see
  `docs/recipes/brand-assets.md`.
- Privacy policy URL when ASC / review requires it
  (`docs/recipes/privacy-policy-url.md`).

## Privacy

Complete App Privacy labels to match the hosted privacy page
(`apps/web/content/privacy.md` / live URL) and reality
(see `docs/recipes/store-compliance.md`). For a pure on-device app,
**Data Not Collected** is the typical truthful answer — must match Play Data
safety when shipping **both** platforms.

## Exercise mode

Skip Apple Developer Program, ASC app creation, production device builds,
TestFlight, and App Store submit. Still allowed: Simulator + Expo Go and
(optional) EAS simulator profiles. Skip these until you have a paid account.
