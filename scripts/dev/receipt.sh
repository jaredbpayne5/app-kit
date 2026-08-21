#!/usr/bin/env bash
#
# scripts/dev/receipt.sh — proof that a verification command actually ran green
# at a specific commit.
#
# Without this, a reviewer takes the builder's word for "checks pass". A receipt
# is tied to the commit it was written at, so a stale or absent one is
# detectable — which is the property a reviewer actually needs.
#
# What a receipt proves and does not prove: `record` runs as the last link of the
# `verify` chain, so it is reached only if every earlier link exited 0. It cannot
# prove that nobody wrote one deliberately. Anything that can run shell can forge
# a file, so this is a speed bump against a careless or over-eager agent, not a
# security boundary. `record` is deliberately not a public npm script and refuses
# to run unless the verify chain invoked it. Treat a receipt as a claim with a
# commit attached, not as a cryptographic proof — a reviewer may always re-run
# the checks instead.
#
# Receipts live under .run/receipts/ and are gitignored. They are evidence about
# one machine at one moment, never a source of authority.
#
# Usage:
#   npm run receipt:check -- --command=verify      # does HEAD have one?
#   npm run receipt:check -- --command=verify --strict
#
# Recording happens inside `npm run verify`. There is no by-hand equivalent.
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
    # Only the verify chain sets this. Without it, `record` was a one-command
    # path to a green receipt for a run that never happened — the exact
    # claim-without-evidence problem receipts exist to remove.
    if [[ "${APP_KIT_RECEIPT_FROM_VERIFY:-}" != "1" ]]; then
      echo "receipt: refusing to record — a receipt is written by the verify chain, not by hand" >&2
      echo "receipt: run 'npm run verify'" >&2
      exit 2
    fi
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
