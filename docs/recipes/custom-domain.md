# Custom domain for the marketing lander

`<slug>.pages.dev` satisfies App Store / Play privacy-URL requirements. Attach a
studio subdomain only when an app earns marketing spend — this recipe is the
promotion path so it is a Step, not a research project.

## Three paths

### Path 1 — One-time studio domain (human)

1. Register **one** studio domain via [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)
   (at-cost DNS; zone lands on Cloudflare automatically).
2. Add to `~/.app-factory/env` (never commit):

```bash
CLOUDFLARE_ZONE_ID=REPLACE_WITH_ZONE_ID
CLOUDFLARE_STUDIO_DOMAIN=yourstudio.com
```

3. Extend the Cloudflare API token (Stage 0) with **Zone → DNS → Edit** on that
   zone, in addition to **Account → Cloudflare Pages → Edit**.

### Path 2 — Per-app subdomain (default)

```bash
bash scripts/web/attach-domain.sh <subdomain>
# example: bash scripts/web/attach-domain.sh myapp
# → https://myapp.yourstudio.com
```

What the script does (idempotent):

1. `POST …/pages/projects/<slug>/domains` with `{ "name": "<sub>.<studio>" }`
   (Wrangler 4 has no `pages domains` CLI — API only).
2. Ensures a **proxied** DNS `CNAME` `<sub>.<studio>` → `<slug>.pages.dev`.
3. Prints the live HTTPS URL (certificate is automatic once Pages status is Active).

**After attach — required:**

1. Update `apps/mobile/store/metadata/*/privacy_url.txt` and `support_url.txt` to the new
   `https://<sub>.<studio>/privacy`.
2. Update `apps/web/lander.json` and `apps/product.json` (`privacyUrl` / `termsUrl`)
   if they embed marketing / legal URLs.
3. `npm run sync:legal && npm run web:build && npm run web:deploy`.

Store listings must never keep pointing at a URL you later delete.

Dry-run / missing credentials: the script aborts with a clear error and makes
**no** API calls (`bash scripts/web/attach-domain.sh myapp` without env → clean fail).

### Path 3 — Dedicated domain (earned)

Recipe-only (no script):

1. Register the app’s own domain (Cloudflare Registrar or elsewhere).
2. Add it as a Cloudflare zone; attach via the same Pages domains API + DNS CNAME
   (or dashboard → Pages → Custom domains).
3. **301-redirect** the old studio subdomain with [Cloudflare Bulk Redirects](https://developers.cloudflare.com/rules/url-forwarding/bulk-redirects/)
   (free) so existing store-listing links keep working.
4. **Never delete** the old subdomain record while any store listing still uses it.

## Deferred live test

Full `attach-domain.sh` against a real studio subdomain is **deferred** until the
first app needs marketing on a custom host (same pattern as other Stage 4/5
deferred-live checks). Until then:

- `npm run web:deploy` → `https://<slug>.pages.dev` is the production privacy URL
- `bash scripts/web/attach-domain.sh …` without credentials must abort cleanly (verified)

## See also

- `docs/recipes/privacy-policy-url.md` — sync → build → deploy for legal pages
- PROCESS Phase 5 (Lander) — when to build/deploy; custom domain is optional after
