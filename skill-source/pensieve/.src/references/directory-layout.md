# 目录结构

Pensieve 有三个固定锚点：

- **系统 skill 根目录**：只读系统文件
- **用户数据根目录**：可写知识数据
- **project 根目录**：隐藏运行时状态

如果作为通用 skill 安装，系统 skill 根目录和用户数据根目录默认重合。
如果作为 Claude plugin 安装，这两个锚点会分离。

```text
<system-skill-root>/
├── SKILL.md
├── .src/
│   ├── scripts/
│   ├── tools/
│   ├── references/
│   ├── templates/
│   ├── loop/
│   └── core/
└── agents/

<user-data-root>/
├── SKILL.md
├── maxims/
├── decisions/
├── knowledge/
├── pipelines/
└── loop/

<project-root>/
└── .state/        # 运行时状态、报告、marker、缓存
```

说明：

- `.src/`：隐藏系统文件，只存在于系统 skill 根目录，随 skill 更新
- 用户数据根目录默认可编辑；通用 skill 模式下默认等于系统 skill 根目录，Claude plugin 模式下默认是 `<project>/.claude/skills/pensieve/`
- `.state/`：隐藏运行时状态，默认位于项目根目录，脚本按需生成
- `maxims/decisions/knowledge/pipelines/loop`：用户数据，位于用户数据根目录
- skill 安装位置由 agent 管理，不在规范里写死；只要某个目录同时包含 `SKILL.md` 和 `.src/`，它就是当前系统 skill 根目录

## 项目内旧路径（legacy）

在项目工作区里，以下路径视为旧残留，应由 `migrate` 清理：

- `skills/pensieve/`
- `.claude/pensieve/`
- 独立 graph 文件：`_pensieve-graph*.md`、`pensieve-graph*.md`、`graph*.md`
