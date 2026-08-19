#!/usr/bin/env bash
# Run shellcheck on guard / hook scripts. Missing binary: fail, including on
# CI. The workflow installs shellcheck before npm run check.
#
# Glob hook and guard directories. Do not list individual hook files by
# hand — a deleted waiter must not stay on a list and keep check green.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck-guards: shellcheck is not on PATH. Install it (brew install shellcheck, or apt-get install shellcheck on CI) so npm run check can prove the guards parse."
  exit 1
fi

shopt -s nullglob
files=(
  .cursor/hooks/*.sh
  .claude/hooks/*.sh
  .githooks/*
  scripts/lib/*.sh
  scripts/ci/*.sh
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "shellcheck-guards: glob set is empty"
  exit 1
fi

echo "shellcheck-guards: checking ${#files[@]} files"
if ! shellcheck -S warning "${files[@]}"; then
  echo "shellcheck-guards: failed"
  exit 1
fi
echo "shellcheck-guards: ok"
