/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before icon import */
import { EmptyState } from '@/components/empty-state';
import { fireEvent, render, screen } from '@testing-library/react-native';

jest.mock('lucide-react-native', () => require('@/__tests__/test-utils').mockLucideIcons());
jest.mock('@/ui/icon', () => require('@/__tests__/test-utils').mockUiIcon('empty-icon'));
jest.mock('@/ui/button', () => require('@/__tests__/test-utils').mockUiButton());
jest.mock('@/ui/text', () => require('@/__tests__/test-utils').mockUiText());

import { InboxIcon } from 'lucide-react-native';

describe('EmptyState', () => {
  it('renders title body and fires primary action', () => {
    const onAction = jest.fn();
    render(
      <EmptyState
        icon={InboxIcon}
        title="Nothing here"
        body="Add your first item."
        actionLabel="Add item"
        onAction={onAction}
      />
    );
    expect(screen.getByTestId('empty-state')).toBeTruthy();
    expect(screen.getByText('Nothing here')).toBeTruthy();
    fireEvent.press(screen.getByTestId('empty-state-action'));
    expect(onAction).toHaveBeenCalled();
  });
});
