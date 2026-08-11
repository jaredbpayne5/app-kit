declare module '@react-native/normalize-colors' {
  /** Returns a packed ARGB number, or null if the color string is invalid. */
  export default function normalizeColor(color: string | number): number | null;
}
