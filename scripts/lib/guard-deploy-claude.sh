#!/usr/bin/env bash
# Claude PreToolUse adapter for guard-deploy-match.sh.
# jq missing: allow (not secret detection). Secrets stay fail-closed.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ -z "$command" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-deploy-match.sh
source "$ROOT/scripts/lib/guard-deploy-match.sh"

if guard_should_ask "$command"; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Confirm before continuing: push to main, EAS build/submit/update / expo prebuild, Cloudflare Pages deploy, custom-domain attach, store:push / fastlane, session:down, disabling git hooks, or adding a dependency. This matcher is a speed bump, not a security boundary."}}
JSON
  exit 0
fi

exit 0
