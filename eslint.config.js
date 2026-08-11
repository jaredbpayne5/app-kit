// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const eslintConfigPrettier = require('eslint-config-prettier');

// Seam enforcement. AGENTS.md states these rules in prose ("Seams — use these,
// don't go around them" and the Stack section); this makes them machine-checkable
// so a fast model can't quietly bypass them mid-build.
//
// These libraries are all still used — just in one file each. A direct import in
// a screen defeats the seam's whole purpose: e.g. importing react-native-purchases
// straight into a paywall bypasses PURCHASES_MODE 'mock' and silently loses the
// ability to test the paywall without a paid store account.
//
// Escape hatch: add the file to an override below, or use an eslint-disable-next-line
// comment with a reason. This is a speed bump, not a wall.
const RESTRICTED_IMPORTS = [
  'error',
  {
    paths: [
      {
        name: 'expo-sqlite',
        message:
          "Use the storage seam ('@/lib/storage') instead — it handles corrupt-value quarantine and versioned migrations.",
      },
      {
        name: 'expo-sqlite/kv-store',
        message: "Use the storage seam ('@/lib/storage') instead of the KV store directly.",
      },
      {
        name: 'react-native-purchases',
        message:
          "Use the purchases seam ('@/lib/purchases') instead — a direct import bypasses PURCHASES_MODE 'mock'.",
      },
      {
        name: 'expo-haptics',
        message: "Use the haptics seam ('@/lib/haptics') instead.",
      },
      {
        name: 'expo-notifications',
        message: "Use the notifications seam ('@/lib/local-notifications') instead.",
      },
      {
        name: '@sentry/react-native',
        message:
          "Use the error seam ('@/lib/report-error') instead — Sentry init lives in '@/lib/sentry'.",
      },
      {
        name: 'react-native',
        importNames: ['StyleSheet', 'Animated', 'FlatList'],
        message:
          'Styling is NativeWind classes (no StyleSheet). Animation is Reanimated (not the legacy Animated API). Lists use @shopify/flash-list (not FlatList).',
      },
    ],
  },
];

// Files that legitimately own a restricted import.
const SEAM_FILES = [
  'apps/mobile/lib/storage.ts',
  'apps/mobile/lib/purchases.ts',
  'apps/mobile/lib/haptics.ts',
  'apps/mobile/lib/local-notifications.ts',
  'apps/mobile/lib/report-error.ts',
  'apps/mobile/lib/sentry.ts',
];

module.exports = defineConfig([
  expoConfig,
  eslintConfigPrettier,
  {
    ignores: [
      'dist/*',
      '.expo/*',
      'node_modules/*',
      'android/*',
      'ios/*',
      'apps/mobile/android/*',
      'apps/mobile/ios/*',
      'apps/web/dist/*',
    ],
  },
  {
    files: ['apps/mobile/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': RESTRICTED_IMPORTS,
    },
  },
  {
    // The seams themselves must import what they wrap.
    files: SEAM_FILES,
    rules: {
      'no-restricted-imports': 'off',
    },
  },
  {
    // Tests mock the underlying libraries directly to prove the seam's behaviour
    // (e.g. that the RevenueCat SDK is NOT loaded in free/mock mode).
    files: ['apps/mobile/**/*.test.{ts,tsx}', 'apps/mobile/__tests__/**/*.{ts,tsx}'],
    rules: {
      'no-restricted-imports': 'off',
    },
  },
  {
    // AGENTS.md permits FlatList for a fixed-length horizontal pager. Everything
    // else stays restricted here — this is not a blanket exemption.
    files: ['apps/mobile/app/onboarding.tsx'],
    rules: {
      'no-restricted-imports': [
        'error',
        {
          paths: RESTRICTED_IMPORTS[1].paths.map((entry) =>
            entry.name === 'react-native'
              ? { ...entry, importNames: ['StyleSheet', 'Animated'] }
              : entry
          ),
        },
      ],
    },
  },
]);
