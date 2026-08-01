import { Text } from '@/ui/text';
import { Picker } from '@react-native-picker/picker';
import { useMemo, useState } from 'react';
import { Modal, Pressable, View } from 'react-native';

export function buildNumberOptions(min: number, max: number, step: number): number[] {
  const values: number[] = [];
  for (let n = min; n <= max + 1e-9; n += step) {
    values.push(Math.round(n * 1000) / 1000);
  }
  return values;
}

export function nearestNumberOption(amount: number, options: number[]): number {
  let best = options[0] ?? amount;
  let bestDelta = Math.abs(best - amount);
  for (const option of options) {
    const delta = Math.abs(option - amount);
    if (delta < bestDelta) {
      best = option;
      bestDelta = delta;
    }
  }
  return best;
}

type NumberWheelFieldProps = {
  value: string;
  onChange: (raw: string) => void;
  min?: number;
  max?: number;
  step?: number;
  /** Unit suffix shown in labels (e.g. `kg`, `lb`, `%`). */
  unit?: string;
  emptyLabel?: string;
  title?: string;
  /** Seed when value is empty. */
  defaultValue?: number;
  testID?: string;
  doneTestID?: string;
};

/**
 * Discrete amount control with the native wheel picker (iOS UIPickerView).
 * Maestro: prefer the Done button (`doneTestID`) over tapping wheel rows.
 */
export function NumberWheelField({
  value,
  onChange,
  min = 0.5,
  max = 100,
  step = 0.5,
  unit,
  emptyLabel = 'Choose amount',
  title = 'Amount',
  defaultValue,
  testID = 'input-number-wheel',
  doneTestID = 'btn-number-wheel-done',
}: NumberWheelFieldProps) {
  const options = useMemo(() => buildNumberOptions(min, max, step), [min, max, step]);
  const [open, setOpen] = useState(false);

  const parsed = Number.parseFloat(value);
  const hasValue = Number.isFinite(parsed);
  const seed = defaultValue ?? options[Math.floor(options.length / 2)] ?? min;
  const selected = hasValue ? nearestNumberOption(parsed, options) : seed;
  const [draft, setDraft] = useState(selected);

  function formatLabel(amount: number): string {
    const shown = Number.isInteger(amount) ? String(amount) : String(amount);
    return unit ? `${shown} ${unit}` : shown;
  }

  function openPicker() {
    setDraft(selected);
    setOpen(true);
  }

  function commit(amount: number) {
    onChange(Number.isInteger(step) ? String(amount) : amount.toFixed(1));
  }

  return (
    <View className="gap-2">
      <Pressable
        testID={testID}
        accessibilityRole="button"
        accessibilityLabel={hasValue ? `${title} ${formatLabel(parsed)}` : emptyLabel}
        className="min-h-11 justify-center rounded-lg bg-transparent py-1 active:opacity-70"
        onPress={openPicker}>
        <Text className={hasValue ? undefined : 'text-muted-foreground'}>
          {hasValue ? formatLabel(parsed) : emptyLabel}
        </Text>
      </Pressable>

      <Modal visible={open} transparent animationType="slide" onRequestClose={() => setOpen(false)}>
        <Pressable
          accessibilityLabel="Dismiss number picker"
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
                  commit(draft);
                  setOpen(false);
                }}>
                <Text className="font-semibold text-primary">Done</Text>
              </Pressable>
            </View>
            <Picker
              selectedValue={draft}
              onValueChange={(next) => setDraft(Number(next))}
              testID="number-wheel-picker">
              {options.map((option) => (
                <Picker.Item key={option} label={formatLabel(option)} value={option} />
              ))}
            </Picker>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}
