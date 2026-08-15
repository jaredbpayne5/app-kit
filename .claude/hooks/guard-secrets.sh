#!/usr/bin/env bash
# Flags content that looks like a real secret outside real env files.
# .env.example is NOT exempt — placeholder files must not receive live keys.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "jq is required for Claude hooks but is not installed. Install jq (e.g. brew install jq) then retry."}}
JSON
  exit 0
fi

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
content=$(echo "$input" | jq -r '.tool_input.command // .tool_input.content // .tool_input.new_string // empty')

base="$(basename "$file_path" 2>/dev/null || true)"
# Allow real local env files only (not .env.example).
case "$base" in
  .env|.env.local)
    exit 0
    ;;
esac
# .env.development.local style
if [[ "$base" == .env.* && "$base" == *.local ]]; then
  exit 0
fi

# Private keys / AWS-style / GitHub PATs — hard deny outside env files
if echo "$content" | grep -Eqe '-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}'; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "A private key or cloud credential pattern was detected outside an env file. Blocked to avoid leaking a real secret."}}
JSON
  exit 0
fi

exit 0
