export type StreakState = {
  count: number;
  lastDayKey: string | null;
};

export type DayKey<TNow> = (now: TNow) => string;

function dayOrdinal(dayKey: string): number {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(dayKey);
  if (!match) throw new Error(`Invalid day key "${dayKey}"; expected YYYY-MM-DD`);

  let year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  year -= month <= 2 ? 1 : 0;
  const era = Math.floor(year / 400);
  const yearOfEra = year - era * 400;
  const shiftedMonth = month + (month > 2 ? -3 : 9);
  const dayOfYear = Math.floor((153 * shiftedMonth + 2) / 5) + day - 1;
  const dayOfEra =
    yearOfEra * 365 + Math.floor(yearOfEra / 4) - Math.floor(yearOfEra / 100) + dayOfYear;
  return era * 146097 + dayOfEra;
}

/**
 * Records one activity day. Time and timezone policy are injected through
 * `now` + `dayKey`; this logic never reads the system clock.
 */
export function recordStreak<TNow>(
  previous: StreakState | null,
  now: TNow,
  dayKey: DayKey<TNow>
): StreakState {
  const today = dayKey(now);
  dayOrdinal(today); // validate even on the first call
  if (!previous?.lastDayKey) return { count: 1, lastDayKey: today };

  const difference = dayOrdinal(today) - dayOrdinal(previous.lastDayKey);
  if (difference <= 0) return previous;
  if (difference === 1) return { count: previous.count + 1, lastDayKey: today };
  return { count: 1, lastDayKey: today };
}
