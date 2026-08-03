/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before the screen import */
import { render, screen } from '@testing-library/react-native';
import React from 'react';

jest.mock('expo-router', () => {
  const React = require('react');
  return {
    Link: ({ children }: { children: React.ReactNode }) => <>{children}</>,
    Stack: {
      Screen: () => null,
    },
  };
});

jest.mock('@/ui/button', () => require('@/__tests__/test-utils').mockUiButton());
jest.mock('@/ui/text', () => require('@/__tests__/test-utils').mockUiText());

import NotFoundScreen from '@/app/+not-found';

describe('NotFoundScreen', () => {
  it('renders a labeled home link', () => {
    render(<NotFoundScreen />);
    expect(screen.getByTestId('not-found-screen')).toBeTruthy();
    expect(screen.getByLabelText('Go to home screen')).toBeTruthy();
  });
});
