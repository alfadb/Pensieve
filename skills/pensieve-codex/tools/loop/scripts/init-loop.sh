#!/bin/bash
# Pensieve（Codex）Loop 初始化脚本
#
# 用途：创建项目内 loop 目录并生成最小上下文骨架文件
#
# 用法：
#   init-loop.sh <slug> [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

project_root() {
  if [[ -n "${CODEX_PROJECT_DIR:-}" ]]; then
    echo "$CODEX_PROJECT_DIR"
    return 0
  fi
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    echo "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

usage() {
  cat << EOF
Usage:
  $0 <slug> [--force]
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

FORCE=""
if [[ "${!#}" == "--force" ]]; then
  FORCE="--force"
  set -- "${@:1:$(($# - 1))}"
fi

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

SLUG="$1"
DATE="$(date +%Y-%m-%d)"

PROJECT_ROOT="$(project_root)"
DATA_ROOT="$PROJECT_ROOT/.codex/pensieve"
LOOP_BASE_DIR="$DATA_ROOT/loop"

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,pipelines,loop}

LOOP_NAME="${DATE}-${SLUG}"
LOOP_DIR="$LOOP_BASE_DIR/$LOOP_NAME"

if [[ -d "$LOOP_DIR" ]]; then
  if [[ "$FORCE" != "--force" ]]; then
    echo "Error: Loop 目录已存在：$LOOP_DIR"
    echo "使用 --force 继续（不会删除已有文件，但可能覆盖骨架文件）"
    exit 1
  fi
  echo "Warning: loop 目录已存在，将覆盖骨架文件：$LOOP_DIR" >&2
fi

mkdir -p "$LOOP_DIR"

cat > "$LOOP_DIR/_meta.md" << EOF
---
type: loop
slug: $SLUG
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

# Loop 元信息

- Goal: （待补充）
- 验收方式: （待补充）
EOF

cat > "$LOOP_DIR/_context.md" << 'EOF'
# Conversation Context

## Pre-Context

### Final Consensus
- Goal:
- Scope:
- Constraints:

### Verification
- How to verify done:

### Notes
- Assumptions:
- Risks:

---

## Post-Context

### Deviations
- Before:
- Found:
- Adjustment:

### Interventions
- Manual intervention log:
EOF

cat > "$LOOP_DIR/_agent-prompt.md" << EOF
---
name: expert-developer
description: 按计划逐项执行当前任务，然后返回
---

你在执行一个 loop 的单个计划项。

## Loop 目录

优先读取：
- \`$LOOP_DIR/_context.md\`
- \`$LOOP_DIR/_meta.md\`

## 约束

- 只做当前计划项范围内的工作；不要顺手扩展
- 能验证就验证（测试/构建/运行最小检查）
- 若发现缺信息：把缺口变成下一条计划项（先补信息再继续）
EOF

echo ""
echo "Loop 初始化完成"
echo "Directory: $LOOP_DIR"
echo ""
echo "LOOP_DIR=$LOOP_DIR"
echo ""
echo "Next steps:"
echo "1) 补全 $LOOP_DIR/_context.md"
echo "2) 用 update_plan 生成任务列表并逐项执行"

