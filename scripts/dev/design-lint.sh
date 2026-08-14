#!/usr/bin/env bash
#
# scripts/dev/design-lint.sh — grep-based guard for a few generic-UI patterns
# found and fixed once in a product build. Cheap, mechanical checks a weak
# model can run reliably — nowhere near a substitute for real visual review,
# but enough to keep a fixed mistake from quietly coming back.
#
# Scans the same apps/mobile TS/TSX tree NativeWind compiles (minus native /
# generated dirs). A folder a model invents must not escape these checks.
#
# Usage:
#   npm run design-lint
#   bash scripts/dev/design-lint.sh
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

FAIL=0

grep_mobile() {
  grep -rn "$@" \
    --include='*.tsx' --include='*.ts' \
    --exclude-dir=node_modules --exclude-dir=android --exclude-dir=ios \
    --exclude-dir=.expo --exclude-dir=__tests__ \
    apps/mobile 2>/dev/null \
    | grep -vE '\.test\.(ts|tsx):' || true
}

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
  grep_mobile -E "text-\[[0-9]" \
    | grep -v '^apps/mobile/ui/text\.tsx:' \
    | grep -v "^${TEXT_SIZE_ALLOWLIST}.*text-\[22px\]" || true
)"
if [[ -n "$TEXT_SIZE_HITS" ]]; then
  echo "design-lint: raw text-[Npx] literal(s) outside ui/text.tsx's scale:"
  echo "$TEXT_SIZE_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no raw text-[Npx] literals outside ui/text.tsx (besides the documented paywall.tsx price exception)"
fi

# --- 2. Literal bullet characters (should be an icon+text row, not "•ˑtext")--
BULLET_HITS="$(grep_mobile -F '•')"
if [[ -n "$BULLET_HITS" ]]; then
  echo "design-lint: literal bullet character(s) — use an icon+text row instead:"
  echo "$BULLET_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no literal bullet characters in apps/mobile TS/TSX"
fi

# --- 3. Hardcoded hex colors via Tailwind arbitrary-value syntax ------------
# Self-review rubric item 8 ("light + dark mode") mostly needs real
# rendering, but a hardcoded hex bypasses the theme tokens outright and is
# guaranteed to break in the mode it wasn't eyeballed in — this is the one
# slice of that rubric item that's actually mechanical.
HEX_CLASS_HITS="$(grep_mobile -E '\[#[0-9A-Fa-f]{3,8}\]')"
if [[ -n "$HEX_CLASS_HITS" ]]; then
  echo "design-lint: hardcoded hex color(s) via Tailwind arbitrary value — use a theme token:"
  echo "$HEX_CLASS_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded hex Tailwind classes in apps/mobile TS/TSX"
fi

# --- 3b. Hardcoded hsl()/hsla()/rgb()/rgba() literals ------------------------
# Same rule as hex: colors belong in global.css → theme-tokens, not inline in
# screens/components. (Hex-only grep missed BrandAtmosphere's hsla() washes.)
FUNC_COLOR_HITS="$(
  grep_mobile -E '\b(hsla?|rgba?)\s*\(' \
    | grep -v '^apps/mobile/lib/theme-tokens\.ts:' \
    | grep -v '^apps/mobile/lib/theme\.ts:' \
    || true
)"
if [[ -n "$FUNC_COLOR_HITS" ]]; then
  echo "design-lint: hardcoded hsl/hsla/rgb/rgba literal(s) — use a theme token from lib/theme-tokens.ts:"
  echo "$FUNC_COLOR_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded hsl/hsla/rgb/rgba literals in apps/mobile TS/TSX"
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
  grep_mobile -E "\\b(bg|text|border|ring|fill|stroke|from|to|via)-(${NAMED_PALETTE})(-(100|200|300|400|500|600|700|800|900))?(/[0-9.]+)?\\b" \
    | grep -vE ':[0-9]+:[[:space:]]*[*/]' \
    | grep -vE '^apps/mobile/ui/alert-dialog\.tsx:[0-9]+:.*bg-black/50' \
    | grep -vE '^apps/mobile/components/date-field\.tsx:[0-9]+:.*bg-black/40' \
    | grep -vE '^apps/mobile/components/number-wheel-field\.tsx:[0-9]+:.*bg-black/40' \
    || true
)"
if [[ -n "$NAMED_COLOR_HITS" ]]; then
  echo "design-lint: hardcoded named Tailwind palette class(es) — use a theme token:"
  echo "$NAMED_COLOR_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no hardcoded named Tailwind palette classes (besides documented dismiss-scrims)"
fi

# --- 4. Empty catch blocks ----------------------------------------------------
# Self-review rubric item 7 ("no unguarded JSON.parse; no unhandled promise
# rejection; no empty catch") is mostly a judgment call, but a literal empty
# catch block is unambiguous and mechanical.
EMPTY_CATCH_HITS="$(grep_mobile -E 'catch\s*(\([^)]*\))?\s*\{\s*\}')"
if [[ -n "$EMPTY_CATCH_HITS" ]]; then
  echo "design-lint: empty catch block(s) — report or explicitly no-op with a comment:"
  echo "$EMPTY_CATCH_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no empty catch blocks in apps/mobile TS/TSX"
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

# --- 6. New routes while the design inventory is still a placeholder ---------
# Catches *new route files* under apps/mobile/app/ while screens-status.md
# still carries its sentinel. Does not catch a freehand redesign of an
# existing screen. The template ships the sentinel plus the 8 routes below;
# fail only when a file appears that is not in this list. Update the list if
# the template itself gains a route, or this check fires on the template.
TEMPLATE_ROUTE_BASELINE=(
  'apps/mobile/app/_layout.tsx'
  'apps/mobile/app/onboarding.tsx'
  'apps/mobile/app/+html.tsx'
  'apps/mobile/app/+not-found.tsx'
  'apps/mobile/app/(tabs)/_layout.tsx'
  'apps/mobile/app/(tabs)/index.tsx'
  'apps/mobile/app/(tabs)/library.tsx'
  'apps/mobile/app/(tabs)/settings.tsx'
)
NEW_ROUTES=""
if grep -q '<!-- TEMPLATE_PLACEHOLDER -->' docs/screens-status.md 2>/dev/null; then
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    is_baseline=0
    for b in "${TEMPLATE_ROUTE_BASELINE[@]}"; do
      if [[ "$f" == "$b" ]]; then
        is_baseline=1
        break
      fi
    done
    if [[ "$is_baseline" -eq 0 ]]; then
      NEW_ROUTES+="  $f"$'\n'
    fi
  done < <(find apps/mobile/app -type f -name '*.tsx' | sort)
fi
if [[ -n "$NEW_ROUTES" ]]; then
  echo "design-lint: new route file(s) under apps/mobile/app/ while docs/screens-status.md still has its TEMPLATE_PLACEHOLDER sentinel:"
  printf '%s' "$NEW_ROUTES"
  echo "  Fill docs/screens-status.md (Designed = yes + artifact) and remove the sentinel before building the screen."
  FAIL=1
else
  echo "design-lint: no new route files while the screens-status sentinel is present"
fi

# --- 7. Inline style={{}} without an explicit native-required marker ---------
# NativeWind is the styling system. Dynamic insets, pager width, and libraries
# that do not accept className (gorhom sheets, native pickers) may keep a
# style={{ }} object if this line or the next includes `native-required`
# (Prettier often wraps the object onto the following line).
INLINE_STYLE_HITS=""
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  file="${hit%%:*}"
  rest="${hit#*:}"
  lineno="${rest%%:*}"
  next=$((lineno + 1))
  if sed -n "${lineno},${next}p" "$file" | grep -q 'native-required'; then
    continue
  fi
  INLINE_STYLE_HITS+="$hit"$'\n'
done < <(grep_mobile -E 'style=\{\{')
if [[ -n "$INLINE_STYLE_HITS" ]]; then
  echo "design-lint: inline style={{ }} without a native-required comment on this line or the next — use NativeWind className, or mark the exception:"
  printf '%s' "$INLINE_STYLE_HITS" | sed 's/^/  /'
  FAIL=1
else
  echo "design-lint: no unmarked inline style={{ }} in apps/mobile TS/TSX"
fi

if [[ "$FAIL" -eq 1 ]]; then
  exit 1
fi

echo "design-lint OK"
