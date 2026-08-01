/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before the screen import */
import { render, screen } from '@testing-library/react-native';
import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';

jest.mock('expo-router', () => ({
  router: { replace: jest.fn() },
}));

jest.mock('@/lib/app-version', () => ({
  getAppDisplayName: () => 'Smoke App',
}));

jest.mock('@/lib/storage', () => ({
  setJSON: jest.fn(async () => undefined),
}));

jest.mock('@/ui/button', () => {
  const React = require('react');
  const { Pressable } = require('react-native');
  return {
    Button: ({
      children,
      testID,
      ...props
    }: {
      children?: React.ReactNode;
      testID?: string;
      accessibilityLabel?: string;
    }) => (
      <Pressable testID={testID} {...props}>
        {children}
      </Pressable>
    ),
  };
});

jest.mock('@/ui/text', () => {
  const React = require('react');
  const { Text } = require('react-native');
  return {
    Text: ({ children, ...props }: { children?: React.ReactNode }) => (
      <Text {...props}>{children}</Text>
    ),
  };
});

import OnboardingScreen from '@/app/onboarding';

function renderOnboarding() {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 0, left: 0, right: 0, bottom: 0 },
      }}>
      <OnboardingScreen />
    </SafeAreaProvider>
  );
}

describe('OnboardingScreen a11y', () => {
  it('labels continue, skip, and slide progress', () => {
    renderOnboarding();
    expect(screen.getByLabelText('Continue')).toBeTruthy();
    expect(screen.getByLabelText('Skip onboarding')).toBeTruthy();
    expect(screen.getByLabelText('Slide 1 of 3')).toBeTruthy();
  });
});
