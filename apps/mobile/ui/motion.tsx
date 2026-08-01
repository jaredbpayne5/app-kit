import { cssInterop } from 'nativewind';
import type { ReactNode } from 'react';
import { View, type ViewProps } from 'react-native';
import Animated, { FadeInDown, ZoomIn } from 'react-native-reanimated';

// Reanimated's Animated.View is not one of the components NativeWind maps by
// default, so `className` has to be registered explicitly. cssInterop mutates
// the component it is handed, so registering the shared Animated.View would
// rewire it for every library in the app — that breaks @gorhom/bottom-sheet,
// whose handle measures itself through onLayout on that exact component.
// Register a private copy instead.
const AnimatedView = Animated.createAnimatedComponent(View);
cssInterop(AnimatedView, { className: 'style' });

type MotionProps = ViewProps & {
  children?: ReactNode;
  delay?: number;
};

/**
 * Fade + slide-up on mount. Use for screen content and list sections.
 *
 * These use Reanimated's `entering` prop rather than `useAnimatedStyle` on
 * purpose: an animated `style` on the same node replaces the styles NativeWind
 * derives from `className`, which silently drops all layout classes.
 */
export function FadeSlideIn({ children, delay = 0, ...props }: MotionProps) {
  return (
    <AnimatedView entering={FadeInDown.duration(400).delay(delay)} {...props}>
      {children}
    </AnimatedView>
  );
}

/** Fade + spring scale-in on mount — for icons and checkmarks appearing in place. */
export function PopIn({ children, delay = 0, ...props }: MotionProps) {
  return (
    <AnimatedView entering={ZoomIn.springify().damping(14).delay(delay)} {...props}>
      {children}
    </AnimatedView>
  );
}
