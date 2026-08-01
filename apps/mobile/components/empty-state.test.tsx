/* eslint-disable @typescript-eslint/no-require-imports -- Jest mock factories need require() */
/* eslint-disable import/first -- mocks must run before icon import */
import { EmptyState } from '@/components/empty-state';
import { fireEvent, render, screen } from '@testing-library/react-native';

jest.mock('lucide-react-native', () => {
  const React = require('react');
  const { View } = require('react-native');
  const Stub = () => <View />;
  return { InboxIcon: Stub };
});

jest.mock('@/ui/icon', () => {
  const React = require('react');
  const { View } = require('react-native');
  return { Icon: () => <View testID="empty-icon" /> };
});

jest.mock('@/ui/button', () => {
  const React = require('react');
  const { Pressable } = require('react-native');
  return {
    Button: ({
      children,
      testID,
      onPress,
    }: {
      children?: React.ReactNode;
      testID?: string;
      onPress?: () => void;
    }) => (
      <Pressable testID={testID} onPress={onPress}>
        {children}
      </Pressable>
    ),
  };
});

jest.mock('@/ui/text', () => {
  const React = require('react');
  const { Text } = require('react-native');
  return {
    Text: ({ children, ...props }: { children?: React.ReactNode }) => (
      <Text {...props}>{children}</Text>
    ),
  };
});

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
