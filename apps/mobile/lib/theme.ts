import { DarkTheme, DefaultTheme, type Theme } from 'expo-router/react-navigation';

import { THEME } from '@/lib/theme-tokens';

/**
 * Color tokens as JS strings, for the props NativeWind classes can't reach
 * (navigation chrome, tab bar, bottom sheets, charts). Generated from
 * apps/mobile/global.css — see scripts/dev/gen-theme.ts.
 */
export { THEME };
export type { ThemeTokens } from '@/lib/theme-tokens';

/**
 * Append alpha to a generated `hsl(...)` token for props that need opacity.
 * Emits `hsla(...)` — React Native's color normalizer rejects slash-alpha on
 * `hsl()` and only accepts it on `hsla()` (@react-native/normalize-colors).
 */
export function hslWithAlpha(hsl: string, alpha: number): string {
  const match = /^hsl\((.+)\)$/.exec(hsl.trim());
  if (!match) return hsl;
  return `hsla(${match[1]} / ${alpha})`;
}

export const NAV_THEME: Record<'light' | 'dark', Theme> = {
  light: {
    ...DefaultTheme,
    colors: {
      background: THEME.light.background,
      border: THEME.light.border,
      card: THEME.light.card,
      notification: THEME.light.destructive,
      primary: THEME.light.primary,
      text: THEME.light.foreground,
    },
  },
  dark: {
    ...DarkTheme,
    colors: {
      background: THEME.dark.background,
      border: THEME.dark.border,
      card: THEME.dark.card,
      notification: THEME.dark.destructive,
      primary: THEME.dark.primary,
      text: THEME.dark.foreground,
    },
  },
};
