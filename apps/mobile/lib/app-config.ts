/**
 * Product capability flags. Set these once per app, near the start.
 * Defaults keep the shell simple: on-device KV storage, no monetization.
 */
export const APP_CONFIG = {
  /** 'kv' = expo-sqlite kv-store; 'sql' = full SQL via expo-sqlite */
  STORAGE: 'kv' as 'kv' | 'sql',
  /** All paid modes use RevenueCat. 'free' never loads the purchases SDK. */
  MONETIZATION: 'free' as 'free' | 'subscription' | 'one-time',
} as const;

/** Dev-only: drive entitlement state without any store/RevenueCat account. */
export const PURCHASES_MODE = 'mock' as 'mock' | 'live';

/** When PURCHASES_MODE is 'mock', flip to test locked/unlocked UI. */
export const MOCK_ENTITLED = true;
