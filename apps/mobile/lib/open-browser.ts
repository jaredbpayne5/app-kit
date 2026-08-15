import { reportError } from '@/lib/report-error';
import * as WebBrowser from 'expo-web-browser';
import { Alert } from 'react-native';

export async function openInAppBrowser(
  url: string,
  opts: { label: string; scope: string }
): Promise<void> {
  try {
    await WebBrowser.openBrowserAsync(url);
  } catch (error) {
    reportError(error, { scope: opts.scope, label: opts.label, url });
    Alert.alert(`Couldn’t open ${opts.label}`, 'Please try again.');
  }
}
