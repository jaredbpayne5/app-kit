#!/usr/bin/env bash
# Forces an explicit pause before an agent writes to env/secrets files,
# eas submit track, app identity, or data-practices.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "jq is required for Claude hooks but is not installed. Install jq (e.g. brew install jq) then retry."}}
JSON
  exit 0
fi

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

if [[ "$file_path" == *.env* ]] \
  || [[ "$file_path" == *"service-account"* ]] \
  || [[ "$file_path" == *.keystore ]] \
  || [[ "$file_path" == *.jks ]] \
  || [[ "$file_path" == *credentials.json ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "This touches an env/secrets/signing file. CLAUDE.md requires explicit sign-off — confirm this is intentional."}}
JSON
  exit 0
fi

if [[ "$file_path" == *"/eas.json" ]] || [[ "$file_path" == *"eas.json" ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Editing eas.json can change build profiles or Play submit track. Confirm before continuing."}}
JSON
  exit 0
fi

if [[ "$file_path" == *"/app.json" ]] || [[ "$file_path" == *"app.json" ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "Editing app.json can change android.package / version identity. Changing package after first Play upload breaks the listing — confirm this is intentional."}}
JSON
  exit 0
fi

if [[ "$file_path" == *"data-practices.json" ]]; then
  cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "data-practices.json drives your App Store and Play privacy declarations — confirm this edit is intentional, then re-run npm run gen-compliance."}}
JSON
  exit 0
fi

exit 0
