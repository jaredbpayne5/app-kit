#!/usr/bin/env bash
# scripts/lib/guard-sensitive-paths.sh — classify a repo-relative path or a
# bash command. Adapters own JSON / permission I/O.
#
# Usage:
#   # shellcheck source=scripts/lib/guard-sensitive-paths.sh
#   source "$ROOT/scripts/lib/guard-sensitive-paths.sh"
#   guard_rel_path "$path" "$ROOT"          # prints repo-relative path
#   guard_path_class "$rel"                 # deny-secret | ask-identity | allow
#   guard_is_protected "$rel"               # 0 if agents must not edit this file
#   guard_is_init_app "$command"            # 0 if this is init-app
#   guard_command_class "$command"          # deny-secret | ask-identity | allow
#
# Returns via stdout (classifiers) or exit status (init-app / protected).

guard_rel_path() {
  local path="$1"
  local root="$2"
  path="${path#file://}"
  if [[ -n "$root" && "$path" == "$root/"* ]]; then
    path="${path#"$root"/}"
  fi
  printf '%s' "$path"
}

guard_path_class() {
  local rel="$1"
  case "$rel" in
    *.p8 | *.keystore | *.jks) printf 'deny-secret'; return ;;
  esac
  case "$rel" in
    *service-account*.json | */credentials.json | credentials.json)
      printf 'deny-secret'
      return
      ;;
  esac
  case "$rel" in
    .env | .env.local | .env.* | */.env | */.env.local | */.env.*)
      printf 'ask-identity'
      return
      ;;
  esac
  case "$rel" in
    */app.json | app.json | */eas.json | eas.json | *data-practices.json)
      printf 'ask-identity'
      return
      ;;
  esac
  case "$rel" in
    apps/mobile/ios | apps/mobile/ios/* | apps/mobile/android | apps/mobile/android/*)
      printf 'ask-identity'
      return
      ;;
  esac
  printf 'allow'
}

# Factory net: hooks, shared matchers, eslint, githooks, CI.
# Keep in sync with .claude/settings.json permissions.deny.
guard_is_protected() {
  local rel="$1"
  case "$rel" in
    .claude/hooks/* | */.claude/hooks/*) return 0 ;;
    .claude/settings.json | */.claude/settings.json) return 0 ;;
    .cursor/hooks/* | */.cursor/hooks/*) return 0 ;;
    .cursor/hooks.json | */.cursor/hooks.json) return 0 ;;
    .githooks/* | */.githooks/*) return 0 ;;
    eslint.config.js | */eslint.config.js) return 0 ;;
    .github/workflows/ci.yml | */.github/workflows/ci.yml) return 0 ;;
    scripts/lib/guard-*.sh | */scripts/lib/guard-*.sh) return 0 ;;
    scripts/lib/fail-proof-checks.test.sh | */scripts/lib/fail-proof-checks.test.sh) return 0 ;;
    scripts/dev/receipt.sh | */scripts/dev/receipt.sh) return 0 ;;
    .run/receipts/* | */.run/receipts/*) return 0 ;;
  esac
  return 1
}

# Speed bump for common write shapes (rm, redirect, tee, cp, mv) onto a
# protected path — not a security boundary. Does not cover sed, python,
# chmod, or every bash -c wrapper.
guard_command_writes_protected() {
  local command="$1"
  local pat='(\.claude/hooks/|\.claude/settings\.json|\.cursor/hooks|\.githooks/|eslint\.config\.js|\.github/workflows/ci\.yml|scripts/lib/guard-|scripts/lib/fail-proof-checks\.test\.sh|scripts/dev/receipt\.sh|\.run/receipts/)'
  if echo "$command" | grep -Eqe "\\brm\\b[^;&|]*${pat}"; then
    return 0
  fi
  if echo "$command" | grep -Eqe "(>|>>|[[:space:]]tee[[:space:]]|\\b(cp|mv)\\b)[^;&|]*${pat}"; then
    return 0
  fi
  return 1
}

guard_is_init_app() {
  local command="$1"
  echo "$command" | grep -Eqe '(^|[;&|]) *(npm run )?init-app\b|scripts/factory/init-app\.sh'
}

guard_command_class() {
  local command="$1"
  if echo "$command" | grep -Eqe '\.p8\b|\.keystore\b|\.jks\b|service-account|credentials\.json'; then
    printf 'deny-secret'
    return
  fi
  if echo "$command" | grep -Eqe '\.env\b|eas\.json|app\.json|data-practices\.json|apps/mobile/ios|apps/mobile/android'; then
    printf 'ask-identity'
    return
  fi
  printf 'allow'
}
