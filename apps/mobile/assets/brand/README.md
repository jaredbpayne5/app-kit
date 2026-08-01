# Brand masters

Put product artwork in `apps/brand/`, and `brand.json` here, then run:

```bash
npm run brand:generate
```

| File | Required | Notes |
|------|----------|-------|
| `apps/brand/icon-master.png` | yes | Square PNG, ≥1024×1024 |
| `apps/brand/splash-master.png` | no | Square ≥1024; falls back to icon-master |
| `apps/mobile/assets/brand/brand.json` | yes | `{ "background": "#RRGGBB" }` |

Outputs (overwrites):

- `apps/mobile/assets/images/icon.png` (1024, flattened — no alpha for App Store)
- `apps/mobile/assets/images/adaptive-icon.png` (1024, 66% safe-zone inset)
- `apps/mobile/assets/images/splash.png` (1024)
- `apps/mobile/assets/images/favicon.png` (48)
- `apps/web/template/og-image.png` (1200×630)
