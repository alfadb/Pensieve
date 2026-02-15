#!/bin/bash
# 初始化项目级 Pensieve（Codex）用户数据目录：
#   <project>/.codex/pensieve/
#
# 约束：
# - 该目录由用户/项目拥有，永不被 skill 更新覆盖
# - 可重复执行（幂等）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)" # .../skills/pensieve-codex

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

PROJECT_ROOT="$(project_root)"
DATA_ROOT="$PROJECT_ROOT/.codex/pensieve"

mkdir -p "$DATA_ROOT"/{maxims,decisions,knowledge,loop,pipelines}

TEMPLATES_ROOT="$SKILL_ROOT/templates"
SYSTEM_KNOWLEDGE_ROOT="$SKILL_ROOT/knowledge"

# seed maxims (never overwrite)
TEMPLATE_MAXIMS_DIR="$TEMPLATES_ROOT/maxims"
if [[ -d "$TEMPLATE_MAXIMS_DIR" ]]; then
  for template_maxim in "$TEMPLATE_MAXIMS_DIR"/*.md; do
    [[ -f "$template_maxim" ]] || continue
    target_maxim="$DATA_ROOT/maxims/$(basename "$template_maxim")"
    if [[ ! -f "$target_maxim" ]]; then
      cp "$template_maxim" "$target_maxim"
    fi
  done
fi

# seed knowledge (never overwrite)
KNOWLEDGE_SEEDED_COUNT=0
if [[ -d "$SYSTEM_KNOWLEDGE_ROOT" ]]; then
  while IFS= read -r source_file; do
    [[ -f "$source_file" ]] || continue
    rel_path="${source_file#$SYSTEM_KNOWLEDGE_ROOT/}"
    target_file="$DATA_ROOT/knowledge/$rel_path"
    mkdir -p "$(dirname "$target_file")"
    if [[ ! -f "$target_file" ]]; then
      cp "$source_file" "$target_file"
      ((KNOWLEDGE_SEEDED_COUNT++)) || true
    fi
  done < <(find "$SYSTEM_KNOWLEDGE_ROOT" -type f | LC_ALL=C sort)
fi

# seed pipeline (never overwrite)
REVIEW_PIPELINE="$DATA_ROOT/pipelines/run-when-reviewing-code.md"
if [[ ! -f "$REVIEW_PIPELINE" ]]; then
  cp "$TEMPLATES_ROOT/pipeline.run-when-reviewing-code.md" "$REVIEW_PIPELINE"
fi

# seed README (never overwrite)
README="$DATA_ROOT/README.md"
if [[ ! -f "$README" ]]; then
  cat > "$README" << 'EOF'
# .codex/pensieve（项目数据）

这是项目级的 Pensieve（Codex）用户数据目录：
- **永不**被 skill/插件更新覆盖
- 可选择提交到仓库用于团队共享（或按需忽略）

## 结构

- `maxims/`: 工程原则（建议：一条原则一个文件）
- `decisions/`: 决策记录（ADR）
- `knowledge/`: 外部参考资料（可链接或摘录）
- `pipelines/`: 可复用流程蓝图（用于 loop 拆分任务）
- `loop/`: 每次 loop 的上下文与执行记录
EOF
fi

echo "✅ 初始化完成：$DATA_ROOT"
MAXIM_COUNT=0
if [[ -d "$DATA_ROOT/maxims" ]]; then
  MAXIM_COUNT="$(find "$DATA_ROOT/maxims" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
fi
echo "  - maxims/*.md: $MAXIM_COUNT"
echo "  - knowledge/*: 新播种 $KNOWLEDGE_SEEDED_COUNT 个文件（不会覆盖已有文件）"
PIPELINE_STATUS="missing"
if [[ -f "$REVIEW_PIPELINE" ]]; then
  PIPELINE_STATUS="present"
fi
echo "  - pipelines/run-when-reviewing-code.md: $PIPELINE_STATUS"
