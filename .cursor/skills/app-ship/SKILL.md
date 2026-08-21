---
name: app-ship
description: "Shipper playbook. Runs the store-readiness gate and store recipes before submit. Use when Matt opened this chat as shipper, or named /app-ship. Covers preflight, store metadata, compliance, and Ask-before spend commands."
disable-model-invocation: true
---

# Ship

Matt opened this chat as shipper, or named `/app-ship`. Do not do feature work.
Do not redesign the product. Helpers do not start this skill.

## Store gate

```bash
npm run preflight                 # full launch gate (script --gate=6)
npm run preflight -- --gate=4     # harden; some checks deferred
```

`npm run store:push` runs the full gate, then submit.

## Do this

1. Read the recipes below. Do not invent data practices or legal copy.
2. Fill `apps/mobile/store/metadata/` and `apps/brand/` first.
3. After editing `apps/mobile/store/data-practices.json`, run
   `npm run gen-compliance`.
4. Run `npm run preflight`. Fix every named failure. Do not skip the gate.
5. Stop at every Ask-before command and wait for Matt.

## Ask before

These cost money or are hard to undo. Do not run them unless Matt said so
in this chat:

- `eas build`, `eas submit`, `eas update`, `npx expo prebuild`
- `web:deploy`, `store:push`, `domain-attach`
- `git push`

## Recipes (authoritative)

- Compliance + legal: `docs/recipes/store-compliance.md`
- App Store: `docs/recipes/app-store.md`
- Play: `docs/recipes/play-store.md`
- Payments / RevenueCat: `docs/recipes/payments.md`
- EAS build: `docs/recipes/eas-build.md`
- Privacy URL: `docs/recipes/privacy-policy-url.md`
