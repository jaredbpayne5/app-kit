#!/usr/bin/env bash
# Run shellcheck on guard / hook scripts. Missing binary: fail locally,
# warn-and-pass on CI (ci.yml is agent-denied, so we cannot apt-get it there).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

if ! command -v shellcheck >/dev/null 2>&1; then
  if [[ "${CI:-}" == true ]]; then
    echo "shellcheck-guards: shellcheck not installed on CI — skipped"
    exit 0
  fi
  echo "shellcheck-guards: shellcheck is not on PATH. Install it (brew install shellcheck) so npm run check can prove the guards parse."
  exit 1
fi

files=(
  scripts/lib/guard-deploy-match.sh
  scripts/lib/guard-sensitive-paths.sh
  scripts/lib/guard-sensitive-writes-claude.sh
  scripts/lib/mailbox-check.sh
  scripts/lib/mailbox-check-claude.sh
  scripts/lib/guard-deploy-claude.sh
  scripts/lib/fail-proof-checks.test.sh
  scripts/dev/shellcheck-guards.sh
  .cursor/hooks/guard-shell.sh
  .cursor/hooks/guard-protected-files.sh
  .cursor/hooks/guard-secret-files.sh
  .cursor/hooks/guard-identity-writes.sh
  .cursor/hooks/guard-mailbox.sh
  .cursor/hooks/wait-for-mail.sh
)

echo "shellcheck-guards: checking ${#files[@]} files"
if ! shellcheck -S warning "${files[@]}"; then
  echo "shellcheck-guards: failed"
  exit 1
fi
echo "shellcheck-guards: ok"
