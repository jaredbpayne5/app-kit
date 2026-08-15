/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
import { Paywall } from '@/components/paywall';
import { restore } from '@/lib/purchases';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react-native';

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
  restore: jest.fn(async () => ({ ok: true, restored: false })),
}));

jest.mock('expo-web-browser', () => ({
  openBrowserAsync: jest.fn(),
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
    expect(screen.getByTestId('paywall-link-privacy')).toBeTruthy();
    expect(screen.getByTestId('paywall-link-terms')).toBeTruthy();
  });

  async function pressRestore() {
    global.__paywallTestConfig.APP_CONFIG = {
      STORAGE: 'kv',
      MONETIZATION: 'subscription',
    };
    render(<Paywall />);
    await waitFor(() => expect(screen.getByLabelText('Restore purchases')).toBeTruthy());
    await act(async () => {
      fireEvent.press(screen.getByLabelText('Restore purchases'));
    });
  }

  it('shows the restore() error text when restore() returns ok:false', async () => {
    (restore as jest.Mock).mockResolvedValueOnce({
      ok: false,
      error:
        'Missing EXPO_PUBLIC_REVENUECAT_API_KEY (or platform-specific keys). Copy .env.example → .env.local.',
    });
    await pressRestore();
    await waitFor(() =>
      expect(screen.getByText(/Missing EXPO_PUBLIC_REVENUECAT_API_KEY/)).toBeTruthy()
    );
  });

  it('shows Restore failed when restore() returns ok:false with an empty error', async () => {
    (restore as jest.Mock).mockResolvedValueOnce({ ok: false, error: '' });
    await pressRestore();
    await waitFor(() => expect(screen.getByText('Restore failed')).toBeTruthy());
  });

  it('shows Restore complete when restore() returns entitlements', async () => {
    (restore as jest.Mock).mockResolvedValueOnce({ ok: true, restored: true });
    await pressRestore();
    await waitFor(() => expect(screen.getByText('Restore complete.')).toBeTruthy());
  });

  it('shows No purchases to restore when restore() succeeds with nothing', async () => {
    (restore as jest.Mock).mockResolvedValueOnce({ ok: true, restored: false });
    await pressRestore();
    await waitFor(() => expect(screen.getByText('No purchases to restore.')).toBeTruthy());
  });
});
