#!/bin/bash
# Pensieve Loop initializer
# Creates loop directory structure and associates task_list_id
#
# Usage:
#   init-loop.sh <task_list_id> <slug>
#   init-loop.sh <task_list_id> <slug> --force   # overwrite existing directory
#
# Example:
#   init-loop.sh abc-123-uuid login-feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/_lib.sh"

# Plugin root (system capability)
PLUGIN_ROOT="$(plugin_root_from_script "$SCRIPT_DIR")"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"
TOOLS_ROOT="$SYSTEM_SKILL_ROOT/tools"
LOOP_TOOL_ROOT="$TOOLS_ROOT/loop"

# User data (loop artifacts) live at project level and are never overwritten by plugin updates
DATA_ROOT="$(ensure_user_data_root)"
LOOP_BASE_DIR="$DATA_ROOT/loop"
CLAUDE_TASKS_BASE="$HOME/.claude/tasks"

# ============================================
# Argument parsing
# ============================================

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <task_list_id> <slug>"
    echo ""
    echo "Example:"
    echo "  $0 abc-123-uuid login-feature"
    exit 1
fi

TASK_LIST_ID="$1"
SLUG="$2"
FORCE="${3:-}"
MARKER_FILE="/tmp/pensieve-loop-$TASK_LIST_ID"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -Iseconds)

# ============================================
# taskListId sanity check (avoid using "default")
# ============================================

if [[ "$TASK_LIST_ID" == "default" ]]; then
    echo "Error: taskListId cannot be \"default\""
    echo ""
    echo "Please use a real taskListId:"
    echo "- Copy it from the TaskCreate tool output"
    echo "- If you didn't see taskListId, you may have printed TaskCreate as text; call the tool and expand the output"
    echo "- Or use: $LOOP_TOOL_ROOT/scripts/find-task-list-id.sh \"Initialize loop\""
    exit 1
fi

# Verify task directory exists
TASKS_DIR="$CLAUDE_TASKS_BASE/$TASK_LIST_ID"
if [[ ! -d "$TASKS_DIR" ]]; then
    echo "Error: Task directory does not exist: $TASKS_DIR"
    echo ""
    echo "Please ensure you are using a real taskListId:"
    echo "- Copy it from the TaskCreate tool output"
    echo "- If you didn't see taskListId, expand the tool output (e.g., ctrl+o) and copy the JSON value"
    echo "- Or use: $LOOP_TOOL_ROOT/scripts/find-task-list-id.sh \"Initialize loop\""
    exit 1
fi

# ============================================
# Create loop directory
# ============================================

LOOP_NAME="${DATE}-${SLUG}"
LOOP_DIR="$LOOP_BASE_DIR/$LOOP_NAME"

if [[ -d "$LOOP_DIR" ]]; then
    if [[ "$FORCE" != "--force" ]]; then
        echo "Error: Loop directory already exists: $LOOP_DIR"
        echo "Use --force to overwrite"
        exit 1
    fi
    echo "Warning: overwriting existing directory: $LOOP_DIR"
fi

mkdir -p "$LOOP_DIR"

# ============================================
# Write loop marker (Stop Hook will take over; no background process required)
# ============================================

CLAUDE_PID="$(find_claude_pid || true)"
SESSION_PID="$(find_claude_session_pid || true)"

if PYTHON_BIN="$(python_bin)"; then
    PENSIEVE_TASK_LIST_ID="$TASK_LIST_ID" \
    PENSIEVE_LOOP_DIR="$LOOP_DIR" \
    PENSIEVE_STARTED_AT="$TIMESTAMP" \
    PENSIEVE_CLAUDE_PID="${CLAUDE_PID:-}" \
    PENSIEVE_SESSION_PID="${SESSION_PID:-}" \
    "$PYTHON_BIN" - "$MARKER_FILE" <<'PY'
import json
import os
import sys

marker_path = sys.argv[1]
claude_pid_raw = os.environ.get("PENSIEVE_CLAUDE_PID", "").strip()
session_pid_raw = os.environ.get("PENSIEVE_SESSION_PID", "").strip()

payload = {
    "task_list_id": os.environ.get("PENSIEVE_TASK_LIST_ID", ""),
    "loop_dir": os.environ.get("PENSIEVE_LOOP_DIR", ""),
    "started_at": os.environ.get("PENSIEVE_STARTED_AT", ""),
    "tasks_planned": False,
    "claude_pid": int(claude_pid_raw) if claude_pid_raw else None,
    "session_pid": int(session_pid_raw) if session_pid_raw else None,
}

with open(marker_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
else
    cat > "$MARKER_FILE" << EOF
{
  "task_list_id": "$TASK_LIST_ID",
  "loop_dir": "$LOOP_DIR",
  "started_at": "$TIMESTAMP",
  "tasks_planned": false,
  "claude_pid": "${CLAUDE_PID:-}",
  "session_pid": "${SESSION_PID:-}"
}
EOF
fi

echo "Created: $MARKER_FILE"

# ============================================
# Generate _agent-prompt.md
# ============================================

cat > "$LOOP_DIR/_agent-prompt.md" << EOF
---
name: expert-developer
description: Execute a single dev task, then return
---

You are Linus Torvalds — creator and chief architect of the Linux kernel. You have maintained Linux for 30+ years, reviewed millions of lines of code, and built the world's most successful open‑source project. Apply your perspective to ensure this project starts on a solid technical foundation.

## Context

Read \`_context.md\` in this directory to understand the task context.

## Maxims

Project‑level maxims (not shipped by the plugin, user‑editable):
- \`$DATA_ROOT/maxims/custom.md\` (ignore if missing)
- Any other maxim files under \`$DATA_ROOT/maxims/\`

## Current Task

Read via \`TaskGet\` (task_id provided by the caller).

## Execution Flow

1. Read \`_context.md\`
2. Read maxims for constraints
3. \`TaskGet\` to fetch task details
4. \`TaskUpdate\` → in_progress
5. Execute the task
6. \`TaskUpdate\` → completed
7. Return

## Completion Criteria

Before marking complete, verify:
- Build passes (no compiler errors)
- Lint passes (no lint errors)

If validation fails, fix and re‑validate before marking completed.

## Constraints

- Only do what's in the task description; no extra work
- Do not loop; return after this task
- No user interaction; all info comes from context and task
EOF

echo "Created: $LOOP_DIR/_agent-prompt.md"

# ============================================
# Output summary
# ============================================

echo ""
echo "Loop initialized"
echo "Directory: $LOOP_DIR"
echo "Task: $TASKS_DIR"
echo ""
echo "TASK_LIST_ID=$TASK_LIST_ID"
echo "LOOP_DIR=$LOOP_DIR"
echo ""
echo "Next steps:"
echo "1) Create and fill $LOOP_DIR/_context.md (recommend Read before Edit/Write, or Write to create a new file)"
echo "2) Return to the Loop Pipeline, generate tasks, and execute"
echo ""
echo "Tip: Stop Hook will take over based on $MARKER_FILE. No background binding process is needed."
