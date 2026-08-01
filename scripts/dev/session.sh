#!/usr/bin/env bash
#
# scripts/dev/session.sh — one-command session up / down / status.
# No Docker / no backend — this template is local-first.
#
# Usage:
#   npm run session:up
#   npm run session:up -- --no-sim
#   npm run session:down              # Metro, iOS sim, Android emulator, Gradle
#   npm run session:down -- --watch   # same, then re-kill for ~20s if something
#                                     # (Cursor agent shells, nohup) relaunches
#   npm run session:down -- --watch=30
#   npm run session:down -- --deep    # alias for --watch (compat)
#   npm run session:status
#
# session:down does NOT killall node or unrelated Java — only known
# Expo/sim/emu/Gradle/adb patterns.
#
# Environment facts (non-interactive shells lack ~/.zshrc):
#   ANDROID_HOME defaults to the Homebrew commandlinetools path used here.
#   JAVA_HOME defaults to Temurin 17.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/lib/ensure-ios-sim.sh
source "$ROOT/scripts/lib/ensure-ios-sim.sh"

export ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export JAVA_HOME="${JAVA_HOME:-/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else GREEN=""; YELLOW=""; RED=""; BOLD=""; DIM=""; RESET=""; fi

ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; }

usage() {
  sed -n '2,20p' "$0"
}

# Metro/Expo — never blanket killall node.
METRO_PGREP_PAT='expo start|expo/AppEntry|node_modules/\.bin/expo|metro.*808[0-9]'

# Android emulator for this template's AVD (and qemu it spawns).
EMU_PGREP_PAT='emulator -avd pixel8|qemu-system-.* -avd pixel8|android-commandlinetools/emulator/qemu'

# Shells that agents leave behind which *relaunch* Metro/emulator after we kill them.
# Narrow on purpose — do not match arbitrary Cursor/agent work.
RELAUNCH_PGREP_PAT='nohup emulator -avd pixel8|nohup npm run dev -w mobile|npm run dev -w mobile -- --port 808[0-9]|expo start -c --port 808[0-9]|emulator -avd pixel8 >>'

# Gradle / Kotlin daemons left by Android builds.
GRADLE_PGREP_PAT='GradleDaemon|KotlinCompileDaemon'

metro_pids() {
  pgrep -f "$METRO_PGREP_PAT" 2>/dev/null || true
}

list_metro() {
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

adb_devices() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices 2>/dev/null | awk 'NR>1 && $2!="" {print}' || true
}

emu_pids() {
  pgrep -f "$EMU_PGREP_PAT" 2>/dev/null || true
}

gradle_pids() {
  pgrep -f "$GRADLE_PGREP_PAT" 2>/dev/null || true
}

relaunch_pids() {
  pgrep -f "$RELAUNCH_PGREP_PAT" 2>/dev/null || true
}

# Kill a whitespace-separated pid list; returns how many TERM signals were sent.
kill_pid_list() {
  local signal="${1:-TERM}"
  shift
  local count=0 pid
  for pid in "$@"; do
    [[ -n "$pid" ]] || continue
    kill "-$signal" "$pid" 2>/dev/null || true
    count=$((count + 1))
  done
  printf '%s' "$count"
}

stop_metro() {
  local pids killed=0
  pids="$(metro_pids)"
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    killed="$(kill_pid_list TERM $pids)"
    sleep 1
  fi
  # Ports that Expo/Metro commonly hold even if pgrep missed the parent.
  local port pids_on_port
  for port in 8081 8082 8083; do
    pids_on_port="$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true)"
    if [[ -n "$pids_on_port" ]]; then
      # shellcheck disable=SC2086
      kill_pid_list KILL $pids_on_port >/dev/null
    fi
  done
  pids="$(metro_pids)"
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    kill_pid_list KILL $pids >/dev/null
  fi
  printf '%s' "$killed"
}

stop_ios() {
  local before after
  before="$(count_booted_sims)"
  if [[ "$(uname -s)" != "Darwin" ]] || ! command -v xcrun >/dev/null 2>&1; then
    warn "simctl unavailable — skipped iOS Simulator"
    printf '0'
    return 0
  fi
  xcrun simctl shutdown all >/dev/null 2>&1 || true
  osascript -e 'quit app "Simulator"' >/dev/null 2>&1 || true
  sleep 1
  after="$(count_booted_sims)"
  if [[ "$after" -gt 0 ]]; then
    bad "still $after booted simulator(s)"
    booted_sims | sed 's/^/    /'
  fi
  printf '%s' "$before"
}

stop_android_emulator() {
  local before=0
  if command -v adb >/dev/null 2>&1; then
    before="$(adb devices 2>/dev/null | grep -c 'emulator-' || true)"
    # Graceful per-emulator kill when any are listed.
    local serial
    while read -r serial _; do
      [[ "$serial" == emulator-* ]] || continue
      adb -s "$serial" emu kill >/dev/null 2>&1 || true
    done < <(adb devices 2>/dev/null | awk 'NR>1 && $1 ~ /^emulator-/ {print}')
  fi
  local pids
  pids="$(emu_pids)"
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    kill_pid_list TERM $pids >/dev/null
    sleep 1
    pids="$(emu_pids)"
    # shellcheck disable=SC2086
    [[ -n "$pids" ]] && kill_pid_list KILL $pids >/dev/null
  fi
  # crashpad / netsimd children sometimes linger
  pkill -KILL -f 'android-commandlinetools/emulator/(crashpad_handler|netsimd)' 2>/dev/null || true
  if command -v adb >/dev/null 2>&1; then
    adb kill-server >/dev/null 2>&1 || true
  fi
  printf '%s' "${before:-0}"
}

stop_gradle() {
  local killed=0
  if [[ -x "$ROOT/apps/mobile/android/gradlew" ]]; then
    (cd "$ROOT/apps/mobile/android" && ./gradlew --stop) >/dev/null 2>&1 || true
  fi
  local pids
  pids="$(gradle_pids)"
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    killed="$(kill_pid_list TERM $pids)"
    sleep 1
    pids="$(gradle_pids)"
    # shellcheck disable=SC2086
    [[ -n "$pids" ]] && kill_pid_list KILL $pids >/dev/null
  fi
  printf '%s' "$killed"
}

# Agent / nohup shells that re-run `emulator -avd pixel8` or Metro after we stop them.
stop_relaunchers() {
  local pids killed=0
  pids="$(relaunch_pids)"
  if [[ -n "$pids" ]]; then
    # shellcheck disable=SC2086
    killed="$(kill_pid_list KILL $pids)"
  fi
  printf '%s' "$killed"
}

anything_still_up() {
  [[ -n "$(metro_pids)" ]] && return 0
  [[ -n "$(emu_pids)" ]] && return 0
  [[ -n "$(gradle_pids)" ]] && return 0
  [[ "$(count_booted_sims)" -gt 0 ]] && return 0
  local port
  for port in 8081 8082 8083; do
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 0
  done
  return 1
}

teardown_once() {
  local relaunchers metro_killed sims_before emu_before gradle_killed
  relaunchers="$(stop_relaunchers)"
  sims_before="$(stop_ios)"
  metro_killed="$(stop_metro)"
  emu_before="$(stop_android_emulator)"
  gradle_killed="$(stop_gradle)"
  # Second pass on relaunchers — they sometimes spawn *during* the kills above.
  local more
  more="$(stop_relaunchers)"
  relaunchers=$((relaunchers + more))

  printf '%s %s %s %s %s' "$relaunchers" "$sims_before" "$metro_killed" "$emu_before" "$gradle_killed"
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

cmd_down() {
  local watch=0
  local watch_secs=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deep)
        # Compat: old flag meant "extra thorough". Now aliases --watch.
        watch=1
        shift
        ;;
      --watch)
        watch=1
        shift
        ;;
      --watch=*)
        watch=1
        watch_secs="${1#--watch=}"
        shift
        ;;
      -h|--help) usage; exit 0 ;;
      *)
        printf 'Unknown arg: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done

  printf '%ssession down%s\n' "$BOLD" "$RESET"

  local counts relaunchers sims_before metro_killed emu_before gradle_killed
  counts="$(teardown_once)"
  # shellcheck disable=SC2086
  set -- $counts
  relaunchers=$1; sims_before=$2; metro_killed=$3; emu_before=$4; gradle_killed=$5

  if [[ "$sims_before" -gt 0 ]]; then
    ok "iOS Simulator: shut down (was $sims_before booted)"
  else
    ok "iOS Simulator: none were booted"
  fi

  if [[ "$metro_killed" -gt 0 ]]; then
    ok "Metro/Expo: killed $metro_killed process(es)"
  else
    ok "Metro/Expo: none were running"
  fi

  if [[ "$emu_before" -gt 0 ]]; then
    ok "Android emulator: stopped (was $emu_before device(s))"
  else
    ok "Android emulator: none were attached"
  fi

  if [[ "$gradle_killed" -gt 0 ]]; then
    ok "Gradle daemons: stopped $gradle_killed"
  else
    ok "Gradle daemons: none were running"
  fi

  if [[ "$relaunchers" -gt 0 ]]; then
    ok "Relauncher shells: killed $relaunchers (agent/nohup Metro or emulator)"
  else
    ok "Relauncher shells: none matched"
  fi

  if [[ "$watch" -eq 1 ]]; then
    printf '\n%swatching %ss for respawns…%s\n' "$DIM" "$watch_secs" "$RESET"
    local end now
    end=$((SECONDS + watch_secs))
    while (( SECONDS < end )); do
      if anything_still_up || [[ -n "$(relaunch_pids)" ]]; then
        warn "respawn detected — killing again"
        teardown_once >/dev/null
      fi
      sleep 2
    done
  fi

  printf '\n%sfinal status%s\n' "$BOLD" "$RESET"
  if anything_still_up; then
    bad "something is still up — run: npm run session:status"
    cmd_status
    exit 1
  fi
  ok "all clear (Metro, iOS sim, Android emu, Gradle)"
  if command -v adb >/dev/null 2>&1; then
    local left
    left="$(adb_devices)"
    if [[ -n "$left" ]]; then
      warn "adb still lists:"
      printf '%s\n' "$left" | sed 's/^/    /'
      warn "run: adb kill-server"
    else
      ok "adb devices: empty"
    fi
  fi
}

cmd_status() {
  printf '%ssession status%s\n' "$BOLD" "$RESET"

  ok "backend: none (local-first template)"

  if [[ "$(uname -s)" == "Darwin" ]] && command -v xcrun >/dev/null 2>&1; then
    local n
    n="$(count_booted_sims)"
    if [[ "$n" -gt 0 ]]; then
      ok "Booted iOS simulators: $n"
      booted_sims | sed 's/^/    /'
    else
      ok "Booted iOS simulators: 0"
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

  local emu
  emu="$(emu_pids)"
  if [[ -n "$emu" ]]; then
    ok "Android emulator processes:"
    pgrep -fl "$EMU_PGREP_PAT" 2>/dev/null | sed 's/^/    /' || true
  else
    ok "Android emulator processes: none"
  fi

  if command -v adb >/dev/null 2>&1; then
    local devices
    devices="$(adb_devices)"
    if [[ -n "$devices" ]]; then
      ok "adb devices:"
      printf '%s\n' "$devices" | sed 's/^/    /'
    else
      ok "adb devices: empty"
    fi
  else
    warn "adb not on PATH (set ANDROID_HOME)"
  fi

  local gradle
  gradle="$(gradle_pids)"
  if [[ -n "$gradle" ]]; then
    ok "Gradle/Kotlin daemons:"
    pgrep -fl "$GRADLE_PGREP_PAT" 2>/dev/null | sed 's/^/    /' || true
  else
    ok "Gradle/Kotlin daemons: none"
  fi

  local relaunch
  relaunch="$(relaunch_pids)"
  if [[ -n "$relaunch" ]]; then
    warn "Possible relauncher shells still alive:"
    pgrep -fl "$RELAUNCH_PGREP_PAT" 2>/dev/null | sed 's/^/    /' || true
    warn "Run: npm run session:down -- --watch"
  else
    ok "Relauncher shells: none matched"
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
