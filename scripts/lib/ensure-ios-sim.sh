#!/usr/bin/env bash
# scripts/lib/ensure-ios-sim.sh — sourceable helper to boot an iOS Simulator if needed.
#
# Usage (from another script):
#   # shellcheck source=scripts/lib/ensure-ios-sim.sh
#   source "$ROOT/scripts/lib/ensure-ios-sim.sh"
#   ensure_ios_sim || exit 1
#
# Behavior:
#   1. Already-booted simulator → return 0 silently.
#   2. Else pick newest iOS runtime + highest-end available iPhone (jq over simctl JSON).
#   3. boot + open Simulator.app + bootstatus -b.
#   4. 120s timeout → return 1. Never creates or erases devices.
#
# Requires: macOS, xcrun simctl, jq.
#

# bootstatus -b blocks until booted; bound the wait. Silence status spam.
wait_for_boot() {
  local udid="$1"
  local secs="${2:-120}"
  perl -e '
    my $secs = shift; my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
      open STDOUT, ">", "/dev/null";
      open STDERR, ">", "/dev/null";
      exec @ARGV; exit 127
    }
    local $SIG{ALRM} = sub { kill "TERM", $pid; sleep 1; kill "KILL", $pid; exit 1 };
    alarm $secs;
    waitpid($pid, 0);
    exit($? == 0 ? 0 : 1);
  ' "$secs" xcrun simctl bootstatus "$udid" -b
}

ensure_ios_sim() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'ensure_ios_sim: requires macOS (uname=%s)\n' "$(uname -s)" >&2
    return 1
  fi
  if ! command -v xcrun >/dev/null 2>&1 || ! xcrun simctl help >/dev/null 2>&1; then
    printf 'ensure_ios_sim: xcrun simctl unavailable — install Xcode / Simulator\n' >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    printf 'ensure_ios_sim: jq missing — brew install jq\n' >&2
    return 1
  fi

  local booted
  booted="$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || true)"
  if [[ "${booted:-0}" -gt 0 ]]; then
    return 0
  fi

  local picked name udid
  picked="$(
    xcrun simctl list devices available -j 2>/dev/null | jq -r '
      def gen: (.name | capture("iPhone (?<n>[0-9]+)"; "i") | .n | tonumber) // 0;
      def tier:
        if (.name | test("Pro Max")) then 400
        elif (.name | test("Pro")) then 300
        elif (.name | test("Plus|Air")) then 200
        elif (.name | test("SE|mini")) then 50
        else 100 end;
      def score: tier + gen;
      .devices
      | to_entries
      | map(select(.key | test("SimRuntime\\.iOS-")))
      | map(
          . as $e
          | ($e.key | capture("iOS-(?<maj>[0-9]+)-(?<min>[0-9]+)")) as $v
          | {
              runtime: $e.key,
              maj: ($v.maj | tonumber),
              min: ($v.min | tonumber),
              devices: $e.value
            }
        )
      | map(select(.devices | length > 0))
      | sort_by(.maj, .min)
      | last
      | .devices
      | map(select(.name | startswith("iPhone")))
      | if length == 0 then empty else . end
      | sort_by(score)
      | last
      | "\(.udid)\t\(.name)"
    '
  )"

  if [[ -z "${picked}" ]]; then
    printf 'ensure_ios_sim: no available iPhone simulator found (will not create devices)\n' >&2
    return 1
  fi

  udid="${picked%%$'\t'*}"
  name="${picked#*$'\t'}"

  printf 'Booting iOS Simulator (%s)…\n' "$name" >&2
  if ! xcrun simctl boot "$udid" >/dev/null 2>&1; then
    # Already booting / race — continue to bootstatus.
    true
  fi
  open -a Simulator >/dev/null 2>&1 || true

  if ! wait_for_boot "$udid" 120; then
    printf 'ensure_ios_sim: timed out after 120s waiting for %s (%s) to boot\n' "$name" "$udid" >&2
    return 1
  fi

  return 0
}
