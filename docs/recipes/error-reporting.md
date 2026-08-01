# Error reporting (Sentry, wired but dormant)

Call sites should use:

```ts
import { reportError } from '@/lib/report-error';

try {
  // …
} catch (e) {
  reportError(e, { screen: 'home' });
}
```

## Default behavior (no DSN)

- `EXPO_PUBLIC_SENTRY_DSN` unset or empty → `Sentry.init` is **not** called
- `__DEV__`: `reportError` logs to the console
- Production: `reportError` is a no-op (nothing leaves the device)
- The `@sentry/react-native` dependency and `apps/mobile/lib/sentry.ts` lazy
  loader ship with the template; the **Expo config plugin is opt-in** (not in
  default `app.json`) so `preflight` / EAS builds stay reachable without a DSN

## Activate Sentry (first app that needs crash reporting)

1. Create a Sentry project (org + project slug).
2. Put the **public** DSN in `.env.local`:

   ```bash
   EXPO_PUBLIC_SENTRY_DSN=https://…@….ingest.sentry.io/…
   ```

3. Add the Expo plugin to `apps/mobile/app.json` `plugins` (opt-in):

   ```json
   [
     "@sentry/react-native/expo",
     {
       "organization": "YOUR_SENTRY_ORG",
       "project": "YOUR_SENTRY_PROJECT",
       "url": "https://sentry.io/"
     }
   ]
   ```

4. Set `crash_reporting` in `apps/mobile/store/data-practices.json` (not
   `"none"`) and re-run `npm run gen-compliance`.
5. Rebuild (dev client / EAS). Expo Go may load JS init, but native crash
   capture needs a development build.
6. Confirm: trigger `reportError(new Error('sentry-smoke'))` and see the event
   in the Sentry Issues UI.

`reportError` already forwards to `Sentry.captureException` when init ran —
no call-site changes.
