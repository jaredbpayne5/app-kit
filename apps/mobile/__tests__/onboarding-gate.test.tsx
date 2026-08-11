/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before the module under test */
import { act, render, screen, waitFor } from '@testing-library/react-native';
import React from 'react';
import { Text, View } from 'react-native';

/**
 * The onboarding gate is the single most load-bearing piece of routing in the
 * template, and it has no UI of its own — so it is easy to break silently.
 *
 * It used to live inside `app/(tabs)/index.tsx`, the demo home screen every
 * clone is told to replace. Replacing that file deleted onboarding and nothing
 * failed. These tests cover the behaviour directly.
 */

const mockGetJSON = jest.fn();
const mockSetJSON = jest.fn(async (..._args: unknown[]) => undefined);
const mockRemove = jest.fn(async (..._args: unknown[]) => undefined);
const mockReportError = jest.fn();

jest.mock('@/lib/storage', () => ({
  getJSON: (...args: unknown[]) => mockGetJSON(...args),
  setJSON: (...args: unknown[]) => mockSetJSON(...args),
  remove: (...args: unknown[]) => mockRemove(...args),
}));

jest.mock('@/lib/report-error', () => ({
  reportError: (...args: unknown[]) => mockReportError(...args),
}));

import {
  markOnboardingSeen,
  ONBOARDING_STORAGE_KEY,
  resetOnboardingSeen,
  useOnboardingGate,
} from '@/lib/onboarding';

/** Mirrors how app/_layout.tsx consumes the gate. */
function GateProbe() {
  const { ready, seen } = useOnboardingGate();
  if (!ready) return <View testID="splash-held" />;
  return (
    <View testID="gate">
      <Text testID="destination">{seen ? 'tabs' : 'onboarding'}</Text>
    </View>
  );
}

describe('useOnboardingGate', () => {
  beforeEach(() => {
    mockGetJSON.mockReset();
    mockSetJSON.mockClear();
    mockRemove.mockClear();
    mockReportError.mockClear();
  });

  it('holds the splash until storage has been read', async () => {
    let resolveRead: (value: boolean | null) => void = () => {};
    mockGetJSON.mockReturnValue(
      new Promise<boolean | null>((resolve) => {
        resolveRead = resolve;
      })
    );

    render(<GateProbe />);
    expect(screen.getByTestId('splash-held')).toBeTruthy();

    await act(async () => {
      resolveRead(true);
    });
    expect(screen.getByTestId('gate')).toBeTruthy();
  });

  it('routes an unseen user to onboarding', async () => {
    mockGetJSON.mockResolvedValue(null);
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('onboarding');
    });
    expect(mockGetJSON).toHaveBeenCalledWith(ONBOARDING_STORAGE_KEY);
  });

  it('routes a returning user to the tabs', async () => {
    mockGetJSON.mockResolvedValue(true);
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('tabs');
    });
  });

  it('treats a non-true stored value as unseen', async () => {
    mockGetJSON.mockResolvedValue(false);
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('onboarding');
    });
  });

  it('fails open to onboarding when storage throws', async () => {
    mockGetJSON.mockRejectedValue(new Error('disk gone'));
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('onboarding');
    });
    expect(mockReportError).toHaveBeenCalledWith(expect.any(Error), { scope: 'onboarding.gate' });
  });

  it('reacts to completion without a remount', async () => {
    mockGetJSON.mockResolvedValue(null);
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('onboarding');
    });

    mockGetJSON.mockResolvedValue(true);
    await act(async () => {
      await markOnboardingSeen();
    });

    expect(mockSetJSON).toHaveBeenCalledWith(ONBOARDING_STORAGE_KEY, true);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('tabs');
    });
  });

  // Settings → Reset onboarding clears the key at runtime. A read-once gate
  // would leave the user stranded in the tabs until a force-quit.
  it('reacts to a runtime reset without a remount', async () => {
    mockGetJSON.mockResolvedValue(true);
    render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('tabs');
    });

    mockGetJSON.mockResolvedValue(null);
    await act(async () => {
      await resetOnboardingSeen();
    });

    expect(mockRemove).toHaveBeenCalledWith(ONBOARDING_STORAGE_KEY);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('onboarding');
    });
  });

  it('stops listening after unmount', async () => {
    mockGetJSON.mockResolvedValue(true);
    const view = render(<GateProbe />);
    await waitFor(() => {
      expect(screen.getByTestId('destination')).toHaveTextContent('tabs');
    });

    view.unmount();
    const callsBefore = mockGetJSON.mock.calls.length;
    await act(async () => {
      await resetOnboardingSeen();
    });
    expect(mockGetJSON.mock.calls.length).toBe(callsBefore);
  });
});

describe('root layout gate wiring', () => {
  // Structural guard: Stack.Protected is what makes deep links unable to skip
  // onboarding. A plain <Stack> with both screens always registered would let
  // /library resolve directly.
  it('protects both routes at the root layout', () => {
    const source = require('fs').readFileSync(
      require('path').join(__dirname, '..', 'app', '_layout.tsx'),
      'utf8'
    );
    expect(source).toContain('useOnboardingGate');
    expect(source).toMatch(/<Stack\.Protected guard=\{seen\}>/);
    expect(source).toMatch(/<Stack\.Protected guard=\{!seen\}>/);
    expect(source).toContain('preventAutoHideAsync');
  });
});
