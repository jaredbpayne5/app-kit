import Constants from 'expo-constants';

/** Display / marketing version from app.json `expo.version`. */
export function getAppVersion(): string {
  return Constants.expoConfig?.version ?? '0.0.0';
}

/** Android versionCode or iOS buildNumber when available. */
export function getNativeBuildNumber(): string | null {
  const android = Constants.expoConfig?.android?.versionCode;
  if (typeof android === 'number') return String(android);

  const ios = Constants.expoConfig?.ios?.buildNumber;
  if (typeof ios === 'string' && ios.length > 0) return ios;

  return null;
}

export function getAppDisplayName(): string {
  return process.env.EXPO_PUBLIC_APP_NAME ?? Constants.expoConfig?.name ?? 'Mobile App';
}
