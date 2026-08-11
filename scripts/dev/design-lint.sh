#!/usr/bin/env bash
#
# scripts/dev/design-lint.sh — grep-based guard for a few generic-UI patterns
# found and fixed once in a product build. Cheap, mechanical checks a weak
# model can run reliably — nowhere near a substitute for real visual review,
# but enough to keep a fixed mistake from quietly coming back.
#
# Usage:
#   npm run design-lint
#   bash scripts/dev/design-lint.sh
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

FAIL=0

# --- 1. Raw text-[Npx] literals outside ui/ ----------------------------------
# ui/text.tsx is the one sanctioned place to define the type scale; screens
# should use its variants, not ad hoc arbitrary sizes. One documented
# exception below: paywall.tsx's anchored-plan price is a 22px non-heading
# emphasis number with no natural home in the scale — h2's pixel values match
# but carry heading ARIA semantics that would be wrong for a price string,
# and a single call site doesn't justify a new variant. Allowlisted explicitly
# rather than silently ignored.
TEXT_SIZE_ALLOWLIST='apps/mobile/components/paywall.tsx:'
TEXT_SIZE_HITS="$(
  grep -rnE "text-\[[0-9]" \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components 2>/dev/null \
    | grep -v "^${TEXT_SIZE_ALLOWLIST}.*text-\[22px\]" || true
)"
if [[ -n "$TEXT_SIZE_HITS" ]]; then
  echo "design-lint: raw text-[Npx] literal(s) outside ui/text.tsx's scale:"
  echo "$TEXT_SIZE_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no raw text-[Npx] literals in app/ or components/ (besides the documented paywall.tsx price exception)"
fi

# --- 2. Literal bullet characters (should be an icon+text row, not "•ˑtext")--
BULLET_HITS="$(
  grep -rnF '•' \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components 2>/dev/null || true
)"
if [[ -n "$BULLET_HITS" ]]; then
  echo "design-lint: literal bullet character(s) — use an icon+text row instead:"
  echo "$BULLET_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no literal bullet characters in app/ or components/"
fi

# --- 3. Hardcoded hex colors via Tailwind arbitrary-value syntax ------------
# Self-review rubric item 8 ("light + dark mode") mostly needs real
# rendering, but a hardcoded hex bypasses the theme tokens outright and is
# guaranteed to break in the mode it wasn't eyeballed in — this is the one
# slice of that rubric item that's actually mechanical.
HEX_CLASS_HITS="$(
  grep -rnE '\[#[0-9A-Fa-f]{3,8}\]' \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components apps/mobile/ui 2>/dev/null || true
)"
if [[ -n "$HEX_CLASS_HITS" ]]; then
  echo "design-lint: hardcoded hex color(s) via Tailwind arbitrary value — use a theme token:"
  echo "$HEX_CLASS_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded hex Tailwind classes in app/, components/, or ui/"
fi

# --- 3b. Hardcoded hsl()/hsla()/rgb()/rgba() literals ------------------------
# Same rule as hex: colors belong in global.css → theme-tokens, not inline in
# screens/components. (Hex-only grep missed BrandAtmosphere's hsla() washes.)
FUNC_COLOR_HITS="$(
  grep -rnE '\b(hsla?|rgba?)\s*\(' \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components apps/mobile/ui 2>/dev/null || true
)"
if [[ -n "$FUNC_COLOR_HITS" ]]; then
  echo "design-lint: hardcoded hsl/hsla/rgb/rgba literal(s) — use a theme token from lib/theme-tokens.ts:"
  echo "$FUNC_COLOR_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded hsl/hsla/rgb/rgba literals in app/, components/, or ui/"
fi

# --- 3c. Hardcoded named Tailwind palette classes ----------------------------
# Hex/hsl rules miss `text-white` and `bg-black/50`. Named palette classes
# also bypass theme tokens. shadow-* is not in the utility list — shadow-black/5
# is a shadow tint, not a surface or text colour.
# Dismiss-scrims are a deliberate neutral overlay that must not invert with
# the theme; routing them through a token would be wrong. Allowlisted
# explicitly rather than loosening the pattern.
NAMED_PALETTE='white|black|slate|gray|grey|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose'
NAMED_COLOR_HITS="$(
  grep -rnE "\\b(bg|text|border|ring|fill|stroke|from|to|via)-(${NAMED_PALETTE})(-(100|200|300|400|500|600|700|800|900))?(/[0-9.]+)?\\b" \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components apps/mobile/ui 2>/dev/null \
    | grep -vE ':[0-9]+:[[:space:]]*[*/]' \
    | grep -vE '^apps/mobile/ui/alert-dialog\.tsx:30:.*bg-black/50' \
    | grep -vE '^apps/mobile/components/date-field\.tsx:86:.*bg-black/40' \
    | grep -vE '^apps/mobile/components/number-wheel-field\.tsx:99:.*bg-black/40' \
    || true
)"
if [[ -n "$NAMED_COLOR_HITS" ]]; then
  echo "design-lint: hardcoded named Tailwind palette class(es) — use a theme token:"
  echo "$NAMED_COLOR_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded named Tailwind palette classes in app/, components/, or ui/ (besides documented dismiss-scrims)"
fi

# --- 4. Empty catch blocks ----------------------------------------------------
# Self-review rubric item 7 ("no unguarded JSON.parse; no unhandled promise
# rejection; no empty catch") is mostly a judgment call, but a literal empty
# catch block is unambiguous and mechanical.
EMPTY_CATCH_HITS="$(
  grep -rnE 'catch\s*(\([^)]*\))?\s*\{\s*\}' \
    --include='*.tsx' --include='*.ts' \
    apps/mobile/app apps/mobile/components apps/mobile/lib 2>/dev/null | grep -v '\.test\.' || true
)"
if [[ -n "$EMPTY_CATCH_HITS" ]]; then
  echo "design-lint: empty catch block(s) — report or explicitly no-op with a comment:"
  echo "$EMPTY_CATCH_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no empty catch blocks in app/, components/, or lib/"
fi

# --- 5. Safe-area insets on top-level screens --------------------------------
# Self-review rubric item 6 ("safe-area insets handled on every screen") —
# a real rendering check would need a device/simulator, but every screen
# that paints its own UI (i.e. isn't a pure redirect stub) should at least
# reference useSafeAreaInsets/SafeAreaView somewhere.
#
# Discovery is a recursive find over apps/mobile/app rather than a fixed list of
# globs. An earlier version hardcoded `app/*.tsx` and `app/(app)/*.tsx`; the real
# route group is `(tabs)`, so every screen an agent actually builds went
# unchecked while this reported success. Any route group — existing or added
# later — is covered now.
SAFE_AREA_MISS=""
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  case "$base" in
    _layout.tsx | +not-found.tsx | +html.tsx) continue ;;
    *.test.tsx) continue ;;
  esac
  # Redirect-only stub — paints nothing, so safe-area is meaningless. A file
  # that redirects *and* renders styled UI is a real screen and must still be
  # checked, so require the absence of any NativeWind class before skipping.
  if grep -q '<Redirect' "$f" && ! grep -q 'className=' "$f"; then
    continue
  fi
  if ! grep -q 'useSafeAreaInsets\|SafeAreaView' "$f"; then
    SAFE_AREA_MISS+="  $f"$'\n'
  fi
done < <(find apps/mobile/app -type f -name '*.tsx' | sort)
if [[ -n "$SAFE_AREA_MISS" ]]; then
  echo "design-lint: screen(s) with no useSafeAreaInsets/SafeAreaView reference:"
  printf '%s' "$SAFE_AREA_MISS"
  FAIL=1
else
  echo "design-lint: every top-level screen references safe-area insets"
fi

if [[ "$FAIL" -eq 1 ]]; then
  exit 1
fi

echo "design-lint OK"
