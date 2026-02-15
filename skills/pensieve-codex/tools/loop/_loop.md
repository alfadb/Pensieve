---
description: 在 Codex CLI 中用 update_plan 驱动“拆分 -> 执行 -> 验证”的 loop 工作流。触发词：loop / 用 loop / loop 模式。
---

# Loop 工具（Codex）

你在执行一个“自动化迭代回路”：把复杂任务拆成可独立验证的小步，然后按顺序逐个完成、逐个验证。

本版本的关键差异：
- 不使用 Claude Code 的 Task 系统与 Stop hook
- 用 Codex 的 `update_plan` 来承载任务列表与进度
- 项目级落盘目录是：`<project>/.codex/pensieve/`

## Tool Contract

### Use when

- 任务复杂，涉及多个步骤/文件，需要边做边验证
- 用户明确要求进入 loop（或接受建议进入 loop）

### Do not use when

- 只改 1–2 个文件且范围明确（直接做更快）
- 目标不清晰（先澄清，再考虑 loop）

### Required inputs

- 已确认的目标/范围/约束
-（推荐）已完成 Init（保证 `.codex/pensieve/` 存在）

### Output contract

- 先给出“理解摘要 + 是否进入 loop”的一行确认（除非用户已明确说 loop）
- 创建 loop 目录并记录上下文
- 使用 `update_plan` 输出可执行的任务列表，并按列表逐项完成

### Failure fallback

- 初始化脚本失败：停止并返回错误 + 重试命令
- 执行中发现信息不足：把不足作为一个独立计划项（先补信息再继续），不要硬上

## 推荐执行步骤（机械化）

### Phase 0：简单任务判断

如果满足以下条件，建议直接完成，不要 loop：
- 文件 ≤ 2
- 需求明确
- 不需要探索/决策

否则进入 Phase 1。

### Phase 1：自动检查并初始化/更新（必须）

当用户说 `loop` 时，必须先确保项目目录可用，并创建本次 loop 的目录骨架。

运行（一键，推荐）：

```bash
bash ~/.agents/skills/pensieve/pensieve-codex/tools/loop/scripts/start-loop.sh [slug]
```

说明：
- 该命令会自动补齐 `<project>/.codex/pensieve/`（不覆盖已有文件）
- 会在 `<project>/.codex/pensieve/loop/` 下创建新的 loop 目录，并输出 `LOOP_DIR`
- 若当天同名目录已存在，会自动使用 `slug-2 / slug-3 ...` 避免冲突

### Phase 2：写入上下文并确认

在 `LOOP_DIR/_context.md` 写清楚：
- Goal / Scope / Constraints
- 你将如何验证“完成”

然后用一段话把上下文摘要复述给用户，确认无误再继续。

### Phase 3：生成任务列表（update_plan）

1. 读取项目原则：`<project>/.codex/pensieve/maxims/*.md`（如存在）
2. 如有流程蓝图，优先复用：`<project>/.codex/pensieve/pipelines/*.md`
3. 用 `update_plan` 生成 3–7 个可执行任务；每个任务必须包含：
   - 要改哪些文件/模块
   - 怎么验证（测试/命令/行为）

### Phase 4：逐项执行

按计划逐项执行：
- 只做当前任务范围内的工作
- 每完成一个任务就验证一次（能跑就跑）
- 发现偏差/人工干预点：追加到 `LOOP_DIR/_context.md` 的 Post-Context

### Phase 5：收尾

- 所有计划项完成后，给出简短总结（改了什么、怎么验证）
- 可选：把可复用经验写进 `.codex/pensieve/maxims/` 或 `.codex/pensieve/pipelines/`
