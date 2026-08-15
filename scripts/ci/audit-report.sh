#!/usr/bin/env bash
# CI: print npm audit as a report. Never `npm audit fix --force`.
# Exit 0 so a vulnerability list cannot block merge — humans read the log.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

printf '%s\n' "audit-report: npm audit (report only; not a gate)"
npm audit || true
exit 0
