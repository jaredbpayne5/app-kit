/**
 * scripts/store/brand-generate.ts — derive store/app brand assets from one master icon.
 *
 * Usage:
 *   npm run brand:generate
 *   npx tsx scripts/store/brand-generate.ts
 *
 * Input:
 *   apps/brand/icon-master.png              (required, square, ≥1024px)
 *   apps/brand/splash-master.png            (optional)
 *   apps/mobile/assets/brand/brand.json     ({ "background": "#RRGGBB" })
 *
 * Output (overwrites):
 *   apps/mobile/assets/images/icon.png            1024×1024 (no alpha — ASC-safe)
 *   apps/mobile/assets/images/adaptive-icon.png   1024×1024 (foreground, 66% safe-zone inset)
 *   apps/mobile/assets/images/splash.png          1024×1024
 *   apps/mobile/assets/images/favicon.png         48×48
 *   apps/web/template/og-image.png                1200×630
 */
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

/** Override for fixture smokes (`FACTORY_ROOT=/tmp/...`). Default: repo root. */
const ROOT = process.env.FACTORY_ROOT
  ? path.resolve(process.env.FACTORY_ROOT)
  : path.resolve(__dirname, '../..');
const BRAND_MASTER_DIR = path.join(ROOT, 'apps/brand');
const BRAND_JSON_DIR = path.join(ROOT, 'apps/mobile/assets/brand');
const MASTER_PATH = path.join(BRAND_MASTER_DIR, 'icon-master.png');
const SPLASH_MASTER_PATH = path.join(BRAND_MASTER_DIR, 'splash-master.png');
const BRAND_JSON_PATH = path.join(BRAND_JSON_DIR, 'brand.json');

const OUT = {
  icon: path.join(ROOT, 'apps/mobile/assets/images/icon.png'),
  adaptive: path.join(ROOT, 'apps/mobile/assets/images/adaptive-icon.png'),
  splash: path.join(ROOT, 'apps/mobile/assets/images/splash.png'),
  favicon: path.join(ROOT, 'apps/mobile/assets/images/favicon.png'),
  og: path.join(ROOT, 'apps/web/template/og-image.png'),
} as const;

/** Android adaptive icon: keep artwork inside the center ~66% safe zone. */
const ADAPTIVE_SAFE_RATIO = 0.66;

type BrandJson = { background: string };

function parseArgs(argv: string[]): void {
  for (const arg of argv) {
    if (arg === '-h' || arg === '--help') {
      console.log(`Usage: npm run brand:generate

Requires apps/brand/icon-master.png (square, ≥1024px) and apps/mobile/assets/brand/brand.json.
Optional: apps/brand/splash-master.png`);
      process.exit(0);
    }
  }
}

function parseHexBackground(raw: string): { r: number; g: number; b: number } {
  const m = /^#?([0-9a-fA-F]{6})$/.exec(raw.trim());
  if (!m) {
    throw new Error(`brand.json background must be #RRGGBB (got ${JSON.stringify(raw)})`);
  }
  const hex = m[1];
  return {
    r: parseInt(hex.slice(0, 2), 16),
    g: parseInt(hex.slice(2, 4), 16),
    b: parseInt(hex.slice(4, 6), 16),
  };
}

function loadBrand(): BrandJson {
  if (!fs.existsSync(BRAND_JSON_PATH)) {
    throw new Error(`Missing ${path.relative(ROOT, BRAND_JSON_PATH)}`);
  }
  const data = JSON.parse(fs.readFileSync(BRAND_JSON_PATH, 'utf8')) as BrandJson;
  if (!data.background || typeof data.background !== 'string') {
    throw new Error('brand.json must include string "background": "#RRGGBB"');
  }
  parseHexBackground(data.background); // validate early
  return data;
}

async function assertMaster(file: string): Promise<{ width: number; height: number }> {
  if (!fs.existsSync(file)) {
    throw new Error(`Missing master: ${path.relative(ROOT, file)} — add a square PNG ≥1024px`);
  }
  const meta = await sharp(file).metadata();
  const width = meta.width ?? 0;
  const height = meta.height ?? 0;
  if (width < 1 || height < 1) {
    throw new Error(`${path.relative(ROOT, file)}: could not read dimensions`);
  }
  if (width !== height) {
    throw new Error(`${path.relative(ROOT, file)}: must be square (got ${width}×${height})`);
  }
  if (width < 1024) {
    throw new Error(`${path.relative(ROOT, file)}: must be ≥1024px (got ${width}×${height})`);
  }
  return { width, height };
}

async function assertOut(file: string, width: number, height: number): Promise<void> {
  if (!fs.existsSync(file)) {
    throw new Error(`Expected output missing: ${path.relative(ROOT, file)}`);
  }
  const meta = await sharp(file).metadata();
  if (meta.width !== width || meta.height !== height) {
    throw new Error(
      `${path.relative(ROOT, file)}: got ${meta.width}×${meta.height}, want ${width}×${height}`
    );
  }
}

async function main(): Promise<void> {
  parseArgs(process.argv.slice(2));
  const brand = loadBrand();
  const bg = parseHexBackground(brand.background);
  await assertMaster(MASTER_PATH);

  // icon — 1024×1024, flattened (no alpha) onto background for ASC
  await sharp(MASTER_PATH)
    .resize(1024, 1024, { fit: 'cover' })
    .flatten({ background: bg })
    .png()
    .toFile(OUT.icon);
  await assertOut(OUT.icon, 1024, 1024);
  console.log('  ✓ apps/mobile/assets/images/icon.png (1024×1024, no alpha)');

  // adaptive — artwork inset to safe zone on transparent canvas
  const inset = Math.round(1024 * ADAPTIVE_SAFE_RATIO);
  const insetBuf = await sharp(MASTER_PATH).resize(inset, inset, { fit: 'cover' }).png().toBuffer();
  const left = Math.round((1024 - inset) / 2);
  await sharp({
    create: {
      width: 1024,
      height: 1024,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    },
  })
    .composite([{ input: insetBuf, left, top: left }])
    .png()
    .toFile(OUT.adaptive);
  await assertOut(OUT.adaptive, 1024, 1024);
  console.log('  ✓ apps/mobile/assets/images/adaptive-icon.png (1024×1024, safe-zone inset)');

  // splash — optional splash-master, else icon-master on solid background
  const splashSrc = fs.existsSync(SPLASH_MASTER_PATH) ? SPLASH_MASTER_PATH : MASTER_PATH;
  if (splashSrc === SPLASH_MASTER_PATH) {
    await assertMaster(SPLASH_MASTER_PATH);
  }
  await sharp({
    create: {
      width: 1024,
      height: 1024,
      channels: 3,
      background: bg,
    },
  })
    .composite([
      {
        input: await sharp(splashSrc).resize(768, 768, { fit: 'inside' }).png().toBuffer(),
        gravity: 'centre',
      },
    ])
    .png()
    .toFile(OUT.splash);
  await assertOut(OUT.splash, 1024, 1024);
  console.log('  ✓ apps/mobile/assets/images/splash.png (1024×1024)');

  // favicon
  await sharp(MASTER_PATH).resize(48, 48, { fit: 'cover' }).png().toFile(OUT.favicon);
  await assertOut(OUT.favicon, 48, 48);
  console.log('  ✓ apps/mobile/assets/images/favicon.png (48×48)');

  // OG image for lander
  fs.mkdirSync(path.dirname(OUT.og), { recursive: true });
  const ogIcon = await sharp(MASTER_PATH).resize(420, 420, { fit: 'inside' }).png().toBuffer();
  await sharp({
    create: {
      width: 1200,
      height: 630,
      channels: 3,
      background: bg,
    },
  })
    .composite([{ input: ogIcon, gravity: 'centre' }])
    .png()
    .toFile(OUT.og);
  await assertOut(OUT.og, 1200, 630);
  console.log('  ✓ apps/web/template/og-image.png (1200×630)');

  console.log('brand:generate done');
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
