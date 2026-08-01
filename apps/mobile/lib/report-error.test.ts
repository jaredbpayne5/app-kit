import { reportError } from '@/lib/report-error';

const mockCapture = jest.fn();
const mockIsInit = jest.fn(() => false);

jest.mock('@/lib/sentry', () => ({
  captureException: (...args: unknown[]) => mockCapture(...args),
  isSentryInitialized: () => mockIsInit(),
}));

describe('lib/report-error', () => {
  beforeEach(() => {
    mockCapture.mockReset();
    mockIsInit.mockReturnValue(false);
  });

  it('does not throw when called with an Error (no Sentry)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => reportError(new Error('boom'), { screen: 'home' })).not.toThrow();
    expect(mockCapture).not.toHaveBeenCalled();
    spy.mockRestore();
  });

  it('does not throw when called with a string (no Sentry)', () => {
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => reportError('boom')).not.toThrow();
    expect(mockCapture).not.toHaveBeenCalled();
    spy.mockRestore();
  });

  it('forwards to Sentry when initialized', () => {
    mockIsInit.mockReturnValue(true);
    const spy = jest.spyOn(console, 'error').mockImplementation(() => {});
    const err = new Error('wired');
    expect(() => reportError(err, { screen: 'settings' })).not.toThrow();
    expect(mockCapture).toHaveBeenCalledWith(err, { screen: 'settings' });
    spy.mockRestore();
  });
});
