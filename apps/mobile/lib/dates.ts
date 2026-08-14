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

/** Parse `YYYY-MM-DD` into a local Date at midnight. Invalid calendar dates return null. */
export function parseIsoDateLocal(isoDate: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDate);
  if (!match) return null;
  const year = Number.parseInt(match[1], 10);
  const month = Number.parseInt(match[2], 10);
  const day = Number.parseInt(match[3], 10);
  if (!year || month < 1 || month > 12 || day < 1 || day > 31) return null;
  const date = new Date(year, month - 1, day);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }
  return date;
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
