#!/usr/bin/env bash
# Cursor beforeReadFile + preToolUse: deny keystores, .p8, service-account JSON.
# jq missing is fail-closed — this is secret detection. afterFileEdit cannot reject.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  cat <<'JSON'
{"permission":"deny","user_message":"jq is required to scan for secret-file paths. Install jq (e.g. brew install jq) then retry.","agent_message":"jq is required for the secret-file hook but is not installed."}
JSON
  exit 0
fi

input=$(cat)
path=$(echo "$input" | jq -r '
  .tool_input.file_path
  // .tool_input.path
  // .file_path
  // .path
  // empty
')

if [[ -z "$path" ]]; then
  echo '{"permission":"allow"}'
  exit 0
fi

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=scripts/lib/guard-sensitive-paths.sh
source "$ROOT/scripts/lib/guard-sensitive-paths.sh"

rel="$(guard_rel_path "$path" "$ROOT")"
if [[ "$(guard_path_class "$rel")" == deny-secret ]]; then
  cat <<'JSON'
{"permission":"deny","user_message":"This path looks like a signing key or cloud service-account file. Reading or writing it is denied. Handle it yourself outside the agent.","agent_message":"Denied: keystore, .p8, or service-account path."}
JSON
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
