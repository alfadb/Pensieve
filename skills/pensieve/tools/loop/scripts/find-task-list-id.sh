#!/bin/bash
# Find taskListId by task subject in ~/.claude/tasks
# Usage: find-task-list-id.sh [subject]
# Default subject: Initialize loop

set -euo pipefail

SUBJECT="${1:-Initialize loop}"
TASKS_BASE="$HOME/.claude/tasks"

if [[ ! -d "$TASKS_BASE" ]]; then
    echo "Error: task directory does not exist: $TASKS_BASE" >&2
    exit 1
fi

matches=()

for dir in "$TASKS_BASE"/*; do
    [[ -d "$dir" ]] || continue

    if command -v jq >/dev/null 2>&1; then
        if jq -e --arg subj "$SUBJECT" '.subject == $subj' "$dir"/*.json >/dev/null 2>&1; then
            matches+=("$dir")
        fi
    else
        if grep -Rqs "\"subject\" *: *\"$SUBJECT\"" "$dir"/*.json 2>/dev/null; then
            matches+=("$dir")
        fi
    fi
done

if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "Error: no taskListId found for subject=\"$SUBJECT\"" >&2
    exit 1
fi

# Pick the most recently modified directory
latest_dir=$(ls -dt "${matches[@]}" | head -1)
basename "$latest_dir"
