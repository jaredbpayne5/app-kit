import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { PAYWALL_PLANS } from '@/lib/paywall-plans';

type StoreKitSubscription = {
  productID?: string;
  internalID?: string;
  recurringSubscriptionPeriod?: string;
};

type StoreKitFile = {
  subscriptionGroups?: {
    subscriptions?: StoreKitSubscription[];
  }[];
};

function loadStoreKit(): StoreKitFile {
  const raw = readFileSync(join(__dirname, '..', 'store', 'storekit', 'Products.storekit'), 'utf8');
  return JSON.parse(raw) as StoreKitFile;
}

function collectSubscriptions(sk: StoreKitFile): StoreKitSubscription[] {
  return (sk.subscriptionGroups ?? []).flatMap((group) => group.subscriptions ?? []);
}

describe('PAYWALL_PLANS vs Products.storekit', () => {
  const subscriptions = collectSubscriptions(loadStoreKit());
  const productIDs = subscriptions
    .map((sub) => sub.productID)
    .filter((id): id is string => Boolean(id));

  it.each(PAYWALL_PLANS)('has a productID ending in .$fallbackPackageId (plan $key)', (plan) => {
    expect(productIDs.some((id) => id.endsWith(`.${plan.fallbackPackageId}`))).toBe(true);
  });

  it('has unique productIDs', () => {
    expect(new Set(productIDs).size).toBe(productIDs.length);
  });

  it('has unique internalIDs', () => {
    const internalIDs = subscriptions
      .map((sub) => sub.internalID)
      .filter((id): id is string => Boolean(id));
    expect(new Set(internalIDs).size).toBe(internalIDs.length);
  });

  it('gives the annual product a P1Y period', () => {
    const annual = subscriptions.find((sub) => sub.productID?.endsWith('.annual'));
    expect(annual?.recurringSubscriptionPeriod).toBe('P1Y');
  });
});
