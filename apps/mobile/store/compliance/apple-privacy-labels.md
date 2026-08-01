# App Store Connect — App Privacy labels

Generated from `apps/mobile/store/data-practices.json`. Enter in ASC → App Privacy.

## Privacy policy URL

Use the hosted privacy URL from `apps/mobile/store/metadata/ios/en-US/privacy_url.txt`
(must return HTTP 200 — see `npm run preflight`).

## Data collection

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data from this app? | No |
| Data linked to the user? | No |
| Data used to track the user? | No |
| Encrypted in transit? | Yes |

## Data types to declare

- **Data Not Collected** — on-device / local-first default (no accounts, no analytics; nothing leaves the device unless a product feature adds collection)

### Flags (source of truth)

- collects_accounts: `false`
- collects_user_content: `false`
- collects_purchases: `false`
- analytics: `none`
- crash_reporting: `none`
- data_shared_with_third_parties: `false`

## Deletion

Mechanism: `uninstall` — clear app data / uninstall (no cloud account in the default template)
