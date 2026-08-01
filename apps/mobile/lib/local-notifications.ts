/**
 * Local notifications seam — scheduled reminders only (no remote push).
 *
 * `expo-notifications` is required lazily so importing this module never
 * requests permission or touches the native module.
 */
import { Platform } from 'react-native';

type NotificationsModule = typeof import('expo-notifications');

const CHANNEL_ID = 'reminders';
const CHANNEL_NAME = 'Reminders';

let notifications: NotificationsModule | null = null;
let channelReady = false;

function loadNotifications(): NotificationsModule {
  if (!notifications) {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    notifications = require('expo-notifications') as NotificationsModule;
  }
  return notifications;
}

/** True after expo-notifications has been required (tests / observability). */
export function isNotificationsModuleLoaded(): boolean {
  return notifications !== null;
}

/** Test-only: clear the lazy module cache. */
export function __resetNotificationsForTests(): void {
  notifications = null;
  channelReady = false;
}

export type NotificationResult =
  | { ok: true; identifier?: string }
  | {
      ok: false;
      reason: 'permission-denied' | 'dependency-unavailable' | 'error';
      message: string;
    };

export type ReminderTrigger =
  { type: 'daily'; hour: number; minute: number } | { type: 'date'; date: Date };

export type ScheduleReminderInput = {
  id: string;
  title: string;
  body: string;
  trigger: ReminderTrigger;
};

export type ScheduledReminder = {
  id: string;
  title: string | null | undefined;
  body: string | null | undefined;
};

async function ensureAndroidChannel(mod: NotificationsModule): Promise<void> {
  if (Platform.OS !== 'android' || channelReady) return;
  await mod.setNotificationChannelAsync(CHANNEL_ID, {
    name: CHANNEL_NAME,
    importance: mod.AndroidImportance.DEFAULT,
  });
  channelReady = true;
}

function isGranted(status: { granted?: boolean; status?: string }): boolean {
  return status.granted === true || status.status === 'granted';
}

/**
 * Request notification permission. Never throws — returns granted/denied.
 */
export async function requestPermission(): Promise<NotificationResult> {
  try {
    const mod = loadNotifications();
    // Android 13+ shows the system prompt only after a channel exists.
    await ensureAndroidChannel(mod);
    let permission = await mod.getPermissionsAsync();
    if (!isGranted(permission)) {
      permission = await mod.requestPermissionsAsync();
    }
    return isGranted(permission)
      ? { ok: true }
      : {
          ok: false,
          reason: 'permission-denied',
          message: 'Notification permission was not granted.',
        };
  } catch (error) {
    return {
      ok: false,
      reason: 'dependency-unavailable',
      message: error instanceof Error ? error.message : 'Notifications unavailable.',
    };
  }
}

/**
 * Schedule a local reminder (daily time or one-off date). Local only —
 * never requests a push token.
 */
export async function scheduleReminder(input: ScheduleReminderInput): Promise<NotificationResult> {
  try {
    const mod = loadNotifications();
    await ensureAndroidChannel(mod);

    const permission = await mod.getPermissionsAsync();
    if (!isGranted(permission)) {
      return {
        ok: false,
        reason: 'permission-denied',
        message: 'Notification permission was not granted.',
      };
    }

    const channel = Platform.OS === 'android' ? ({ channelId: CHANNEL_ID } as const) : {};

    const trigger =
      input.trigger.type === 'daily'
        ? {
            type: mod.SchedulableTriggerInputTypes.DAILY,
            hour: input.trigger.hour,
            minute: input.trigger.minute,
            ...channel,
          }
        : {
            type: mod.SchedulableTriggerInputTypes.DATE,
            date: input.trigger.date,
            ...channel,
          };

    const identifier = await mod.scheduleNotificationAsync({
      identifier: input.id,
      content: {
        title: input.title,
        body: input.body,
      },
      trigger: trigger as import('expo-notifications').NotificationTriggerInput,
    });

    return { ok: true, identifier };
  } catch (error) {
    return {
      ok: false,
      reason: 'error',
      message: error instanceof Error ? error.message : 'Failed to schedule reminder.',
    };
  }
}

export async function cancelReminder(id: string): Promise<NotificationResult> {
  try {
    const mod = loadNotifications();
    await mod.cancelScheduledNotificationAsync(id);
    return { ok: true, identifier: id };
  } catch (error) {
    return {
      ok: false,
      reason: 'error',
      message: error instanceof Error ? error.message : 'Failed to cancel reminder.',
    };
  }
}

export async function cancelAll(): Promise<NotificationResult> {
  try {
    const mod = loadNotifications();
    await mod.cancelAllScheduledNotificationsAsync();
    return { ok: true };
  } catch (error) {
    return {
      ok: false,
      reason: 'error',
      message: error instanceof Error ? error.message : 'Failed to cancel reminders.',
    };
  }
}

export async function listScheduled(): Promise<ScheduledReminder[]> {
  try {
    const mod = loadNotifications();
    const scheduled = await mod.getAllScheduledNotificationsAsync();
    return scheduled.map((item) => ({
      id: item.identifier,
      title: item.content.title,
      body: item.content.body,
    }));
  } catch {
    return [];
  }
}
