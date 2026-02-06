#!/bin/bash
# Pensieve Loop end tool
# Stop a loop by task_list_id
#
# Usage:
#   end-loop.sh <task_list_id>   # stop a specific loop
#   end-loop.sh --all            # stop all active loops

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"
[[ -n "$PYTHON_BIN" ]] || {
    echo "Error: python3 is required but not found" >&2
    exit 1
}

json_get_value() {
    local file="$1"
    local key="$2"
    local default_value="${3:-}"

    [[ -n "$PYTHON_BIN" ]] || {
        echo "$default_value"
        return 0
    }

    "$PYTHON_BIN" - "$file" "$key" "$default_value" <<'PY'
import json
import sys

file_path, key, default_value = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    print(default_value)
    sys.exit(0)

if not isinstance(data, dict):
    print(default_value)
    sys.exit(0)

value = data.get(key)
if value is None:
    print(default_value)
elif isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, (int, float)):
    print(value)
elif isinstance(value, str):
    print(value)
else:
    print(default_value)
PY
}

# ============================================
# Argument parsing
# ============================================

if [[ $# -lt 1 ]]; then
    echo "❌ Error: missing argument" >&2
    echo "" >&2
    echo "Usage:" >&2
    echo "  $0 <task_list_id>   # stop a specific loop" >&2
    echo "  $0 --all            # stop all active loops" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  <task_list_id>  taskListId returned by Phase 1 TaskCreate" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  ./end-loop.sh abc-123-uuid" >&2
    echo "  ./end-loop.sh --all" >&2
    exit 1
fi

# ============================================
# End a single loop
# ============================================

end_loop_by_marker() {
    local marker="$1"
    [[ -f "$marker" ]] || return 1

    local task_id loop_dir pid
    task_id=$(json_get_value "$marker" "task_list_id" "") || return 1
    loop_dir=$(json_get_value "$marker" "loop_dir" "") || return 1
    [[ -n "$task_id" && -n "$loop_dir" ]] || return 1

    echo "Stopping Loop: $task_id"
    echo "  Directory: $loop_dir"

    # Remove marker file (Stop Hook will not continue)
    rm -f "$marker"
    echo "  Cleaned"
    echo ""
}

# ============================================
# Main
# ============================================

if [[ "$1" == "--all" ]]; then
    echo "Stopping all active loops..."
    echo ""

    found=false
    for marker in /tmp/pensieve-loop-*; do
        [[ -f "$marker" ]] || continue
        found=true
        end_loop_by_marker "$marker"
    done

    if [[ "$found" == false ]]; then
        echo "No active loops"
    fi
else
    TASK_LIST_ID="$1"
    MARKER="/tmp/pensieve-loop-$TASK_LIST_ID"

    if [[ ! -f "$MARKER" ]]; then
        echo "Error: loop marker not found: $MARKER"
        echo ""
        echo "Active loops:"
        for marker in /tmp/pensieve-loop-*; do
            [[ -f "$marker" ]] || continue
            task_id=$(json_get_value "$marker" "task_list_id" "") || continue
            [[ -n "$task_id" ]] || continue
            echo "  - $task_id"
        done
        exit 1
    fi

    end_loop_by_marker "$MARKER"
    echo "Loop ended"
fi
