import { THEME } from '@/lib/theme';
import { useColorScheme } from 'nativewind';
import { View } from 'react-native';
import Svg, { Circle, Line, Polyline, Rect } from 'react-native-svg';

export type ChartPoint = { x: number; y: number };

type ChartProps = {
  points: ChartPoint[];
  width?: number;
  height?: number;
  /** `line` (default) or `bar`. */
  variant?: 'line' | 'bar';
  testID?: string;
};

/**
 * Minimal Line/Bar chart on `react-native-svg` — no extra chart dependency.
 * Prefer this for sparklines and simple series; only reach for a heavier charting
 * library when a product genuinely outgrows it.
 */
export function Chart({
  points,
  width = 320,
  height = 160,
  variant = 'line',
  testID = 'chart',
}: ChartProps) {
  const { colorScheme } = useColorScheme();
  const theme = THEME[colorScheme === 'dark' ? 'dark' : 'light'];
  const pad = 12;
  const innerW = width - pad * 2;
  const innerH = height - pad * 2;

  if (points.length === 0) {
    return <View style={{ width, height }} testID={testID} accessibilityLabel="Empty chart" />;
  }

  const xs = points.map((p) => p.x);
  const ys = points.map((p) => p.y);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  const spanX = maxX - minX || 1;
  const spanY = maxY - minY || 1;

  const scaled = points.map((p) => ({
    x: pad + ((p.x - minX) / spanX) * innerW,
    y: pad + innerH - ((p.y - minY) / spanY) * innerH,
  }));

  return (
    <View testID={testID} accessibilityLabel={`${variant} chart`}>
      <Svg width={width} height={height}>
        <Line
          x1={pad}
          y1={pad + innerH}
          x2={pad + innerW}
          y2={pad + innerH}
          stroke={theme.border}
          strokeWidth={1}
        />
        {variant === 'bar' ? (
          scaled.map((p, i) => {
            const barW = Math.max(4, innerW / points.length - 4);
            const barH = pad + innerH - p.y;
            return (
              <Rect
                key={`${p.x}-${i}`}
                x={p.x - barW / 2}
                y={p.y}
                width={barW}
                height={barH}
                fill={theme.chart1}
                rx={2}
              />
            );
          })
        ) : (
          <>
            <Polyline
              points={scaled.map((p) => `${p.x},${p.y}`).join(' ')}
              fill="none"
              stroke={theme.chart1}
              strokeWidth={2}
            />
            {scaled.map((p, i) => (
              <Circle key={`${p.x}-${i}`} cx={p.x} cy={p.y} r={3} fill={theme.chart1} />
            ))}
          </>
        )}
      </Svg>
    </View>
  );
}
