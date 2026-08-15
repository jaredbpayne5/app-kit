#!/usr/bin/env bash
# Run shellcheck on guard / hook scripts. Missing binary: fail, including on
# CI. The workflow installs shellcheck before npm run check.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck-guards: shellcheck is not on PATH. Install it (brew install shellcheck, or apt-get install shellcheck on CI) so npm run check can prove the guards parse."
  exit 1
fi

files=(
  scripts/lib/guard-deploy-match.sh
  scripts/lib/guard-deploy-match.test.sh
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
  .claude/hooks/guard-secrets.sh
  .claude/hooks/guard-deploy.sh
  .claude/hooks/guard-sensitive-writes.sh
  .claude/hooks/wait-for-review.sh
  .githooks/pre-commit
  scripts/dev/knip-clone.sh
  scripts/ci/expo-sdk-check.sh
  scripts/ci/audit-report.sh
  scripts/lib/u4-fail-proof.sh
)

echo "shellcheck-guards: checking ${#files[@]} files"
if ! shellcheck -S warning "${files[@]}"; then
  echo "shellcheck-guards: failed"
  exit 1
fi
echo "shellcheck-guards: ok"
