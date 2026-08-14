import { formatIsoDateLabel, parseIsoDateLocal, toIsoDateLocal } from '@/lib/dates';

describe('toIsoDateLocal', () => {
  it('formats local calendar components without UTC shift', () => {
    expect(toIsoDateLocal(new Date(2026, 0, 15))).toBe('2026-01-15');
    expect(toIsoDateLocal(new Date(2026, 11, 31))).toBe('2026-12-31');
  });
});

describe('parseIsoDateLocal', () => {
  it('parses YYYY-MM-DD as local midnight', () => {
    const date = parseIsoDateLocal('2026-07-04');
    expect(date).not.toBeNull();
    expect(date!.getFullYear()).toBe(2026);
    expect(date!.getMonth()).toBe(6);
    expect(date!.getDate()).toBe(4);
  });

  it('returns null for invalid input', () => {
    expect(parseIsoDateLocal('nope')).toBeNull();
    expect(parseIsoDateLocal('2026-02-31')).toBeNull();
  });
});

describe('formatIsoDateLabel', () => {
  it('returns a non-empty locale label', () => {
    expect(formatIsoDateLabel('2026-01-15').length).toBeGreaterThan(0);
  });
});
