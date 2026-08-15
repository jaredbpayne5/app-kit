/**
 * Secure storage seam — tokens and secrets only.
 *
 * Regular app data goes through `lib/storage.ts` (on-device KV/SQL).
 * Tokens, API keys, and anything that must not sit in plaintext SQLite
 * go through this file. Screens never import `expo-secure-store`.
 *
 * The native module is lazy-loaded (same pattern as `lib/purchases.ts`)
 * so importing this file does not load SecureStore until a function runs.
 * Unavailable on web.
 *
 * [VOLATILE] API checked 2026-08-15 via Context7 `/expo/expo` sdk-56:
 *   getItemAsync / setItemAsync / deleteItemAsync / isAvailableAsync
 */
import { reportError } from '@/lib/report-error';
import { Platform } from 'react-native';

type SecureStoreSdk = typeof import('expo-secure-store');

let sdk: SecureStoreSdk | null = null;

/** Test/observability helper — true only after a native-path require(). */
export function isSecureStoreLoaded(): boolean {
  return sdk !== null;
}

/** @internal — clears the lazy module cache between Jest cases. */
export function __resetSecureStoreForTests(): void {
  sdk = null;
}

function loadSdk(): SecureStoreSdk {
  if (!sdk) {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    sdk = require('expo-secure-store') as SecureStoreSdk;
  }
  return sdk;
}

function isWeb(): boolean {
  return Platform.OS === 'web';
}

/**
 * Read a secret. Missing key, web, or an unavailable store → `null`.
 * Never logs the value.
 */
export async function getSecret(key: string): Promise<string | null> {
  if (isWeb()) return null;

  const SecureStore = loadSdk();
  if (!(await SecureStore.isAvailableAsync())) return null;

  try {
    return await SecureStore.getItemAsync(key);
  } catch (error) {
    reportError(error, { scope: 'secure-storage.getSecret', key });
    return null;
  }
}

/**
 * Write a secret. Throws on web or if the store is unavailable — a silent
 * success would look like the token was saved.
 * Never logs the value.
 */
export async function setSecret(key: string, value: string): Promise<void> {
  if (isWeb()) {
    throw new Error('Secure storage is not available on web.');
  }

  const SecureStore = loadSdk();
  if (!(await SecureStore.isAvailableAsync())) {
    throw new Error('Secure storage is not available on this device.');
  }

  try {
    await SecureStore.setItemAsync(key, value);
  } catch (error) {
    reportError(error, { scope: 'secure-storage.setSecret', key });
    throw error;
  }
}

/**
 * Delete a secret. Throws on web or if the store is unavailable.
 */
export async function deleteSecret(key: string): Promise<void> {
  if (isWeb()) {
    throw new Error('Secure storage is not available on web.');
  }

  const SecureStore = loadSdk();
  if (!(await SecureStore.isAvailableAsync())) {
    throw new Error('Secure storage is not available on this device.');
  }

  try {
    await SecureStore.deleteItemAsync(key);
  } catch (error) {
    reportError(error, { scope: 'secure-storage.deleteSecret', key });
    throw error;
  }
}
