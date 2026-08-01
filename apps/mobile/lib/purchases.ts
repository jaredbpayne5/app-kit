/**
 * Purchases seam — RevenueCat mock | live behind flags.
 *
 * `MONETIZATION: 'free'` never loads `react-native-purchases` (R5 / Expo Go).
 * `PURCHASES_MODE: 'mock'` drives entitlement from `MOCK_ENTITLED` (no SDK, no account).
 * `PURCHASES_MODE: 'live'` loads the SDK only when monetization is paid (dev build).
 *
 * [VOLATILE] API checked 2026-07-24 via Context7 `/revenuecat/react-native-purchases`:
 *   Purchases.configure({ apiKey })
 *   getOfferings / purchasePackage / restorePurchases / getCustomerInfo
 *   customerInfo.entitlements.active; error.userCancelled
 */
import { APP_CONFIG, MOCK_ENTITLED, PURCHASES_MODE } from '@/lib/app-config';
import { useEffect, useState } from 'react';
import { Platform } from 'react-native';

import type { CustomerInfo, PurchasesOfferings, PurchasesPackage } from 'react-native-purchases';

export type OfferingPackage = {
  identifier: string;
  productId: string;
  title: string;
  description: string;
  price: string;
};

export type PurchaseResult =
  { ok: true; productId: string } | { ok: false; error: string; cancelled?: boolean };

type PurchasesSdk = typeof import('react-native-purchases').default;

let sdk: PurchasesSdk | null = null;
let sdkConfigured = false;
/** Live-mode cache: package identifier → native PurchasesPackage */
const livePackageById = new Map<string, PurchasesPackage>();
let cachedCustomerInfo: CustomerInfo | null = null;

function isPaid(): boolean {
  return APP_CONFIG.MONETIZATION !== 'free';
}

function isLive(): boolean {
  return isPaid() && PURCHASES_MODE === 'live';
}

/** Test/observability helper — true only after a live-path require(). */
export function isPurchasesSdkLoaded(): boolean {
  return sdk !== null;
}

/** @internal — clears module caches between Jest cases. */
export function __resetPurchasesForTests(): void {
  sdk = null;
  sdkConfigured = false;
  livePackageById.clear();
  cachedCustomerInfo = null;
}

function loadSdk(): PurchasesSdk {
  if (!isLive()) {
    throw new Error('RevenueCat SDK load attempted outside live + paid monetization');
  }
  if (!sdk) {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    sdk = require('react-native-purchases').default as PurchasesSdk;
  }
  return sdk;
}

function resolveApiKey(): string {
  const ios = process.env.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY?.trim();
  const android = process.env.EXPO_PUBLIC_REVENUECAT_ANDROID_API_KEY?.trim();
  const fallback = process.env.EXPO_PUBLIC_REVENUECAT_API_KEY?.trim();
  const key =
    Platform.select({ ios: ios || fallback, android: android || fallback, default: fallback }) ??
    '';
  if (!key || key.startsWith('REPLACE_WITH_')) {
    throw new Error(
      'Missing EXPO_PUBLIC_REVENUECAT_API_KEY (or platform-specific keys). Copy .env.example → .env.local.'
    );
  }
  return key;
}

async function ensureConfigured(): Promise<PurchasesSdk> {
  const Purchases = loadSdk();
  if (!sdkConfigured) {
    Purchases.configure({ apiKey: resolveApiKey() });
    sdkConfigured = true;
  }
  return Purchases;
}

function mapPackages(offerings: PurchasesOfferings): OfferingPackage[] {
  livePackageById.clear();
  const current = offerings.current;
  if (!current) return [];
  return current.availablePackages.map((pkg) => {
    livePackageById.set(pkg.identifier, pkg);
    return {
      identifier: pkg.identifier,
      productId: pkg.product.identifier,
      title: pkg.product.title,
      description: pkg.product.description,
      price: pkg.product.priceString,
    };
  });
}

function mockPackages(): OfferingPackage[] {
  return [
    {
      identifier: 'monthly',
      productId: 'com.example.mobileapp.premium.monthly',
      title: 'Premium Monthly',
      description: 'Mock offering (PURCHASES_MODE=mock)',
      price: '$4.99',
    },
  ];
}

function entitlementActive(info: CustomerInfo | null, key: string): boolean {
  if (!info) return false;
  return key in info.entitlements.active;
}

function isUserCancelled(err: unknown): boolean {
  if (!err || typeof err !== 'object') return false;
  const e = err as { userCancelled?: boolean; code?: string };
  return e.userCancelled === true || e.code === 'PURCHASE_CANCELLED';
}

export async function getOfferings(): Promise<OfferingPackage[]> {
  if (!isPaid()) return [];
  if (!isLive()) return mockPackages();

  const Purchases = await ensureConfigured();
  try {
    const offerings = await Purchases.getOfferings();
    return mapPackages(offerings);
  } catch (err) {
    // Offline / store failure: return last-known packages if any, else rethrow.
    if (livePackageById.size > 0) {
      return [...livePackageById.values()].map((pkg) => ({
        identifier: pkg.identifier,
        productId: pkg.product.identifier,
        title: pkg.product.title,
        description: pkg.product.description,
        price: pkg.product.priceString,
      }));
    }
    throw err;
  }
}

export async function purchase(packageIdentifier: string): Promise<PurchaseResult> {
  if (!isPaid()) {
    return { ok: false, error: 'Purchases disabled (MONETIZATION=free)' };
  }
  if (!isLive()) {
    return { ok: true, productId: packageIdentifier };
  }

  const Purchases = await ensureConfigured();
  let pkg = livePackageById.get(packageIdentifier);
  if (!pkg) {
    await getOfferings();
    pkg = livePackageById.get(packageIdentifier);
  }
  if (!pkg) {
    return { ok: false, error: `Unknown package: ${packageIdentifier}` };
  }

  try {
    const result = await Purchases.purchasePackage(pkg);
    cachedCustomerInfo = result.customerInfo;
    return { ok: true, productId: result.productIdentifier };
  } catch (err) {
    if (isUserCancelled(err)) {
      return { ok: false, error: 'Purchase cancelled', cancelled: true };
    }
    const message = err instanceof Error ? err.message : 'Purchase failed';
    return { ok: false, error: message };
  }
}

export async function restore(): Promise<void> {
  if (!isPaid() || !isLive()) return;
  const Purchases = await ensureConfigured();
  cachedCustomerInfo = await Purchases.restorePurchases();
}

/**
 * Async entitlement check for non-React call sites (repos, share guards, etc.).
 */
export async function isEntitlementActive(key: string): Promise<boolean> {
  if (!isPaid()) return false;
  if (!isLive()) return MOCK_ENTITLED;

  try {
    const Purchases = await ensureConfigured();
    const info = await Purchases.getCustomerInfo();
    cachedCustomerInfo = info;
    return entitlementActive(info, key);
  } catch {
    return entitlementActive(cachedCustomerInfo, key);
  }
}

/**
 * Entitlement hook. Call sites identical across mock | live | free.
 */
export function useEntitlement(key: string): { active: boolean; isLoading: boolean } {
  const paid = isPaid();
  const live = isLive();

  const [liveActive, setLiveActive] = useState(() => entitlementActive(cachedCustomerInfo, key));
  const [liveLoading, setLiveLoading] = useState(true);

  useEffect(() => {
    if (!paid || !live) return;

    let cancelled = false;
    let listener: ((info: CustomerInfo) => void) | undefined;

    void (async () => {
      try {
        const Purchases = await ensureConfigured();
        const info = await Purchases.getCustomerInfo();
        if (cancelled) return;
        cachedCustomerInfo = info;
        setLiveActive(entitlementActive(info, key));

        listener = (updated) => {
          cachedCustomerInfo = updated;
          setLiveActive(entitlementActive(updated, key));
        };
        Purchases.addCustomerInfoUpdateListener(listener);
      } catch {
        if (!cancelled) {
          // Offline: fall back to last cached CustomerInfo if present.
          setLiveActive(entitlementActive(cachedCustomerInfo, key));
        }
      } finally {
        if (!cancelled) setLiveLoading(false);
      }
    })();

    return () => {
      cancelled = true;
      if (listener && sdk) {
        sdk.removeCustomerInfoUpdateListener(listener);
      }
    };
  }, [key, paid, live]);

  if (!paid) return { active: false, isLoading: false };
  if (!live) return { active: MOCK_ENTITLED, isLoading: false };
  return { active: liveActive, isLoading: liveLoading };
}
