#!/usr/bin/env bash
# Cursor beforeShellExecution adapter for the shared deploy / spend /
# dependency-add matcher. Flat permission JSON (SKILL.md:152-160).
# stdin field is .command, not .tool_input.command.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo '{"permission":"allow"}'
  exit 0
fi

input=$(cat)
command=$(echo "$input" | jq -r '.command // empty')

if [[ -z "$command" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-deploy-match.sh
source "$ROOT/scripts/lib/guard-deploy-match.sh"
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"

if guard_command_writes_protected "$command"; then
  cat <<'JSON'
{"permission":"deny","user_message":"This command would rewrite a factory guard (hooks, matchers, mailbox check, eslint, githooks, or CI). Denied so an agent cannot hollow out the safety net. Change it yourself in the editor if you really mean to.","agent_message":"Shell denied: command writes to a protected guard file."}
JSON
  exit 0
fi

if guard_should_ask "$command"; then
  cat <<'JSON'
{"permission":"ask","user_message":"Confirm before continuing: push to main, EAS build/submit/update / expo prebuild, Cloudflare Pages deploy (web:deploy / wrangler pages deploy), custom-domain attach (attach-domain / wrangler pages domain / Cloudflare DNS or Pages domains API), store:push / fastlane, or adding a dependency (npm/yarn/pnpm/bun install or add with a package, npx expo install). EAS builds, lander deploys, public DNS changes, and store submissions cost money or are irreversible; a new dependency can add permission prompts and App Review questions (docs/recipes/native-kit.md).","agent_message":"A hook flagged this shell command as a deploy, store, or dependency-add action that needs confirmation."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
