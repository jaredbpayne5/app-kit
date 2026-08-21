#!/usr/bin/env bash
#
# scripts/dev/receipt.sh — proof that a verification command actually ran green
# at a specific commit.
#
# Without this, a reviewer takes the builder's word for "checks pass". A receipt
# is written only by a command that succeeded, and is tied to the commit it ran
# against, so a stale or absent receipt is detectable.
#
# Receipts live under .run/receipts/ and are gitignored. They are evidence about
# one machine at one moment, never a source of authority.
#
# Usage:
#   npm run receipt:record -- --command=verify     # after a green run
#   npm run receipt:check -- --command=verify      # does HEAD have one?
#   npm run receipt:check -- --command=verify --strict
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

ACTION="${1:-}"
shift || true

COMMAND=""
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --command=*) COMMAND="${1#--command=}"; shift ;;
    --command) COMMAND="${2:-}"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    -h | --help) sed -n '2,18p' "$0"; exit 0 ;;
    *) printf 'Unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ -z "$COMMAND" ]]; then
  echo "receipt: --command=<label> is required" >&2
  exit 2
fi

# Label is used in a filename; keep it boring.
if [[ ! "$COMMAND" =~ ^[A-Za-z0-9_:-]+$ ]]; then
  echo "receipt: --command must be alphanumeric with - _ : only" >&2
  exit 2
fi

COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
DIR=".run/receipts"
SAFE_LABEL="${COMMAND//:/-}"
FILE="${DIR}/${SAFE_LABEL}-${COMMIT}.json"

tree_state() {
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo dirty
  else
    echo clean
  fi
}

case "$ACTION" in
  record)
    mkdir -p "$DIR"
    printf '{\n  "command": "%s",\n  "commit": "%s",\n  "branch": "%s",\n  "timestamp": "%s",\n  "exit_code": 0,\n  "tree": "%s"\n}\n' \
      "$COMMAND" "$COMMIT" "$BRANCH" \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(tree_state)" \
      > "$FILE"
    echo "receipt: recorded $COMMAND green at ${COMMIT:0:12} ($(tree_state) tree)"
    ;;

  check)
    if [[ ! -f "$FILE" ]]; then
      echo "receipt: no '$COMMAND' receipt for HEAD ${COMMIT:0:12}"
      echo "receipt: run 'npm run $COMMAND' — a green run records one"
      [[ "$STRICT" -eq 1 ]] && exit 1
      echo "receipt: warn-only — pass --strict to make this fail"
      exit 0
    fi

    recorded_tree="$(sed -nE 's/.*"tree": "([a-z]+)".*/\1/p' "$FILE" | head -1)"
    recorded_at="$(sed -nE 's/.*"timestamp": "([^"]+)".*/\1/p' "$FILE" | head -1)"
    echo "receipt: '$COMMAND' passed at ${COMMIT:0:12} on $recorded_at (${recorded_tree} tree)"

    problem=0
    if [[ "$recorded_tree" != clean ]]; then
      echo "receipt: the tree was dirty when this ran, so the commit does not fully describe what was verified"
      problem=1
    fi
    if [[ "$(tree_state)" == dirty ]]; then
      echo "receipt: the tree is dirty now, so uncommitted changes are unproven"
      problem=1
    fi

    if [[ "$problem" -eq 1 && "$STRICT" -eq 1 ]]; then
      exit 1
    fi
    exit 0
    ;;

  *)
    echo "receipt: first argument must be 'record' or 'check'" >&2
    exit 2
    ;;
esac
