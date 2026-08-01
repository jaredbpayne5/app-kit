/**
 * Local calendar-day helpers. Never use `Date#toISOString()` for YYYY-MM-DD —
 * UTC conversion shifts the calendar day near midnight in many timezones.
 */

/** Format a local Date as `YYYY-MM-DD`. */
export function toIsoDateLocal(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/** Parse `YYYY-MM-DD` into a local Date at midnight. */
export function parseIsoDateLocal(isoDate: string): Date | null {
  const [year, month, day] = isoDate.split('-').map((part) => Number.parseInt(part, 10));
  if (!year || !month || !day) return null;
  return new Date(year, month - 1, day);
}

/** Locale-aware long date label for an ISO local date. */
export function formatIsoDateLabel(isoDate: string): string {
  const date = parseIsoDateLocal(isoDate);
  if (!date) return isoDate;
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}
