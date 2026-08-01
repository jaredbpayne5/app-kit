import { SymbolView, type SymbolViewProps } from 'expo-symbols';
import type { LucideIcon } from 'lucide-react-native';
import { Platform, type ColorValue } from 'react-native';

type TabBarIconProps = {
  /** SF Symbol name — used on iOS, where it matches the system tab bar look. */
  symbol: SymbolViewProps['name'];
  /** Lucide fallback for Android and web. */
  lucide: LucideIcon;
  color: ColorValue;
  focused: boolean;
};

const SIZE = 26;

/**
 * SF Symbols on iOS, Lucide everywhere else. iOS tab bars read as non-native
 * fast when they use a third-party icon set, and SF Symbols cost no assets.
 */
export function TabBarIcon({ symbol, lucide: Fallback, color, focused }: TabBarIconProps) {
  if (Platform.OS === 'ios') {
    return (
      <SymbolView
        name={symbol}
        size={SIZE}
        tintColor={color}
        type="hierarchical"
        weight={focused ? 'semibold' : 'regular'}
      />
    );
  }

  return <Fallback size={SIZE} color={color} strokeWidth={focused ? 2.4 : 2} />;
}
