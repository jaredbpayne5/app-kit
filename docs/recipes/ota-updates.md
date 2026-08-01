# Recipe — OTA updates (EAS Update)

Ship JavaScript-only fixes without a full App Store / Play Store binary when the
installed app’s **runtime version** matches. This template uses:

```json
"runtimeVersion": { "policy": "appVersion" }
```

So the runtime version equals `expo.version` in `apps/mobile/app.json` (e.g. `1.0.0`). A store
binary built at `1.0.0` only receives OTA updates published for that same version.

`expo-updates` is a **no-op in Expo Go** — local UI work stays Expo Go–friendly.
OTA applies to **development / preview / production builds** that include native
`expo-updates` (EAS Build).

Replace `REPLACE_WITH_EAS_PROJECT_ID` in `apps/mobile/app.json` (`extra.eas.projectId` **and**
`updates.url`) before the first real EAS Update. Or run `eas update:configure`
once the EAS project exists (ask first).

## When OTA is allowed

| Change type | Ship how |
|-------------|----------|
| JS / TS screens, styles, copy, most `apps/mobile/` logic | `eas update` |
| New/changed native module, config plugin, `app.json` native fields, permissions | **Store build** (`eas build` + submit) |
| Bumped `expo.version` (via `npm run bump-version`) | New store binary first; then OTAs for that version |

**Store policy (both stores):** OTA must **not** change the app’s core purpose.
Bug fixes and minor UX are fine; a different product via update is not.

## Publish an update

```bash
# After a production binary exists for this expo.version:
eas update --branch production --message "fix: clarify settings copy"
```

Use the branch that matches how you distribute builds (often `production` for
store, `preview` for internal). Confirm with `eas channel:list` / project docs
once channels are wired.

## Rollback

1. Find the previous good update: `eas update:list --branch production`
2. Republish or promote that update (EAS dashboard **or** CLI republish of the
   prior group). Prefer the dashboard “Rollback” on the branch/channel if shown.
3. If rollback is unclear, ship a new update that reverts the bad change with a
   clear `--message`.

If the bad change required a native bump, OTA cannot fix it — ship a store build.

## Related

- `npm run bump-version` prints an OTA vs store-build reminder.
- Ask first: `eas update`, `eas build`, `eas submit`.
- Go-live / prod env: `docs/FACTORY-PLAN.md (no backend go-live in this template)` (Stage 3 Part D).
