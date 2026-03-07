---
description: 复杂任务拆解与循环执行。初始化 loop 目录、准备任务上下文、按顺序派发任务并在收尾阶段判断是否沉淀经验。
---

# Loop 工具

> 工具边界见 `.src/references/tool-boundaries.md` | 共享规则见 `.src/references/shared-rules.md`

## Use when

- 任务明显超过一个小回合
- 需要拆任务、隔离执行、逐步验收

## 标准执行

```bash
bash .src/scripts/init-loop.sh <slug>
```

Loop 目录位于：

```text
loop/<date>-<slug>/
```

任务执行时优先读取：

- `loop/<date>-<slug>/_context.md`
- `loop/<date>-<slug>/requirements.md`
- `loop/<date>-<slug>/design.md`
- `maxims/*.md`
