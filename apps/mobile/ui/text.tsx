import { cn } from '@/lib/utils';
import { Slot } from '@rn-primitives/slot';
import { cva, type VariantProps } from 'class-variance-authority';
import * as React from 'react';
import { Platform, Text as RNText, type Role } from 'react-native';

// Modular type scale (the ONLY place a screen-level px/leading value should be
// chosen — screens use these variants instead of raw `text-[Npx]` literals).
// `font-rounded` maps to San Francisco Rounded on iOS only (tailwind.config.js);
// it's a no-op utility on Android/web, so heading personality there comes from
// weight/tracking instead of an unreliable font-family guess.
const ROUNDED_HEADING = Platform.select({ ios: 'font-rounded', default: '' });

const textVariants = cva(
  cn(
    // 17/22 matches iOS Body — the size most rows/labels in an app converge
    // on ad hoc if left unscaled; this makes it the real default instead of
    // Tailwind's 16px `text-base`.
    'text-[17px] leading-[22px] text-foreground',
    Platform.select({
      web: 'select-text',
    })
  ),
  {
    variants: {
      variant: {
        default: '',
        // Hero numbers (a dashboard stat, a paywall price) — the single
        // biggest emphasis level in the app.
        display: cn(
          'text-center text-[34px] font-extrabold leading-[40px] tracking-tight',
          ROUNDED_HEADING,
          Platform.select({ web: 'scroll-m-20 text-balance' })
        ),
        h1: cn(
          'text-center text-[28px] font-bold leading-[34px] tracking-tight',
          ROUNDED_HEADING,
          Platform.select({ web: 'scroll-m-20 text-balance' })
        ),
        h2: cn(
          'text-[22px] font-semibold leading-[28px] tracking-tight',
          ROUNDED_HEADING,
          Platform.select({ web: 'scroll-m-20 first:mt-0' })
        ),
        h3: cn(
          'text-[18px] font-semibold leading-[24px] tracking-tight',
          Platform.select({ web: 'scroll-m-20' })
        ),
        h4: cn('text-[17px] font-semibold leading-[22px]', Platform.select({ web: 'scroll-m-20' })),
        p: 'mt-3 leading-7 sm:mt-6',
        blockquote: 'mt-4 border-l-2 pl-3 italic sm:mt-6 sm:pl-6',
        code: cn(
          'relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold'
        ),
        lead: 'text-[18px] leading-[26px] text-muted-foreground',
        large: 'text-[17px] font-semibold leading-[22px]',
        small: 'text-[13px] font-medium leading-[18px]',
        muted: 'text-[14px] leading-[20px] text-muted-foreground',
        caption: 'text-[12px] leading-[16px] text-muted-foreground',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
);

type TextVariantProps = VariantProps<typeof textVariants>;

type TextVariant = NonNullable<TextVariantProps['variant']>;

const ROLE: Partial<Record<TextVariant, Role>> = {
  h1: 'heading',
  h2: 'heading',
  h3: 'heading',
  h4: 'heading',
  blockquote: Platform.select({ web: 'blockquote' as Role }),
  code: Platform.select({ web: 'code' as Role }),
};

const ARIA_LEVEL: Partial<Record<TextVariant, string>> = {
  h1: '1',
  h2: '2',
  h3: '3',
  h4: '4',
};

const TextClassContext = React.createContext<string | undefined>(undefined);

function Text({
  className,
  asChild = false,
  variant = 'default',
  ...props
}: React.ComponentProps<typeof RNText> &
  React.RefAttributes<typeof RNText> &
  TextVariantProps & {
    asChild?: boolean;
  }) {
  const textClass = React.useContext(TextClassContext);
  const Component = asChild ? Slot : RNText;
  return (
    <Component
      className={cn(textVariants({ variant }), textClass, className)}
      role={variant ? ROLE[variant] : undefined}
      aria-level={variant ? ARIA_LEVEL[variant] : undefined}
      {...props}
    />
  );
}

export { Text, TextClassContext };
