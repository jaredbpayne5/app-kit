/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
import { Paywall } from '@/components/paywall';
import { render, screen, waitFor } from '@testing-library/react-native';

jest.mock('lucide-react-native', () => {
  const React = require('react');
  const { View } = require('react-native');
  const Stub = () => <View />;
  return { RefreshCw: Stub, Sparkles: Stub };
});

type TestConfig = {
  APP_CONFIG: {
    STORAGE: 'kv';
    MONETIZATION: 'free' | 'subscription' | 'one-time';
  };
  PURCHASES_MODE: 'mock' | 'live';
  MOCK_ENTITLED: boolean;
};

declare global {
  var __paywallTestConfig: TestConfig;
}

jest.mock('@/lib/app-config', () => {
  const state: TestConfig = {
    APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'free' },
    PURCHASES_MODE: 'mock',
    MOCK_ENTITLED: true,
  };
  global.__paywallTestConfig = state;
  return {
    get APP_CONFIG() {
      return state.APP_CONFIG;
    },
    get PURCHASES_MODE() {
      return state.PURCHASES_MODE;
    },
    get MOCK_ENTITLED() {
      return state.MOCK_ENTITLED;
    },
  };
});

jest.mock('@/lib/purchases', () => ({
  getOfferings: jest.fn(async () => [
    {
      identifier: 'monthly',
      productId: 'com.example.mobileapp.premium.monthly',
      title: 'Premium Monthly',
      description: 'Mock',
      price: '$4.99',
    },
  ]),
  purchase: jest.fn(),
  restore: jest.fn(),
}));

describe('Paywall', () => {
  afterEach(() => {
    global.__paywallTestConfig.APP_CONFIG = {
      STORAGE: 'kv',
      MONETIZATION: 'free',
    };
  });

  it('renders nothing when MONETIZATION is free', () => {
    global.__paywallTestConfig.APP_CONFIG = {
      STORAGE: 'kv',
      MONETIZATION: 'free',
    };
    const { toJSON } = render(<Paywall />);
    expect(toJSON()).toBeNull();
    expect(screen.queryByTestId('paywall')).toBeNull();
  });

  it('shows paywall and mock offering when subscription', async () => {
    global.__paywallTestConfig.APP_CONFIG = {
      STORAGE: 'kv',
      MONETIZATION: 'subscription',
    };
    render(<Paywall />);
    await waitFor(() => expect(screen.getByTestId('paywall')).toBeTruthy());
    expect(screen.getByTestId('plan-card-monthly')).toBeTruthy();
    expect(screen.getByTestId('plan-card-annual')).toBeTruthy();
    expect(screen.getByLabelText(/Monthly plan/)).toBeTruthy();
    expect(screen.getByLabelText('Restore purchases')).toBeTruthy();
  });
});
