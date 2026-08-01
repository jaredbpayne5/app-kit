import { Button } from '@/ui/button';
import { Icon } from '@/ui/icon';
import { Text } from '@/ui/text';
import type { LucideIcon } from 'lucide-react-native';
import { View } from 'react-native';

type EmptyStateProps = {
  icon: LucideIcon;
  title: string;
  body: string;
  actionLabel: string;
  onAction: () => void;
  testID?: string;
};

/**
 * Standard empty state: icon, explanation, and a single obvious action.
 * Every list or collection screen should have one — a blank screen reads as broken.
 */
export function EmptyState({
  icon,
  title,
  body,
  actionLabel,
  onAction,
  testID = 'empty-state',
}: EmptyStateProps) {
  return (
    <View className="items-center justify-center gap-4 p-6" testID={testID}>
      <Icon as={icon} className="size-10 text-muted-foreground" />
      <View className="gap-2">
        <Text variant="h4" className="text-center">
          {title}
        </Text>
        <Text variant="muted" className="text-center">
          {body}
        </Text>
      </View>
      <Button testID={`${testID}-action`} accessibilityLabel={actionLabel} onPress={onAction}>
        <Text>{actionLabel}</Text>
      </Button>
    </View>
  );
}
