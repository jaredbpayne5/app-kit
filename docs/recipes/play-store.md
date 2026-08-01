# Google Play Store

**Warn:** creating a Play developer account costs a one-time Google fee.
EAS Submit can publish builds — keep `eas.json` submit track on `internal`
and `releaseStatus: draft` until you intentionally promote.

## Checklist

1. Google Play Console account + new app listing.
2. Set a **real** `android.package` in `apps/mobile/app.json` **before** the first upload
   (changing it later creates a different app).
3. Production AAB via EAS (`docs/recipes/eas-build.md`).
4. First upload is often manual in Play Console (create the app, upload AAB).
5. Optional later: upload a Google Play **service account** key to EAS
   credentials (`eas credentials`) so `eas submit` can upload for you.
6. Never commit `*service-account*.json` or keystores.

## Submit profile (template default)

```json
"submit": {
  "production": {
    "android": {
      "track": "internal",
      "releaseStatus": "draft"
    }
  }
}
```

Only change `track` to `production` deliberately, by hand.

## Store assets

- High-res icon + feature graphic
- Phone screenshots (and tablet if you declare tablet support)
- Privacy policy URL (required for many app types)

## Exercise mode

Skip the Console account + submit until you've paid the $25 registration.
