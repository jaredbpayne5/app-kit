/**
 * Paywall plan slots — generic template defaults.
 *
 * Products replace titles/prices/benefits with their own copy. Slots render
 * before RevenueCat resolves; store localized prices win when a package matches.
 */
import type { OfferingPackage } from '@/lib/purchases';

export type PaywallPlanKey = 'annual' | 'monthly' | 'weekly';

export type PaywallPlan = {
  key: PaywallPlanKey;
  title: string;
  /** Placeholder price until the store reports a localized price. */
  price: string;
  period: string;
  note: string;
  fallbackPackageId: string;
  /** Visually anchored as the primary card. */
  anchored: boolean;
};

export type ResolvedPlan = PaywallPlan & {
  packageIdentifier: string;
  fromStore: boolean;
};

export const TRIAL_COPY = 'Free trial available on some plans. Cancel anytime before it ends.';

export const PREMIUM_BENEFITS = [
  'Unlock premium features for this app',
  'Restore purchases on any device signed into the same store account',
];

export const PAYWALL_PLANS: PaywallPlan[] = [
  {
    key: 'annual',
    title: 'Annual',
    price: '$39.99',
    period: 'per year',
    note: 'Best value',
    fallbackPackageId: 'annual',
    anchored: true,
  },
  {
    key: 'monthly',
    title: 'Monthly',
    price: '$4.99',
    period: 'per month',
    note: 'Flexible month to month',
    fallbackPackageId: 'monthly',
    anchored: false,
  },
];

const PLAN_PATTERNS: Record<PaywallPlanKey, RegExp> = {
  annual: /annual|yearly|(^|[^a-z])year|12.?month/i,
  monthly: /monthly|(^|[^a-z])month/i,
  weekly: /weekly|(^|[^a-z])week/i,
};

/**
 * Fill plan slots from store offerings. A package can only fill one slot.
 */
export function resolvePaywallPlans(packages: OfferingPackage[]): {
  plans: ResolvedPlan[];
  others: OfferingPackage[];
} {
  const remaining = [...packages];

  const plans = PAYWALL_PLANS.map<ResolvedPlan>((plan) => {
    const pattern = PLAN_PATTERNS[plan.key];
    const index = remaining.findIndex(
      (pkg) => pattern.test(pkg.identifier) || pattern.test(pkg.productId)
    );

    if (index === -1) {
      return { ...plan, packageIdentifier: plan.fallbackPackageId, fromStore: false };
    }

    const [match] = remaining.splice(index, 1);
    return {
      ...plan,
      packageIdentifier: match.identifier,
      price: match.price || plan.price,
      fromStore: true,
    };
  });

  return { plans, others: remaining };
}
