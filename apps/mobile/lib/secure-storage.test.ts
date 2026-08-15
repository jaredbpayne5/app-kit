import { reportError } from '@/lib/report-error';
import { Platform } from 'react-native';
import {
  __resetSecureStoreForTests,
  deleteSecret,
  getSecret,
  isSecureStoreLoaded,
  setSecret,
} from '@/lib/secure-storage';

const mockGetItemAsync = jest.fn();
const mockSetItemAsync = jest.fn();
const mockDeleteItemAsync = jest.fn();
const mockIsAvailableAsync = jest.fn();

jest.mock('expo-secure-store', () => ({
  getItemAsync: (...args: unknown[]) => mockGetItemAsync(...args),
  setItemAsync: (...args: unknown[]) => mockSetItemAsync(...args),
  deleteItemAsync: (...args: unknown[]) => mockDeleteItemAsync(...args),
  isAvailableAsync: (...args: unknown[]) => mockIsAvailableAsync(...args),
}));

jest.mock('@/lib/report-error', () => ({
  reportError: jest.fn(),
}));

describe('secure-storage seam', () => {
  const previousOs = Platform.OS;

  beforeEach(() => {
    __resetSecureStoreForTests();
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { configurable: true, get: () => 'ios' });
    mockIsAvailableAsync.mockResolvedValue(true);
    mockGetItemAsync.mockResolvedValue(null);
    mockSetItemAsync.mockResolvedValue(undefined);
    mockDeleteItemAsync.mockResolvedValue(undefined);
  });

  afterEach(() => {
    Object.defineProperty(Platform, 'OS', { configurable: true, get: () => previousOs });
  });

  it('does not load the native module on import', () => {
    expect(isSecureStoreLoaded()).toBe(false);
  });

  it('getSecret loads the module and returns the stored value', async () => {
    mockGetItemAsync.mockResolvedValue('tok_123');
    await expect(getSecret('session')).resolves.toBe('tok_123');
    expect(isSecureStoreLoaded()).toBe(true);
    expect(mockGetItemAsync).toHaveBeenCalledWith('session');
  });

  it('setSecret and deleteSecret go through the native module', async () => {
    await setSecret('session', 'tok_123');
    expect(mockSetItemAsync).toHaveBeenCalledWith('session', 'tok_123');
    await deleteSecret('session');
    expect(mockDeleteItemAsync).toHaveBeenCalledWith('session');
  });

  it('web: getSecret returns null without loading; set/delete throw', async () => {
    Object.defineProperty(Platform, 'OS', { configurable: true, get: () => 'web' });
    await expect(getSecret('session')).resolves.toBeNull();
    expect(isSecureStoreLoaded()).toBe(false);
    await expect(setSecret('session', 'tok_123')).rejects.toThrow('not available on web');
    await expect(deleteSecret('session')).rejects.toThrow('not available on web');
    expect(mockSetItemAsync).not.toHaveBeenCalled();
  });

  it('unavailable store: getSecret returns null; set/delete throw without reportError', async () => {
    mockIsAvailableAsync.mockResolvedValue(false);

    await expect(getSecret('session')).resolves.toBeNull();
    await expect(setSecret('session', 'tok_123')).rejects.toThrow('not available on this device');
    await expect(deleteSecret('session')).rejects.toThrow('not available on this device');

    expect(mockGetItemAsync).not.toHaveBeenCalled();
    expect(mockSetItemAsync).not.toHaveBeenCalled();
    expect(mockDeleteItemAsync).not.toHaveBeenCalled();
    expect(reportError).not.toHaveBeenCalled();
  });
});
