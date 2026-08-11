import normalizeColor from '@react-native/normalize-colors';

import { hslWithAlpha } from '@/lib/theme';

describe('hslWithAlpha', () => {
  it('emits hsla slash-alpha that React Native can normalize', () => {
    const out = hslWithAlpha('hsl(0 0% 9%)', 0.95);
    expect(out).toBe('hsla(0 0% 9% / 0.95)');
    // RN rejects slash-alpha on hsl(); only hsla() parses (normalize-colors@0.85.3).
    expect(normalizeColor(out)).not.toBeNull();
  });

  it('passes through strings that are not hsl(...) tokens', () => {
    expect(hslWithAlpha('red', 0.5)).toBe('red');
    expect(hslWithAlpha('hsla(0 0% 9% / 1)', 0.5)).toBe('hsla(0 0% 9% / 1)');
  });
});
