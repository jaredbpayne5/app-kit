import '../global.css';

import { initNotificationHandler } from '@/lib/local-notifications';
import { useOnboardingGate } from '@/lib/onboarding';
import { initSentryIfConfigured, wrapRoot } from '@/lib/sentry';
import { NAV_THEME } from '@/lib/theme';
import { BottomSheetModalProvider } from '@gorhom/bottom-sheet';
import { PortalHost } from '@rn-primitives/portal';
import { Stack } from 'expo-router';
import { ThemeProvider } from 'expo-router/react-navigation';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useColorScheme } from 'nativewind';
import { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

// Dormant until EXPO_PUBLIC_SENTRY_DSN is non-empty — no SDK load / no network.
const sentryActive = initSentryIfConfigured();

// Eager: a reminder scheduled earlier can fire before any screen calls the
// seam. Registers the foreground handler only — does not request permission.
initNotificationHandler();

// Hold the splash while the onboarding gate resolves, so the first frame is the
// correct destination rather than a blank view that then redirects.
SplashScreen.preventAutoHideAsync().catch(() => {
  // Already hidden (fast refresh, web) — not fatal.
});

/**
 * Onboarding gate. Lives here — at the root — on purpose.
 *
 * `Stack.Protected` removes the unreachable route from the navigator entirely,
 * so this also covers deep links: a link straight to /library cannot skip
 * onboarding, which a screen-level redirect could not prevent.
 */
function RootNavigator() {
  const { ready, seen } = useOnboardingGate();

  useEffect(() => {
    if (!ready) return;
    SplashScreen.hideAsync().catch(() => {
      // Already hidden — not fatal.
    });
  }, [ready]);

  // Splash is still up; rendering the navigator now would flash the wrong route.
  if (!ready) return null;

  return (
    <Stack>
      <Stack.Protected guard={seen}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      </Stack.Protected>
      <Stack.Protected guard={!seen}>
        <Stack.Screen name="onboarding" options={{ headerShown: false }} />
      </Stack.Protected>
    </Stack>
  );
}

function RootLayout() {
  const { colorScheme } = useColorScheme();

  return (
    <GestureHandlerRootView style={{ flex: 1 }} /* native-required: RNGH root */>
      <SafeAreaProvider>
        <ThemeProvider value={NAV_THEME[colorScheme ?? 'light']}>
          <BottomSheetModalProvider>
            <StatusBar style={colorScheme === 'dark' ? 'light' : 'dark'} />
            <RootNavigator />
            <PortalHost />
          </BottomSheetModalProvider>
        </ThemeProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

export default sentryActive ? wrapRoot(RootLayout) : RootLayout;
