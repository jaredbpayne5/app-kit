#!/usr/bin/env bash
# scripts/lib/guard-deploy-match.sh — sourceable matcher for deploy / spend /
# dependency-add commands. Adapters own all I/O.
#
# This is a speed bump against an aligned agent's mistakes, not a security
# boundary. It does not catch every wrapper (for example `bash -c`).
#
# Usage (from another script):
#   # shellcheck source=scripts/lib/guard-deploy-match.sh
#   source "$ROOT/scripts/lib/guard-deploy-match.sh"
#   if guard_should_ask "$command"; then
#     # emit ask
#   fi
#
# Returns 0 if the command must be confirmed, 1 otherwise.
# No JSON, no stdin, no stdout.
#
# Detection for push-to-main, EAS/prebuild, web:deploy/wrangler, domain-attach,
# and store:push/fastlane is the logic previously inline in
# .claude/hooks/guard-deploy.sh. Dependency-add cases (F3) are added here.

guard_should_ask() {
  local command="$1"
  local is_push_to_main=false
  local is_eas_cmd=false
  local is_web_deploy=false
  local is_domain_attach=false
  local is_store_push=false
  local is_dep_add=false
  local is_session_down=false
  local is_hooks_bypass=false
  local current_branch

  if echo "$command" | grep -Eq '(^|[;&|]) *git[[:space:]]+push'; then
    if echo "$command" | grep -Eq '\bmain\b'; then
      is_push_to_main=true
    else
      current_branch=$(git -C "${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-.}}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
      if [[ "$current_branch" == "main" ]]; then
        is_push_to_main=true
      fi
    fi
  fi

  if echo "$command" | grep -Eq '\beas(-cli)? (build|submit|update)\b|\bnpx eas-cli (build|submit|update)\b|\bnpx expo prebuild\b|\bexpo prebuild\b'; then
    is_eas_cmd=true
  fi

  if echo "$command" | grep -Eq '(^|[;&|]) *(npm run )?session:down\b|scripts/dev/session\.sh[[:space:]]+down'; then
    is_session_down=true
  fi

  if echo "$command" | grep -Eq 'git[[:space:]]+config[[:space:]].*core\.hooksPath[[:space:]]*(=|[[:space:]])[[:space:]]*/dev/null'; then
    is_hooks_bypass=true
  fi
  if echo "$command" | grep -Eq '\brm\b.*\.githooks/pre-commit'; then
    is_hooks_bypass=true
  fi

  # Cloudflare Pages lander deploy — ask (CLAUDE.md Hard Stop / web:deploy).
  # npm run web:deploy always matched; direct-bash path must be scripts/web/ (monorepo).
  if echo "$command" | grep -Eq '\b(npm run )?web:deploy\b|scripts/web/deploy-lander\.sh'; then
    is_web_deploy=true
  fi
  if echo "$command" | grep -Eq '\bwrangler pages deploy\b|\bnpx wrangler pages deploy\b'; then
    is_web_deploy=true
  fi

  # Custom domain attach — ask (mutates public DNS / Pages domains).
  # Prefer scripts/web/ path; bare attach-domain also matches npm run domain-attach.
  if echo "$command" | grep -Eq '\b(npm run )?domain-attach\b|\b(npm run )?attach-domain\b|scripts/web/attach-domain\.sh'; then
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
  if echo "$command" | grep -Eq '\b(npm run )?store:push\b|scripts/store/store-push\.sh'; then
    is_store_push=true
  fi
  if echo "$command" | grep -Eq '\b(bundle exec )?fastlane\b|\bnpx fastlane\b'; then
    is_store_push=true
  fi

  # F3 — adding a dependency (AGENTS.md Ask before). Bare `npm install` / `npm ci`
  # restore a lockfile and are not a dependency change. `npm install <pkg>` is
  # gated when at least one argument does not start with `-`.
  # Anchored like git push (`(^|[;&|]) *`) so a mention in `echo` or a commit
  # message does not ask. Zero or more `NAME=value` assignments (unquoted, or
  # double-/single-quoted so `FOO="a b" npm install x` still gates), then
  # optional `sudo`, then an optional path prefix.
  # Known limit: a quoted value containing `;` (e.g. X="; npm install y")
  # still looks like a command separator.
  local assign_val='("[^"]*"|'\''[^'\'']*'\''|[^[:space:];|&]*)'
  local dep_prefix='(^|[;&|]) *([A-Za-z_][A-Za-z0-9_]*='"$assign_val"'[[:space:]]+)*(sudo[[:space:]]+)?'
  if echo "$command" | grep -Eq "${dep_prefix}([^[:space:];|&]*/)?(yarn|pnpm|bun)[[:space:]]+add\b"; then
    is_dep_add=true
  fi
  if echo "$command" | grep -Eq "${dep_prefix}(([^[:space:];|&]*/)?npx[[:space:]]+)?([^[:space:];|&]*/)?expo[[:space:]]+install\b"; then
    is_dep_add=true
  fi
  # `npm add` is an alias for `npm install`; both need a package argument to gate.
  if echo "$command" | grep -Eq "${dep_prefix}([^[:space:];|&]*/)?npm[[:space:]]+(i|install|add)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[^[:space:];|&-]"; then
    is_dep_add=true
  fi

  if [[ "$is_push_to_main" == true || "$is_eas_cmd" == true || "$is_web_deploy" == true || "$is_domain_attach" == true || "$is_store_push" == true || "$is_dep_add" == true || "$is_session_down" == true || "$is_hooks_bypass" == true ]]; then
    return 0
  fi
  return 1
}
