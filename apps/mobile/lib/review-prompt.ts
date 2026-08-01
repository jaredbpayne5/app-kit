/**
 * In-app review prompt — once per install, after a positive moment.
 *
 * Lazily requires `expo-store-review`. Writes the "already asked" flag *before*
 * `requestReview` so a dismissed prompt never becomes a second ask.
 */
import { reportError } from '@/lib/report-error';
import { getJSON, setJSON } from '@/lib/storage';

export const REVIEW_PROMPTED_STORAGE_KEY = 'app.reviewPrompted';

export type ReviewPromptOutcome = 'prompted' | 'already-prompted' | 'unavailable' | 'error';

type StoreReviewModule = typeof import('expo-store-review');

let storeReview: StoreReviewModule | null = null;

function loadStoreReview(): StoreReviewModule {
  if (!storeReview) {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    storeReview = require('expo-store-review') as StoreReviewModule;
  }
  return storeReview;
}

/** Test-only: clear the lazy module cache. */
export function __resetReviewPromptForTests(): void {
  storeReview = null;
}

export async function hasPromptedForReview(): Promise<boolean> {
  return (await getJSON<boolean>(REVIEW_PROMPTED_STORAGE_KEY)) === true;
}

/**
 * Ask for a store review at most once per install. Never throws.
 */
export async function maybeRequestReview(): Promise<ReviewPromptOutcome> {
  try {
    if (await hasPromptedForReview()) return 'already-prompted';

    const mod = loadStoreReview();
    if (!(await mod.isAvailableAsync())) return 'unavailable';

    await setJSON(REVIEW_PROMPTED_STORAGE_KEY, true);
    await mod.requestReview();
    return 'prompted';
  } catch (error) {
    reportError(error, { scope: 'reviewPrompt.maybeRequestReview' });
    return 'error';
  }
}
