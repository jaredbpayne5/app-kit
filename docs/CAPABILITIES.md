# Capability reference

What each first-party Expo module costs you in permissions, store-review
questions, and privacy declarations. Use this before adding one.

Source: Expo SDK 56 module docs at
`https://docs.expo.dev/versions/v56.0.0/sdk/<name>.md`.

**Most of these are NOT installed in this template.** Shipping permissions an
app doesn't use fights App Store and Play review, so the default install is
deliberately small. Add what a product actually needs:

```bash
npx expo install expo-camera
```

Then register the config plugin in `apps/mobile/app.json` (the "Permissions
added" column tells you what that pulls in) and update
`apps/mobile/store/data-practices.json` if data leaves the device.

**Installed by default:** `expo-sqlite`, `expo-secure-store`,
`expo-notifications`, `expo-file-system`, `expo-sharing`, `expo-haptics`,
`expo-store-review`, plus the UI floor below.

**Not installed** (add per product): `expo-camera`, `expo-location`,
`expo-audio`, `expo-sensors`, `expo-local-authentication`,
`expo-image-picker`, `expo-image-manipulator`.

| Capability | Package | Ships by default | Expo Go | Simulator | Permissions added | Privacy impact | Seam | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Camera + barcode scan | `expo-camera` | no — `npx expo install` | yes (Included in Expo Go; platforms include `expo-go`) | device-only (docs: Android device only, iOS device only — `android*` / `ios*`) | iOS `NSCameraUsageDescription` via plugin `cameraPermission`. Mic disabled on this plugin (`microphonePermission: false`, `recordAudioAndroid: false`). Android `CAMERA`. | Using the camera for on-device capture/scan alone does **not** change `apps/mobile/store/data-practices.json` (no off-device collection). Upload or cloud processing would. | `apps/mobile/lib/barcode.ts` for scan APIs; otherwise direct import | `barcodeScannerEnabled: true` (default). Products that never scan codes should set `false` to shrink the Android binary (ML Kit barcode model). Camera features cannot be verified by the automated simulator screenshot/e2e pipeline. |
| Local notifications | `expo-notifications` | yes | local-only (platforms list is `android`/`ios` only, but docs state local notifications remain available in Expo Go; remote push unavailable in Expo Go on Android from SDK 53 — needs a development build) | works (scheduling/presentation; push token paths need device/emulator with Play services / proper APNs setup — **not used** in this template) | Android: library adds `RECEIVE_BOOT_COMPLETED` (and related schedule permissions as needed). No iOS usage-description string. Plugin sets `enableBackgroundRemoteNotifications: false` (default). | Local reminders alone: **no** change to `data-practices.json`. Remote push (out of scope here) collects a device push token and **does** require updating data-practices. | `apps/mobile/lib/local-notifications.ts` | Local scheduled reminders only. Seam never calls `getExpoPushTokenAsync` / `getDevicePushTokenAsync`. |
| Sensors (motion / pedometer) | `expo-sensors` | no — `npx expo install` | yes (Included in Expo Go) | works (some sensors may return zeros or limited data on simulators) | iOS `NSMotionUsageDescription` via `motionPermission`. Optional Android `HIGH_SAMPLING_RATE_SENSORS` only if >200Hz (not enabled in template). | On-device motion/steps: **no** change to `data-practices.json` unless you transmit sensor data off-device. | direct import | Accelerometer, barometer, DeviceMotion, gyroscope, light, magnetometer, pedometer. |
| Location | `expo-location` | no — `npx expo install` | yes for foreground (Included in Expo Go). Background location requires a development build on iOS; Android foreground/background services are not available in Expo Go. | works (simulator location simulation) | iOS `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription` (copy set; background modes **off**). Android location permissions via the module. Template: `isIosBackgroundLocationEnabled: false`, `isAndroidBackgroundLocationEnabled: false`. | Foreground on-device location: **no** change while data stays on device. Continuous tracking, background location, or sending coords off-device requires updating `data-practices.json`. | direct import | Prefer when-in-use. Do not enable background plugins without a product need + privacy update. |
| Audio record / playback | `expo-audio` | no — `npx expo install` | yes (Included in Expo Go) | works (mic input limited without host audio; playback works) | iOS `NSMicrophoneUsageDescription` via `microphonePermission`. Android `RECORD_AUDIO` (`recordAudioAndroid: true`). Background playback/recording **disabled** in template (`enableBackgroundPlayback: false`, `enableBackgroundRecording: false`). | On-device recordings: **no** change to `data-practices.json`. Uploading audio off-device would. | direct import | Use for voice memo / practice / meditation. Flip background flags only when the product needs them (adds background modes). |
| Biometric lock | `expo-local-authentication` | no — `npx expo install` | yes for fingerprint/Touch-style flows (Included in Expo Go); **Face ID is not supported in Expo Go** — needs a development build | device-only for real biometrics (simulator passcode fallback may differ) | iOS `NSFaceIDUsageDescription` via `faceIDPermission`. Android `USE_BIOMETRIC` / `USE_FINGERPRINT` auto-added. | Biometric unlock of on-device data: **no** change to `data-practices.json` (no biometric templates leave the device). | direct import | Common premium gate. Pair with secure storage when locking secrets. |
| Secure storage | `expo-secure-store` | yes | yes (Included in Expo Go); `requireAuthentication` is **not** supported in Expo Go when biometrics are available (missing Face ID usage description in Expo Go) | works for basic get/set; biometric-gated reads need a real device (docs: emulators/simulators do not require biometric auth when retrieving secrets the way devices do) | iOS `NSFaceIDUsageDescription` via plugin when using biometric-gated access. `configureAndroidBackup: true` excludes SecureStore from Auto Backup. | Encrypted on-device KV: **no** change to `data-practices.json`. | direct import | Template already sets `ios.config.usesNonExemptEncryption: false`. |
| Image resize / crop / rotate | `expo-image-manipulator` | no — `npx expo install` | yes (Included in Expo Go) | works | none (no config plugin; operates on local file URIs) | On-device image transforms: **no** change to `data-practices.json`. | direct import | Required companion for any image feature. Prefer the contextual `manipulate` / `useImageManipulator` API over deprecated `manipulateAsync`. |
| File system | `expo-file-system` | yes | yes (Included in Expo Go) | works | none beyond plugin flags. Template enables `supportsOpeningDocumentsInPlace` + `enableFileSharing` (iOS Files / iTunes sharing). | Local files only: **no** change to `data-practices.json`. | direct import | Read/write/export on-device files. |
| Share sheet / export | `expo-sharing` | yes | yes (Included in Expo Go) | works | Outbound `shareAsync` needs no permission strings. Plugin defaults keep **incoming** share extension/intent **disabled** (`ios.enabled` / `android.enabled` default `false`). | Sharing a file via the OS share sheet: **no** change to `data-practices.json` by itself. Enabling incoming share + uploading shared content would. | direct import | Pairs with premium export flows. Do not enable incoming share plugins without a product need. |
| Haptics | `expo-haptics` | yes | no (`platforms` are `android` / `ios` / `web` only — no `expo-go`) | works | Android `VIBRATE` added automatically by the library. | None — no data collection. **No** change to `data-practices.json`. | `apps/mobile/lib/haptics.ts` | Semantic helpers: `tapLight`, `tapMedium`, `success`, `warning`, `error`. No-ops on web. |
| In-app store review | `expo-store-review` | yes | yes (Included in Expo Go) | works (API available; the native review UI may no-op or be limited outside store builds) | none | None — **no** change to `data-practices.json`. | direct import | Follow Apple HIG / Play in-app review guidelines: after a signature moment, never from a raw button spam. |

## UI floor — always installed

Native UI/UX primitives baked in so you compose instead of inventing chrome.
None of these add permission prompts.

| Package / surface | Why | Seam / component |
| --- | --- | --- |
| `react-native-reanimated` | All animation. Never use the legacy RN `Animated` API. | `ui/motion.tsx`, `ui/button.tsx` |
| `react-native-gesture-handler` | Swipe actions, sheet gestures. Root view wraps the app in `app/_layout.tsx`. | `ReanimatedSwipeable` in `app/(tabs)/library.tsx` |
| `@gorhom/bottom-sheet` | Modal sheets — the standard iOS input pattern. | `app/(tabs)/library.tsx` |
| `@shopify/flash-list` | Lists. Use instead of `FlatList`, which stutters at length. | `app/(tabs)/library.tsx` |
| `expo-symbols` | SF Symbols on iOS so tab bars and icons read as native. | `components/tab-bar-icon.tsx` |
| `expo-font` | Load brand fonts when you have them; default is **system** typography (true native). | Root layout `useFonts` when assets present |
| `expo-image` | Cached images + placeholders — prefer over RN `Image`. | direct import |
| `expo-localization` | Locale-aware dates / currency / numbers. | direct import + `DateField` labels |
| `expo-linear-gradient` | Onboarding / paywall / hero washes. | `BrandAtmosphere`, paywall |
| `expo-clipboard` | Copy codes / IDs / share text. | direct import |
| `expo-web-browser` | In-app privacy / terms / support (store-review friendly). | Settings legal links |
| `expo-blur` | Paywall / modal overlays. | paywall overlays |
| `@react-native-community/datetimepicker` | Native date entry; store **local** `YYYY-MM-DD` (never `toISOString()` for calendar days). | `apps/mobile/components/date-field.tsx` |
| `@react-native-picker/picker` | Native number / unit wheels. | `apps/mobile/components/number-wheel-field.tsx` |

Install with `npx expo install <pkg>` so the SDK pin matches. After adding a
native module to a development build that was compiled without it, run
`npx expo run:ios` / `run:android` — Metro alone is not enough.

Shared compose kit (no extra native deps): `GroupedSection` / `GroupedRow` /
`GroupedField`, `ui/chart.tsx` (SVG), `EmptyState`, header overflow menu,
`Paywall`, and the `review-prompt` seam.

### Community — not installed; add deliberately

| Package | Notes |
| --- | --- |
| `expo-print` | PDF export products |
| `expo-document-picker` | Import CSV/JSON backups |
| `expo-mail-composer` | Email attachments |
| `expo-keep-awake` | Workouts / timers |
| `expo-asset` | Bundled read-only datasets |
| `expo-device` / `expo-application` / `expo-network` | Diagnostics / offline / version gating |

## Starter kit vs shipped code

Much of this template is **inventory**: wired, tested, and deliberately unused
until a product needs it. A code review that treats "no importers" as "dead
code" will delete the seams this factory exists to provide. Nothing in the list
below is abandoned.

| Dormant until a product needs it | Gated by |
| --- | --- |
| `lib/streak.ts`, `lib/review-prompt.ts`, `lib/local-notifications.ts` | nothing imports them yet — tested seams, ready to wire |
| `withSql` / `registerMigrations` in `lib/storage.ts` | `APP_CONFIG.STORAGE` is `kv` |
| `components/paywall.tsx`, `lib/purchases.ts`, `lib/paywall-plans.ts` | `APP_CONFIG.MONETIZATION` is `free` |
| `ui/card`, `chart`, `input`, `label`, `separator`, `switch`, `textarea`, `alert-dialog`, `native-only-animated-view` | React Native Reusables kit — add screens, not primitives |
| `components/date-field.tsx`, `number-wheel-field.tsx`, `header-overflow-menu.tsx` | compose kit for form/nav screens |
| `PopIn` (`ui/motion.tsx`), `GroupedField`, `SettingsHeaderButton`, `haptics.tapMedium` / `error` | complete primitive APIs, partially used |
| `app/(tabs)/index.tsx`, `library.tsx`, `onboarding.tsx` | demo screens; their own copy says replace on clone |

**Prune at clone time, not before.** Once `docs/PRD.md` is filled and the
product's real screens exist, delete whatever the product will never use —
unused primitives and their deps, seams for features that aren't in the PRD,
the SQL path if the product stays `kv`, the paywall stack if it stays `free`,
and the demo screens. Deleting them while this is still the template only costs
the next clone a re-scaffold.

## Out of scope — per-product only

These carry extra store-review or privacy weight. Add one only when the product genuinely needs it, and update `data-practices.json` alongside it.

| Package / area | Why out of scope |
| --- | --- |
| `expo-video` | Large surface; not every product needs video playback/recording. |
| `expo-calendar` | Calendar access is sensitive and product-specific. |
| `expo-contacts` | Contacts access is sensitive and product-specific. |
| `expo-media-library` | Broad photo-library access beyond picker; store-review questions. |
| `expo-tracking-transparency` | ATT only when advertising/attribution is in scope. |
| `expo-widgets` | Home-screen widgets need native config and product UX. |
| `expo-maps` | **ALPHA** — do not bake into the template. |
| `expo-task-manager` / background location | Privacy / store-review landmines; per-product only. |
| `expo-background-task` | Periodic background work — product-specific. |
| `expo-screen-capture` | Niche premium screenshot lock. |
| `expo-apple-authentication` / `expo-auth-session` | Accounts → **mobile-app-factory**, not this template. |
| Third-party ML (`@react-native-ml-kit/*`, `react-native-vision-camera` plugins, etc.) | Per-product model/camera pipeline decisions; not first-party Expo ambient capabilities. |
| Alpha / niche (`expo-age-range`, `expo-app-integrity`, `expo-gl`, `expo-speech`, `expo-sms`, `expo-live-photo`, `expo-mesh-gradient`, `expo-glass-effect`, …) | Leave out until a product specifically needs one. |

## Remote push notifications — recipe, not installed

Local notifications cover reminders, streaks, and re-engagement **without a server**.

Remote push is **not** installed. When a product truly needs it:

1. APNs key (Apple) + FCM credentials (Google).
2. A **development build** (remote push is not available in Expo Go on Android from SDK 53).
3. Token storage and a sender.

**Recommended path for this factory:** a **Cloudflare Worker + KV** to hold Expo push tokens and broadcast via the [Expo Push Service](https://docs.expo.dev/push-notifications/sending-notifications/) — the Cloudflare account already exists for the marketing lander.

Remote push means collecting a **device identifier** (push token). That ends an honest “Data Not Collected” posture and **requires** updating `apps/mobile/store/data-practices.json` (and store privacy labels) before ship.

## Local-development ceiling

What you can validate without paid App Store / Play Console accounts:

| Area | Without paid store accounts |
| --- | --- |
| Purchases | StoreKit configuration files exercise purchase, restore, accelerated renewal, grace period, billing retry, and refund with no Apple Developer account. |
| Purchases (limits) | Real receipt validation and sandbox IAP against App Store Connect **cannot** be reached without accounts. |
| Camera / barcode | Needs a **physical device**. Free Xcode personal-team provisioning is enough (7-day certs). No TestFlight and no push required. |
| Simulator automation | Camera is device-only on both platforms — automated screenshot/e2e pipelines **cannot** cover camera features. |
| Local notifications | Schedulable on simulator/emulator for local triggers. |
| Face ID | Needs a development build + device; not in Expo Go. |
