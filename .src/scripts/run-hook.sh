#!/bin/bash
# Unified hook launcher for optional Claude hook wiring.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: run-hook.sh <script-name> [args...]" >&2
  exit 1
fi

SCRIPT_NAME="$1"
shift

to_posix_path() {
  local raw_path="$1"
  [[ -n "$raw_path" ]] || {
    echo ""
    return 0
  }

  if [[ "$raw_path" =~ ^[A-Za-z]:[\\/].* ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$raw_path"
      return 0
    fi

    local drive rest drive_lower
    drive="${raw_path:0:1}"
    rest="${raw_path:2}"
    rest="${rest//\\//}"
    drive_lower="$(printf '%s' "$drive" | tr 'A-Z' 'a-z')"
    echo "/$drive_lower$rest"
    return 0
  fi

  echo "$raw_path"
}

ROOT_RAW="${PENSIEVE_SKILL_ROOT:-}"
if [[ -z "$ROOT_RAW" ]]; then
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_RAW="$(cd "$SELF_DIR/../.." && pwd)"
fi
ROOT="$(to_posix_path "$ROOT_RAW")"
TARGET="$ROOT/.src/scripts/$SCRIPT_NAME"

[[ -f "$TARGET" ]] || {
  echo "Hook target not found: $TARGET" >&2
  exit 1
}

exec bash "$TARGET" "$@"
