import Constants from 'expo-constants';
import { Platform } from 'react-native';

/** Display / marketing version from app.json `expo.version`. */
export function getAppVersion(): string {
  return Constants.expoConfig?.version ?? '0.0.0';
}

/** Android versionCode or iOS buildNumber for the running platform. */
export function getNativeBuildNumber(): string | null {
  if (Platform.OS === 'android') {
    const android = Constants.expoConfig?.android?.versionCode;
    if (typeof android === 'number') return String(android);
    return null;
  }

  if (Platform.OS === 'ios') {
    const ios = Constants.expoConfig?.ios?.buildNumber;
    if (typeof ios === 'string' && ios.length > 0) return ios;
    return null;
  }

  return null;
}

export function getAppDisplayName(): string {
  return process.env.EXPO_PUBLIC_APP_NAME ?? Constants.expoConfig?.name ?? 'Mobile App';
}
