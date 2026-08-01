/**
 * Semantic haptics — call sites express intent, not ImpactFeedbackStyle names.
 * No-ops on web.
 */
import { Platform } from 'react-native';
import * as Haptics from 'expo-haptics';

async function run(fn: () => Promise<void>): Promise<void> {
  if (Platform.OS === 'web') return;
  try {
    await fn();
  } catch {
    // Haptics are polish — never fail the caller.
  }
}

export function tapLight(): Promise<void> {
  return run(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));
}

export function tapMedium(): Promise<void> {
  return run(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
}

export function success(): Promise<void> {
  return run(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));
}

export function warning(): Promise<void> {
  return run(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning));
}

export function error(): Promise<void> {
  return run(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error));
}
