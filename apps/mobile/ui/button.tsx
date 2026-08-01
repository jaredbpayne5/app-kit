import { TextClassContext } from '@/ui/text';
import { tapLight } from '@/lib/haptics';
import { cn } from '@/lib/utils';
import { cva, type VariantProps } from 'class-variance-authority';
import { Platform, Pressable, type GestureResponderEvent } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';

const buttonVariants = cva(
  cn(
    'group shrink-0 flex-row items-center justify-center gap-2 rounded-md shadow-none',
    Platform.select({
      web: "aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive whitespace-nowrap outline-none transition-all focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none [&_svg:not([class*='size-'])]:size-4 [&_svg]:pointer-events-none [&_svg]:shrink-0",
    })
  ),
  {
    variants: {
      variant: {
        default: cn(
          'bg-primary shadow-sm shadow-secondary/15 active:bg-primary/90',
          Platform.select({ web: 'hover:bg-primary/90' })
        ),
        destructive: cn(
          'bg-destructive shadow-sm shadow-black/5 active:bg-destructive/90 dark:bg-destructive/60',
          Platform.select({
            web: 'hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40',
          })
        ),
        outline: cn(
          'border border-border bg-background shadow-sm shadow-secondary/10 active:bg-accent dark:border-input dark:bg-input/30 dark:active:bg-input/50',
          Platform.select({
            web: 'hover:bg-accent dark:hover:bg-input/50',
          })
        ),
        secondary: cn(
          'bg-secondary shadow-sm shadow-secondary/20 active:bg-secondary/80',
          Platform.select({ web: 'hover:bg-secondary/80' })
        ),
        ghost: cn(
          'active:bg-accent dark:active:bg-accent/50',
          Platform.select({ web: 'hover:bg-accent dark:hover:bg-accent/50' })
        ),
        link: '',
      },
      size: {
        default: cn('h-10 px-4 py-2 sm:h-9', Platform.select({ web: 'has-[>svg]:px-3' })),
        sm: cn('h-9 gap-1.5 rounded-md px-3 sm:h-8', Platform.select({ web: 'has-[>svg]:px-2.5' })),
        lg: cn('h-11 rounded-md px-6 sm:h-10', Platform.select({ web: 'has-[>svg]:px-4' })),
        icon: 'h-10 w-10 sm:h-9 sm:w-9',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

const buttonTextVariants = cva(
  cn(
    'text-sm font-medium text-foreground',
    Platform.select({ web: 'pointer-events-none transition-colors' })
  ),
  {
    variants: {
      variant: {
        default: 'text-primary-foreground',
        destructive: 'text-white',
        outline: cn(
          'group-active:text-accent-foreground',
          Platform.select({ web: 'group-hover:text-accent-foreground' })
        ),
        secondary: 'text-secondary-foreground',
        ghost: 'group-active:text-accent-foreground',
        link: cn(
          'text-primary group-active:underline',
          Platform.select({ web: 'underline-offset-4 hover:underline group-hover:underline' })
        ),
      },
      size: {
        default: '',
        sm: '',
        lg: '',
        icon: '',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

const PRESS_SPRING = { damping: 18, stiffness: 500, mass: 0.5 };

type ButtonProps = React.ComponentProps<typeof Pressable> &
  React.RefAttributes<typeof Pressable> &
  VariantProps<typeof buttonVariants> & {
    /** Set false for buttons that fire repeatedly (steppers, keypads). */
    haptic?: boolean;
  };

function Button({
  className,
  variant,
  size,
  haptic = true,
  onPressIn,
  onPressOut,
  ...props
}: ButtonProps) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.get() }],
  }));

  function handlePressIn(event: GestureResponderEvent) {
    scale.set(withSpring(0.96, PRESS_SPRING));
    if (haptic && !props.disabled) void tapLight();
    onPressIn?.(event);
  }

  function handlePressOut(event: GestureResponderEvent) {
    scale.set(withSpring(1, PRESS_SPRING));
    onPressOut?.(event);
  }

  // Reanimated owns `style`, NativeWind owns `className`, and they must sit on
  // different nodes: an animated style on the same node silently replaces the
  // styles NativeWind derives from className, leaving the button unpainted.
  return (
    <TextClassContext.Provider value={buttonTextVariants({ variant, size })}>
      <Animated.View style={animatedStyle}>
        <Pressable
          className={cn(
            props.disabled && 'opacity-50',
            buttonVariants({ variant, size }),
            className
          )}
          role="button"
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          {...props}
        />
      </Animated.View>
    </TextClassContext.Provider>
  );
}

export { Button, buttonTextVariants, buttonVariants };
export type { ButtonProps };
