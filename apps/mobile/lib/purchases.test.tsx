import {
  __resetPurchasesForTests,
  getOfferings,
  isPurchasesSdkLoaded,
  purchase,
  useEntitlement,
} from '@/lib/purchases';
import { renderHook, waitFor } from '@testing-library/react-native';

type TestConfig = {
  APP_CONFIG: {
    STORAGE: 'kv';
    MONETIZATION: 'free' | 'subscription' | 'one-time';
  };
  PURCHASES_MODE: 'mock' | 'live';
  MOCK_ENTITLED: boolean;
};

declare global {
  var __purchasesTestConfig: TestConfig;
}

jest.mock('@/lib/app-config', () => {
  const state: TestConfig = {
    APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'free' },
    PURCHASES_MODE: 'mock',
    MOCK_ENTITLED: true,
  };
  global.__purchasesTestConfig = state;
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

jest.mock('react-native-purchases', () => ({
  __esModule: true,
  default: {
    configure: jest.fn(),
    getOfferings: jest.fn(),
    purchasePackage: jest.fn(),
    restorePurchases: jest.fn(),
    getCustomerInfo: jest.fn(),
    addCustomerInfoUpdateListener: jest.fn(),
    removeCustomerInfoUpdateListener: jest.fn(),
  },
}));

function setConfig(partial: Partial<TestConfig> & { APP_CONFIG?: TestConfig['APP_CONFIG'] }) {
  const state = global.__purchasesTestConfig;
  if (partial.APP_CONFIG) state.APP_CONFIG = partial.APP_CONFIG;
  if (partial.PURCHASES_MODE !== undefined) state.PURCHASES_MODE = partial.PURCHASES_MODE;
  if (partial.MOCK_ENTITLED !== undefined) state.MOCK_ENTITLED = partial.MOCK_ENTITLED;
}

describe('purchases seam', () => {
  afterEach(() => {
    __resetPurchasesForTests();
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'free' },
      PURCHASES_MODE: 'mock',
      MOCK_ENTITLED: true,
    });
    jest.clearAllMocks();
    delete process.env.EXPO_PUBLIC_REVENUECAT_API_KEY;
  });

  it('free: useEntitlement inactive and SDK not loaded', async () => {
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'free' },
      MOCK_ENTITLED: true,
    });
    const { result } = renderHook(() => useEntitlement('premium'));
    expect(result.current.isLoading).toBe(false);
    expect(result.current.active).toBe(false);
    expect(await getOfferings()).toEqual([]);
    expect(isPurchasesSdkLoaded()).toBe(false);
  });

  it('subscription+mock: MOCK_ENTITLED=true unlocks without SDK', async () => {
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'subscription' },
      PURCHASES_MODE: 'mock',
      MOCK_ENTITLED: true,
    });
    const { result } = renderHook(() => useEntitlement('premium'));
    expect(result.current.isLoading).toBe(false);
    expect(result.current.active).toBe(true);
    expect(isPurchasesSdkLoaded()).toBe(false);

    const offerings = await getOfferings();
    expect(offerings.length).toBeGreaterThan(0);
    const bought = await purchase(offerings[0]!.identifier);
    expect(bought).toEqual({ ok: true, productId: offerings[0]!.identifier });
  });

  it('subscription+mock: MOCK_ENTITLED=false locks UI', () => {
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'subscription' },
      PURCHASES_MODE: 'mock',
      MOCK_ENTITLED: false,
    });
    const { result } = renderHook(() => useEntitlement('premium'));
    expect(result.current.isLoading).toBe(false);
    expect(result.current.active).toBe(false);
  });

  it('subscription+live: active when entitlement present', async () => {
    process.env.EXPO_PUBLIC_REVENUECAT_API_KEY = 'test_public_sdk_key';
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'subscription' },
      PURCHASES_MODE: 'live',
      MOCK_ENTITLED: false,
    });

    // eslint-disable-next-line @typescript-eslint/no-require-imports -- mock module
    const Purchases = require('react-native-purchases').default as {
      configure: jest.Mock;
      getCustomerInfo: jest.Mock;
    };
    Purchases.getCustomerInfo.mockResolvedValue({
      entitlements: { active: { premium: { identifier: 'premium' } } },
    });

    const { result } = renderHook(() => useEntitlement('premium'));
    await waitFor(() => expect(result.current.isLoading).toBe(false));
    expect(result.current.active).toBe(true);
    expect(Purchases.configure).toHaveBeenCalled();
    expect(isPurchasesSdkLoaded()).toBe(true);
  });

  it('subscription+live: inactive when entitlement missing', async () => {
    process.env.EXPO_PUBLIC_REVENUECAT_API_KEY = 'test_public_sdk_key';
    setConfig({
      APP_CONFIG: { STORAGE: 'kv', MONETIZATION: 'subscription' },
      PURCHASES_MODE: 'live',
      MOCK_ENTITLED: false,
    });

    // eslint-disable-next-line @typescript-eslint/no-require-imports -- mock module
    const Purchases = require('react-native-purchases').default as {
      getCustomerInfo: jest.Mock;
    };
    Purchases.getCustomerInfo.mockResolvedValue({
      entitlements: { active: {} },
    });

    const { result } = renderHook(() => useEntitlement('premium'));
    await waitFor(() => expect(result.current.isLoading).toBe(false));
    expect(result.current.active).toBe(false);
  });
});
