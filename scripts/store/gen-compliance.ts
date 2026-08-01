/**
 * scripts/store/gen-compliance.ts — single source → Play + Apple + privacy disclosure.
 *
 * Usage: npm run gen-compliance
 *
 * Reads:  apps/mobile/store/data-practices.json
 * Writes: apps/mobile/store/compliance/play-data-safety.md
 *         apps/mobile/store/compliance/play-data-safety.csv  (Play Console CSV import starter)
 *         apps/mobile/store/compliance/apple-privacy-labels.md
 *         apps/web/content/privacy.md  (section between <!-- data-practices:start/end -->)
 * Then runs: npm run sync:legal
 *
 * R2 (2026): Play still supports Data safety CSV import/export
 * (support.google.com/googleplay/android-developer/answer/10787469).
 * The CSV here is a starter covering declared categories — export the full
 * Console template and reconcile before import on a live app.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

/** Where this script lives (always the real repo), used to locate sync-legal.ts. */
const SCRIPT_ROOT = path.resolve(__dirname, '../..');
/** Override for fixture smokes (`FACTORY_ROOT=/tmp/...`). Default: repo root. */
const ROOT = process.env.FACTORY_ROOT ? path.resolve(process.env.FACTORY_ROOT) : SCRIPT_ROOT;
const PRACTICES_PATH = path.join(ROOT, 'apps/mobile/store/data-practices.json');
const COMPLIANCE_DIR = path.join(ROOT, 'apps/mobile/store/compliance');
const PRIVACY_PATH = path.join(ROOT, 'apps/web/content/privacy.md');

const START = '<!-- data-practices:start -->';
const END = '<!-- data-practices:end -->';

type DataPractices = {
  collects_accounts: boolean;
  collects_user_content: boolean;
  collects_purchases: boolean;
  analytics: 'none' | string;
  crash_reporting: 'sentry' | 'none' | string;
  data_shared_with_third_parties: boolean;
  data_encrypted_in_transit: boolean;
  deletion_mechanism: 'in-app' | string;
  contact_email: string;
};

function loadPractices(): DataPractices {
  if (!fs.existsSync(PRACTICES_PATH)) {
    throw new Error('Missing apps/mobile/store/data-practices.json');
  }
  return JSON.parse(fs.readFileSync(PRACTICES_PATH, 'utf8')) as DataPractices;
}

function yn(v: boolean): string {
  return v ? 'Yes' : 'No';
}

function collectedCategories(p: DataPractices): string[] {
  const cats: string[] = [];
  if (p.collects_accounts) cats.push('Account info (email / identifiers)');
  if (p.collects_user_content) cats.push('User content (text, media, or other content you create)');
  if (p.collects_purchases) cats.push('Purchase history (StoreKit / Play Billing via RevenueCat)');
  if (p.analytics !== 'none') cats.push(`Analytics (${p.analytics})`);
  if (p.crash_reporting !== 'none') {
    cats.push(`Crash / diagnostics (${p.crash_reporting})`);
  }
  return cats;
}

/** True when every collection flag is off — this template's on-device default. */
function isOnDeviceNoCollection(p: DataPractices): boolean {
  return collectedCategories(p).length === 0 && !p.data_shared_with_third_parties;
}

function playMarkdown(p: DataPractices): string {
  const cats = collectedCategories(p);
  const collectsAny = cats.length > 0;
  const noCollection = isOnDeviceNoCollection(p);
  const deletionAnswer =
    p.deletion_mechanism === 'in-app'
      ? 'Yes — in-app account deletion'
      : p.deletion_mechanism === 'uninstall'
        ? 'Uninstall / clear app data (no cloud account in default template)'
        : p.deletion_mechanism;
  return `# Play Console — Data safety answers

Generated from \`apps/mobile/store/data-practices.json\`. Enter these in Play Console →
App content → Data safety (or import the companion CSV starter, then review).

## Data collection and security

| Question | Answer |
|----------|--------|
| Does the app collect or share required user data types? | ${yn(collectsAny)} |
| Data encrypted in transit? | ${yn(p.data_encrypted_in_transit)} |
| Data shared with third parties? | ${yn(p.data_shared_with_third_parties)} |
| Users can request deletion? | ${deletionAnswer} |

## Data types collected

${
  collectsAny
    ? cats.map((c) => `- ${c}`).join('\n')
    : noCollection
      ? '- **Data not collected** — on-device / local-first default (nothing leaves the device unless a product feature adds collection)'
      : '- None declared in data-practices.json'
}

### Flags (source of truth)

- collects_accounts: \`${p.collects_accounts}\`
- collects_user_content: \`${p.collects_user_content}\`
- collects_purchases: \`${p.collects_purchases}\`
- analytics: \`${p.analytics}\`
- crash_reporting: \`${p.crash_reporting}\`
- data_shared_with_third_parties: \`${p.data_shared_with_third_parties}\`

## Contact

${p.contact_email ? p.contact_email : '_(set contact_email in apps/mobile/store/data-practices.json)_'}
`;
}

/** Starter CSV — not a full Console export; reconcile before live import. */
function playCsv(p: DataPractices): string {
  const rows: string[][] = [
    [
      'Question ID (machine readable)',
      'Response (machine readable)',
      'Response value',
      'Answer requirement',
      'Human-friendly question label',
    ],
  ];
  const add = (qid: string, response: string, value: string, req: string, label: string) => {
    rows.push([qid, response, value, req, label]);
  };

  // High-level collection signal (human review still required in Console).
  add(
    'PSL_DATA_TYPES_PERSONAL',
    'PSL_EMAIL_ADDRESS',
    p.collects_accounts ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'Personal info Email address'
  );
  add(
    'PSL_DATA_TYPES_PERSONAL',
    'PSL_USER_IDS',
    p.collects_accounts ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'Personal info User IDs'
  );
  add(
    'PSL_DATA_TYPES_PHOTOS_AND_VIDEOS',
    'PSL_PHOTOS',
    p.collects_user_content ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'Photos and videos Photos (user content proxy)'
  );
  add(
    'PSL_DATA_TYPES_APP_ACTIVITY',
    'PSL_USER_GENERATED_CONTENT',
    p.collects_user_content ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'App activity User-generated content'
  );
  add(
    'PSL_DATA_TYPES_FINANCIAL',
    'PSL_PURCHASE_HISTORY',
    p.collects_purchases ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'Financial info Purchase history'
  );
  add(
    'PSL_DATA_TYPES_APP_INFO_AND_PERFORMANCE',
    'PSL_CRASH_LOGS',
    p.crash_reporting !== 'none' ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'App info and performance Crash logs'
  );
  add(
    'PSL_DATA_TYPES_APP_INFO_AND_PERFORMANCE',
    'PSL_OTHER_PERFORMANCE_DATA',
    p.analytics !== 'none' ? 'TRUE' : '',
    'MULTIPLE_CHOICE',
    'App info and performance Diagnostics / analytics'
  );

  const escape = (c: string) => `"${c.replace(/"/g, '""')}"`;
  return rows.map((r) => r.map(escape).join(',')).join('\n') + '\n';
}

function appleMarkdown(p: DataPractices): string {
  const cats = collectedCategories(p);
  const collectsAny = cats.length > 0;
  const noCollection = isOnDeviceNoCollection(p);
  return `# App Store Connect — App Privacy labels

Generated from \`apps/mobile/store/data-practices.json\`. Enter in ASC → App Privacy.

## Privacy policy URL

Use the hosted privacy URL from \`apps/mobile/store/metadata/ios/en-US/privacy_url.txt\`
(must return HTTP 200 — see \`npm run preflight\`).

## Data collection

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data from this app? | ${yn(collectsAny)} |
| Data linked to the user? | ${yn(p.collects_accounts || p.collects_purchases)} |
| Data used to track the user? | ${yn(p.analytics !== 'none' || p.data_shared_with_third_parties)} |
| Encrypted in transit? | ${yn(p.data_encrypted_in_transit)} |

## Data types to declare

${
  collectsAny
    ? cats.map((c) => `- ${c}`).join('\n')
    : noCollection
      ? '- **Data Not Collected** — on-device / local-first default (no accounts, no analytics; nothing leaves the device unless a product feature adds collection)'
      : '- Data Not Collected (only if genuinely true for this product)'
}

### Flags (source of truth)

- collects_accounts: \`${p.collects_accounts}\`
- collects_user_content: \`${p.collects_user_content}\`
- collects_purchases: \`${p.collects_purchases}\`
- analytics: \`${p.analytics}\`
- crash_reporting: \`${p.crash_reporting}\`
- data_shared_with_third_parties: \`${p.data_shared_with_third_parties}\`

## Deletion

Mechanism: \`${p.deletion_mechanism}\`${
    p.deletion_mechanism === 'uninstall'
      ? ' — clear app data / uninstall (no cloud account in the default template)'
      : ''
  }
`;
}

function privacySection(p: DataPractices): string {
  const cats = collectedCategories(p);
  const noCollection = isOnDeviceNoCollection(p);
  const collectLine = cats.length
    ? cats.map((c) => `- ${c}`).join('\n')
    : noCollection
      ? '- We do not collect personal data from this app. Processing stays on your device (on-device / local-first default).'
      : '- We do not collect personal data beyond what is required to run the app on your device.';
  const securityLine = noCollection
    ? '- Data stays on-device by default. Any optional network features use encrypted transport (HTTPS / TLS).'
    : p.data_encrypted_in_transit
      ? '- Data transmitted over the network is encrypted in transit (HTTPS / TLS).'
      : '- Review encryption practices before shipping.';
  const deletionLine =
    p.deletion_mechanism === 'in-app'
      ? '- You can delete your account from in-app Settings when accounts are enabled.'
      : p.deletion_mechanism === 'uninstall'
        ? '- Clear app data / uninstall to remove on-device data. There is no cloud account in the default template.'
        : `- Deletion mechanism: ${p.deletion_mechanism}.`;
  const lines = [
    '### What we collect',
    '',
    collectLine,
    '',
    '### Sharing',
    '',
    p.data_shared_with_third_parties
      ? '- Some data may be shared with third parties as described in this policy.'
      : '- We do not sell your personal data. We do not share personal data with third parties for their own marketing.',
    '',
    '### Security',
    '',
    securityLine,
    '',
    '### Deletion',
    '',
    deletionLine,
    '',
    '### Contact',
    '',
    p.contact_email
      ? `- Privacy contact: ${p.contact_email}`
      : '- Privacy contact: _(set contact_email in apps/mobile/store/data-practices.json)_',
    '',
    `<!-- gen-compliance fingerprint: accounts=${p.collects_accounts} user_content=${p.collects_user_content} purchases=${p.collects_purchases} analytics=${p.analytics} crash=${p.crash_reporting} shared=${p.data_shared_with_third_parties} -->`,
  ];
  return lines.join('\n');
}

function injectPrivacy(section: string): void {
  if (!fs.existsSync(PRIVACY_PATH)) {
    throw new Error('Missing apps/web/content/privacy.md');
  }
  const raw = fs.readFileSync(PRIVACY_PATH, 'utf8');
  if (!raw.includes(START) || !raw.includes(END)) {
    throw new Error(`apps/web/content/privacy.md must contain ${START} and ${END} markers`);
  }
  const before = raw.slice(0, raw.indexOf(START) + START.length);
  const after = raw.slice(raw.indexOf(END));
  const next = `${before}\n${section}\n${after}`;
  fs.writeFileSync(PRIVACY_PATH, next);
}

function main(): void {
  const p = loadPractices();
  fs.mkdirSync(COMPLIANCE_DIR, { recursive: true });

  const playMd = playMarkdown(p);
  const appleMd = appleMarkdown(p);
  const csv = playCsv(p);
  const section = privacySection(p);

  fs.writeFileSync(path.join(COMPLIANCE_DIR, 'play-data-safety.md'), playMd);
  fs.writeFileSync(path.join(COMPLIANCE_DIR, 'play-data-safety.csv'), csv);
  fs.writeFileSync(path.join(COMPLIANCE_DIR, 'apple-privacy-labels.md'), appleMd);
  injectPrivacy(section);

  console.log('  ✓ apps/mobile/store/compliance/play-data-safety.md');
  console.log('  ✓ apps/mobile/store/compliance/play-data-safety.csv');
  console.log('  ✓ apps/mobile/store/compliance/apple-privacy-labels.md');
  console.log('  ✓ apps/web/content/privacy.md (data-practices section)');

  // Invoke sync-legal.ts directly so FACTORY_ROOT fixture smokes do not need a
  // package.json inside the temp tree, and so the legal HTML write stays scoped.
  execFileSync('npx', ['tsx', path.join(SCRIPT_ROOT, 'scripts/web/sync-legal.ts')], {
    cwd: SCRIPT_ROOT,
    stdio: 'inherit',
    env: { ...process.env, FACTORY_ROOT: ROOT },
  });
  console.log('gen-compliance done');
}

main();
