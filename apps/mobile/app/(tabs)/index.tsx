// Demo screen — replace this with your product's home.
//
// The onboarding gate deliberately does NOT live here. It is in
// `app/_layout.tsx` via `Stack.Protected`, so replacing this file cannot
// silently remove onboarding. Do not move gating logic back into a screen.
import { BrandAtmosphere } from '@/components/brand-atmosphere';
import { GroupedRow, GroupedSection } from '@/components/grouped';
import { getAppDisplayName } from '@/lib/app-version';
import { FadeSlideIn } from '@/ui/motion';
import { Text } from '@/ui/text';
import { router } from 'expo-router';
import { View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export default function HomeScreen() {
  const appName = getAppDisplayName();
  const insets = useSafeAreaInsets();

  return (
    <View
      className="flex-1 bg-grouped"
      style={{ paddingBottom: Math.max(insets.bottom, 0) }}
      testID="home-screen">
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
