import { Link, Stack } from 'expo-router';
import { View } from 'react-native';
import { Button } from '@/ui/button';
import { Text } from '@/ui/text';

export default function NotFoundScreen() {
  return (
    <>
      <Stack.Screen options={{ title: 'Oops!' }} />
      <View
        className="flex-1 items-center justify-center gap-6 bg-background p-6"
        testID="not-found-screen">
        <View className="gap-2">
          <Text variant="h3" className="text-center">
            This screen doesn’t exist
          </Text>
          <Text variant="muted" className="text-center">
            The page you were looking for couldn’t be found.
          </Text>
        </View>
        <Link href="/" asChild>
          <Button variant="outline" testID="link-home" accessibilityLabel="Go to home screen">
            <Text>Go to home screen</Text>
          </Button>
        </Link>
      </View>
    </>
  );
}
