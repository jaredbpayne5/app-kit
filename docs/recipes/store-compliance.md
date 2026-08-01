# Store compliance (local-first apps)

Canonical legal markdown lives in `apps/web/content/{privacy,terms}.md`. The app
does **not** ship in-app legal screens — Settings opens hosted URLs from
`apps/product.json` via `apps/mobile/lib/product.ts`. Keep copy reviewed before
store submission; run `npm run sync:legal` so hosted HTML under `apps/web/` matches.

Complete the sections that match the platforms this app ships to.

## Play Console — Data safety (typical for this template)

This template is **local-first** (on-device storage by default). Most products
built from it **do not** collect account data unless the product adds a network feature:

1. Declare only what this product actually sends off-device — be specific and
   accurate, not generic.
2. On-device-only prefs via `apps/mobile/lib/storage` are not separately "collected" by
   you. Anything synced to a server is — answer the questionnaire for the real
   data flows, not assumptions from other templates.
3. Link the **hosted** Privacy Policy URL (required for Play —
   `docs/recipes/privacy-policy-url.md`).
4. Do not claim "no data" if you later add analytics, crash reporting, ads, or
   any network identity.

## Apple — App Privacy labels

When shipping to iOS (or both platforms), complete **App Privacy** in
App Store Connect to match the same reality as Play and the hosted privacy page.

For a pure on-device app, **Data Not Collected** is often the truthful answer.
Only claim that if the product genuinely never sends anything off-device.

Rules:

1. Answers must match Play Data safety when shipping **both** platforms.
2. If you add crash reporting, analytics, ads, or any network identity →
   update labels **and** `apps/web/content/privacy.md` in the same change
   (then `npm run sync:legal`).
3. See also `docs/recipes/app-store.md`.

## Hard rule

Never invent data practices in legal copy. Align with `apps/mobile/store/data-practices.json`.
