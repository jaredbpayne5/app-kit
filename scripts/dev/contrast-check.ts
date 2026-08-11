/**
 * scripts/dev/contrast-check.ts — WCAG contrast guard for the brand color tokens.
 *
 * The brand palette lives in apps/mobile/assets/brand/brand.json and is invented
 * once per product with no automated check that the result is actually legible.
 * This reads the HSL tokens straight out of apps/mobile/global.css (both
 * `:root` and `.dark:root`) and fails the check when a foreground/background
 * pair used for real text falls below WCAG AA. Pure math, no dependency.
 *
 * Usage:
 *   npm run contrast-check
 *   npx tsx scripts/dev/contrast-check.ts
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(__dirname, '../..');
const CSS_PATH = path.join(ROOT, 'apps/mobile/global.css');

/** Foreground/background pairs that carry real body/label text in this app. */
const PAIRS: [fg: string, bg: string, label: string][] = [
  ['--foreground', '--background', 'foreground on background'],
  ['--foreground', '--card', 'foreground on card'],
  ['--foreground', '--grouped', 'foreground on grouped (list) background'],
  ['--card-foreground', '--card', 'card-foreground on card'],
  ['--popover-foreground', '--popover', 'popover-foreground on popover'],
  ['--primary-foreground', '--primary', 'primary-foreground on primary'],
  ['--secondary-foreground', '--secondary', 'secondary-foreground on secondary'],
  ['--muted-foreground', '--muted', 'muted-foreground on muted'],
  ['--muted-foreground', '--card', 'muted-foreground on card'],
  ['--muted-foreground', '--grouped', 'muted-foreground on grouped'],
  ['--accent-foreground', '--accent', 'accent-foreground on accent'],
  ['--destructive-foreground', '--destructive', 'destructive-foreground on destructive'],
];

const AA_NORMAL = 4.5;
const AA_LARGE = 3.0;

type Hsl = { h: number; s: number; l: number };
type Theme = Record<string, Hsl>;

function parseHslValue(raw: string): Hsl {
  const m = /^\s*([\d.]+)\s+([\d.]+)%\s+([\d.]+)%\s*$/.exec(raw.trim());
  if (!m) throw new Error(`Unparseable HSL token: ${JSON.stringify(raw)}`);
  return { h: parseFloat(m[1]), s: parseFloat(m[2]), l: parseFloat(m[3]) };
}

function parseBlock(css: string, selector: string): Theme {
  const re = new RegExp(`${selector.replace(/[.:]/g, '\\$&')}\\s*\\{([^}]*)\\}`);
  const match = re.exec(css);
  if (!match) throw new Error(`Missing ${selector} block in ${CSS_PATH}`);
  const theme: Theme = {};
  for (const line of match[1].split(';')) {
    const m = /--([a-z0-9-]+):\s*([^;]+)/.exec(line);
    if (!m) continue;
    const [, name, value] = m;
    if (name === 'radius') continue; // not a color token
    theme[`--${name}`] = parseHslValue(value);
  }
  return theme;
}

function hslToRgb({ h, s, l }: Hsl): [number, number, number] {
  const sN = s / 100;
  const lN = l / 100;
  const c = (1 - Math.abs(2 * lN - 1)) * sN;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = lN - c / 2;
  let r = 0;
  let g = 0;
  let b = 0;
  if (h < 60) [r, g, b] = [c, x, 0];
  else if (h < 120) [r, g, b] = [x, c, 0];
  else if (h < 180) [r, g, b] = [0, c, x];
  else if (h < 240) [r, g, b] = [0, x, c];
  else if (h < 300) [r, g, b] = [x, 0, c];
  else [r, g, b] = [c, 0, x];
  return [(r + m) * 255, (g + m) * 255, (b + m) * 255];
}

function relativeLuminance([r, g, b]: [number, number, number]): number {
  const chan = (v: number) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b);
}

function contrastRatio(a: Hsl, b: Hsl): number {
  const la = relativeLuminance(hslToRgb(a));
  const lb = relativeLuminance(hslToRgb(b));
  const [lighter, darker] = la >= lb ? [la, lb] : [lb, la];
  return (lighter + 0.05) / (darker + 0.05);
}

function checkTheme(name: string, theme: Theme): boolean {
  console.log(`\n${name}`);
  let ok = true;
  for (const [fgVar, bgVar, label] of PAIRS) {
    const fg = theme[fgVar];
    const bg = theme[bgVar];
    if (!fg || !bg) {
      console.log(`  ? ${label}: missing token (${fgVar} / ${bgVar})`);
      continue;
    }
    const ratio = contrastRatio(fg, bg);
    const rounded = ratio.toFixed(2);
    if (ratio >= AA_NORMAL) {
      console.log(`  ✓ ${label}: ${rounded}:1 (AA normal text)`);
    } else if (ratio >= AA_LARGE) {
      console.log(`  ⚠ ${label}: ${rounded}:1 (AA large/bold text only — avoid for body copy)`);
    } else {
      console.log(`  ✗ ${label}: ${rounded}:1 (below AA — FAIL)`);
      ok = false;
    }
  }
  return ok;
}

function main(): void {
  const css = fs.readFileSync(CSS_PATH, 'utf8');
  const light = parseBlock(css, ':root');
  const dark = parseBlock(css, '.dark:root');
  const lightOk = checkTheme('Light theme', light);
  const darkOk = checkTheme('Dark theme', dark);
  if (!lightOk || !darkOk) {
    console.error(
      '\ncontrast-check: FAILED — fix the token pair(s) above in apps/mobile/global.css'
    );
    process.exit(1);
  }
  console.log('\ncontrast-check: all pairs pass AA (or are large-text-only warnings)');
}

main();
