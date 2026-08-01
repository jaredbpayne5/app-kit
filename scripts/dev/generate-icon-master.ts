/**
 * scripts/dev/generate-icon-master.ts — programmatic brand-mark fallback, no design tool.
 *
 * apps/brand/icon-master.png ships as the literal default Expo/RN template
 * logo until a product supplies real master art. Rather than block on
 * commissioning a designer, this builds a simple, generic two-tone badge
 * mark as an SVG string and rasterizes it with `sharp` (already a
 * devDependency, used by scripts/store/brand-generate.ts) — zero new
 * dependencies, zero external assets.
 *
 * Reads primary/accent/secondary hexes from
 * apps/mobile/assets/brand/brand.json; falls back to neutral placeholder
 * colors when that file is missing or incomplete.
 *
 * This is a *starting* mark, not a final logo — swap apps/brand/icon-master.png
 * for real artwork whenever it exists; `npm run brand:generate` picks it up
 * unchanged either way.
 *
 * Usage:
 *   npm run generate-icon-master
 *   npx tsx scripts/dev/generate-icon-master.ts
 */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

const ROOT = path.resolve(__dirname, '../..');
const OUT = path.join(ROOT, 'apps/brand/icon-master.png');
const BRAND_PATH = path.join(ROOT, 'apps/mobile/assets/brand/brand.json');

const SIZE = 1024;

type BrandHexes = { primary: string; accent: string; secondary: string };

// Neutral placeholder for a fresh clone that hasn't picked a palette yet.
const FALLBACK: BrandHexes = {
  primary: '#334155', // slate
  accent: '#2563EB', // blue
  secondary: '#64748B', // muted slate
};

const HEX_RE = /^#[0-9A-Fa-f]{6}$/;

function pickHex(value: unknown, fallback: string): string {
  return typeof value === 'string' && HEX_RE.test(value) ? value : fallback;
}

function readBrandHexes(): BrandHexes {
  if (!fs.existsSync(BRAND_PATH)) return FALLBACK;

  try {
    const brand = JSON.parse(fs.readFileSync(BRAND_PATH, 'utf8')) as Record<string, unknown>;
    return {
      primary: pickHex(brand.primary, FALLBACK.primary),
      accent: pickHex(brand.accent, FALLBACK.accent),
      secondary: pickHex(brand.secondary, FALLBACK.secondary),
    };
  } catch {
    return FALLBACK;
  }
}

/** Generic abstract mark: full-bleed Primary background, a large Accent
 * circle, a smaller offset Secondary circle — an "orbit" motif with no
 * inherent subject matter, so it doesn't bias any particular product
 * vertical. */
function buildSvg({ primary, accent, secondary }: BrandHexes): string {
  return `
<svg width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${SIZE}" height="${SIZE}" fill="${primary}" />
  <circle cx="512" cy="512" r="280" fill="${accent}" />
  <circle cx="680" cy="340" r="110" fill="${secondary}" />
</svg>
`.trim();
}

async function main(): Promise<void> {
  const hexes = readBrandHexes();
  const svg = buildSvg(hexes);
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  await sharp(Buffer.from(svg)).png().toFile(OUT);
  console.log(`✓ wrote ${path.relative(ROOT, OUT)} (${SIZE}×${SIZE})`);
  console.log(`  primary=${hexes.primary} accent=${hexes.accent} secondary=${hexes.secondary}`);
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
