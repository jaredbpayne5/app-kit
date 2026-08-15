import { Button } from '@/ui/button';
import { Icon } from '@/ui/icon';
import { Text } from '@/ui/text';
import { APP_CONFIG } from '@/lib/app-config';
import { getAppDisplayName } from '@/lib/app-version';
import {
  PREMIUM_BENEFITS,
  TRIAL_COPY,
  resolvePaywallPlans,
  type ResolvedPlan,
} from '@/lib/paywall-plans';
import { getOfferings, purchase, restore } from '@/lib/purchases';
import { PRIVACY_URL, TERMS_URL } from '@/lib/product';
import { reportError } from '@/lib/report-error';
import * as WebBrowser from 'expo-web-browser';
import { RefreshCw, Sparkles } from 'lucide-react-native';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, View } from 'react-native';

type PaywallProps = {
  /** Called after a successful purchase. */
  onPurchased?: (productId: string) => void;
};

const BENEFIT_ICONS = [Sparkles, RefreshCw] as const;

/**
 * Plans from getOfferings() when MONETIZATION is paid; renders nothing when `free`.
 * Includes restore-purchases (App Review requirement for paid apps).
 */
export function Paywall(props: PaywallProps) {
  if (APP_CONFIG.MONETIZATION === 'free') {
    return null;
  }
  return <PaywallPaid {...props} />;
}

function PaywallPaid({ onPurchased }: PaywallProps) {
  const [packages, setPackages] = useState<Awaited<ReturnType<typeof getOfferings>>>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [offeringsError, setOfferingsError] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const list = await getOfferings();
        if (!cancelled) setPackages(list);
      } catch (err) {
        reportError(err, { screen: 'paywall', action: 'getOfferings' });
        if (!cancelled) setOfferingsError(true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function onBuy(packageIdentifier: string) {
    setBusy(true);
    setMessage(null);
    try {
      const result = await purchase(packageIdentifier);
      if (!result.ok) {
        if (!result.cancelled) setMessage(result.error);
        return;
      }
      onPurchased?.(result.productId);
      setMessage('Purchase complete.');
    } catch (err) {
      reportError(err, { screen: 'paywall', action: 'purchase', packageIdentifier });
      setMessage(err instanceof Error ? err.message : 'Purchase failed');
    } finally {
      setBusy(false);
    }
  }

  async function onRestore() {
    setBusy(true);
    setMessage(null);
    try {
      const result = await restore();
      if (!result.ok) {
        setMessage(result.error || 'Restore failed');
        return;
      }
      setMessage(result.restored ? 'Restore complete.' : 'No purchases to restore.');
    } catch (err) {
      reportError(err, { screen: 'paywall', action: 'restore' });
      setMessage(err instanceof Error ? err.message : 'Restore failed');
    } finally {
      setBusy(false);
    }
  }

  const { plans, others } = resolvePaywallPlans(packages);
  const hasUnconfirmedPrice = plans.some((plan) => !plan.fromStore);
  const appName = getAppDisplayName();

  return (
    <View className="gap-4" testID="paywall">
      <View className="gap-1">
        <Text variant="large">{appName} Premium</Text>
        <Text variant="muted" testID="paywall-trial">
          {TRIAL_COPY}
        </Text>
      </View>

      <View className="gap-2" testID="paywall-benefits">
        {PREMIUM_BENEFITS.map((benefit, index) => (
          <View key={benefit} className="flex-row items-start gap-2.5">
            <Icon as={BENEFIT_ICONS[index] ?? Sparkles} className="mt-0.5 size-4 text-primary" />
            <Text variant="small" className="flex-1 text-muted-foreground">
              {benefit}
            </Text>
          </View>
        ))}
      </View>

      {plans.map((plan) => (
        <PlanCard
          key={plan.key}
          plan={plan}
          disabled={busy || loading}
          onPress={() => void onBuy(plan.packageIdentifier)}
        />
      ))}

      {loading ? (
        <ActivityIndicator testID="paywall-loading" accessibilityLabel="Loading plans" />
      ) : null}

      {!loading && offeringsError ? (
        <Text variant="small" className="text-destructive" testID="paywall-offerings-error">
          Couldn’t reach the store for current plans. Check your connection and reopen this screen —
          nothing is charged until the store confirms the price.
        </Text>
      ) : null}

      {!loading && hasUnconfirmedPrice ? (
        <Text variant="small" className="text-muted-foreground" testID="paywall-empty">
          Prices the store hasn’t confirmed yet are estimates. The App Store or Play Store always
          confirms the final price before you pay.
        </Text>
      ) : null}

      {others.length > 0 ? (
        <View className="gap-2" testID="paywall-other-plans">
          <Text variant="small" className="font-semibold uppercase text-muted-foreground">
            Other plans
          </Text>
          {others.map((pkg) => (
            <Button
              key={pkg.identifier}
              variant="outline"
              testID={`btn-buy-${pkg.identifier}`}
              accessibilityLabel={`Buy ${pkg.title || pkg.identifier}${pkg.price ? ` — ${pkg.price}` : ''}`}
              disabled={busy || loading}
              onPress={() => void onBuy(pkg.identifier)}>
              <Text>
                {pkg.title || pkg.identifier}
                {pkg.price ? ` — ${pkg.price}` : ''}
              </Text>
            </Button>
          ))}
        </View>
      ) : null}

      <Pressable
        testID="btn-restore-purchases"
        accessibilityRole="button"
        accessibilityLabel="Restore purchases"
        disabled={busy}
        onPress={() => void onRestore()}>
        <Text className="text-center text-primary">Restore purchases</Text>
      </Pressable>

      <View className="flex-row justify-center gap-4">
        <Pressable
          testID="paywall-link-privacy"
          accessibilityRole="link"
          accessibilityLabel="Privacy Policy"
          onPress={() => {
            void WebBrowser.openBrowserAsync(PRIVACY_URL);
          }}>
          <Text variant="small" className="text-muted-foreground underline">
            Privacy Policy
          </Text>
        </Pressable>
        <Pressable
          testID="paywall-link-terms"
          accessibilityRole="link"
          accessibilityLabel="Terms of Use"
          onPress={() => {
            void WebBrowser.openBrowserAsync(TERMS_URL);
          }}>
          <Text variant="small" className="text-muted-foreground underline">
            Terms of Use
          </Text>
        </Pressable>
      </View>

      {message ? (
        <Text variant="muted" testID="paywall-message">
          {message}
        </Text>
      ) : null}
    </View>
  );
}

function PlanCard({
  plan,
  disabled,
  onPress,
}: {
  plan: ResolvedPlan;
  disabled: boolean;
  onPress: () => void;
}) {
  const label = `${plan.title} plan, ${plan.price} ${plan.period}${
    plan.anchored ? ', best value' : ''
  }`;

  if (plan.anchored) {
    return (
      <View
        className="gap-2 rounded-xl border border-primary/40 bg-primary/5 p-4"
        testID={`plan-card-${plan.key}`}>
        <View className="flex-row items-center justify-between">
          <Text variant="large">{plan.title}</Text>
          <View className="rounded-md bg-accent px-2.5 py-1" testID="plan-badge-best-value">
            <Text variant="small" className="font-semibold text-accent-foreground">
              Best value
            </Text>
          </View>
        </View>
        <Text className="text-[22px] font-semibold text-foreground">{plan.price}</Text>
        <Text variant="muted">{plan.period}</Text>
        <Text variant="small" className="text-muted-foreground">
          {plan.note}
        </Text>
        <Button
          testID={`btn-buy-${plan.packageIdentifier}`}
          accessibilityLabel={label}
          disabled={disabled}
          onPress={onPress}>
          <Text>Continue</Text>
        </Button>
      </View>
    );
  }

  return (
    <Pressable
      testID={`plan-card-${plan.key}`}
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled}
      className="gap-1 rounded-xl border border-border bg-card p-4 active:bg-muted/40"
      onPress={onPress}>
      <View className="flex-row items-center justify-between">
        <Text variant="large">{plan.title}</Text>
        <Text variant="large">{plan.price}</Text>
      </View>
      <Text variant="muted">{plan.period}</Text>
      <Text variant="small" className="text-muted-foreground">
        {plan.note}
      </Text>
    </Pressable>
  );
}
