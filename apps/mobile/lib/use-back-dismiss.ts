/**
 * Close an open overlay with Android's hardware back button.
 *
 * @gorhom/bottom-sheet registers no back handler of its own, so back falls
 * through to the navigator: the tab changes underneath while the sheet stays
 * open. Call this whenever an overlay owns the screen.
 *
 * `onBack` should be stable (wrap it in useCallback) — the listener
 * re-subscribes whenever it changes. No-ops off Android, where back does not
 * exist.
 */
import { useEffect } from 'react';
import { BackHandler, Platform } from 'react-native';

export function useBackDismiss(active: boolean, onBack: () => void): void {
  useEffect(() => {
    if (!active || Platform.OS !== 'android') return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      onBack();
      // Consume the press so the navigator does not also act on it.
      return true;
    });
    return () => subscription.remove();
  }, [active, onBack]);
}
