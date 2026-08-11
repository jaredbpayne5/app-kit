# Ads attribution (paid install campaigns)

**Do not install any attribution SDK into the template by default.**  
Organic-only apps skip this entirely. Implement this recipe **per app** only when
you start paid install campaigns (Meta / Google / Apple Search Ads, etc.).

Attribution SDKs pull in the heaviest mobile compliance surface: iOS App Tracking
Transparency (ATT), IDFA / tracking declarations, privacy-label changes, and
SKAdNetwork configuration. Treat this as a deliberate product decision, not a
default factory step.

## 1. When you need it

| Situation | What to do |
|-----------|------------|
| Organic installs only (ASO, lander, word of mouth) | **Skip** — no MMP / Meta SDK |
| Meta (Facebook/Instagram) paid installs | Need conversion feedback via an **MMP** (e.g. AppsFlyer — free tier exists) **or** Meta’s SDK |
| Google / Apple Search Ads with deep measurement | Usually an MMP; confirm the network’s current requirement |
| “I just want retention charts” | **Not this recipe** — see §4 (product analytics) |

Say **`start paid ads`** in a product session before any agent installs packages.

## 2. Install path `[VOLATILE]`

APIs and package names change. Before coding, re-check:

- [AppsFlyer Expo install](https://dev.appsflyer.com/hc/docs/rn_expoinstallation)
- [Expo tracking transparency](https://docs.expo.dev/versions/latest/sdk/tracking-transparency/)

### A. Development build required

These native modules **do not run in Expo Go**. Use a development build
(`expo-dev-client` + EAS / local). Ask before `eas build` / `npx expo prebuild`.

### B. Packages (current sketch — verify before install)

```bash
npx expo install expo-dev-client react-native-appsflyer expo-tracking-transparency
```

Register plugins in `apps/mobile/app.json` (shapes from current AppsFlyer / Expo docs):

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-appsflyer",
        {
          "shouldUseStrictMode": false,
          "shouldUsePurchaseConnector": false
        }
      ],
      [
        "expo-tracking-transparency",
        {
          "userTrackingPermission": "This identifier will be used to measure advertising campaign performance."
        }
      ]
    ],
    "ios": {
      "infoPlist": {
        "SKAdNetworkItems": []
      }
    }
  }
}
```

Fill `SKAdNetworkItems` with the network IDs your MMP / Meta docs list for the
campaigns you actually run. Empty array = incomplete for paid Meta measurement.

### C. ATT prompt copy (App Review)

Vague ATT strings get rejected. The purpose string must say **what** you track
and **why** (ads measurement), not “to improve your experience.”

Request permission only after a clear pre-prompt screen that explains the value
in plain language — then call `requestTrackingPermissionsAsync()` from
`expo-tracking-transparency`.

### D. Init

Initialize AppsFlyer with keys from EAS env / `.env.local` — **never** commit
real keys. Dev keys go in `EXPO_PUBLIC_*` only if you accept they ship in the
client binary; prefer server-side / build-time secrets where the MMP allows.

## 3. Compliance coupling (hard rule)

Adding **any** attribution / ads SDK **requires**, in the same change set:

1. Update `apps/mobile/store/data-practices.json`:
   - set `analytics` to the vendor name (e.g. `"appsflyer"`) — not `"none"`
   - set `data_shared_with_third_parties` as appropriate for the MMP / ad network
   - extend the schema with tracking fields if needed (`tracks_users`, etc.)
2. `npm run gen-compliance`
3. `npm run sync:legal`
4. Resubmit / update Play Data safety + Apple App Privacy labels
5. Re-run `npm run preflight` before `store:push`

### Preflight check 12 (ships dormant in the template)

`scripts/store/review-preflight.sh` already includes **check 12 —
`attribution_undeclared`**: if `package.json` lists a known attribution SDK
(`react-native-appsflyer`, `react-native-fbsdk*`, `react-native-adjust`,
`react-native-branch`, or a Meta/Facebook ads SDK) **and**
`apps/mobile/store/data-practices.json` still has `"analytics": "none"`, preflight fails.

On a stock template (no attribution SDK) the check is a **no-op** (passes).

**On first use of this recipe:** after adding the SDK package, run
`npm run preflight` and **confirm check 12 fails** with `attribution_undeclared`
until you update `data-practices.json` + `gen-compliance`. That proves the guard
is live for this product. Then fix data-practices so it goes green.

Do not ship paid-ads builds while check 12 is red.

## 4. Product analytics (separate — deferred)

Attribution (paid campaign ROI) ≠ product analytics (retention, funnels).

Pre-traction default for this factory:

- Store console analytics (App Store / Play)
- backend SQL on your own tables

A dormant PostHog-style (or similar) product-analytics seam is an option later —
**do not decide or install it in this recipe.** If you add product analytics
later, it still updates `data-practices.json` + `gen-compliance` the same way.

## Checklist (first paid campaign)

- [ ] Human said `start paid ads` for this product
- [ ] Dev build path confirmed (not Expo Go)
- [ ] Packages + plugins installed (ask before `npx expo install`)
- [ ] ATT copy reviewed; SKAdNetwork IDs filled
- [ ] `data-practices.json` updated; `gen-compliance` + `sync:legal` run
- [ ] **Preflight check 12 fires** after adding the SDK (then goes green once data-practices is updated)
- [ ] Privacy labels updated in both store consoles
- [ ] `npm run preflight` green before submit
