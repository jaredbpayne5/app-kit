# Brand assets

Replace these files before Harden / Launch (paths from `apps/mobile/app.json`):

| File | Role |
|------|------|
| `apps/mobile/assets/images/icon.png` | App icon (also source for stores) |
| `apps/mobile/assets/images/adaptive-icon.png` | Android adaptive foreground |
| `apps/mobile/assets/images/splash.png` | Splash image |
| `apps/mobile/assets/images/favicon.png` | Web favicon (optional for store) |

Brand master for `npm run brand:generate`: `apps/brand/icon-master.png`
(see `apps/mobile/assets/brand/` for `brand.json`).

## Checklist

1. Use your product artwork (not the template placeholder).
2. Keep adaptive icon readable on light and dark launcher backgrounds.
3. After replacing images, smoke the splash on a device/emulator/simulator.
4. Play Console still needs a high-res icon + feature graphic + screenshots
   (upload separately in the Console).
5. **App Store icon:** export a **1024×1024** icon with **no alpha channel**
   (no transparency). ASC rejects icons with transparency.
6. **iOS splash / screenshots:** splash should look correct on the booted
   Simulator; capture phone screenshots for the devices you support. iPad
   screenshots are only required if `ios.supportsTablet` is `true` (template
   default is `false` — phone-only).

## Version bumps before each store build

In `apps/mobile/app.json`:

- `expo.version` — user-visible version (e.g. `1.0.1`)
- `android.versionCode` — integer; must increase every Play upload
- `ios.buildNumber` — string; must increase every App Store / TestFlight upload

Prefer `npm run bump-version` when shipping the platforms this app targets.
Settings shows version via `apps/mobile/lib/app-version.ts`.
