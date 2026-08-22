#!/usr/bin/env bash
#
# scripts/dev/backlog-lint.sh — validate the job cards in docs/BACKLOG.md against the
# shape .claude/skills/app-backlog/SKILL.md promises. A vague job produces vague code
# and a weak review, so the fields a builder needs (target files, proof tier,
# dependencies) must be named fields rather than buried in Notes prose.
#
# Only unchecked jobs are linted. A checked job is already built and reviewed.
#
# Warn-only by default so a hand-edited backlog cannot block `npm run check`.
# Pass --strict once the format has settled to make issues fail.
#
# Usage:
#   npm run backlog-lint
#   npm run backlog-lint -- --strict
#   bash scripts/dev/backlog-lint.sh --file=scripts/dev/fixtures/backlog-lint/bad.md
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

PLAN="docs/BACKLOG.md"
STRICT=0
EXPLICIT_FILE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file=*) PLAN="${1#--file=}"; EXPLICIT_FILE=1; shift ;;
    --file) PLAN="${2:-}"; EXPLICIT_FILE=1; shift 2 ;;
    --strict) STRICT=1; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) printf 'Unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$PLAN" ]]; then
  # Quiet only for the default path, where a missing backlog is the normal
  # state of a fresh clone. A named --file that is not there is a typo, and
  # reporting success would turn an operator mistake into a pass.
  if [[ "$EXPLICIT_FILE" -eq 1 ]]; then
    echo "backlog-lint: $PLAN does not exist" >&2
    exit 2
  fi
  echo "backlog-lint: no $PLAN yet — nothing to lint"
  exit 0
fi

# Before a product exists there is nothing to plan. Mirrors the design-lint
# sentinel gate so a template clone stays quiet.
if [[ "$PLAN" == "docs/BACKLOG.md" ]] \
  && grep -q 'TEMPLATE_PLACEHOLDER' docs/PRD.md 2>/dev/null; then
  echo "backlog-lint: docs/PRD.md still has its TEMPLATE_PLACEHOLDER sentinel — skipping"
  exit 0
fi

WARN=0
JOBS=0

warn() {
  echo "  ✗ $*"
  WARN=$((WARN + 1))
}

# Every job number in the file, so Deps can be cross-referenced.
ALL_JOBS=" $(grep -oE '^- \[[ xX]\] [0-9]+\.' "$PLAN" \
  | grep -oE '[0-9]+' | tr '\n' ' ')"

field_value() {
  # First value of "<name>:" in the current block.
  printf '%s\n' "$BLOCK" \
    | sed -nE "s/^[[:space:]]*$1:[[:space:]]*(.*)$/\1/p" \
    | head -1
}

trim() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

NUM=""
CHECKED=""
AT=""
BLOCK=""

validate() {
  [[ -z "$NUM" ]] && return 0
  [[ "$CHECKED" == "yes" ]] && return 0
  JOBS=$((JOBS + 1))

  local label="job $NUM (line $AT)"

  local f
  for f in "Done when" "Files" "Tests" "Deps" "Check" "Notes"; do
    if ! printf '%s\n' "$BLOCK" | grep -qE "^[[:space:]]*$f:"; then
      warn "$label: missing '$f:'"
    fi
  done

  # --- Tests: one or more known tiers -----------------------------------------
  local tests_val tier
  tests_val="$(field_value Tests)"
  if [[ -n "$tests_val" ]]; then
    # `IFS=',' read` scopes the separator to this one command. A bare
    # `local IFS=','` would leak to the Deps loop below, where the values
    # arrive newline-separated.
    local tiers=()
    IFS=',' read -ra tiers <<< "$tests_val"
    for tier in "${tiers[@]}"; do
      tier="$(trim "$tier")"
      [[ -z "$tier" ]] && continue
      case "$tier" in
        logic | screen | flow | none) ;;
        *) warn "$label: unknown test tier '$tier' (use logic, screen, flow, none)" ;;
      esac
    done
  fi

  # --- Files: real paths, not a placeholder -----------------------------------
  local files_val entry
  files_val="$(field_value Files)"
  if [[ -n "$files_val" ]]; then
    case "$files_val" in
      *TBD* | *tbd* | *'???'*)
        warn "$label: Files must name real paths, not a placeholder"
        ;;
    esac
    local entries=()
    IFS=',' read -ra entries <<< "$files_val"
    for entry in "${entries[@]}"; do
      entry="$(trim "$entry")"
      [[ -z "$entry" ]] && continue
      if [[ "$entry" != */* && "$entry" != *.* ]]; then
        warn "$label: Files entry '$entry' does not look like a path"
      fi
    done
  fi

  # --- Deps: none, or earlier jobs that exist ---------------------------------
  local deps_val dep
  deps_val="$(field_value Deps)"
  if [[ -n "$deps_val" ]] && [[ "$(printf '%s' "$deps_val" \
    | tr '[:upper:]' '[:lower:]' | tr -d '[:space:].')" != "none" ]]; then
    for dep in $(printf '%s' "$deps_val" | grep -oE '[0-9]+'); do
      if [[ "$ALL_JOBS" != *" $dep "* ]]; then
        warn "$label: Deps references job $dep, which does not exist"
      elif [[ "$dep" -ge "$NUM" ]]; then
        warn "$label: Deps references job $dep, which is not earlier — jobs must be dependency-ordered"
      fi
    done
  fi
}

LINENO_AT=0
while IFS= read -r line || [[ -n "$line" ]]; do
  LINENO_AT=$((LINENO_AT + 1))
  if [[ "$line" =~ ^-\ \[([\ xX])\]\ ([0-9]+)\. ]]; then
    validate
    if [[ "${BASH_REMATCH[1]}" == " " ]]; then CHECKED="no"; else CHECKED="yes"; fi
    NUM="${BASH_REMATCH[2]}"
    AT="$LINENO_AT"
    BLOCK="$line"
    continue
  fi
  # A new top-level heading ends the current card.
  if [[ "$line" == '#'* ]]; then
    validate
    NUM=""
    BLOCK=""
    continue
  fi
  if [[ -n "$NUM" ]]; then
    BLOCK="$BLOCK
$line"
  fi
done < "$PLAN"
validate

if [[ "$WARN" -eq 0 ]]; then
  echo "backlog-lint: $JOBS unchecked job(s) OK in $PLAN"
  exit 0
fi

echo "backlog-lint: $WARN issue(s) across $JOBS unchecked job(s) in $PLAN"
if [[ "$STRICT" -eq 1 ]]; then
  exit 1
fi
echo "backlog-lint: warn-only — pass --strict to make this fail"
exit 0
