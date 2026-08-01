/**
 * Sentry wiring — dormant until EXPO_PUBLIC_SENTRY_DSN is set.
 *
 * Current API (Context7 /getsentry/sentry-docs + sentry-react-native, checked 2026-07-21):
 *   Sentry.init({ dsn }), Sentry.captureException, Sentry.wrap(RootLayout)
 *   Expo plugin: "@sentry/react-native" or "@sentry/react-native/expo"
 *     with organization + project placeholders for sourcemap upload.
 *
 * The SDK is require()'d only when a DSN is present so Expo Go / no-DSN
 * never loads the native module (R5).
 */
import type { ComponentType } from 'react';

type SentryModule = typeof import('@sentry/react-native');

let Sentry: SentryModule | null = null;
let initialized = false;

export function initSentryIfConfigured(): boolean {
  if (initialized) return true;
  const dsn = process.env.EXPO_PUBLIC_SENTRY_DSN?.trim();
  if (!dsn) return false;

  // eslint-disable-next-line @typescript-eslint/no-require-imports
  Sentry = require('@sentry/react-native') as SentryModule;
  Sentry.init({
    dsn,
    environment: __DEV__ ? 'development' : 'production',
    tracesSampleRate: 0,
  });
  initialized = true;
  return true;
}

export function isSentryInitialized(): boolean {
  return initialized;
}

export function captureException(error: unknown, context?: Record<string, unknown>): void {
  if (!initialized || !Sentry) return;
  Sentry.withScope((scope) => {
    if (context) {
      scope.setExtras(context);
    }
    Sentry!.captureException(error instanceof Error ? error : new Error(String(error)));
  });
}

/** Root wrap — only call after initSentryIfConfigured() returned true. */
export function wrapRoot<P extends Record<string, unknown>>(
  RootComponent: ComponentType<P>
): ComponentType<P> {
  if (!Sentry) return RootComponent;
  return Sentry.wrap(RootComponent);
}
