import {
  REVIEW_PROMPTED_STORAGE_KEY,
  __resetReviewPromptForTests,
  maybeRequestReview,
} from '@/lib/review-prompt';
import { getJSON, setJSON } from '@/lib/storage';

jest.mock('@/lib/storage', () => ({
  getJSON: jest.fn(),
  setJSON: jest.fn(),
}));

jest.mock('@/lib/report-error', () => ({
  reportError: jest.fn(),
}));

const mockIsAvailableAsync = jest.fn();
const mockRequestReview = jest.fn();

jest.mock('expo-store-review', () => ({
  isAvailableAsync: (...args: unknown[]) => mockIsAvailableAsync(...args),
  requestReview: (...args: unknown[]) => mockRequestReview(...args),
}));

describe('maybeRequestReview', () => {
  beforeEach(() => {
    __resetReviewPromptForTests();
    jest.clearAllMocks();
    (getJSON as jest.Mock).mockResolvedValue(null);
    (setJSON as jest.Mock).mockResolvedValue(undefined);
    mockIsAvailableAsync.mockResolvedValue(true);
    mockRequestReview.mockResolvedValue(undefined);
  });

  it('prompts once and stores the flag before requesting', async () => {
    await expect(maybeRequestReview()).resolves.toBe('prompted');
    expect(setJSON).toHaveBeenCalledWith(REVIEW_PROMPTED_STORAGE_KEY, true);
    expect(mockRequestReview).toHaveBeenCalledTimes(1);
  });

  it('skips when already prompted', async () => {
    (getJSON as jest.Mock).mockResolvedValue(true);
    await expect(maybeRequestReview()).resolves.toBe('already-prompted');
    expect(mockRequestReview).not.toHaveBeenCalled();
  });

  it('returns unavailable when the store UI is not available', async () => {
    mockIsAvailableAsync.mockResolvedValue(false);
    await expect(maybeRequestReview()).resolves.toBe('unavailable');
    expect(setJSON).not.toHaveBeenCalled();
  });
});
