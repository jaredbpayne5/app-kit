import { resolvePaywallPlans, type PaywallPlan, PAYWALL_PLANS } from '@/lib/paywall-plans';
import type { OfferingPackage } from '@/lib/purchases';

describe('resolvePaywallPlans', () => {
  it('keeps default plan slots when offerings are empty', () => {
    const { plans, others } = resolvePaywallPlans([]);
    expect(plans).toHaveLength(PAYWALL_PLANS.length);
    expect(plans.every((p) => !p.fromStore)).toBe(true);
    expect(others).toEqual([]);
  });

  it('matches annual package and leaves others', () => {
    const offerings: OfferingPackage[] = [
      {
        identifier: '$rc_annual',
        productId: 'com.example.premium.annual',
        title: 'Annual',
        description: 'Yearly',
        price: '$29.99',
      },
      {
        identifier: 'lifetime',
        productId: 'com.example.premium.lifetime',
        title: 'Lifetime',
        description: 'Once',
        price: '$99.99',
      },
    ];
    const { plans, others } = resolvePaywallPlans(offerings);
    const annual = plans.find((p) => p.key === 'annual')!;
    expect(annual.fromStore).toBe(true);
    expect(annual.price).toBe('$29.99');
    expect(annual.packageIdentifier).toBe('$rc_annual');
    expect(others.map((o) => o.identifier)).toEqual(['lifetime']);
  });

  it('exports at least one anchored plan', () => {
    expect(PAYWALL_PLANS.some((p: PaywallPlan) => p.anchored)).toBe(true);
  });
});
