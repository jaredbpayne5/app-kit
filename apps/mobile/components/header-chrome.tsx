import { Button } from '@/ui/button';
import { Icon } from '@/ui/icon';
import { MoonStarIcon, SettingsIcon, SunIcon } from 'lucide-react-native';
import { useColorScheme } from 'nativewind';
import { router } from 'expo-router';
import { Pressable } from 'react-native';

/** Settings gear for stack `headerLeft` — stable module-scope for Stack options. */
export function SettingsHeaderButton() {
  return (
    <Pressable
      testID="btn-settings"
      accessibilityRole="button"
      accessibilityLabel="Settings"
      hitSlop={12}
      className="items-center justify-center px-2 py-1"
      onPress={() => router.push('/settings')}>
      <Icon as={SettingsIcon} className="size-5 text-foreground" />
    </Pressable>
  );
}

const THEME_ICONS = {
  light: SunIcon,
  dark: MoonStarIcon,
};

/** Theme toggle for stack `headerRight` — use a named function, not an inline arrow in options. */
export function ThemeToggle() {
  const { colorScheme, toggleColorScheme } = useColorScheme();
  const isDark = colorScheme === 'dark';

  return (
    <Button
      onPress={toggleColorScheme}
      size="icon"
      variant="ghost"
      className="ios:size-9 rounded-full web:mx-4"
      accessibilityRole="button"
      accessibilityLabel={isDark ? 'Switch to light theme' : 'Switch to dark theme'}
      accessibilityState={{ selected: isDark }}>
      <Icon as={THEME_ICONS[colorScheme ?? 'light']} className="size-5" />
    </Button>
  );
}
