/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before the screen import */
import { fireEvent, render, screen, waitFor } from '@testing-library/react-native';
import React from 'react';

const mockToggleColorScheme = jest.fn();
const mockPush = jest.fn();

jest.mock('expo-router', () => {
  const React = require('react');
  return {
    Link: ({ children }: { children: React.ReactNode }) => <>{children}</>,
    Redirect: () => null,
    router: {
      push: (...args: unknown[]) => mockPush(...args),
    },
  };
});

jest.mock('nativewind', () => ({
  cssInterop: jest.fn(),
  useColorScheme: () => ({
    colorScheme: 'light',
    toggleColorScheme: mockToggleColorScheme,
    setColorScheme: jest.fn(),
  }),
}));

jest.mock('lucide-react-native', () => require('@/__tests__/test-utils').mockLucideIcons());

jest.mock('@/lib/storage', () => ({
  getJSON: jest.fn(async () => true),
  setJSON: jest.fn(async () => undefined),
  remove: jest.fn(async () => undefined),
}));

jest.mock('@/ui/text', () => require('@/__tests__/test-utils').mockUiText());
jest.mock('@/ui/icon', () => require('@/__tests__/test-utils').mockUiIcon());
jest.mock('@/ui/button', () => require('@/__tests__/test-utils').mockUiButton());

jest.mock('expo-linear-gradient', () => {
  const React = require('react');
  const { View } = require('react-native');
  return {
    LinearGradient: ({ children, ...props }: { children?: React.ReactNode }) => (
      <View {...props}>{children}</View>
    ),
  };
});

import HomeScreen from '@/app/(tabs)/index';
import { ThemeToggle } from '@/components/header-chrome';

describe('HomeScreen', () => {
  beforeEach(() => {
    mockToggleColorScheme.mockClear();
    mockPush.mockClear();
  });

  it('renders the home shell with settings entry', async () => {
    render(<HomeScreen />);
    await waitFor(() => {
      expect(screen.getByTestId('home-screen')).toBeTruthy();
    });
    expect(screen.getByTestId('link-settings')).toBeTruthy();
  });

  it('exposes accessibility labels for settings', async () => {
    render(<HomeScreen />);
    await waitFor(() => {
      expect(screen.getByTestId('home-screen')).toBeTruthy();
    });
    expect(screen.getByLabelText('Settings')).toBeTruthy();
  });

  it('navigates to settings from the grouped row', async () => {
    render(<HomeScreen />);
    await waitFor(() => {
      expect(screen.getByTestId('link-settings')).toBeTruthy();
    });
    fireEvent.press(screen.getByTestId('link-settings'));
    expect(mockPush).toHaveBeenCalledWith('/settings');
  });
});

describe('ThemeToggle', () => {
  beforeEach(() => {
    mockToggleColorScheme.mockClear();
  });

  // Regression: VoiceOver / Switch Control activation fires onPress, not onPressIn.
  it('toggles the theme via onPress (assistive-tech activation)', () => {
    render(<ThemeToggle />);
    fireEvent.press(screen.getByLabelText('Switch to dark theme'));
    expect(mockToggleColorScheme).toHaveBeenCalledTimes(1);
  });
});
