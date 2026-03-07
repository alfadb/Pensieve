---
description: 刷新 Pensieve skill 源码。优先通过 git pull 或 npx skills update 完成更新；不做结构迁移与 doctor 分级。
---

# Upgrade 工具

> 工具边界见 `.src/references/tool-boundaries.md` | 共享规则见 `.src/references/shared-rules.md`

## Use when

- 用户要求升级 Pensieve
- 需要确认升级前后版本变化

如果用户先问“怎么更新 Pensieve”，先读 `.src/references/skill-lifecycle.md`，再执行本工具。

## 标准执行

```bash
bash .src/scripts/run-upgrade.sh
```

可选 dry-run：

```bash
bash .src/scripts/run-upgrade.sh --dry-run
```

升级后手动跑：

```bash
bash .src/scripts/run-doctor.sh --strict
```
