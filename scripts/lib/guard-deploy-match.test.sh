#!/usr/bin/env bash
# scripts/lib/guard-deploy-match.test.sh — table-driven checks for
# guard_should_ask. Sourced matcher only; adapters are two optional smokes.
#
# Usage:
#   npm run guard-check
#   bash scripts/lib/guard-deploy-match.test.sh
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-deploy-match.sh
source "$ROOT/scripts/lib/guard-deploy-match.sh"

FAIL=0
PASS=0

check_row() {
  local expect="$1"
  local cmd="$2"
  local got
  if guard_should_ask "$cmd"; then
    got=ask
  else
    got=allow
  fi
  if [[ "$got" == "$expect" ]]; then
    PASS=$((PASS + 1))
    printf 'ok    %-5s  %s\n' "$got" "$cmd"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  %-5s  %s  (expected %s)\n' "$got" "$cmd" "$expect"
  fi
}

echo "=== must ask ==="
while IFS=$'\t' read -r expect cmd; do
  [[ -z "${expect:-}" || "$expect" == \#* ]] && continue
  check_row "$expect" "$cmd"
done <<'ROWS'
ask	npm install lodash
ask	npm i lodash
ask	npm add lodash
ask	npm install --save-dev lodash
ask	npm install -D lodash
ask	yarn add x
ask	pnpm add x
ask	bun add x
ask	npx expo install expo-camera
ask	cd apps/mobile && npm install lodash
ask	sudo npm install -g x
ask	./node_modules/.bin/npm add x
ask	NODE_ENV=production npm install x
ask	CI=true npm i lodash
ask	FOO=1 BAR=2 yarn add x
ask	CI=true npx expo install expo-camera
ask	CI=true sudo npm install -g x
ask	PATH=/usr/local/bin npm install x
ask	npm_config_registry=https://r.io npm i x
ask	CI=true ./node_modules/.bin/npm add x
ask	npm install x; echo done
ask	cat foo | npm install x
ask	echo "npm install x" && npm install y
ask	FOO="a b" npm install x
ask	FOO='a b' npm install x
ROWS

echo "=== must NOT ask ==="
while IFS=$'\t' read -r expect cmd; do
  [[ -z "${expect:-}" || "$expect" == \#* ]] && continue
  check_row "$expect" "$cmd"
done <<'ROWS'
allow	echo npm install lodash
allow	echo 'run yarn add x first'
allow	git commit -m 'npm install lodash'
allow	echo NODE_ENV=production npm install x
allow	git commit -m "CI=true npm install x"
allow	echo "FOO=a npm install x"
allow	echo FOO="a b" npm install x
allow	npm install
allow	npm ci
allow	npm add
allow	npm install --production
allow	NODE_ENV=production npm install
allow	NODE_ENV=production npm ci
allow	NODE_ENV=production npm run check
allow	npm run add-thing
allow	npm run check
allow	bun run dev
allow	FOO=bar echo hi
allow	grep -r 'yarn add' docs/
allow	printf 'npm install lodash'
ROWS

echo "=== other guards ==="
while IFS=$'\t' read -r expect cmd; do
  [[ -z "${expect:-}" || "$expect" == \#* ]] && continue
  check_row "$expect" "$cmd"
done <<'ROWS'
ask	npx eas build --platform ios
ask	eas submit --platform android
ask	npx expo prebuild
ask	git push origin main
ask	git  push origin main
ask	npx eas-cli build --platform ios
ask	npm run session:down
ask	git config core.hooksPath /dev/null
ask	rm .githooks/pre-commit
ask	npm run web:deploy
ask	npm run store:push
ask	bundle exec fastlane deliver
allow	echo git push origin main
allow	echo npm run session:down
allow	git commit -m wip
allow	git status
allow	npm run check
ROWS

echo "=== adapter smoke ==="
if ! command -v jq >/dev/null 2>&1; then
  echo "skip  adapter smoke (jq not found)"
else
  smoke_cmd='npm install lodash'
  cursor_out=$(jq -nc --arg c "$smoke_cmd" '{command:$c}' | bash "$ROOT/.cursor/hooks/guard-shell.sh")
  claude_out=$(jq -nc --arg c "$smoke_cmd" '{tool_input:{command:$c}}' | bash "$ROOT/.claude/hooks/guard-deploy.sh")
  cursor_perm=$(echo "$cursor_out" | jq -er '.permission')
  claude_perm=$(echo "$claude_out" | jq -er '.hookSpecificOutput.permissionDecision')
  if echo "$cursor_out" | jq -e . >/dev/null && [[ "$cursor_perm" == ask ]]; then
    PASS=$((PASS + 1))
    printf 'ok    %-5s  cursor adapter  %s\n' "$cursor_perm" "$smoke_cmd"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  cursor adapter  got %s  (expected ask, valid JSON)\n' "${cursor_perm:-invalid}"
  fi
  if echo "$claude_out" | jq -e . >/dev/null && [[ "$claude_perm" == ask ]]; then
    PASS=$((PASS + 1))
    printf 'ok    %-5s  claude adapter  %s\n' "$claude_perm" "$smoke_cmd"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  claude adapter  got %s  (expected ask, valid JSON)\n' "${claude_perm:-invalid}"
  fi
fi

echo
if [[ "$FAIL" -gt 0 ]]; then
  echo "guard-deploy-match: $PASS passed, $FAIL failed"
  exit 1
fi
echo "guard-deploy-match: $PASS passed, 0 failed"
exit 0
