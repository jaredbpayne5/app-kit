# Store metadata

Listing copy and screenshots as repo files. Source of truth for
`npm run store:push` (fastlane `deliver` / `supply`). Fill every `TBD`
before submit — `npm run preflight` greps for it.

## Layout

Stub files ship with `TBD` (and example.com URLs). Replace every `TBD` before
submit — `npm run preflight` fails while any remain.

```
store/metadata/
  ios/en-US/          # App Store Connect (fastlane deliver)
  android/en-US/      # Play Console (fastlane supply)
  ios/review-notes.md # App Review notes (demo login, IAP test, contact)
```

## Character limits

<!-- keep these comments accurate — preflight enforces name/subtitle/keywords/short_description/changelog limits -->

| File | Platform | Limit |
|------|----------|-------|
| `name.txt` | iOS | ≤30 characters |
| `subtitle.txt` | iOS | ≤30 characters |
| `keywords.txt` | iOS | ≤100 characters **total** (comma-separated) |
| `description.txt` | iOS | ≤4000 characters |
| `release_notes.txt` | iOS | ≤4000 characters |
| `title.txt` | Android | ≤30 characters |
| `short_description.txt` | Android | ≤80 characters |
| `full_description.txt` | Android | ≤4000 characters |
| `changelogs/default.txt` | Android | ≤500 characters |

Privacy / support URLs: full `https://…` URLs in `privacy_url.txt` /
`support_url.txt` (iOS). Play privacy URL is set via Play Console / supply
listing when configured.
