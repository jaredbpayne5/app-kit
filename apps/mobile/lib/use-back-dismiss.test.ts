import { useBackDismiss } from '@/lib/use-back-dismiss';
import { renderHook } from '@testing-library/react-native';
import { BackHandler, Platform } from 'react-native';

const remove = jest.fn();
const addEventListener = jest
  .spyOn(BackHandler, 'addEventListener')
  .mockImplementation(() => ({ remove }) as never);

function pressBack(): boolean | null | undefined {
  const handler = addEventListener.mock.calls.at(-1)?.[1];
  return handler?.();
}

describe('useBackDismiss', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Platform.OS = 'android';
  });

  it('dismisses and swallows the press while active', () => {
    const onBack = jest.fn();
    renderHook(() => useBackDismiss(true, onBack));

    expect(pressBack()).toBe(true);
    expect(onBack).toHaveBeenCalledTimes(1);
  });

  it('does not listen while inactive', () => {
    renderHook(() => useBackDismiss(false, jest.fn()));

    expect(addEventListener).not.toHaveBeenCalled();
  });

  it('unsubscribes when the overlay closes', () => {
    const { rerender } = renderHook(
      ({ active }: { active: boolean }) => useBackDismiss(active, jest.fn()),
      { initialProps: { active: true } }
    );

    rerender({ active: false });

    expect(remove).toHaveBeenCalledTimes(1);
  });

  it('stays out of the way off Android', () => {
    Platform.OS = 'ios';
    renderHook(() => useBackDismiss(true, jest.fn()));

    expect(addEventListener).not.toHaveBeenCalled();
  });
});
