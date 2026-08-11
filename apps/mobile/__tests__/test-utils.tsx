/* eslint-disable @typescript-eslint/no-require-imports -- these run inside jest.mock factories, before imports */
/**
 * Shared Jest mocks for the `ui/` primitives.
 *
 * Screen tests stub the primitives rather than rendering NativeWind's real
 * `Text`/`Button`, so assertions target the screen's own structure. Those stubs
 * were duplicated verbatim in every test file; they live here instead.
 *
 * Not collected by Jest — `testMatch` only picks up `*.test.ts(x)`.
 *
 * Call from inside a mock factory so it runs after hoisting:
 *
 *   jest.mock('@/ui/text', () => require('@/__tests__/test-utils').mockUiText());
 */
import { render } from '@testing-library/react-native';
import type { ReactElement, ReactNode } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';

type StubProps = Record<string, unknown> & { children?: ReactNode };

/**
 * Render a screen inside a `SafeAreaProvider` with deterministic metrics.
 *
 * `useSafeAreaInsets` throws without a provider, and design-lint requires every
 * screen that paints UI to use it — so screen tests need this wrapper.
 */
export function renderWithSafeArea(ui: ReactElement) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, left: 0, right: 0, bottom: 34 },
      }}>
      {ui}
    </SafeAreaProvider>
  );
}

/** `ui/text` -> React Native `Text`, forwarding testID/accessibility props. */
export function mockUiText() {
  const React = require('react');
  const { Text } = require('react-native');
  return {
    Text: ({ children, ...props }: StubProps) => <Text {...props}>{children}</Text>,
  };
}

/** `ui/button` -> `Pressable`, forwarding onPress/testID/accessibility props. */
export function mockUiButton() {
  const React = require('react');
  const { Pressable } = require('react-native');
  return {
    Button: ({ children, ...props }: StubProps) => <Pressable {...props}>{children}</Pressable>,
  };
}

/** `ui/icon` -> an empty `View`, optionally tagged for querying. */
export function mockUiIcon(testID?: string) {
  const React = require('react');
  const { View } = require('react-native');
  return {
    Icon: () => <View testID={testID} />,
  };
}

/**
 * `lucide-react-native` -> a stub for any icon name.
 *
 * A Proxy rather than an enumerated list, so adding an icon to a component
 * doesn't fail unrelated tests with an undefined-component error.
 */
export function mockLucideIcons() {
  const React = require('react');
  const { View } = require('react-native');
  const Stub = () => <View />;
  return new Proxy(
    {},
    {
      get: (_target, property) => {
        // Keep Babel's interop on the CommonJS path so named imports read
        // straight off this object instead of looking for `.default`.
        if (property === '__esModule') return false;
        if (typeof property === 'symbol') return undefined;
        return Stub;
      },
    }
  );
}
