/* eslint-disable import/first -- expo-constants mock must run before the module import */
import { Platform } from 'react-native';

const expoConfig: {
  android?: { versionCode?: number };
  ios?: { buildNumber?: string };
} = {};

jest.mock('expo-constants', () => ({
  __esModule: true,
  default: {
    get expoConfig() {
      return expoConfig;
    },
  },
}));

import { getNativeBuildNumber } from '@/lib/app-version';

function setPlatformOS(os: typeof Platform.OS) {
  Object.defineProperty(Platform, 'OS', { configurable: true, value: os });
}

const divergent = {
  android: { versionCode: 7 },
  ios: { buildNumber: '12' },
};

describe('getNativeBuildNumber', () => {
  afterEach(() => {
    expoConfig.android = undefined;
    expoConfig.ios = undefined;
    setPlatformOS('ios');
  });

  it('returns the iOS build number on iOS when both platforms are present', () => {
    Object.assign(expoConfig, divergent);
    setPlatformOS('ios');
    expect(getNativeBuildNumber()).toBe('12');
  });

  it('returns the Android versionCode on Android when both platforms are present', () => {
    Object.assign(expoConfig, divergent);
    setPlatformOS('android');
    expect(Platform.OS).toBe('android');
    expect(getNativeBuildNumber()).toBe('7');
  });

  it('returns null on iOS when ios.buildNumber is missing (does not use android)', () => {
    expoConfig.android = { versionCode: 7 };
    setPlatformOS('ios');
    expect(getNativeBuildNumber()).toBeNull();
  });

  it('returns null on Android when android.versionCode is missing (does not use ios)', () => {
    expoConfig.ios = { buildNumber: '12' };
    setPlatformOS('android');
    expect(Platform.OS).toBe('android');
    expect(getNativeBuildNumber()).toBeNull();
  });
});
