/**
 * Vendor-agnostic error reporting seam.
 * Default: log in __DEV__, no-op in production (no DSN).
 * When EXPO_PUBLIC_SENTRY_DSN is set and initSentryIfConfigured() ran, forwards to Sentry.
 */
import { captureException, isSentryInitialized } from '@/lib/sentry';

export function reportError(error: unknown, context?: Record<string, unknown>): void {
  if (isSentryInitialized()) {
    captureException(error, context);
  }

  if (!__DEV__) return;

  const err = error instanceof Error ? error : new Error(String(error));
  if (context && Object.keys(context).length > 0) {
    console.error('[reportError]', err, context);
  } else {
    console.error('[reportError]', err);
  }
}
