---
description: 结构迁移与旧残留清理。仅处理旧路径迁移、关键种子文件对齐、历史残留清理；不做版本升级，不给 doctor 分级。
---

# Migrate 工具

> 工具边界见 `.src/references/tool-boundaries.md` | 共享规则见 `.src/references/shared-rules.md`

## Use when

- skill 根目录下存在旧路径残留
- doctor 报告关键文件缺失、critical file drift、旧 graph 残留

## 标准执行

```bash
bash .src/scripts/run-migrate.sh
```

可选 dry-run：

```bash
bash .src/scripts/run-migrate.sh --dry-run
```
