#!/bin/bash
# Pensieve（Codex）一键开始 loop：
# - 自动检查/初始化（或补齐缺失种子文件）到 <project>/.codex/pensieve/
# - 自动创建一个新的 loop 目录到 <project>/.codex/pensieve/loop/
#
# 用法：
#   start-loop.sh [slug] [--force]
#
# 约定：
# - 默认 slug 为 "loop"
# - 若当天同 slug 已存在，则自动追加后缀：<slug>-2, <slug>-3...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_PROJECT_DATA_SH="$SCRIPT_DIR/../../init/scripts/init-project-data.sh"
INIT_LOOP_SH="$SCRIPT_DIR/init-loop.sh"

usage() {
  cat << EOF
Usage:
  $0 [slug] [--force]
EOF
}

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

slug=""
force=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force="--force"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$slug" ]]; then
        slug="$1"
        shift
      else
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$slug" ]]; then
  slug="loop"
fi

# 1) 确保项目级数据目录存在并播种缺失内容（不覆盖已有文件）
bash "$INIT_PROJECT_DATA_SH"

# 2) 若未指定 --force，则自动选择一个不冲突的 slug
if [[ "$force" != "--force" ]]; then
  DATE="$(date +%Y-%m-%d)"
  PROJECT_ROOT="$(project_root)"
  LOOP_BASE_DIR="$PROJECT_ROOT/.codex/pensieve/loop"
  mkdir -p "$LOOP_BASE_DIR"

  candidate="$slug"
  n=2
  while [[ -d "$LOOP_BASE_DIR/${DATE}-${candidate}" ]]; do
    candidate="${slug}-${n}"
    n=$((n + 1))
  done
  slug="$candidate"
fi

# 3) 创建 loop 目录与骨架文件
bash "$INIT_LOOP_SH" "$slug" ${force:+$force}

