#!/usr/bin/env bash
#
# scripts/dev/session.sh — one-command session up / down / status (sims + Metro only).
# No Docker / no backend — this template is local-first.
#
# Usage:
#   npm run session:up
#   npm run session:up -- --no-sim
#   npm run session:down          # stop all sims + all Metro
#   npm run session:down -- --deep  # same as down (kept for CLI compatibility)
#   npm run session:status
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/lib/ensure-ios-sim.sh
source "$ROOT/scripts/lib/ensure-ios-sim.sh"

if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else GREEN=""; YELLOW=""; RED=""; BOLD=""; DIM=""; RESET=""; fi

ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; }

usage() {
  sed -n '2,14p' "$0"
}

# Metro/Expo process signature — never blanket killall node.
METRO_PGREP_PAT='expo start|expo/AppEntry|metro'

metro_pids() {
  pgrep -f "$METRO_PGREP_PAT" 2>/dev/null || true
}

list_metro() {
  # shellcheck disable=SC2009
  pgrep -fl "$METRO_PGREP_PAT" 2>/dev/null || true
}

listening_metro_ports() {
  local port
  for port in 8081 8082 8083 19000 19001 19002; do
    if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      local pids
      pids="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
      printf '  port %s  pid=%s\n' "$port" "${pids:-?}"
    fi
  done
}

booted_sims() {
  xcrun simctl list devices booted 2>/dev/null | grep '(Booted)' || true
}

count_booted_sims() {
  local n
  n="$(booted_sims | grep -c '(Booted)' || true)"
  printf '%s' "${n:-0}"
}

cmd_up() {
  local no_sim=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-sim) no_sim=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *)
        printf 'Unknown arg: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  printf '%ssession up%s\n' "$BOLD" "$RESET"
  if [[ "$no_sim" -eq 0 ]]; then
    ensure_ios_sim || exit 1
  else
    warn "skipped iOS Simulator (--no-sim)"
  fi

  printf '\n%ssummary%s\n' "$BOLD" "$RESET"
  ok "backend: none (local-first template)"

  if [[ "$no_sim" -eq 0 ]]; then
    local n
    n="$(count_booted_sims)"
    if [[ "$n" -gt 0 ]]; then
      ok "Simulator booted ($n):"
      booted_sims | sed 's/^/    /'
    else
      bad "No booted simulator"
    fi
  fi
}

kill_all_metro() {
  local pids
  pids="$(metro_pids)"
  if [[ -z "$pids" ]]; then
    printf '0'
    return 0
  fi
  local count=0
  local pid
  for pid in $pids; do
    kill -TERM "$pid" 2>/dev/null || true
    count=$((count + 1))
  done
  sleep 2
  pids="$(metro_pids)"
  for pid in $pids; do
    kill -KILL "$pid" 2>/dev/null || true
  done
  sleep 1
  printf '%s' "$count"
}

cmd_down() {
  local deep=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deep) deep=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *)
        printf 'Unknown arg: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  printf '%ssession down%s%s\n' "$BOLD" "$RESET" "$([[ "$deep" -eq 1 ]] && printf ' (--deep)' || true)"

  local sims_before
  sims_before="$(count_booted_sims)"
  if [[ "$(uname -s)" == "Darwin" ]] && command -v xcrun >/dev/null 2>&1; then
    xcrun simctl shutdown all >/dev/null 2>&1 || true
    osascript -e 'quit app "Simulator"' >/dev/null 2>&1 || true
    sleep 1
    local sims_after
    sims_after="$(count_booted_sims)"
    if [[ "$sims_before" -gt 0 ]]; then
      ok "shut down simulators (was $sims_before booted → $sims_after)"
    else
      ok "no simulators were booted"
    fi
    if [[ "$sims_after" -gt 0 ]]; then
      bad "still $sims_after booted simulator(s) after shutdown all"
      booted_sims | sed 's/^/    /'
    fi
  else
    warn "simctl unavailable — skipped simulator shutdown"
  fi

  local killed
  killed="$(kill_all_metro)"
  local remain
  remain="$(metro_pids)"
  if [[ -n "$remain" ]]; then
    bad "Metro/Expo still running after kill: $remain"
    list_metro | sed 's/^/    /'
  elif [[ "$killed" -gt 0 ]]; then
    ok "killed $killed Metro/Expo process(es)"
  else
    ok "no Metro/Expo processes were running"
  fi

  if [[ "$deep" -eq 1 ]]; then
    ok "--deep: no Docker in this template (noop)"
  fi

  printf '\n%sdone%s  metro_killed=%s  deep=%s\n' \
    "$DIM" "$RESET" "$killed" "$deep"
}

cmd_status() {
  printf '%ssession status%s\n' "$BOLD" "$RESET"

  ok "backend: none (local-first template)"

  if [[ "$(uname -s)" == "Darwin" ]] && command -v xcrun >/dev/null 2>&1; then
    local n
    n="$(count_booted_sims)"
    if [[ "$n" -gt 0 ]]; then
      ok "Booted simulators: $n"
      booted_sims | sed 's/^/    /'
    else
      ok "Booted simulators: 0"
    fi
  else
    warn "simctl unavailable"
  fi

  local metro
  metro="$(list_metro)"
  if [[ -n "$metro" ]]; then
    ok "Metro/Expo processes:"
    printf '%s\n' "$metro" | sed 's/^/    /'
    printf '  %slistening ports:%s\n' "$DIM" "$RESET"
    listening_metro_ports
  else
    ok "Metro/Expo processes: none"
  fi
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    up) cmd_up "$@" ;;
    down) cmd_down "$@" ;;
    status) cmd_status "$@" ;;
    -h|--help|"") usage; [[ -n "$cmd" ]] || exit 2; exit 0 ;;
    *)
      printf 'Unknown subcommand: %s (use up|down|status)\n' "$cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
