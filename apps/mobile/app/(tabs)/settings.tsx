import { GroupedRow, GroupedSection } from '@/components/grouped';
import { Paywall } from '@/components/paywall';
import { APP_CONFIG } from '@/lib/app-config';
import { getAppDisplayName, getAppVersion, getNativeBuildNumber } from '@/lib/app-version';
import { resetOnboardingSeen } from '@/lib/onboarding';
import { PRIVACY_URL, TERMS_URL } from '@/lib/product';
import { useEntitlement } from '@/lib/purchases';
import { reportError } from '@/lib/report-error';
import { Text } from '@/ui/text';
import * as WebBrowser from 'expo-web-browser';
import { Alert, ScrollView, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

async function openInAppBrowser(url: string, label: string): Promise<void> {
  try {
    await WebBrowser.openBrowserAsync(url);
  } catch (error) {
    reportError(error, { scope: 'settings.openInAppBrowser', label, url });
    Alert.alert(`Couldn’t open ${label}`, 'Please try again.');
  }
}

async function resetOnboarding(): Promise<void> {
  try {
    // The root gate reacts to this and swaps the protected route to onboarding;
    // no manual navigation needed.
    await resetOnboardingSeen();
  } catch (error) {
    reportError(error, { scope: 'settings.resetOnboarding' });
    Alert.alert('Couldn’t reset onboarding', 'Please try again.');
  }
}

export default function SettingsScreen() {
  const name = getAppDisplayName();
  const version = getAppVersion();
  const build = getNativeBuildNumber();
  const insets = useSafeAreaInsets();
  const premium = useEntitlement('premium');

  return (
    <ScrollView
      className="flex-1 bg-grouped"
      contentContainerClassName="gap-6 p-6"
      contentContainerStyle={{ paddingBottom: Math.max(insets.bottom, 24) }}
      keyboardShouldPersistTaps="handled"
      testID="settings-screen">
      <View className="gap-1">
        <Text variant="h4">Settings</Text>
        <Text variant="muted">{name}</Text>
      </View>

      <GroupedSection header="Version" testID="settings-version">
        <GroupedRow label="Build" value={`v${version}${build ? ` (${build})` : ''}`} last />
      </GroupedSection>

      <GroupedSection header="Legal" testID="settings-links">
        <GroupedRow
          label="Privacy Policy"
          showChevron
          testID="link-privacy"
          accessibilityLabel="Privacy Policy"
          onPress={() => {
            void openInAppBrowser(PRIVACY_URL, 'Privacy Policy');
          }}
        />
        <GroupedRow
          label="Terms of Use"
          showChevron
          last
          testID="link-terms"
          accessibilityLabel="Terms of Use"
          onPress={() => {
            void openInAppBrowser(TERMS_URL, 'Terms of Use');
          }}
        />
      </GroupedSection>

      {APP_CONFIG.MONETIZATION !== 'free' ? (
        <GroupedSection header="Premium" testID="settings-premium">
          <GroupedRow
            label="Status"
            value={premium.isLoading ? 'Checking…' : premium.active ? 'Active' : 'Locked'}
            last
          />
        </GroupedSection>
      ) : null}

      {APP_CONFIG.MONETIZATION !== 'free' ? <Paywall /> : null}

      {__DEV__ ? (
        <GroupedSection header="Developer">
          <GroupedRow
            label="Reset onboarding"
            testID="btn-reset-onboarding"
            accessibilityLabel="Reset onboarding"
            onPress={() => void resetOnboarding()}
            last
          />
        </GroupedSection>
      ) : null}

      <Text variant="muted">Your preferences stay on this device. No account required.</Text>
    </ScrollView>
  );
}
