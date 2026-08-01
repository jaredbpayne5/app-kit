#!/usr/bin/env bash
# Asks before EAS build/submit/update, expo prebuild, push to main,
# Cloudflare Pages deploy, custom-domain attach, store:push / fastlane.
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

is_push_to_main=false
if echo "$command" | grep -Eq '(^|[;&|]) *git push'; then
  if echo "$command" | grep -Eq '\bmain\b'; then
    is_push_to_main=true
  else
    current_branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$current_branch" == "main" ]]; then
      is_push_to_main=true
    fi
  fi
fi

is_eas_cmd=false
if echo "$command" | grep -Eq '\beas (build|submit|update)\b|\bnpx expo prebuild\b|\bexpo prebuild\b'; then
  is_eas_cmd=true
fi

# Cloudflare Pages lander deploy — ask (CLAUDE.md Hard Stop / web:deploy).
# npm run web:deploy always matched; direct-bash path must be scripts/web/ (monorepo).
is_web_deploy=false
if echo "$command" | grep -Eq '\b(npm run )?web:deploy\b|\bbash scripts/web/deploy-lander\.sh\b'; then
  is_web_deploy=true
fi
if echo "$command" | grep -Eq '\bwrangler pages deploy\b|\bnpx wrangler pages deploy\b'; then
  is_web_deploy=true
fi

# Custom domain attach — ask (mutates public DNS / Pages domains).
# Prefer scripts/web/ path; bare attach-domain also matches npm run domain-attach.
is_domain_attach=false
if echo "$command" | grep -Eq '\b(npm run )?domain-attach\b|\b(npm run )?attach-domain\b|\bbash scripts/web/attach-domain\.sh\b'; then
  is_domain_attach=true
fi
if echo "$command" | grep -Eq '\bwrangler pages domains?\b|\bnpx wrangler pages domains?\b'; then
  is_domain_attach=true
fi
# Cloudflare DNS / Pages domains API (attach-domain.sh and ad-hoc curls).
if echo "$command" | grep -Eq 'api\.cloudflare\.com/client/v4/(zones/[^/]+/dns_records|accounts/[^/]+/pages/projects/[^/]+/domains)'; then
  is_domain_attach=true
fi

# Store listing / binary push — ask (store:push + fastlane deliver/supply).
# npm run store:push always matched; direct-bash path must be scripts/store/ (monorepo).
is_store_push=false
if echo "$command" | grep -Eq '\b(npm run )?store:push\b|\bbash scripts/store/store-push\.sh\b'; then
  is_store_push=true
fi
if echo "$command" | grep -Eq '\b(bundle exec )?fastlane\b|\bnpx fastlane\b'; then
  is_store_push=true
fi

if [[ "$is_push_to_main" == true || "$is_eas_cmd" == true || "$is_web_deploy" == true || "$is_domain_attach" == true || "$is_store_push" == true ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Confirm before continuing: push to main, EAS build/submit/update / expo prebuild, Cloudflare Pages deploy (web:deploy / wrangler pages deploy), custom-domain attach (attach-domain / wrangler pages domain / Cloudflare DNS or Pages domains API), or store:push / fastlane. EAS builds, lander deploys, public DNS changes, and store submissions cost money or are irreversible."}}
JSON
  exit 0
fi

exit 0
