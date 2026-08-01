import { APP_CONFIG, MOCK_ENTITLED, PURCHASES_MODE } from '@/lib/app-config';

// The template ships with STORAGE kv / MONETIZATION free. A real app legitimately
// changes these, so the strict default assertions apply only while app.json still
// has the template placeholder bundle id (com.example.*). After that we only check
// each flag holds a valid value from its union — catches typos without failing
// paid apps.
const appJson = require('../app.json') as {
  expo?: { ios?: { bundleIdentifier?: string } };
};
const isTemplate = String(appJson.expo?.ios?.bundleIdentifier ?? '').startsWith('com.example.');

describe('APP_CONFIG spine', () => {
  it('STORAGE is a valid value (template default: kv)', () => {
    if (isTemplate) expect(APP_CONFIG.STORAGE).toBe('kv');
    else expect(['kv', 'sql']).toContain(APP_CONFIG.STORAGE);
  });

  it('MONETIZATION is a valid value (template default: free)', () => {
    if (isTemplate) expect(APP_CONFIG.MONETIZATION).toBe('free');
    else expect(['free', 'subscription', 'one-time']).toContain(APP_CONFIG.MONETIZATION);
  });

  it('PURCHASES_MODE is mock|live and MOCK_ENTITLED is boolean (template default: mock/true)', () => {
    if (isTemplate) {
      expect(PURCHASES_MODE).toBe('mock');
      expect(MOCK_ENTITLED).toBe(true);
    } else {
      expect(['mock', 'live']).toContain(PURCHASES_MODE);
      expect(typeof MOCK_ENTITLED).toBe('boolean');
    }
  });
});
