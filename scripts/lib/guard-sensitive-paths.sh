#!/usr/bin/env bash
# scripts/lib/guard-sensitive-paths.sh — classify a repo-relative path or a
# bash command. Adapters own JSON / permission I/O.
#
# Usage:
#   # shellcheck source=scripts/lib/guard-sensitive-paths.sh
#   source "$ROOT/scripts/lib/guard-sensitive-paths.sh"
#   guard_rel_path "$path" "$ROOT"          # prints repo-relative path
#   guard_path_class "$rel"                 # deny-secret | ask-identity | allow
#   guard_is_init_app "$command"            # 0 if this is init-app
#   guard_command_class "$command"          # deny-secret | ask-identity | allow
#
# Returns via stdout (classifiers) or exit status (init-app).

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
    *service-account*.json | *service-account.json | */credentials.json | credentials.json)
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
