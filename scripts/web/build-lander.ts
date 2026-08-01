/**
 * Build static marketing lander into apps/web/dist from apps/web/lander.json + templates.
 *
 * Usage: npm run web:build
 */
import { execFileSync } from 'node:child_process';
import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';

/** Where this script lives (always the real repo), used to locate sync-legal.ts. */
const SCRIPT_ROOT = path.resolve(__dirname, '../..');
/** Override for fixture smokes (`FACTORY_ROOT=/tmp/...`). Default: repo root. */
const ROOT = process.env.FACTORY_ROOT ? path.resolve(process.env.FACTORY_ROOT) : SCRIPT_ROOT;
const DIST = path.join(ROOT, 'apps/web/dist');
const TEMPLATE_DIR = path.join(ROOT, 'apps/web/template');

type Feature = { title: string; body: string };

type LanderConfig = {
  appName: string;
  oneLiner: string;
  features: Feature[];
  iosUrl: string;
  androidUrl: string;
  contactEmail: string;
  screenshots?: [string, string, string];
};

type ProductIdentity = {
  slug?: string;
  privacyUrl?: string;
};

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function assertNoTokens(filePath: string, contents: string) {
  const leftover = contents.match(/\{\{[A-Z0-9_]+\}\}/g);
  if (leftover?.length) {
    throw new Error(
      `Unreplaced tokens in ${path.relative(ROOT, filePath)}: ${leftover.join(', ')}`
    );
  }
}

function replaceAll(template: string, vars: Record<string, string>): string {
  let out = template;
  for (const [key, value] of Object.entries(vars)) {
    out = out.replaceAll(`{{${key}}}`, value);
  }
  return out;
}

function loadConfig(): LanderConfig {
  const raw = readFileSync(path.join(ROOT, 'apps/web/lander.json'), 'utf8');
  const cfg = JSON.parse(raw) as LanderConfig;
  if (!Array.isArray(cfg.features) || cfg.features.length < 3) {
    throw new Error('apps/web/lander.json must include at least 3 features');
  }
  return cfg;
}

function siteOrigin(): string {
  const productPath = path.join(ROOT, 'apps/product.json');
  if (existsSync(productPath)) {
    const product = JSON.parse(readFileSync(productPath, 'utf8')) as ProductIdentity;
    const privacyUrl = String(product.privacyUrl || '').trim();
    if (privacyUrl && !/example\.com|TBD/i.test(privacyUrl)) {
      try {
        const url = new URL(privacyUrl);
        if (url.protocol === 'https:') return url.origin;
      } catch {
        // Fall through to the deterministic Pages origin.
      }
    }
    const slug = String(product.slug || '').trim();
    if (slug) return `https://${slug}.pages.dev`;
  }
  return '';
}

function writeIndex(cfg: LanderConfig) {
  const template = readFileSync(path.join(TEMPLATE_DIR, 'index.template.html'), 'utf8');
  const shots = cfg.screenshots ?? [
    'images/screenshot-1.png',
    'images/screenshot-2.png',
    'images/screenshot-3.png',
  ];
  const origin = siteOrigin();
  // Absolute URL when we know the Pages origin; relative fallback still resolves on-host.
  const ogImageUrl = origin ? `${origin}/og-image.png` : 'og-image.png';
  const structuredData = JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: cfg.appName,
    description: cfg.oneLiner,
    url: origin,
    applicationCategory: 'UtilitiesApplication',
    operatingSystem: 'iOS, Android',
  }).replace(/</g, '\\u003c');
  const html = replaceAll(template, {
    APP_NAME: escapeHtml(cfg.appName),
    ONE_LINER: escapeHtml(cfg.oneLiner),
    IOS_URL: escapeHtml(cfg.iosUrl || '#'),
    ANDROID_URL: escapeHtml(cfg.androidUrl || '#'),
    IOS_BADGE_CLASS: !cfg.iosUrl || cfg.iosUrl === '#' ? 'hidden' : '',
    ANDROID_BADGE_CLASS: !cfg.androidUrl || cfg.androidUrl === '#' ? 'hidden' : '',
    SCREENSHOT_1: escapeHtml(shots[0]),
    SCREENSHOT_2: escapeHtml(shots[1]),
    SCREENSHOT_3: escapeHtml(shots[2]),
    FEATURE_1_TITLE: escapeHtml(cfg.features[0].title),
    FEATURE_1_BODY: escapeHtml(cfg.features[0].body),
    FEATURE_2_TITLE: escapeHtml(cfg.features[1].title),
    FEATURE_2_BODY: escapeHtml(cfg.features[1].body),
    FEATURE_3_TITLE: escapeHtml(cfg.features[2].title),
    FEATURE_3_BODY: escapeHtml(cfg.features[2].body),
    CONTACT_EMAIL: escapeHtml(cfg.contactEmail),
    OG_IMAGE_URL: escapeHtml(ogImageUrl),
    CANONICAL_URL: escapeHtml(origin || '/'),
    STRUCTURED_DATA: structuredData,
  });
  const outPath = path.join(DIST, 'index.html');
  assertNoTokens(outPath, html);
  writeFileSync(outPath, html, 'utf8');
  console.log('wrote apps/web/dist/index.html');
}

function writeSeoFiles() {
  const origin = siteOrigin();
  if (!origin) {
    console.warn('product slug missing — skipping robots.txt and sitemap.xml');
    return;
  }
  const urls = [origin, `${origin}/privacy`, `${origin}/terms`];
  writeFileSync(
    path.join(DIST, 'robots.txt'),
    `User-agent: *\nAllow: /\n\nSitemap: ${origin}/sitemap.xml\n`,
    'utf8'
  );
  writeFileSync(
    path.join(DIST, 'sitemap.xml'),
    [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
      ...urls.map((url) => `  <url><loc>${escapeHtml(url)}</loc></url>`),
      '</urlset>',
      '',
    ].join('\n'),
    'utf8'
  );
  console.log('wrote apps/web/dist/robots.txt + sitemap.xml');
}

function writeLegalPages() {
  // Prefer already-synced pages (same markdown source as the hosted lander).
  for (const name of ['privacy.html', 'terms.html'] as const) {
    const src = path.join(ROOT, 'apps/web', name);
    const html = readFileSync(src, 'utf8');
    const outPath = path.join(DIST, name);
    assertNoTokens(outPath, html);
    writeFileSync(outPath, html, 'utf8');
    console.log(`wrote apps/web/dist/${name}`);
  }
}

function copyAssets() {
  cpSync(path.join(TEMPLATE_DIR, 'style.css'), path.join(DIST, 'style.css'));
  console.log('wrote apps/web/dist/style.css');
  const imagesSrc = path.join(TEMPLATE_DIR, 'images');
  const imagesDest = path.join(DIST, 'images');
  mkdirSync(imagesDest, { recursive: true });
  for (const name of readdirSync(imagesSrc)) {
    cpSync(path.join(imagesSrc, name), path.join(imagesDest, name));
  }
  console.log('wrote apps/web/dist/images/*');

  const ogSrc = path.join(TEMPLATE_DIR, 'og-image.png');
  if (existsSync(ogSrc)) {
    cpSync(ogSrc, path.join(DIST, 'og-image.png'));
    console.log('wrote apps/web/dist/og-image.png');
  } else {
    console.warn(
      'apps/web/template/og-image.png missing — run npm run brand:generate before deploy for social previews'
    );
  }
}

function main() {
  // Keep hosted legal HTML fresh from content/*.md (avoids stale Phase 5 copies).
  execFileSync('npx', ['tsx', path.join(SCRIPT_ROOT, 'scripts/web/sync-legal.ts')], {
    cwd: SCRIPT_ROOT,
    stdio: 'inherit',
    env: { ...process.env, FACTORY_ROOT: ROOT },
  });
  const cfg = loadConfig();
  rmSync(DIST, { recursive: true, force: true });
  mkdirSync(DIST, { recursive: true });
  writeIndex(cfg);
  writeLegalPages();
  writeSeoFiles();
  copyAssets();
  console.log('web:build complete');
}

main();
