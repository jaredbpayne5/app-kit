import { THEME, hslWithAlpha } from '@/lib/theme';
import { cn } from '@/lib/utils';
import { LinearGradient } from 'expo-linear-gradient';
import { useColorScheme } from 'nativewind';
import { View, type ViewProps } from 'react-native';

type BrandAtmosphereProps = ViewProps & {
  /** Softer wash for form screens; richer for hero/onboarding. */
  intensity?: 'soft' | 'rich';
};

/**
 * Decorative background wash using theme tokens + linear gradient.
 * Keep interactive content above this layer (`pointerEvents="none"`).
 */
export function BrandAtmosphere({
  intensity = 'soft',
  className,
  style,
  ...props
}: BrandAtmosphereProps) {
  const { colorScheme } = useColorScheme();
  const dark = colorScheme === 'dark';
  const rich = intensity === 'rich';
  const tokens = THEME[dark ? 'dark' : 'light'];
  // Light wash matches --background (100%); dark wash is the prior 4% end stop.
  const wash = tokens.atmosphereWash;
  const colors = [wash, hslWithAlpha(tokens.atmosphereMid, 0.95), wash] as const;

  return (
    <View
      pointerEvents="none"
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      className={cn('absolute inset-0 overflow-hidden', className)}
      style={style}
      {...props}>
      <LinearGradient
        colors={[...colors]}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.9, y: 1 }}
        style={{ position: 'absolute', inset: 0 }} /* native-required: LinearGradient fill */
      />
      <View
        className={cn(
          'absolute -left-16 -top-10 rounded-full bg-secondary',
          rich ? 'h-64 w-64 opacity-[0.14]' : 'h-48 w-48 opacity-[0.09]'
        )}
      />
      <View
        className={cn(
          'absolute -right-20 top-24 rounded-full bg-primary',
          rich ? 'h-56 w-56 opacity-[0.12]' : 'h-40 w-40 opacity-[0.08]'
        )}
      />
      <View
        className={cn(
          'absolute -bottom-24 left-1/4 rounded-full bg-accent',
          rich ? 'h-52 w-52 opacity-[0.08]' : 'h-36 w-36 opacity-[0.05]'
        )}
      />
    </View>
  );
}
