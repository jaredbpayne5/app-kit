import { Icon } from '@/ui/icon';
import { Text } from '@/ui/text';
import { MoreHorizontalIcon } from 'lucide-react-native';
import { useRef, useState, type ReactNode } from 'react';
import { Modal, Pressable, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export type HeaderMenuItem = {
  label: string;
  testID: string;
  onPress: () => void;
};

const DROPDOWN_WIDTH = 200;

type HeaderOverflowMenuProps = {
  items: HeaderMenuItem[];
  /** Optional trailing slot next to the ⋯ control (e.g. ThemeToggle). */
  trailing?: ReactNode;
};

/**
 * Header ⋯ control — anchored dropdown with stable testIDs (Maestro-friendly).
 * Prefer this over ActionSheetIOS for e2e. Pass product nav items from the screen/layout.
 */
export function HeaderOverflowMenu({ items, trailing }: HeaderOverflowMenuProps) {
  const insets = useSafeAreaInsets();
  const anchorRef = useRef<View>(null);
  const [open, setOpen] = useState(false);
  const [anchor, setAnchor] = useState<{
    x: number;
    y: number;
    width: number;
    height: number;
  } | null>(null);

  function openMenu() {
    const show = (x: number, y: number, width: number, height: number) => {
      setAnchor({ x, y, width, height });
      setOpen(true);
    };

    const node = anchorRef.current;
    if (!node?.measureInWindow) {
      show(280, 56, 40, 32);
      return;
    }

    let measured = false;
    node.measureInWindow((x, y, width, height) => {
      measured = true;
      show(x, y, width, height);
    });
    queueMicrotask(() => {
      if (!measured) show(280, 56, 40, 32);
    });
  }

  const top = anchor ? anchor.y + anchor.height + 6 : insets.top + 52;
  const left = anchor ? Math.max(8, anchor.x + anchor.width - DROPDOWN_WIDTH) : undefined;

  return (
    <View className="flex-row items-center gap-1">
      <View ref={anchorRef} collapsable={false}>
        <Pressable
          testID="btn-overflow-menu"
          accessibilityRole="button"
          accessibilityLabel="Open menu"
          accessibilityState={{ expanded: open }}
          hitSlop={12}
          className="items-center justify-center px-2 py-1"
          onPress={openMenu}>
          <Icon as={MoreHorizontalIcon} className="size-6 text-foreground" />
        </Pressable>
      </View>
      {trailing}

      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <View className="flex-1">
          <Pressable
            accessibilityLabel="Dismiss menu"
            className="absolute inset-0"
            onPress={() => setOpen(false)}
          />
          <View
            testID="overflow-menu-dropdown"
            className="absolute overflow-hidden rounded-xl border border-border bg-card shadow-lg"
            style={{ top, left, width: DROPDOWN_WIDTH }} /* native-required: measureInWindow */
          >
            {items.map((item, index) => (
              <Pressable
                key={item.testID}
                testID={item.testID}
                accessibilityRole="button"
                accessibilityLabel={item.label}
                className={`px-4 py-3 active:bg-muted/60 ${
                  index < items.length - 1 ? 'border-b border-border/70' : ''
                }`}
                onPress={() => {
                  setOpen(false);
                  item.onPress();
                }}>
                <Text>{item.label}</Text>
              </Pressable>
            ))}
          </View>
        </View>
      </Modal>
    </View>
  );
}
