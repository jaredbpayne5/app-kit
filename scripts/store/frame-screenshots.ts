/**
 * scripts/store/frame-screenshots.ts — compose raw Maestro shots onto store canvases.
 *
 * Usage:
 *   npx tsx scripts/store/frame-screenshots.ts --platform=ios|android|both
 *
 * Reads:  apps/mobile/store/screenshots/raw/<device>/{home,settings,privacy}.png
 *         apps/mobile/store/screenshots/headlines.json
 * Writes: apps/mobile/store/metadata/ios/en-US/images/iphone_6_9/<nn>_<name>.png   (1320×2868)
 *         apps/mobile/store/metadata/android/en-US/images/phoneScreenshots/<nn>_<name>.png (1080×1920)
 *
 * Store sizes (R2, mid-2026):
 *   iOS 6.9" class (required): 1320×2868
 *   Play phone (recommended):  1080×1920 (9:16; sides 320–3840)
 *
 * Asserts output dimensions via sharp metadata (and sips on macOS when available).
 * Idempotent: overwrites framed outputs.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';

type Platform = 'ios' | 'android' | 'both';

const ROOT = path.resolve(__dirname, '../..');
const RAW_ROOT = path.join(ROOT, 'apps/mobile/store/screenshots/raw');
const HEADLINES_PATH = path.join(ROOT, 'apps/mobile/store/screenshots/headlines.json');

/** R2 — Apple 6.9" accepted size; Play recommended phone. */
const IOS_CANVAS = { width: 1320, height: 2868 } as const;
const ANDROID_CANVAS = { width: 1080, height: 1920 } as const;

const SHOT_ORDER = ['home', 'settings', 'privacy'] as const;

function parseArgs(argv: string[]): { platform: Platform } {
  let platform: Platform | '' = '';
  for (const arg of argv) {
    if (arg.startsWith('--platform=')) {
      platform = arg.slice('--platform='.length) as Platform;
    } else if (arg === '-h' || arg === '--help') {
      console.log('Usage: npx tsx scripts/store/frame-screenshots.ts --platform=ios|android|both');
      process.exit(0);
    }
  }
  if (platform !== 'ios' && platform !== 'android' && platform !== 'both') {
    console.error('Missing or invalid --platform=ios|android|both');
    process.exit(2);
  }
  return { platform };
}

function loadHeadlines(): Record<string, string> {
  const raw = fs.readFileSync(HEADLINES_PATH, 'utf8');
  return JSON.parse(raw) as Record<string, string>;
}

function findRaw(deviceSlug: string, shot: string): string | null {
  const direct = path.join(RAW_ROOT, deviceSlug, `${shot}.png`);
  if (fs.existsSync(direct)) return direct;
  // Fallback: any raw/<dir>/<shot>.png
  if (!fs.existsSync(RAW_ROOT)) return null;
  for (const ent of fs.readdirSync(RAW_ROOT, { withFileTypes: true })) {
    if (!ent.isDirectory()) continue;
    const p = path.join(RAW_ROOT, ent.name, `${shot}.png`);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

async function assertDimensions(file: string, width: number, height: number): Promise<void> {
  const meta = await sharp(file).metadata();
  if (meta.width !== width || meta.height !== height) {
    throw new Error(
      `Dimension mismatch ${file}: got ${meta.width}x${meta.height}, want ${width}x${height}`
    );
  }
  if (process.platform === 'darwin') {
    try {
      const out = execFileSync('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', file], {
        encoding: 'utf8',
      });
      const w = /pixelWidth:\s*(\d+)/.exec(out)?.[1];
      const h = /pixelHeight:\s*(\d+)/.exec(out)?.[1];
      if (w !== String(width) || h !== String(height)) {
        throw new Error(`sips mismatch ${file}: ${out}`);
      }
    } catch (err) {
      if (err instanceof Error && err.message.startsWith('sips mismatch')) {
        throw err;
      }
      // sips optional if sharp already asserted
    }
  }
}

function svgHeadline(text: string, canvasW: number, bandH: number): Buffer {
  const escaped = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
  const fontSize = Math.round(canvasW * 0.055);
  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${canvasW}" height="${bandH}" xmlns="http://www.w3.org/2000/svg">
  <rect width="100%" height="100%" fill="#0f1419"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        fill="#f5f7fa" font-family="Helvetica, Arial, sans-serif"
        font-size="${fontSize}" font-weight="700">${escaped}</text>
</svg>`;
  return Buffer.from(svg);
}

async function frameOne(opts: {
  rawPath: string;
  outPath: string;
  headline: string;
  width: number;
  height: number;
}): Promise<void> {
  const { rawPath, outPath, headline, width, height } = opts;
  fs.mkdirSync(path.dirname(outPath), { recursive: true });

  const bandH = Math.round(height * 0.14);
  const padX = Math.round(width * 0.06);
  const padBottom = Math.round(height * 0.06);
  const shotMaxH = height - bandH - padBottom;
  const shotMaxW = width - padX * 2;

  const shotBuf = await sharp(rawPath)
    .resize(shotMaxW, shotMaxH, { fit: 'inside', withoutEnlargement: false })
    .png()
    .toBuffer();
  const shotMeta = await sharp(shotBuf).metadata();
  const shotW = shotMeta.width ?? shotMaxW;
  const shotH = shotMeta.height ?? shotMaxH;
  const left = Math.round((width - shotW) / 2);
  const top = bandH + Math.round((shotMaxH - shotH) / 2);

  const headlineSvg = svgHeadline(headline || ' ', width, bandH);

  await sharp({
    create: {
      width,
      height,
      channels: 3,
      background: { r: 15, g: 20, b: 25 },
    },
  })
    .composite([
      { input: headlineSvg, top: 0, left: 0 },
      { input: shotBuf, top, left },
    ])
    .png()
    .toFile(outPath);

  await assertDimensions(outPath, width, height);
}

async function framePlatform(
  platform: 'ios' | 'android',
  headlines: Record<string, string>
): Promise<number> {
  const canvas = platform === 'ios' ? IOS_CANVAS : ANDROID_CANVAS;
  const deviceSlug = platform === 'ios' ? 'iphone_6_9' : 'pixel_phone';
  const outDir =
    platform === 'ios'
      ? path.join(ROOT, 'apps/mobile/store/metadata/ios/en-US/images/iphone_6_9')
      : path.join(ROOT, 'apps/mobile/store/metadata/android/en-US/images/phoneScreenshots');

  fs.mkdirSync(outDir, { recursive: true });
  // Idempotent clean of previous framed set for this platform folder
  for (const ent of fs.readdirSync(outDir)) {
    if (ent.endsWith('.png')) fs.unlinkSync(path.join(outDir, ent));
  }

  let written = 0;
  for (let i = 0; i < SHOT_ORDER.length; i++) {
    const shot = SHOT_ORDER[i];
    const rawPath = findRaw(deviceSlug, shot);
    if (!rawPath) {
      throw new Error(
        `Missing raw screenshot for ${shot} (looked under ${RAW_ROOT}/${deviceSlug}/ and siblings)`
      );
    }
    const nn = String(i + 1).padStart(2, '0');
    const outPath = path.join(outDir, `${nn}_${shot}.png`);
    const headline = headlines[shot] ?? shot;
    await frameOne({
      rawPath,
      outPath,
      headline,
      width: canvas.width,
      height: canvas.height,
    });
    console.log(`  ✓ ${platform} ${nn}_${shot}.png (${canvas.width}×${canvas.height})`);
    written += 1;
  }
  return written;
}

async function main(): Promise<void> {
  const { platform } = parseArgs(process.argv.slice(2));
  const headlines = loadHeadlines();
  let total = 0;
  if (platform === 'ios' || platform === 'both') {
    total += await framePlatform('ios', headlines);
  }
  if (platform === 'android' || platform === 'both') {
    total += await framePlatform('android', headlines);
  }
  console.log(`framed ${total} PNG(s)`);
}

main().catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
