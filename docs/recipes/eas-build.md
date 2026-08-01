# EAS Build

**Warn:** cloud builds burn Expo credits. Do not run without developer yes
(ask before running).

## Profiles (see `eas.json`)

| Profile | Use |
|---------|-----|
| `development` | Dev client APK (custom native modules) |
| `preview` | Internal APK for testers |
| `production` | **AAB** for Google Play |

## First-time setup

1. Create an Expo account.
2. Install CLI: `npm i -g eas-cli`
3. From the repo: `eas login` then `eas build:configure`
4. Replace `REPLACE_WITH_EAS_PROJECT_ID` in `apps/mobile/app.json`.

## Production Android build

```bash
eas build --platform android --profile production
```

Output should be an `.aab` (Android App Bundle). Play Console expects AAB for
new apps — not a release APK.

## Exercise mode

Skip cloud builds until you have a paid account.
