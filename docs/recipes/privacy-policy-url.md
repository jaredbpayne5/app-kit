# Hosted privacy policy URL (store listings)

The app does **not** ship in-app privacy/terms screens. Settings opens hosted
HTTPS URLs from `apps/product.json` (via `apps/mobile/lib/product.ts`). Store
listings also need that **public HTTPS URL**. This template hosts the page on
the marketing lander (Cloudflare Pages).

## What to do

1. Keep canonical copy in `apps/web/content/privacy.md` (and `apps/web/content/terms.md`).
2. Sync + build + deploy:

```bash
npm run sync:legal
npm run web:build
npm run web:deploy   # ask first — needs CLOUDFLARE_* in ~/.app-factory/env
```

`sync:legal` writes HTML under `apps/web/` only (no in-app `legal-content.ts`).
`web:deploy` prints the live lander URL. The hosted privacy policy is:

```text
https://<slug>.pages.dev/privacy
```

(` /privacy.html` redirects to that path on Cloudflare Pages — either works in a
browser; prefer the extensionless URL in store listings.)

Verify after deploy:

```bash
curl -sfIL "https://<slug>.pages.dev/privacy.html" | head -1   # expect HTTP/2 200 (after redirects)
```

3. Paste that URL into Play Console / App Store Connect (and support URL fields),
   and keep `apps/product.json` `privacyUrl` / `termsUrl` in sync so Settings opens
   the same pages. Stage 4 store automation pastes it into metadata when you run
   that pipeline.
4. Re-run the three commands whenever legal copy changes so the public pages stay
   current.

## What not to do

- Do not invent data practices the app does not have.
- Do not point store listings at a broken or login-walled URL.
- Do not add a separate BaaS just to host a page — Pages is enough.
- Do not skip `sync:legal` and edit only the HTML; canonical copy is
  `apps/web/content/{privacy,terms}.md`.
- Do not add in-app `privacy.tsx` / `terms.tsx` screens.

## Apple

When shipping iOS, App Privacy labels must match the same reality. The hosted
URL is still useful for App Store Connect / support pages.

See also: `docs/recipes/store-compliance.md`, `docs/recipes/custom-domain.md`
(optional studio subdomain after launch).
