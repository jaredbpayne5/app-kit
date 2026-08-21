#!/usr/bin/env bash
#
# scripts/factory/init-app.sh — set app identity after cloning the template.
#
# Usage:
#   npm run init-app -- --name "My App" --slug my-app --package com.me.myapp
#   npm run init-app -- --name "My App" --slug my-app --package com.me.my_app \
#     --bundle-id com.me.myapp
#   npm run init-app -- --name "My App" --slug my-app --package com.me.myapp \
#     --bundle-id com.me.myapp --scheme myapp --contact-email hi@me.com \
#     --copyright-holder "Jane Doe" --dry-run
#
# Writes: apps/mobile/app.json, .env*, apps/product.json, apps/web/lander.json,
# and StoreKit productIDs. Privacy/terms URLs use https://<slug>.pages.dev/…
#
# Display names may contain spaces. Slug must be URL-safe lowercase.
# Android package ids may include underscores. iOS bundle ids may not —
# if --package is invalid as an iOS id, pass an explicit --bundle-id.
#
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Fixture smokes set FACTORY_ROOT to a temp tree; default is this repo.
ROOT="${FACTORY_ROOT:-$SCRIPT_ROOT}"
cd "$ROOT"

NAME=""
SLUG=""
PACKAGE=""
BUNDLE_ID=""
BUNDLE_ID_SET=0
SCHEME=""
CONTACT_EMAIL=""
COPYRIGHT_HOLDER=""
DRY_RUN=0

# Android: lowercase, digits, underscore, dots (Java package style).
ANDROID_PKG_RE='^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
# iOS: letters, digits, hyphens, dots — no underscores (Apple reverse-DNS).
IOS_BUNDLE_RE='^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+$'
# Expo slug / pages.dev / deep-link scheme source: lowercase, digits, hyphens.
SLUG_RE='^[a-z0-9]+(-[a-z0-9]+)*$'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    --slug) SLUG="${2:-}"; shift 2 ;;
    --package) PACKAGE="${2:-}"; shift 2 ;;
    --bundle-id) BUNDLE_ID="${2:-}"; BUNDLE_ID_SET=1; shift 2 ;;
    --scheme) SCHEME="${2:-}"; shift 2 ;;
    --contact-email) CONTACT_EMAIL="${2:-}"; shift 2 ;;
    --copyright-holder) COPYRIGHT_HOLDER="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,19p' "$0"
      exit 0
      ;;
    *)
      printf 'Unknown arg: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$NAME" || -z "$SLUG" || -z "$PACKAGE" ]]; then
  cat >&2 <<'EOF'
Missing required flags.

Required:
  --name "Display Name"
  --slug my-app-slug
  --package com.company.app

Optional:
  --bundle-id com.company.app   (defaults to --package when that id is also valid on iOS)
  --scheme myapp                (defaults from slug, alphanumeric)
  --contact-email you@domain    (defaults to support@<slug>.app — replace before store launch)
  --copyright-holder "Name"     (stamps LICENSE; omitted leaves the placeholder)
  --dry-run                     (print resolved values; do not write files)

Note: Android packages may use underscores (_). iOS bundle ids may not.
If --package contains _ (or otherwise fails the iOS rule), pass --bundle-id explicitly.
EOF
  exit 2
fi

if [[ ! "$SLUG" =~ $SLUG_RE ]]; then
  echo "Invalid --slug \"$SLUG\". Use lowercase letters, digits, and hyphens (e.g. my-app), no spaces." >&2
  exit 2
fi

if [[ -z "$SCHEME" ]]; then
  SCHEME="$(printf '%s' "$SLUG" | tr -cd 'a-zA-Z0-9' | tr '[:upper:]' '[:lower:]')"
fi

if [[ -z "$CONTACT_EMAIL" ]]; then
  CONTACT_EMAIL="support@${SLUG}.app"
fi

if [[ "$CONTACT_EMAIL" == *example.com* ]]; then
  echo "Refusing example.com contact email — pass --contact-email with a real address." >&2
  exit 1
fi

if [[ "$PACKAGE" == com.anonymous.* ]]; then
  echo "Refusing com.anonymous.* package id — choose a real reverse-DNS id." >&2
  exit 1
fi

if [[ ! "$PACKAGE" =~ $ANDROID_PKG_RE ]]; then
  echo "Android package id looks invalid: $PACKAGE (expected like com.company.app; lowercase, digits, underscores, dots)" >&2
  exit 1
fi

if [[ "$BUNDLE_ID_SET" -eq 0 ]]; then
  if [[ "$PACKAGE" =~ $IOS_BUNDLE_RE ]]; then
    BUNDLE_ID="$PACKAGE"
  else
    cat >&2 <<EOF
--package "$PACKAGE" is valid for Android but not for iOS (bundle ids cannot use underscores, and must match: Letter[Letter|Digit|Hyphen]*(.Letter[Letter|Digit|Hyphen]*)+).

Pass an explicit --bundle-id, for example:
  npm run init-app -- --name "$NAME" --slug "$SLUG" --package "$PACKAGE" --bundle-id com.company.app
EOF
    exit 1
  fi
fi

if [[ "$BUNDLE_ID" == com.anonymous.* ]]; then
  echo "Refusing com.anonymous.* bundle id — choose a real reverse-DNS id." >&2
  exit 1
fi

if [[ ! "$BUNDLE_ID" =~ $IOS_BUNDLE_RE ]]; then
  echo "iOS bundle id looks invalid: $BUNDLE_ID (letters, digits, hyphens, dots only — no underscores)" >&2
  exit 1
fi

APP_JSON="$ROOT/apps/mobile/app.json"
ENV_EXAMPLE="$ROOT/apps/mobile/.env.example"
ENV_LOCAL="$ROOT/apps/mobile/.env.local"
PRODUCT_JSON="$ROOT/apps/product.json"
LANDER_JSON="$ROOT/apps/web/lander.json"
STOREKIT="$ROOT/apps/mobile/store/storekit/Products.storekit"
DATA_PRACTICES="$ROOT/apps/mobile/store/data-practices.json"
IOS_PRIVACY_URL_FILE="$ROOT/apps/mobile/store/metadata/ios/en-US/privacy_url.txt"
IOS_SUPPORT_URL_FILE="$ROOT/apps/mobile/store/metadata/ios/en-US/support_url.txt"
LICENSE_FILE="$ROOT/LICENSE"
PRIVACY_URL="https://${SLUG}.pages.dev/privacy"
TERMS_URL="https://${SLUG}.pages.dev/terms"

if [[ ! -f "$APP_JSON" ]]; then
  echo "apps/mobile/app.json not found" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  cat <<EOF
Dry run — no files will be written.

Resolved identity:
  name:       $NAME
  slug:       $SLUG
  scheme:     $SCHEME
  android:    $PACKAGE
  ios:        $BUNDLE_ID
  contact:    $CONTACT_EMAIL
  copyright:  ${COPYRIGHT_HOLDER:-"(omit — LICENSE placeholder stays)"}
  privacy:    $PRIVACY_URL
  terms:      $TERMS_URL

Intended edits:
  • $APP_JSON — expo.name, expo.slug, expo.scheme, expo.android.package, expo.ios.bundleIdentifier
  • $ENV_EXAMPLE — upsert EXPO_PUBLIC_APP_NAME (if file exists)
  • $ENV_LOCAL — upsert EXPO_PUBLIC_APP_NAME (if file exists)
  • $PRODUCT_JSON — name, slug, contactEmail, privacyUrl, termsUrl (iosUrl/androidUrl stay # until listing live)
  • $LANDER_JSON — appName, contactEmail
  • $STOREKIT — productID prefixes from bundle id; warn if _developerTeamID still REPLACE_WITH_*
  • $DATA_PRACTICES — contact_email
  • $IOS_PRIVACY_URL_FILE / $IOS_SUPPORT_URL_FILE — live lander URLs
  • $LICENSE_FILE — copyright holder from --copyright-holder (skipped if omitted)
EOF
  exit 0
fi

# Prefer Node for JSON + env edits (handles spaces / special chars safely).
APP_JSON="$APP_JSON" \
PRODUCT_JSON="$PRODUCT_JSON" \
LANDER_JSON="$LANDER_JSON" \
STOREKIT="$STOREKIT" \
DATA_PRACTICES="$DATA_PRACTICES" \
IOS_PRIVACY_URL_FILE="$IOS_PRIVACY_URL_FILE" \
IOS_SUPPORT_URL_FILE="$IOS_SUPPORT_URL_FILE" \
LICENSE_FILE="$LICENSE_FILE" \
COPYRIGHT_HOLDER="$COPYRIGHT_HOLDER" \
NAME="$NAME" \
SLUG="$SLUG" \
SCHEME="$SCHEME" \
BUNDLE_ID="$BUNDLE_ID" \
PACKAGE="$PACKAGE" \
CONTACT_EMAIL="$CONTACT_EMAIL" \
PRIVACY_URL="$PRIVACY_URL" \
TERMS_URL="$TERMS_URL" \
ENV_EXAMPLE="$ENV_EXAMPLE" \
ENV_LOCAL="$ENV_LOCAL" \
node <<'NODE'
const fs = require('fs');

const appPath = process.env.APP_JSON;
const name = process.env.NAME;
const slug = process.env.SLUG;
const scheme = process.env.SCHEME;
const bundleId = process.env.BUNDLE_ID;
const pkg = process.env.PACKAGE;
const contact = process.env.CONTACT_EMAIL;
const privacyUrl = process.env.PRIVACY_URL;
const termsUrl = process.env.TERMS_URL;

const raw = fs.readFileSync(appPath, 'utf8');
const data = JSON.parse(raw);
const expo = data.expo || (data.expo = {});
expo.name = name;
expo.slug = slug;
expo.scheme = scheme;
expo.ios = expo.ios || {};
expo.ios.bundleIdentifier = bundleId;
expo.android = expo.android || {};
expo.android.package = pkg;
fs.writeFileSync(appPath, JSON.stringify(data, null, 2) + '\n');

/** Upsert EXPO_PUBLIC_APP_NAME=… (bare value; spaces allowed). */
function upsertAppName(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return;
  const contents = fs.readFileSync(filePath, 'utf8');
  const line = `EXPO_PUBLIC_APP_NAME=${name}`;
  const next = /^EXPO_PUBLIC_APP_NAME=/m.test(contents)
    ? contents.replace(/^EXPO_PUBLIC_APP_NAME=.*$/m, line)
    : contents.replace(/\s*$/, `\n${line}\n`);
  fs.writeFileSync(filePath, next);
}

upsertAppName(process.env.ENV_EXAMPLE);
upsertAppName(process.env.ENV_LOCAL);

const productPath = process.env.PRODUCT_JSON;
if (productPath && fs.existsSync(productPath)) {
  const product = JSON.parse(fs.readFileSync(productPath, 'utf8'));
  product.name = name;
  product.slug = slug;
  product.contactEmail = contact;
  product.privacyUrl = privacyUrl;
  product.termsUrl = termsUrl;
  // Keep iosUrl/androidUrl as "#" until store listings are live (preflight warns only).
  // Placeholder must stay in sync with apps/product.json and
  // scripts/store/review-preflight.sh — three languages, no shared constant.
  const TAGLINE_PLACEHOLDER = 'A short pitch for the marketing lander.';
  if (!product.tagline || product.tagline === TAGLINE_PLACEHOLDER) {
    product.tagline = `${name} — on-device tools that stay on your phone.`;
  }
  fs.writeFileSync(productPath, JSON.stringify(product, null, 2) + '\n');
}

const landerPath = process.env.LANDER_JSON;
if (landerPath && fs.existsSync(landerPath)) {
  const lander = JSON.parse(fs.readFileSync(landerPath, 'utf8'));
  lander.appName = name;
  lander.contactEmail = contact;
  fs.writeFileSync(landerPath, JSON.stringify(lander, null, 2) + '\n');
}

const storekitPath = process.env.STOREKIT;
if (storekitPath && fs.existsSync(storekitPath)) {
  const sk = JSON.parse(fs.readFileSync(storekitPath, 'utf8'));
  const groups = sk.subscriptionGroups || [];
  for (const g of groups) {
    for (const sub of g.subscriptions || []) {
      const old = String(sub.productID || '');
      // Replace leading reverse-DNS prefix up to .premium / keep suffix after first product segment.
      if (old.includes('.premium.')) {
        sub.productID = `${bundleId}.premium.${old.split('.premium.').pop()}`;
      } else if (old.startsWith('com.example.') || old.includes('mobileapp.')) {
        sub.productID = `${bundleId}.premium.monthly`;
      } else if (old) {
        // Keep suffix after last two dots of a typical id, else rewrite monthly.
        const parts = old.split('.');
        const suffix = parts.length >= 2 ? parts.slice(-2).join('.') : 'premium.monthly';
        sub.productID = `${bundleId}.${suffix}`;
      }
    }
  }
  fs.writeFileSync(storekitPath, JSON.stringify(sk, null, 2) + '\n');
  const team = sk?.settings?._developerTeamID;
  if (!team || String(team).includes('REPLACE_WITH')) {
    console.warn(
      'StoreKit _developerTeamID is still a placeholder — set your Apple Team ID in Xcode / Products.storekit (human/Xcode value).'
    );
  }
}

const practicesPath = process.env.DATA_PRACTICES;
if (practicesPath && fs.existsSync(practicesPath)) {
  const practices = JSON.parse(fs.readFileSync(practicesPath, 'utf8'));
  practices.contact_email = contact;
  fs.writeFileSync(practicesPath, JSON.stringify(practices, null, 2) + '\n');
}

function writeText(filePath, contents) {
  if (!filePath || !fs.existsSync(filePath)) return;
  fs.writeFileSync(filePath, contents.endsWith('\n') ? contents : `${contents}\n`);
}
writeText(process.env.IOS_PRIVACY_URL_FILE, privacyUrl);
writeText(process.env.IOS_SUPPORT_URL_FILE, privacyUrl.replace(/\/privacy$/, ''));

const licensePath = process.env.LICENSE_FILE;
const copyrightHolder = process.env.COPYRIGHT_HOLDER || '';
if (copyrightHolder && licensePath && fs.existsSync(licensePath)) {
  const year = new Date().getFullYear();
  const license = fs.readFileSync(licensePath, 'utf8');
  const next = license.replace(
    /Copyright \(c\) .+/,
    `Copyright (c) ${year} ${copyrightHolder}`
  );
  fs.writeFileSync(licensePath, next);
}
NODE

# JSON.stringify expands short arrays; Prettier wants them inline. Format the
# rewritten JSON so the next `npm run check` / verify does not fail on style.
# Prefer prettier next to the real script install (SCRIPT_ROOT), not the
# fixture tree (FACTORY_ROOT may lack node_modules).
PRETTIER=""
if [[ -x "$SCRIPT_ROOT/node_modules/.bin/prettier" ]]; then
  PRETTIER="$SCRIPT_ROOT/node_modules/.bin/prettier"
elif [[ -x "$ROOT/node_modules/.bin/prettier" ]]; then
  PRETTIER="$ROOT/node_modules/.bin/prettier"
fi
if [[ -n "$PRETTIER" ]]; then
  format_targets=()
  for f in "$APP_JSON" "$PRODUCT_JSON" "$LANDER_JSON" "$DATA_PRACTICES"; do
    [[ -f "$f" ]] && format_targets+=("$f")
  done
  if ((${#format_targets[@]} > 0)); then
    (cd "$SCRIPT_ROOT" && "$PRETTIER" --write "${format_targets[@]}") >/dev/null
  fi
fi

cat <<EOF
Updated app identity:
  name:       $NAME
  slug:       $SLUG
  scheme:     $SCHEME
  android:    $PACKAGE
  ios:        $BUNDLE_ID
  contact:    $CONTACT_EMAIL
  privacy:    $PRIVACY_URL
  terms:      $TERMS_URL

Next: npm run doctor
Then: Claude /app-product (docs/PRD.md) → pictures in docs/design-exports/ →
Claude /app-contract (docs/CONTRACT.md) → Cursor /app-critic (docs/CRITIC.md) →
Claude /app-backlog (docs/BACKLOG.md) → jobs.
EOF
if [[ -z "$COPYRIGHT_HOLDER" ]]; then
  printf 'LICENSE still has REPLACE_WITH_COPYRIGHT_HOLDER — re-run with --copyright-holder (or edit LICENSE by hand).\n'
fi
