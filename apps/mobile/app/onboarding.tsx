import { Button } from '@/ui/button';
import { Text } from '@/ui/text';
import { getAppDisplayName } from '@/lib/app-version';
import { markOnboardingSeen } from '@/lib/onboarding';
import { reportError } from '@/lib/report-error';
import { useCallback, useRef, useState } from 'react';
import {
  Alert,
  Dimensions,
  FlatList,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
  View,
  type ViewToken,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type Slide = {
  key: string;
  title: string;
  body: string;
};

/** Onboarding slides — replace with product-specific welcome, how-it-works, and CTA copy. */
function slidesForApp(appName: string): Slide[] {
  return [
    {
      key: 'welcome',
      title: `Welcome to ${appName}`,
      body: "A short welcome. Replace this with your product's value proposition.",
    },
    {
      key: 'how',
      title: 'How it works',
      body: 'Describe the core loop in one short sentence.',
    },
    {
      key: 'ready',
      title: 'You are ready',
      body: 'Point people at the first action in the app.',
    },
  ];
}

const { width: PAGE_WIDTH } = Dimensions.get('window');
const VIEWABILITY_CONFIG = { viewAreaCoveragePercentThreshold: 60 };

export default function OnboardingScreen() {
  const appName = getAppDisplayName();
  const slides = slidesForApp(appName);
  const listRef = useRef<FlatList<Slide>>(null);
  const [index, setIndex] = useState(0);
  const insets = useSafeAreaInsets();

  async function finish() {
    try {
      // The root gate reacts to this and swaps the protected route to (tabs);
      // no manual navigation needed.
      await markOnboardingSeen();
    } catch (error) {
      reportError(error, { scope: 'onboarding.finish' });
      Alert.alert('Couldn’t finish onboarding', 'Please try again.');
    }
  }

  function onContinue() {
    if (index >= slides.length - 1) {
      void finish();
      return;
    }
    const next = index + 1;
    listRef.current?.scrollToIndex({ index: next, animated: true });
    setIndex(next);
  }

  const onViewableItemsChanged = useCallback(
    ({ viewableItems }: { viewableItems: ViewToken[] }) => {
      const first = viewableItems[0];
      if (first?.index != null) setIndex(first.index);
    },
    []
  );

  const viewabilityConfig = VIEWABILITY_CONFIG;

  return (
    <View
      className="flex-1 bg-background"
      style={{ paddingTop: insets.top }} /* native-required: dynamic inset */
      testID="onboarding-screen">
      <FlatList
        ref={listRef}
        data={slides}
        keyExtractor={(item) => item.key}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onViewableItemsChanged={onViewableItemsChanged}
        viewabilityConfig={viewabilityConfig}
        onMomentumScrollEnd={(e: NativeSyntheticEvent<NativeScrollEvent>) => {
          const next = Math.round(e.nativeEvent.contentOffset.x / PAGE_WIDTH);
          setIndex(next);
        }}
        renderItem={({ item, index: i }) => (
          <View
            style={{ width: PAGE_WIDTH }} /* native-required: pager page width */
            className="flex-1 justify-center gap-3 px-8"
            testID={`onboarding-slide-${i}`}>
            <Text variant="h3">{item.title}</Text>
            <Text variant="muted">{item.body}</Text>
          </View>
        )}
      />

      <View
        className="flex-row items-center justify-center gap-2 pb-2"
        accessible
        accessibilityRole="progressbar"
        accessibilityLabel={`Slide ${index + 1} of ${slides.length}`}
        accessibilityValue={{ min: 1, max: slides.length, now: index + 1 }}>
        {slides.map((s, i) => (
          <View
            key={s.key}
            className={`h-2 w-2 rounded-full ${i === index ? 'bg-primary' : 'bg-muted'}`}
          />
        ))}
      </View>

      <View
        className="gap-3 px-6 pt-2"
        style={{ paddingBottom: insets.bottom + 24 }} /* native-required: dynamic inset */
      >
        <Button
          testID="btn-onboarding-continue"
          accessibilityLabel={index >= slides.length - 1 ? 'Get started' : 'Continue'}
          onPress={onContinue}>
          <Text>{index >= slides.length - 1 ? 'Get started' : 'Continue'}</Text>
        </Button>
        <Button
          variant="ghost"
          testID="btn-onboarding-skip"
          accessibilityLabel="Skip onboarding"
          onPress={() => void finish()}>
          <Text>Skip</Text>
        </Button>
      </View>
    </View>
  );
}
