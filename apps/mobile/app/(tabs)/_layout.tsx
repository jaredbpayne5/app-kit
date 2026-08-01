import { TabBarIcon } from '@/components/tab-bar-icon';
import { ThemeToggle } from '@/components/header-chrome';
import { tapLight } from '@/lib/haptics';
import { THEME } from '@/lib/theme';
import { Tabs } from 'expo-router';
import { HouseIcon, LayersIcon, SettingsIcon } from 'lucide-react-native';
import { useColorScheme } from 'nativewind';

function HeaderRight() {
  return <ThemeToggle />;
}

export default function TabsLayout() {
  const { colorScheme } = useColorScheme();
  const theme = THEME[colorScheme ?? 'light'];

  return (
    <Tabs
      screenOptions={{
        headerRight: HeaderRight,
        tabBarActiveTintColor: theme.foreground,
        tabBarInactiveTintColor: theme.mutedForeground,
        tabBarStyle: { backgroundColor: theme.card, borderTopColor: theme.border },
        sceneStyle: { backgroundColor: theme.grouped },
      }}
      screenListeners={{
        tabPress: () => {
          void tapLight();
        },
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarButtonTestID: 'tab-home',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon symbol="house.fill" lucide={HouseIcon} color={color} focused={focused} />
          ),
        }}
      />
      <Tabs.Screen
        name="library"
        options={{
          title: 'Library',
          tabBarButtonTestID: 'tab-library',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              symbol="square.stack.fill"
              lucide={LayersIcon}
              color={color}
              focused={focused}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarButtonTestID: 'tab-settings',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon
              symbol="gearshape.fill"
              lucide={SettingsIcon}
              color={color}
              focused={focused}
            />
          ),
        }}
      />
    </Tabs>
  );
}
