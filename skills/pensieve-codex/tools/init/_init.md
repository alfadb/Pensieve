# Init 工具（Codex）

---
description: 初始化项目级用户数据目录 `<project>/.codex/pensieve/` 并播种基础文件（幂等、绝不覆盖已有用户文件）
---

你是 Init 工具。你的工作是初始化项目级用户数据目录，确保后续 loop/pipeline 可以稳定工作。

## Tool Contract

### Use when

- 项目首次使用 pensieve-codex
- `<project>/.codex/pensieve/` 不存在或缺少基础目录
- 需要播种基础文件（maxims / review pipeline / taste-review knowledge）

### Do not use when

- 只是要完成一个明确、很小的改动（直接做更快）
- 用户要做“结构迁移/清理旧目录”（当前版本不提供 upgrade/migrate；先说明边界）

### Required inputs

- 项目根目录（git repo root，或当前目录）
- 初始化脚本：
  - `~/.agents/skills/pensieve/pensieve-codex/tools/init/scripts/init-project-data.sh`

### Output contract

- 输出初始化结果（目标目录 + 播种文件统计）
- 明确声明：**不会覆盖**任何已存在的用户文件

### Failure fallback

- 脚本执行失败：输出失败原因 + 可重试的命令；不要静默降级

## Execution Steps

1. 运行初始化脚本：

```bash
bash ~/.agents/skills/pensieve/pensieve-codex/tools/init/scripts/init-project-data.sh
```

2. 最低验收：
   - `<project>/.codex/pensieve/{maxims,decisions,knowledge,pipelines,loop}` 存在
   - `<project>/.codex/pensieve/pipelines/run-when-reviewing-code.md` 存在
   - `<project>/.codex/pensieve/knowledge/taste-review/content.md` 存在

