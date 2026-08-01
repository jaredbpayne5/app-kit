import { BrandAtmosphere } from '@/components/brand-atmosphere';
import { GroupedRow, GroupedSection } from '@/components/grouped';
import { ONBOARDING_STORAGE_KEY } from '@/lib/onboarding';
import { reportError } from '@/lib/report-error';
import { getJSON } from '@/lib/storage';
import { FadeSlideIn } from '@/ui/motion';
import { Text } from '@/ui/text';
import { Redirect, router } from 'expo-router';
import { useEffect, useState } from 'react';
import { View } from 'react-native';

export default function HomeScreen() {
  const appName = process.env.EXPO_PUBLIC_APP_NAME ?? 'App Template';
  const [onboardingReady, setOnboardingReady] = useState(false);
  const [onboardingSeen, setOnboardingSeen] = useState(true);

  useEffect(() => {
    let mounted = true;
    void (async () => {
      try {
        const seen = await getJSON<boolean>(ONBOARDING_STORAGE_KEY);
        if (!mounted) return;
        setOnboardingSeen(seen === true);
      } catch (error) {
        reportError(error, { scope: 'home.onboardingGate' });
        // Fail open to onboarding so cold start never blank-screens forever.
        if (!mounted) return;
        setOnboardingSeen(false);
      } finally {
        if (mounted) setOnboardingReady(true);
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  if (!onboardingReady) {
    return (
      <View
        className="flex-1 bg-grouped"
        testID="home-loading"
        accessibilityLabel="Loading"
        accessibilityRole="progressbar"
        accessibilityState={{ busy: true }}
      />
    );
  }

  if (!onboardingSeen) {
    return <Redirect href="/onboarding" />;
  }

  return (
    <View className="flex-1 bg-grouped" testID="home-screen">
      <BrandAtmosphere intensity="soft" />
      <FadeSlideIn className="flex-1 justify-center gap-6 p-6">
        <View className="gap-2">
          <Text variant="h3" className="text-center">
            {appName}
          </Text>
          <Text variant="muted" className="text-center">
            Local-first Expo starter. Replace this screen with your product.
          </Text>
        </View>
        <GroupedSection header="Get started" footer="Everything here runs on-device.">
          <GroupedRow
            label="Library"
            subtitle="FlashList, bottom sheet, and on-device storage"
            showChevron
            testID="link-library"
            onPress={() => router.push('/library')}
          />
          <GroupedRow
            label="Settings"
            subtitle="Version, legal, and premium"
            showChevron
            last
            testID="link-settings"
            onPress={() => router.push('/settings')}
          />
        </GroupedSection>
      </FadeSlideIn>
    </View>
  );
}
