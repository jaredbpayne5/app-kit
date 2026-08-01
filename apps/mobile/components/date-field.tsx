import DateTimePicker, { type DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { formatIsoDateLabel, parseIsoDateLocal, toIsoDateLocal } from '@/lib/dates';
import { Text } from '@/ui/text';
import { useState } from 'react';
import { Modal, Platform, Pressable, View } from 'react-native';

type DateFieldProps = {
  /** Controlled ISO date `YYYY-MM-DD`, or empty when unset. */
  value: string;
  onChange: (isoDate: string) => void;
  maximumDate?: Date;
  minimumDate?: Date;
  /** Placeholder when value is empty. */
  emptyLabel?: string;
  /** Sheet title on iOS. */
  title?: string;
  /** Seed date when value is empty (defaults to today). */
  seedDate?: Date;
  testID?: string;
  doneTestID?: string;
};

/**
 * Date control backed by the system date picker.
 * Stores `YYYY-MM-DD` for the rest of the app; the user never types the format.
 */
export function DateField({
  value,
  onChange,
  maximumDate,
  minimumDate,
  emptyLabel = 'Choose date',
  title = 'Date',
  seedDate,
  testID = 'input-date',
  doneTestID = 'btn-date-done',
}: DateFieldProps) {
  const [open, setOpen] = useState(false);
  const selected =
    (value ? parseIsoDateLocal(value) : null) ??
    seedDate ??
    new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());

  function onPickerChange(event: DateTimePickerEvent, date?: Date) {
    if (Platform.OS === 'android') {
      setOpen(false);
      if (event.type === 'dismissed' || !date) return;
    }
    if (!date) return;
    onChange(toIsoDateLocal(date));
  }

  return (
    <View className="gap-2">
      <Pressable
        testID={testID}
        accessibilityRole="button"
        accessibilityLabel={value ? `${title} ${formatIsoDateLabel(value)}` : emptyLabel}
        className="min-h-11 justify-center rounded-lg bg-transparent py-1 active:opacity-70"
        onPress={() => setOpen(true)}>
        <Text className={value ? undefined : 'text-muted-foreground'}>
          {value ? formatIsoDateLabel(value) : emptyLabel}
        </Text>
      </Pressable>

      {Platform.OS === 'android' && open ? (
        <DateTimePicker
          testID="date-picker"
          value={selected}
          mode="date"
          display="default"
          maximumDate={maximumDate}
          minimumDate={minimumDate}
          onChange={onPickerChange}
        />
      ) : null}

      {Platform.OS === 'ios' ? (
        <Modal
          visible={open}
          transparent
          animationType="slide"
          onRequestClose={() => setOpen(false)}>
          <Pressable
            accessibilityLabel="Dismiss date picker"
            className="flex-1 justify-end bg-black/40"
            onPress={() => setOpen(false)}>
            <Pressable
              className="rounded-t-3xl bg-card px-4 pb-8 pt-3"
              onPress={(event) => event.stopPropagation()}>
              <View className="mb-2 flex-row items-center justify-between">
                <Text className="text-base font-semibold text-foreground">{title}</Text>
                <Pressable
                  testID={doneTestID}
                  accessibilityRole="button"
                  accessibilityLabel="Done"
                  className="rounded-lg px-3 py-2 active:bg-muted/50"
                  onPress={() => {
                    if (!value) onChange(toIsoDateLocal(selected));
                    setOpen(false);
                  }}>
                  <Text className="font-semibold text-primary">Done</Text>
                </Pressable>
              </View>
              <DateTimePicker
                testID="date-picker"
                value={selected}
                mode="date"
                display="spinner"
                maximumDate={maximumDate}
                minimumDate={minimumDate}
                onChange={onPickerChange}
                style={{ alignSelf: 'stretch' }}
              />
            </Pressable>
          </Pressable>
        </Modal>
      ) : null}
    </View>
  );
}
