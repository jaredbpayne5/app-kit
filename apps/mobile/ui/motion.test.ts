import { readFileSync } from 'node:fs';
import { join } from 'node:path';

describe('ui/motion cssInterop trap', () => {
  it('registers a private AnimatedView copy, not shared Animated.View', () => {
    const source = readFileSync(join(__dirname, 'motion.tsx'), 'utf8');
    expect(source).toMatch(/createAnimatedComponent\(View\)/);
    expect(source).toMatch(/cssInterop\(AnimatedView/);
    expect(source).not.toMatch(/cssInterop\(\s*Animated\.View/);
    expect(source).not.toMatch(/cssInterop\(\s*Animated\s*,/);
  });
});
