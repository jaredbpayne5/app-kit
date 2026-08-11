import { reportError } from '@/lib/report-error';
import { getJSON, remove, setJSON } from '@/lib/storage';
import { useEffect, useState } from 'react';

/**
 * Onboarding gate seam.
 *
 * The gate is read by the ROOT layout (`app/_layout.tsx`), not by any screen.
 * Keep it that way: an earlier version lived inside `app/(tabs)/index.tsx` —
 * the demo home screen that every product clone is told to replace — so
 * replacing home silently deleted onboarding, and a deep link to another tab
 * bypassed it entirely.
 *
 * State is reactive rather than read-once because onboarding can be reset at
 * runtime (Settings → Reset onboarding). With a one-shot read the key would be
 * cleared while the gate still believed onboarding was seen, stranding the user
 * in the tabs until a force-quit.
 */

/** Storage key via `@/lib/storage` — onboarding shown once. */
export const ONBOARDING_STORAGE_KEY = 'onboarding.seen';

type Listener = () => void;
const listeners = new Set<Listener>();

function notifyOnboardingChanged(): void {
  for (const listener of [...listeners]) listener();
}

function subscribe(listener: Listener): () => void {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

/** Mark onboarding complete and wake the root gate. */
export async function markOnboardingSeen(): Promise<void> {
  await setJSON(ONBOARDING_STORAGE_KEY, true);
  notifyOnboardingChanged();
}

/** Clear onboarding and wake the root gate (Settings → Reset onboarding). */
export async function resetOnboardingSeen(): Promise<void> {
  await remove(ONBOARDING_STORAGE_KEY);
  notifyOnboardingChanged();
}

export type OnboardingGate = {
  /** False until the stored value has been read at least once. */
  ready: boolean;
  /** True when onboarding has been completed. */
  seen: boolean;
};

/**
 * Reactive onboarding state for the root navigator.
 *
 * Fails **open** to onboarding: if storage throws, we show onboarding rather
 * than risk a cold start that renders nothing at all.
 */
export function useOnboardingGate(): OnboardingGate {
  const [gate, setGate] = useState<OnboardingGate>({ ready: false, seen: false });

  useEffect(() => {
    let mounted = true;

    async function read(): Promise<void> {
      try {
        const seen = await getJSON<boolean>(ONBOARDING_STORAGE_KEY);
        if (mounted) setGate({ ready: true, seen: seen === true });
      } catch (error) {
        reportError(error, { scope: 'onboarding.gate' });
        if (mounted) setGate({ ready: true, seen: false });
      }
    }

    void read();
    const unsubscribe = subscribe(() => {
      void read();
    });

    return () => {
      mounted = false;
      unsubscribe();
    };
  }, []);

  return gate;
}
