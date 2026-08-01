// Reanimated ships a Jest mock; without it every component that imports
// Animated tries to reach the native worklets runtime and throws.
require('react-native-reanimated').setUpTests();
