import { recordStreak, type StreakState } from '@/lib/streak';

type ZonedNow = { day: string; zone: string };
const zonedDay = (now: ZonedNow) => now.day;
const at = (day: string, zone = 'America/Chicago'): ZonedNow => ({ day, zone });

describe('recordStreak', () => {
  it('increments on consecutive calendar days', () => {
    const first = recordStreak(null, at('2026-07-23'), zonedDay);
    expect(recordStreak(first, at('2026-07-24'), zonedDay)).toEqual({
      count: 2,
      lastDayKey: '2026-07-24',
    });
  });

  it('resets after a skipped day', () => {
    const prior: StreakState = { count: 8, lastDayKey: '2026-07-22' };
    expect(recordStreak(prior, at('2026-07-24'), zonedDay)).toEqual({
      count: 1,
      lastDayKey: '2026-07-24',
    });
  });

  it('is idempotent for repeated calls on the same day', () => {
    const prior: StreakState = { count: 3, lastDayKey: '2026-07-24' };
    expect(recordStreak(prior, at('2026-07-24'), zonedDay)).toBe(prior);
  });

  it('increments across a DST transition calendar boundary', () => {
    const beforeSpringForward: StreakState = { count: 4, lastDayKey: '2026-03-07' };
    expect(recordStreak(beforeSpringForward, at('2026-03-08'), zonedDay).count).toBe(5);
  });

  it('does not break a streak when a timezone change moves the day key backward', () => {
    const prior: StreakState = { count: 5, lastDayKey: '2026-07-24' };
    const movedWest = at('2026-07-23', 'Pacific/Honolulu');
    expect(recordStreak(prior, movedWest, zonedDay)).toBe(prior);
  });
});
