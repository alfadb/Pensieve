#!/bin/bash
# Pensieve Loop end tool
# Stop a loop by task_list_id
#
# Usage:
#   end-loop.sh <task_list_id>   # stop a specific loop
#   end-loop.sh --all            # stop all active loops

set -euo pipefail

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
    task_id=$(jq -r '.task_list_id' "$marker" 2>/dev/null) || return 1
    loop_dir=$(jq -r '.loop_dir' "$marker" 2>/dev/null) || return 1

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
            task_id=$(jq -r '.task_list_id' "$marker" 2>/dev/null) || continue
            echo "  - $task_id"
        done
        exit 1
    fi

    end_loop_by_marker "$MARKER"
    echo "Loop ended"
fi
