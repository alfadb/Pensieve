---
name: pensieve-codex
description: 在 Codex CLI 中提供可复用的 loop 工作流：把复杂任务拆成可验证小步，用 update_plan 驱动逐步执行，并把上下文/产物落盘到项目内 `.codex/pensieve/`。
---

# Pensieve（Codex 版）

Pensieve-codex 的目标是把“复杂任务 = 可验证小步 + 持续执行”固化为一种可重复的工作方式：

- **系统能力（skill/模板/脚本）**：由本 skill 提供，安装在 `~/.agents/skills/pensieve/` 下
- **项目数据（永不覆盖）**：落盘到项目目录：`<project>/.codex/pensieve/`

## 目录约定（项目内）

```
<project>/.codex/pensieve/
  maxims/      # 团队/个人工程原则（可选，但强烈建议）
  decisions/   # 项目决策记录（可选）
  knowledge/   # 外部参考资料（可选）
  pipelines/   # 可复用的流程蓝图（可选）
  loop/        # 每次 loop 的上下文与执行记录（建议保留）
```

## 意图路由（第一步）

优先识别用户的显式指令；没有显式指令时，先问一句确认再执行：

1. 用户明确说 **`init` / 初始化** → 使用 Init 工具：`tools/init/_init.md`
2. 用户明确说 **`loop` / 用 loop** → 使用 Loop 工具：`tools/loop/_loop.md`
3. 用户没有明确指令但任务明显复杂（多文件/多步骤/需要反复验证）→ 建议用户进入 `loop`

约束：
- 本版本不依赖 Claude Code 的 Task 系统/Stop hook；loop 的“自动续跑”通过 **同一会话内持续执行** 达成。
- 除非用户明确说了 `init/loop`，否则不要擅自进入 loop；先用一行问题确认（选项：直接做 / loop）。

## Loop 的自动初始化（硬规则）

当用户说 `loop` 时，必须先自动检查并初始化/更新项目级目录，然后再开始拆分与执行：

```bash
bash ~/.agents/skills/pensieve/pensieve-codex/tools/loop/scripts/start-loop.sh [slug]
```

该命令是幂等的：不会覆盖任何已存在的用户文件，只会补齐缺失的结构与种子文件，并创建一个新的 loop 目录。
