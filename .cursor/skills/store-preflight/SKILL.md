---
name: store-preflight
description: >-
  Runs the store-readiness gate (npm run preflight) and the store recipes
  before submit. Use when preparing App Store or Play submission, running
  preflight, store:push, or filling store metadata / compliance.
---

# Store preflight

Store-readiness gate. Not the same numbering as `docs/build-status.md`
phases 0–8.

## Command

```bash
npm run preflight                 # full launch gate (script --phase=6)
npm run preflight -- --phase=4    # harden; some checks deferred
```

`npm run store:push` runs the full gate, then submit. **Ask before**
`store:push`, `eas build`, `eas submit`, `web:deploy`.

## Do this

1. Read the recipes below. Do not invent data practices or legal copy.
2. Fill `apps/mobile/store/metadata/` and `apps/brand/` first.
3. After editing `apps/mobile/store/data-practices.json`, run
   `npm run gen-compliance`.
4. Run `npm run preflight`. Fix every named failure. Do not skip the gate.

## Recipes (authoritative)

- Compliance + legal: `docs/recipes/store-compliance.md`
- App Store: `docs/recipes/app-store.md`
- Play: `docs/recipes/play-store.md`
- Payments / RevenueCat: `docs/recipes/payments.md`
- EAS build: `docs/recipes/eas-build.md`
- Privacy URL: `docs/recipes/privacy-policy-url.md`
