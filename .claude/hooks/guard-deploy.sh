#!/usr/bin/env bash
# Asks before EAS build/submit/update, expo prebuild, push to main,
# Cloudflare Pages deploy, custom-domain attach, store:push / fastlane,
# and adding a dependency.
# These either cost money, go public, or are hard to undo.
# Deliberately does NOT gate plain `git commit` — only `git push`. Gating
# commits too would make every local commit interactive for no safety gain.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "jq is required for Claude hooks but is not installed. Install jq (e.g. brew install jq) then retry."}}
JSON
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
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Confirm before continuing: push to main, EAS build/submit/update / expo prebuild, Cloudflare Pages deploy (web:deploy / wrangler pages deploy), custom-domain attach (attach-domain / wrangler pages domain / Cloudflare DNS or Pages domains API), store:push / fastlane, or adding a dependency (npm/yarn/pnpm/bun install or add with a package, npx expo install). EAS builds, lander deploys, public DNS changes, and store submissions cost money or are irreversible; a new dependency can add permission prompts and App Review questions (docs/CAPABILITIES.md)."}}
JSON
  exit 0
fi

exit 0
