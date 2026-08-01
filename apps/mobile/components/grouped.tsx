import { Text } from '@/ui/text';
import { tapLight } from '@/lib/haptics';
import { cn } from '@/lib/utils';
import { Icon } from '@/ui/icon';
import { CheckIcon, ChevronRightIcon } from 'lucide-react-native';
import type { ReactNode } from 'react';
import { Pressable, View, type ViewProps } from 'react-native';

type GroupedSectionProps = ViewProps & {
  /** Small uppercase label above the inset group (iOS Settings style). */
  header?: string;
  footer?: string;
  children?: ReactNode;
};

/**
 * iOS Settings–style inset group: rounded card with hairline separators between rows.
 */
export function GroupedSection({
  header,
  footer,
  children,
  className,
  ...props
}: GroupedSectionProps) {
  return (
    <View className={cn('gap-2', className)} {...props}>
      {header ? (
        <Text
          variant="small"
          className="px-4 font-normal uppercase tracking-wide text-muted-foreground">
          {header}
        </Text>
      ) : null}
      {children ? <View className="overflow-hidden rounded-xl bg-card">{children}</View> : null}
      {footer ? (
        <Text variant="small" className="px-4 leading-5 text-muted-foreground">
          {footer}
        </Text>
      ) : null}
    </View>
  );
}

type GroupedRowProps = {
  label: string;
  value?: string;
  subtitle?: string;
  onPress?: () => void;
  selected?: boolean;
  showChevron?: boolean;
  destructive?: boolean;
  disabled?: boolean;
  testID?: string;
  accessibilityLabel?: string;
  trailing?: ReactNode;
  /** Omit the bottom separator (last row). */
  last?: boolean;
};

/** Tappable or static row inside a GroupedSection. */
export function GroupedRow({
  label,
  value,
  subtitle,
  onPress,
  selected,
  showChevron,
  destructive,
  disabled,
  testID,
  accessibilityLabel,
  trailing,
  last,
}: GroupedRowProps) {
  const content = (
    <View
      className={cn(
        'min-h-[44px] flex-row items-center gap-3 bg-card px-4 py-3',
        !last && 'border-b border-border/70'
      )}>
      <View className="min-w-0 flex-1 gap-0.5">
        <Text
          className={cn(destructive ? 'text-destructive' : undefined, disabled && 'opacity-50')}>
          {label}
        </Text>
        {subtitle ? (
          <Text variant="small" className="font-normal leading-5 text-muted-foreground">
            {subtitle}
          </Text>
        ) : null}
      </View>
      {value ? <Text className="shrink text-muted-foreground">{value}</Text> : null}
      {trailing}
      {selected ? <Icon as={CheckIcon} className="size-5 text-primary" /> : null}
      {showChevron && !selected ? (
        <Icon as={ChevronRightIcon} className="size-5 text-muted-foreground/60" />
      ) : null}
    </View>
  );

  if (!onPress) {
    return (
      <View testID={testID} accessibilityLabel={accessibilityLabel ?? label}>
        {content}
      </View>
    );
  }

  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel ?? label}
      accessibilityState={{ selected: selected ?? false, disabled: disabled ?? false }}
      disabled={disabled}
      className="active:bg-muted/60"
      onPress={() => {
        void tapLight();
        onPress();
      }}>
      {content}
    </Pressable>
  );
}

type GroupedFieldProps = ViewProps & {
  label: string;
  hint?: string;
  last?: boolean;
  children: ReactNode;
};

/** Label + control row for forms inside a grouped card. */
export function GroupedField({
  label,
  hint,
  last,
  children,
  className,
  ...props
}: GroupedFieldProps) {
  return (
    <View
      className={cn('gap-2 bg-card px-4 py-3', !last && 'border-b border-border/70', className)}
      {...props}>
      <Text variant="small" className="font-normal text-muted-foreground">
        {label}
      </Text>
      {children}
      {hint ? (
        <Text variant="small" className="font-normal leading-5 text-muted-foreground">
          {hint}
        </Text>
      ) : null}
    </View>
  );
}
