import { Platform } from 'react-native';
import {
  __resetNotificationsForTests,
  cancelAll,
  cancelReminder,
  initNotificationHandler,
  isNotificationsModuleLoaded,
  listScheduled,
  requestPermission,
  scheduleReminder,
} from '@/lib/local-notifications';

const mockGetPermissionsAsync = jest.fn();
const mockRequestPermissionsAsync = jest.fn();
const mockScheduleNotificationAsync = jest.fn();
const mockCancelScheduledNotificationAsync = jest.fn();
const mockCancelAllScheduledNotificationsAsync = jest.fn();
const mockGetAllScheduledNotificationsAsync = jest.fn();
const mockSetNotificationChannelAsync = jest.fn();

jest.mock('expo-notifications', () => ({
  getPermissionsAsync: (...args: unknown[]) => mockGetPermissionsAsync(...args),
  requestPermissionsAsync: (...args: unknown[]) => mockRequestPermissionsAsync(...args),
  scheduleNotificationAsync: (...args: unknown[]) => mockScheduleNotificationAsync(...args),
  cancelScheduledNotificationAsync: (...args: unknown[]) =>
    mockCancelScheduledNotificationAsync(...args),
  cancelAllScheduledNotificationsAsync: (...args: unknown[]) =>
    mockCancelAllScheduledNotificationsAsync(...args),
  getAllScheduledNotificationsAsync: (...args: unknown[]) =>
    mockGetAllScheduledNotificationsAsync(...args),
  setNotificationChannelAsync: (...args: unknown[]) => mockSetNotificationChannelAsync(...args),
  setNotificationHandler: jest.fn(),
  AndroidImportance: { DEFAULT: 5 },
  SchedulableTriggerInputTypes: { DAILY: 'daily', DATE: 'date' },
}));

describe('local notifications seam', () => {
  const previousOs = Platform.OS;

  beforeEach(() => {
    __resetNotificationsForTests();
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { configurable: true, get: () => 'android' });
    mockGetPermissionsAsync.mockResolvedValue({ status: 'granted', granted: true });
    mockRequestPermissionsAsync.mockResolvedValue({ status: 'granted', granted: true });
    mockScheduleNotificationAsync.mockResolvedValue('reminder-1');
    mockCancelScheduledNotificationAsync.mockResolvedValue(undefined);
    mockCancelAllScheduledNotificationsAsync.mockResolvedValue(undefined);
    mockGetAllScheduledNotificationsAsync.mockResolvedValue([]);
    mockSetNotificationChannelAsync.mockResolvedValue(null);
  });

  afterEach(() => {
    Object.defineProperty(Platform, 'OS', { configurable: true, get: () => previousOs });
  });

  it('does not load the native module on import', () => {
    expect(isNotificationsModuleLoaded()).toBe(false);
  });

  it('initNotificationHandler loads the module and registers the foreground handler', () => {
    const { setNotificationHandler } = jest.requireMock('expo-notifications') as {
      setNotificationHandler: jest.Mock;
    };
    initNotificationHandler();
    expect(isNotificationsModuleLoaded()).toBe(true);
    expect(setNotificationHandler).toHaveBeenCalledTimes(1);
  });

  it('permission denied: requestPermission returns denied without throwing', async () => {
    mockGetPermissionsAsync.mockResolvedValue({ status: 'denied', granted: false });
    mockRequestPermissionsAsync.mockResolvedValue({ status: 'denied', granted: false });

    await expect(requestPermission()).resolves.toEqual({
      ok: false,
      reason: 'permission-denied',
      message: 'Notification permission was not granted.',
    });
    expect(isNotificationsModuleLoaded()).toBe(true);
  });

  it('permission denied: scheduleReminder returns denied without throwing', async () => {
    mockGetPermissionsAsync.mockResolvedValue({ status: 'denied', granted: false });

    await expect(
      scheduleReminder({
        id: 'reminder-1',
        title: 'Stretch',
        body: 'Time to stand up.',
        trigger: { type: 'daily', hour: 9, minute: 0 },
      })
    ).resolves.toMatchObject({ ok: false, reason: 'permission-denied' });
    expect(mockScheduleNotificationAsync).not.toHaveBeenCalled();
  });

  it('creates an Android channel before scheduling', async () => {
    await scheduleReminder({
      id: 'reminder-1',
      title: 'Stretch',
      body: 'Time to stand up.',
      trigger: { type: 'daily', hour: 9, minute: 30 },
    });

    expect(mockSetNotificationChannelAsync).toHaveBeenCalledWith(
      'reminders',
      expect.objectContaining({ name: 'Reminders', importance: 5 })
    );
    expect(mockScheduleNotificationAsync).toHaveBeenCalledWith(
      expect.objectContaining({
        identifier: 'reminder-1',
        content: { title: 'Stretch', body: 'Time to stand up.' },
        trigger: expect.objectContaining({
          type: 'daily',
          hour: 9,
          minute: 30,
          channelId: 'reminders',
        }),
      })
    );
  });

  it('schedule then list then cancel', async () => {
    mockGetAllScheduledNotificationsAsync.mockResolvedValue([
      {
        identifier: 'reminder-1',
        content: { title: 'Stretch', body: 'Time to stand up.' },
      },
    ]);

    await expect(
      scheduleReminder({
        id: 'reminder-1',
        title: 'Stretch',
        body: 'Time to stand up.',
        trigger: { type: 'date', date: new Date('2030-01-01T12:00:00Z') },
      })
    ).resolves.toEqual({ ok: true, identifier: 'reminder-1' });

    await expect(listScheduled()).resolves.toEqual([
      { id: 'reminder-1', title: 'Stretch', body: 'Time to stand up.' },
    ]);

    await expect(cancelReminder('reminder-1')).resolves.toEqual({
      ok: true,
      identifier: 'reminder-1',
    });
    expect(mockCancelScheduledNotificationAsync).toHaveBeenCalledWith('reminder-1');

    await expect(cancelAll()).resolves.toEqual({ ok: true });
    expect(mockCancelAllScheduledNotificationsAsync).toHaveBeenCalled();
  });
});
