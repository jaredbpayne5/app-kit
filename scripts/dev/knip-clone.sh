#!/usr/bin/env bash
# knip:clone — unused-code report for a product clone.
# Refuses to run while docs/PRD.md still has the template sentinel
# (naive knip on this factory would flag inventory as dead).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

if grep -q 'TEMPLATE_PLACEHOLDER' "$ROOT/docs/PRD.md"; then
  printf '%s\n' "knip:clone: docs/PRD.md still has <!-- TEMPLATE_PLACEHOLDER -->."
  printf '%s\n' "Fill the PRD first. Template inventory is ignored on purpose — see docs/CAPABILITIES.md."
  exit 1
fi

npx knip "$@"
