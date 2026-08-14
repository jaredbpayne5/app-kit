/**
 * Example screen. Delete it when you build your real product — it exists to
 * show how FlashList, the bottom sheet, swipe actions, on-device storage, and
 * haptics fit together in this template. Removing this file also means
 * removing the `<Tabs.Screen name="library" …>` block in
 * `apps/mobile/app/(tabs)/_layout.tsx`, or the tab route stays registered.
 */
import { EmptyState } from '@/components/empty-state';
import { success, tapLight, warning } from '@/lib/haptics';
import { reportError } from '@/lib/report-error';
import { getJSON, setJSON } from '@/lib/storage';
import { THEME } from '@/lib/theme';
import { useBackDismiss } from '@/lib/use-back-dismiss';
import { Button } from '@/ui/button';
import { Icon } from '@/ui/icon';
import { Text } from '@/ui/text';
import {
  BottomSheetBackdrop,
  BottomSheetModal,
  BottomSheetTextInput,
  BottomSheetView,
  type BottomSheetBackdropProps,
} from '@gorhom/bottom-sheet';
import { FlashList } from '@shopify/flash-list';
import { LayersIcon, Trash2Icon } from 'lucide-react-native';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Pressable, View } from 'react-native';
import ReanimatedSwipeable from 'react-native-gesture-handler/ReanimatedSwipeable';
import { useColorScheme } from 'nativewind';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const STORAGE_KEY = 'library.items';
let nextItemId = 0;

type Item = {
  id: string;
  title: string;
  createdAt: string;
};

function RightAction({ onPress }: { onPress: () => void }) {
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel="Delete item"
      testID="btn-delete-item"
      className="w-20 items-center justify-center bg-destructive active:opacity-80">
      <Icon as={Trash2Icon} className="size-5 text-destructive-foreground" />
    </Pressable>
  );
}

export default function LibraryScreen() {
  const { colorScheme } = useColorScheme();
  const theme = THEME[colorScheme ?? 'light'];
  const insets = useSafeAreaInsets();

  const [items, setItems] = useState<Item[]>([]);
  const [draft, setDraft] = useState('');
  const [sheetOpen, setSheetOpen] = useState(false);
  const sheetRef = useRef<BottomSheetModal>(null);

  const dismissSheet = useCallback(() => sheetRef.current?.dismiss(), []);
  useBackDismiss(sheetOpen, dismissSheet);

  useEffect(() => {
    let mounted = true;
    void (async () => {
      try {
        const saved = await getJSON<Item[]>(STORAGE_KEY);
        if (mounted && saved) setItems(saved);
      } catch (error) {
        reportError(error, { scope: 'library.load' });
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  const persist = useCallback(async (next: Item[]) => {
    setItems(next);
    try {
      await setJSON(STORAGE_KEY, next);
    } catch (error) {
      reportError(error, { scope: 'library.persist' });
    }
  }, []);

  const addItem = useCallback(() => {
    const title = draft.trim();
    if (!title) return;
    const next: Item[] = [
      {
        id: `${Date.now()}-${nextItemId++}`,
        title,
        createdAt: new Date().toISOString(),
      },
      ...items,
    ];
    void persist(next);
    void success();
    setDraft('');
    sheetRef.current?.dismiss();
  }, [draft, items, persist]);

  const removeItem = useCallback(
    (id: string) => {
      void warning();
      void persist(items.filter((item) => item.id !== id));
    },
    [items, persist]
  );

  const renderBackdrop = useCallback(
    (props: BottomSheetBackdropProps) => (
      <BottomSheetBackdrop {...props} appearsOnIndex={0} disappearsOnIndex={-1} />
    ),
    []
  );

  return (
    <View className="flex-1 bg-grouped" testID="library-screen">
      {items.length === 0 ? (
        <View className="flex-1 justify-center">
          <EmptyState
            icon={LayersIcon}
            title="Nothing saved yet"
            body="Add your first item to see the list, swipe actions, and on-device persistence."
            actionLabel="Add item"
            onAction={() => {
              void tapLight();
              sheetRef.current?.present();
            }}
          />
        </View>
      ) : (
        <FlashList
          data={items}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ paddingVertical: 12 }}
          renderItem={({ item }) => (
            <ReanimatedSwipeable
              friction={2}
              rightThreshold={40}
              renderRightActions={() => <RightAction onPress={() => removeItem(item.id)} />}>
              <View className="min-h-[56px] justify-center border-b border-border/70 bg-card px-4 py-3">
                <Text>{item.title}</Text>
                <Text variant="caption">{new Date(item.createdAt).toLocaleDateString()}</Text>
              </View>
            </ReanimatedSwipeable>
          )}
        />
      )}

      <View
        className="px-6"
        style={{ paddingBottom: Math.max(insets.bottom, 16) }} /* native-required: dynamic inset */
      >
        <Button
          testID="btn-add-item"
          accessibilityLabel="Add item"
          onPress={() => {
            void tapLight();
            sheetRef.current?.present();
          }}>
          <Text>Add item</Text>
        </Button>
      </View>

      <BottomSheetModal
        ref={sheetRef}
        accessible={false}
        snapPoints={['32%']}
        enableDynamicSizing={false}
        onChange={(index) => setSheetOpen(index >= 0)}
        onDismiss={() => setSheetOpen(false)}
        backdropComponent={renderBackdrop}
        backgroundStyle={{ backgroundColor: theme.card }}
        handleIndicatorStyle={{ backgroundColor: theme.mutedForeground }}>
        <BottomSheetView
          style={{
            // native-required: gorhom sheet
            paddingHorizontal: 24,
            paddingBottom: 24,
            gap: 16,
          }}>
          <Text variant="h4">New item</Text>
          <BottomSheetTextInput
            value={draft}
            onChangeText={setDraft}
            placeholder="What do you want to remember?"
            placeholderTextColor={theme.mutedForeground}
            testID="input-item-title"
            accessibilityLabel="Item title"
            returnKeyType="done"
            onSubmitEditing={addItem}
            style={{
              // native-required: BottomSheetTextInput does not take className
              height: 44,
              borderRadius: 10,
              paddingHorizontal: 12,
              backgroundColor: theme.muted,
              color: theme.foreground,
              fontSize: 17,
            }}
          />
          <Button testID="btn-save-item" onPress={addItem} disabled={draft.trim().length === 0}>
            <Text>Save</Text>
          </Button>
        </BottomSheetView>
      </BottomSheetModal>
    </View>
  );
}
