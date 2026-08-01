# shellcheck shell=bash
# scripts/dev/maestro-hygiene.sh — shared Maestro temp-dir + CWD-leak scrub.
# Sourced by screenshots.sh and test-e2e.sh. Keeps failure dumps out of ~ and
# the repo root (they otherwise land next to whatever the agent CWD was).
#
# Usage (from a script that has already cd'd to repo root):
#   # shellcheck source=scripts/dev/maestro-hygiene.sh
#   source "$ROOT/scripts/dev/maestro-hygiene.sh"
#   DEBUG="$(maestro_debug_dir "$ROOT")"
#   maestro … || rc=$?
#   maestro_scrub_leaks "$ROOT"

maestro_debug_dir() {
  local root="$1"
  mkdir -p "${root}/.maestro-debug"
  printf '%s\n' "${root}/.maestro-debug"
}

# Remove Maestro failure dumps that sometimes land in CWD despite --test-output-dir.
maestro_scrub_leaks() {
  local dir="${1:-.}"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -type f \( \
    -name 'commands-(maestro-*.json' \
    -o -name 'screenshot-*-*(maestro-*.png' \
    -o -name 'xctest_runner_*.log' \
    -o -name 'maestro.log' \
  \) -delete 2>/dev/null || true
}
