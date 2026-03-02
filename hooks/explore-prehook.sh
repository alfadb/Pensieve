#!/bin/bash
# SubagentStart hook for Explore agents.
# Injects the project-level Pensieve SKILL.md as additionalContext,
# so every Explore agent is aware of existing knowledge before researching.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"
[[ -n "$PYTHON_BIN" ]] || exit 0

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

PROJECT_ROOT_RAW="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROJECT_ROOT="$(to_posix_path "$PROJECT_ROOT_RAW")"
SKILL_FILE="$PROJECT_ROOT/.claude/skills/pensieve/SKILL.md"

[[ -f "$SKILL_FILE" ]] || exit 0

"$PYTHON_BIN" - "$SKILL_FILE" <<'PY'
import json
import sys

skill_file = sys.argv[1]

guidance = """\
[Pensieve] The project knowledge index is shown below. Check it before exploring — what you need may already be documented:
- Knowledge: previously explored file locations, module boundaries, call chains — ready to reuse, no need to grep/glob again.
- Decisions / Maxims: settled architectural decisions and coding principles — follow them, don't re-debate.
- Pipelines: reusable workflows — if one matches the current task, follow it.

---
"""

try:
    with open(skill_file, "r", encoding="utf-8") as f:
        content = f.read()
except Exception:
    sys.exit(0)

print(json.dumps({"additionalContext": guidance + content}))
PY
