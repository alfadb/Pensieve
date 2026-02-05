#!/bin/bash
# Pensieve Loop Controller - Stop Hook
# Check pending tasks and auto-continue the loop

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || exit 0

# Resolve plugin root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SYSTEM_SKILL_ROOT="$PLUGIN_ROOT/skills/pensieve"

# Read hook input
HOOK_INPUT=$(cat)

# Lightweight logging (for debugging; appends across runs)
# log() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
# }
log() { :; }  # no-op

# Get file mtime (seconds), macOS/Linux compatible
get_mtime() {
    local file="$1"
    if stat -f %m "$file" >/dev/null 2>&1; then
        stat -f %m "$file"
    elif stat -c %Y "$file" >/dev/null 2>&1; then
        stat -c %Y "$file"
    else
        echo 0
    fi
}

# Get current Claude PID (for marker binding)
get_claude_pid() {
    local pid="$$"
    while [[ "$pid" -gt 1 ]]; do
        local comm
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')
        comm=$(basename "$comm")
        if [[ "$comm" == "claude" ]]; then
            echo "$pid"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ -z "$pid" ]] && break
    done
    return 1
}

# Get current session shell PID (compat/debug)
get_shell_pid() {
    local pid="$$"
    while [[ "$pid" -gt 1 ]]; do
        local comm
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | sed 's/^[[:space:]]*//')
        comm=$(basename "$comm")
        if [[ "$comm" == "claude" ]]; then
            ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' '
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        [[ -z "$pid" ]] && break
    done
    return 1
}

CURRENT_SESSION_PID="$(get_shell_pid || true)"
CURRENT_CLAUDE_PID="$(get_claude_pid || true)"
log "Hook triggered pid=$$ ppid=$PPID claude_pid=$CURRENT_CLAUDE_PID session_pid=$CURRENT_SESSION_PID"

# ============================================
# Check active loops (via marker files)
# ============================================

# Scan and collect all markers for this session
MARKERS=()

for marker in /tmp/pensieve-loop-*; do
    [[ -f "$marker" ]] || continue

    local_claude_pid=$(jq -r '.claude_pid // empty' "$marker" 2>/dev/null) || true
    [[ -n "$local_claude_pid" ]] || continue
    [[ -n "$CURRENT_CLAUDE_PID" ]] || continue

    # Only handle markers for current session
    [[ "$local_claude_pid" == "$CURRENT_CLAUDE_PID" ]] || continue

    # Cleanup: remove marker if claude_pid is no longer alive
    if ! kill -0 "$local_claude_pid" 2>/dev/null; then
        rm -f "$marker"
        log "stale marker removed: $marker claude_pid=$local_claude_pid"
        continue
    fi

    MARKERS+=("$marker")
done

if [[ "${#MARKERS[@]}" -eq 0 ]]; then
    log "no marker matched, exit"
    exit 0
fi

# Sort by mtime ascending (older loops first)
sort_markers_by_mtime() {
    for m in "$@"; do
        printf "%s %s\n" "$(get_mtime "$m")" "$m"
    done | sort -n | awk '{print $2}'
}

# Initialize globals (overwritten per marker)
MARKER_FILE=""
TASK_LIST_ID=""
LOOP_DIR=""
META_FILE=""
CONTEXT_FILE=""
TASKS_DIR=""
MARKER_TASKS_PLANNED="false"

update_marker_tasks_planned() {
    local total="$1"
    local pending="$2"
    local in_progress="$3"
    local tmp_file="${MARKER_FILE}.tmp"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq \
        --arg now "$now" \
        --argjson total "$total" \
        --argjson pending "$pending" \
        --argjson in_progress "$in_progress" \
        '.tasks_planned = true
        | .last_seen_at = $now
        | .last_seen_total = $total
        | .last_seen_pending = $pending
        | .last_seen_in_progress = $in_progress' \
        "$MARKER_FILE" > "$tmp_file" && mv "$tmp_file" "$MARKER_FILE"
    MARKER_TASKS_PLANNED="true"
}

# ============================================
# Helpers
# ============================================

read_goal() {
    if [[ -f "$META_FILE" ]]; then
        awk '/^## Overview/{flag=1; next} /^## /{flag=0} flag' "$META_FILE" | head -10
    else
        echo "(goal not set)"
    fi
}

read_pipeline() {
    if [[ -f "$META_FILE" ]]; then
        sed -n '/^---$/,/^---$/p' "$META_FILE" | grep "^pipeline:" | sed 's/^pipeline: *//'
    else
        echo "unknown"
    fi
}

# Ignore Phase 1 placeholder task (only for taskListId)
is_ignored_task() {
    local task_file="$1"
    local id subject
    id=$(jq -r '.id // ""' "$task_file" 2>/dev/null)
    subject=$(jq -r '.subject // ""' "$task_file" 2>/dev/null)
    [[ "$id" == "1" && "$subject" == "Initialize loop" ]]
}

is_task_blocked() {
    local task_file="$1"
    local blocked_by
    blocked_by=$(jq -r '.blockedBy // [] | .[]' "$task_file" 2>/dev/null)

    [[ -z "$blocked_by" ]] && return 1

    for dep_id in $blocked_by; do
        local dep_file="$TASKS_DIR/$dep_id.json"
        if [[ -f "$dep_file" ]]; then
            local dep_status
            dep_status=$(jq -r '.status' "$dep_file" 2>/dev/null)
            [[ "$dep_status" != "completed" ]] && return 0
        fi
    done

    return 1
}

get_next_task() {
    for task_file in "$TASKS_DIR"/*.json; do
        [[ -f "$task_file" ]] || continue
        [[ "$(basename "$task_file")" == ".DS_Store" ]] && continue
        is_ignored_task "$task_file" && continue

        local status
        status=$(jq -r '.status' "$task_file" 2>/dev/null)

        if [[ "$status" == "pending" ]]; then
            if ! is_task_blocked "$task_file"; then
                echo "$task_file"
                return 0
            fi
        fi
    done
    return 1
}

count_tasks() {
    local total=0 completed=0 pending=0 in_progress=0

    for task_file in "$TASKS_DIR"/*.json; do
        [[ -f "$task_file" ]] || continue
        [[ "$(basename "$task_file")" == ".DS_Store" ]] && continue
        is_ignored_task "$task_file" && continue

        ((total++)) || true
        local status
        status=$(jq -r '.status' "$task_file" 2>/dev/null)

        case "$status" in
            completed) ((completed++)) || true ;;
            pending) ((pending++)) || true ;;
            in_progress) ((in_progress++)) || true ;;
        esac
    done

    echo "$total $completed $pending $in_progress"
}

check_all_completed_with_stats() {
    local total="$1"
    local pending="$2"
    local in_progress="$3"

    # total==0:
    # - tasks_planned=false → still in setup (only placeholder task) → do not end
    # - tasks_planned=true  → tasks finished and cleaned by system → treat as done
    if [[ "$total" -eq 0 ]]; then
        [[ "$MARKER_TASKS_PLANNED" == "true" ]]
    else
        [[ "$pending" -eq 0 && "$in_progress" -eq 0 ]]
    fi
}

mark_in_progress() {
    local task_file="$1"
    local tmp_file="${task_file}.tmp"
    jq '.status = "in_progress"' "$task_file" > "$tmp_file"
    mv "$tmp_file" "$task_file"
}

# ============================================
# Reinforcement message
# ============================================

generate_reinforcement() {
    local task_file="$1"
    local stats
    stats=$(count_tasks)
    local total completed pending in_progress
    read -r total completed pending in_progress <<< "$stats"

    local task_id task_subject
    task_id=$(jq -r '.id' "$task_file")
    task_subject=$(jq -r '.subject' "$task_file")
    local task_description
    task_description=$(jq -r '.description // ""' "$task_file")

    local agent_prompt="$LOOP_DIR/_agent-prompt.md"

    local context_file="$LOOP_DIR/_context.md"

    local project_root user_data_root
    project_root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    user_data_root="$project_root/.claude/pensieve"

    cat << EOF
Only call Task — do not execute yourself:

Task(subagent_type: "general-purpose", prompt: "Read $agent_prompt and execute task_id=$task_id")

System capability (updated via plugin): $SYSTEM_SKILL_ROOT
Project user data (never overwritten): $user_data_root

If you detect direction drift:
1. Read system pipelines/maxims/knowledge first
2. Record questions + answers in "$context_file" under "Post Context"
3. Continue

Task content:
- subject: $task_subject
- description: $task_description
EOF
}

should_skip_subagent() {
    local task_file="$1"
    local subject description
    subject=$(jq -r '.subject // ""' "$task_file")
    description=$(jq -r '.description // ""' "$task_file")
    [[ "$subject" == "Self‑Improve" ]] && return 0
    echo "$description" | grep -q "do not call agent" && return 0
    return 1
}

# ============================================
# Main
# ============================================

main() {
    local marker
    for marker in $(sort_markers_by_mtime "${MARKERS[@]}"); do
        local local_task_id local_loop_dir
        local_task_id=$(jq -r '.task_list_id' "$marker" 2>/dev/null) || continue
        local_loop_dir=$(jq -r '.loop_dir' "$marker" 2>/dev/null) || continue

        MARKER_FILE="$marker"
        TASK_LIST_ID="$local_task_id"
        LOOP_DIR="$local_loop_dir"
        META_FILE="$LOOP_DIR/_meta.md"
        CONTEXT_FILE="$LOOP_DIR/_context.md"
        TASKS_DIR="$HOME/.claude/tasks/$TASK_LIST_ID"
        MARKER_TASKS_PLANNED=$(jq -r '.tasks_planned // false' "$MARKER_FILE" 2>/dev/null) || MARKER_TASKS_PLANNED="false"

        if [[ ! -d "$TASKS_DIR" ]]; then
            if [[ "$MARKER_TASKS_PLANNED" == "true" ]]; then
                local self_improve_path
                self_improve_path="$SYSTEM_SKILL_ROOT/tools/self-improve/_self-improve.md"

                rm -f "$MARKER_FILE"

                jq -n \
                    --arg msg "✅ Loop done | Self‑improve?" \
                    --arg path "$self_improve_path" \
                    '{
                        "decision": "block",
                        "reason": ("All tasks are complete (task data was cleaned by the system). Run self‑improve?\n\nPipeline path:\n- " + $path + "\n\nIf yes, follow that pipeline; if no, that’s fine. Loop has stopped."),
                        "systemMessage": $msg
                    }'
                exit 0
            fi

            rm -f "$MARKER_FILE"
            log "tasks dir missing, marker removed: $TASKS_DIR"
            continue
        fi

        local stats
        stats=$(count_tasks)
        local total completed pending in_progress
        read -r total completed pending in_progress <<< "$stats"

        if [[ "$total" -gt 0 && "$MARKER_TASKS_PLANNED" != "true" ]]; then
            update_marker_tasks_planned "$total" "$pending" "$in_progress"
        fi

        if check_all_completed_with_stats "$total" "$pending" "$in_progress"; then
            local self_improve_path
            self_improve_path="$SYSTEM_SKILL_ROOT/tools/self-improve/_self-improve.md"

            # Remove marker so Stop Hook won't continue
            rm -f "$MARKER_FILE"

            jq -n \
                --arg msg "✅ Loop done | Self‑improve?" \
                --arg path "$self_improve_path" \
                '{
                    "decision": "block",
                    "reason": ("All tasks are complete. Run self‑improve?\n\nPipeline path:\n- " + $path + "\n\nIf yes, follow that pipeline; if no, that’s fine. Loop has stopped."),
                    "systemMessage": $msg
                }'
            exit 0
        fi

        local next_task
        if next_task=$(get_next_task); then
            if should_skip_subagent "$next_task"; then
                local task_id task_subject task_description
                task_id=$(jq -r '.id' "$next_task")
                task_subject=$(jq -r '.subject' "$next_task")
                task_description=$(jq -r '.description // ""' "$next_task")

                jq -n \
                    --arg msg "⛳️ Loop | #$task_id $task_subject" \
                    --arg subject "$task_subject" \
                    --arg description "$task_description" \
                    '{
                        "decision": "block",
                        "reason": "This task must be executed in the main window (no subagent). Follow the task instructions directly (e.g., read _self-improve.md), then update Task status.",
                        "systemMessage": $msg,
                        "additionalContext": ("Task content:\n- subject: " + $subject + "\n- description: " + $description)
                    }'
                exit 0
            fi

            mark_in_progress "$next_task"

            local reinforcement
            reinforcement=$(generate_reinforcement "$next_task")

            local task_id task_subject
            task_id=$(jq -r '.id' "$next_task")
            task_subject=$(jq -r '.subject' "$next_task")
            local stats
            stats=$(count_tasks)
            local total completed pending in_progress
            read -r total completed pending in_progress <<< "$stats"

            jq -n \
                --arg reason "$reinforcement" \
                --arg msg "🔄 Loop [$completed/$total] | #$task_id $task_subject" \
                '{
                    "decision": "block",
                    "reason": $reason,
                    "systemMessage": $msg
                }'
            exit 0
        fi
    done

    exit 0
}

main
