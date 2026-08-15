# Payments (RevenueCat)

Default `APP_CONFIG.MONETIZATION` is **`free`**. With `free`, `apps/mobile/lib/purchases.ts`
never loads `react-native-purchases` — Expo Go keeps working (R5).

Paid modes (`subscription` | `one-time`) use **RevenueCat only** (`react-native-purchases`).
There is no in-house receipt verification, no `verify-purchase` edge function, and no
entitlements table.

## Modes

| Flag | Behavior |
|------|----------|
| `MONETIZATION: free` | Paywall hidden; SDK never loaded |
| `PURCHASES_MODE: mock` | Entitlement from `MOCK_ENTITLED`; fake offerings; no account |
| `PURCHASES_MODE: live` | Full SDK — needs a **development build** + public SDK key in `.env.local` |

Client seam (`apps/mobile/lib/purchases.ts`): `getOfferings` / `purchase` / `restore` /
`useEntitlement`. Call sites are identical across mock and live.

## Testing ladder

1. **Mock (flag)** — set `MONETIZATION` to `subscription` (or `one-time`) and
   `PURCHASES_MODE: mock`. Flip `MOCK_ENTITLED` to exercise locked/unlocked UI in Expo Go.
2. **StoreKit local (dev build)** — real purchase sheet + latency/error paths **without**
   App Store Connect products or a sandbox Apple ID (steps below).
3. **Sandbox testers** — real ASC / Play products + RevenueCat dashboard offerings.
4. **Production** — live store + live RevenueCat.

### What’s deferred (config, not code)

The live seam is fully coded in the template. You still must configure later:

- Real product IDs in App Store Connect / Play Console
- RevenueCat project, public SDK keys, entitlements, and offerings
- Sandbox / license testers
- Production verification in RevenueCat / stores

## Attach StoreKit config (local iOS, ~1 min)

File: `apps/mobile/store/storekit/Products.storekit`  
(Kept outside `ios/` because CNG regenerates native projects.)

After `npx expo run:ios` (or opening the generated Xcode project):

1. In Xcode, select the app scheme → **Edit Scheme…** → **Run** → **Options**.
2. **StoreKit Configuration** → choose
   `apps/mobile/store/storekit/Products.storekit`.
3. Run on Simulator. Purchases use the local StoreKit file (no sandbox Apple ID needed
   for basic product loading).

Placeholder product ID in the file:
`com.example.mobileapp.premium.monthly` (matches the mock offering product id).

For RevenueCat live + StoreKit local: create a matching product / offering in the
RevenueCat dashboard that uses the same product ID, and set
`EXPO_PUBLIC_REVENUECAT_API_KEY` (or platform-specific keys) in `.env.local`.

## Live-flow-local checklist

- [ ] Dev build installed (`npm run dev:build:ios` / `npx expo run:ios`)
- [ ] StoreKit config attached to the Run scheme (steps above)
- [ ] `MONETIZATION` ≠ `free`, `PURCHASES_MODE: live`, SDK key in `.env.local`
- [ ] Paywall loads offerings; purchase completes on Simulator
- [ ] Cancel path: dismiss the sheet → no error toast
- [ ] Restore purchases refreshes entitlements
- [ ] Toggle airplane mode: cached entitlement still readable; new purchase fails gracefully

## First paid app (sandbox → production)

- [ ] Create real product IDs in App Store Connect / Play Console
- [ ] Wire products → entitlement → offering in RevenueCat
- [ ] Replace placeholder product IDs if you changed them
- [ ] Sandbox testers (Apple) / license testers (Google)
- [ ] Confirm `useEntitlement('<entitlement_id>')` flips after purchase
- [ ] Run Harden / `preflight -- --gate=4` before submit
