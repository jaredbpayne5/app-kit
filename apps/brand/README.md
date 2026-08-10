# Brand masters

Put product artwork here, then run from the repo root:

```bash
npm run brand:generate
```

| File | Required | Notes |
|------|----------|-------|
| `icon-master.png` | yes | Square PNG, ≥1024×1024 |
| `splash-master.png` | no | Square ≥1024; falls back to icon-master |

Palette / background for generation lives in
`apps/mobile/assets/brand/brand.json`.

Optional starting mark (not a final logo):

```bash
npm run generate-icon-master
```

That writes `apps/brand/icon-master.png`. Replace it with real product art
before store submit — `npm run preflight` rejects template placeholder icons.
