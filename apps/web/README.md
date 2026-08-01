# apps/web/

Marketing / lander site for **this product** (same idea as the iOS + Android apps).

**Not** the Expo mobile app (that lives under `apps/mobile/` and ships to both stores).
Use this folder for a simple brochure page: screenshots, short pitch, and
**App Store + Google Play** download links.

Canonical legal markdown: `content/privacy.md` and `content/terms.md`.
`npm run sync:legal` writes hosted HTML here (no in-app legal screens).

Social preview image: run `npm run brand:generate` first (writes
`template/og-image.png`), then `npm run web:build` copies it into `dist/` and
wires Open Graph / Twitter meta from `product.json` slug →
`https://<slug>.pages.dev/og-image.png`.

**Ship goal:** iOS app + Android app + this page.  
**Day-to-day:** you can ignore `apps/web/` until near launch.

Add real pages near launch (Phase 5). Until then this folder is the reserved home
for marketing content.
