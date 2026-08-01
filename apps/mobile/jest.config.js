/** @type {import('jest').Config} */
module.exports = {
  preset: 'jest-expo',
  testMatch: ['**/*.test.ts', '**/*.test.tsx'],
  // Reanimated pulls in react-native-worklets, whose `.native.ts` files throw
  // when the native module is absent. This resolver strips the `.native`
  // extension for worklets only, which is how Reanimated ships Jest support.
  resolver: 'react-native-worklets/jest/resolver.js',
  setupFiles: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    // lucide-react-native's package.json "exports" map sometimes resolves to
    // its un-transpiled ESM build under Jest (Jest's default transform only
    // covers .js/.ts/.jsx/.tsx, not .mjs) — pin it straight to the CJS build.
    // Defense-in-depth: transformIgnorePatterns already allows this package
    // through Jest's transformer, which covers the common case; this closes
    // the remaining resolution-path edge case directly.
    '^lucide-react-native$':
      '<rootDir>/../../node_modules/lucide-react-native/dist/cjs/lucide-react-native.js',
  },
  // Avoid requiring a writable Watchman state dir (Cursor sandbox / CI agents).
  watchman: false,
  transformIgnorePatterns: [
    'node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@sentry/react-native|react-native-purchases|expo-web-browser|expo-linear-gradient|expo-localization|expo-clipboard|expo-blur|expo-font|expo-image|expo-symbols|native-base|react-native-svg|@rn-primitives|nativewind|react-native-css-interop|lucide-react-native|react-native-reanimated|react-native-worklets|react-native-gesture-handler|@shopify/flash-list|@gorhom/bottom-sheet)',
  ],
};
