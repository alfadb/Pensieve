---
id: skill-lifecycle
type: knowledge
title: Pensieve 安装与更新
status: active
created: 2026-03-06
updated: 2026-03-06
tags: [pensieve, install, update, operations]
---

# Pensieve 安装与更新

当用户询问如何安装、初始化、更新、重装、卸载 Pensieve 本身时，先读本文件。

## 安装

### 方式 A：作为通用 skill（Codex / Vercel skills / 其他兼容 agent）

推荐直接安装仓库里的 `skill-source/pensieve/`：

```bash
npx skills add https://github.com/kingkongshot/Pensieve/tree/experimental/skill-source/pensieve --copy
```

说明：

- `--copy` 适合 Pensieve 这种会持续写入用户数据的 skill
- skill 安装路径由 agent 自己管理，不写死
- `codex` 本地实测默认安装到 `<project>/.agents/skills/pensieve`
- 这一模式下，用户数据默认写在安装后的 skill 根目录

安装后：

1. 让 agent 执行 `init`
2. 或者在 skill 根目录手工执行：

```bash
bash .src/scripts/init-project-data.sh
```

### 方式 B：作为 Claude Code 插件

本仓库根目录就是 Claude plugin 根，skill 源码位于 `skill-source/pensieve/`（使用 `skill-source` 而非 `skills` 以避免 CC 插件自动发现导致重复加载）。

本地开发可直接加载：

```bash
claude --plugin-dir /path/to/Pensieve
```

如果把本仓库作为 marketplace source 发布，也可以：

```bash
claude plugin marketplace add kingkongshot/Pensieve#experimental
claude plugin install pensieve@kingkongshot-marketplace
```

这一模式下：

- Claude hooks 已在 plugin 内预接好
- 用户数据写到 `<project>/.claude/skills/pensieve`
- 运行时状态写到 `<project>/.state`

## 初始化后验证

```bash
bash .src/scripts/run-doctor.sh --strict
```

PASS 条件：

- `SKILL.md` 与 `.src/` 存在
- `maxims/decisions/knowledge/pipelines/loop` 目录齐全
- 项目根目录生成 `.state/`
- 默认 pipeline 与 taste-review knowledge 已种子化

## 更新

### 作为通用 skill 安装时

```bash
npx skills update
```

如果维护的是源码 checkout，而不是 agent 已安装副本：

```bash
git pull --ff-only
```

然后按你的 agent 安装方式重新同步该 skill。

### 作为 Claude Code 插件安装时

优先用 Claude 自己的插件更新：

```bash
claude plugin update pensieve
```

交互式等价命令：

```text
/plugin update pensieve
```

更新后固定顺序：

```bash
bash .src/scripts/run-doctor.sh --strict
```

如果 `doctor` 报结构迁移类问题，再执行：

```bash
bash .src/scripts/run-migrate.sh
bash .src/scripts/run-doctor.sh --strict
```

## 卸载

删除已安装的 skill 根目录即可。

如果还要保留用户数据，先备份：

- `maxims/`
- `decisions/`
- `knowledge/`
- `pipelines/`
- `loop/`
- `.state/`（如果想保留体检报告、迁移备份、session marker）

## Claude 增量能力

如果通过 Claude plugin 安装，除了同一份 skill 内容外，还会多出：

- SessionStart marker 检查
- PreToolUse Explore/Plan prompt 注入
- PostToolUse 图谱与 auto memory 自动同步
- Claude 原生 `/plugin update` 生命周期

## 路由规则

- 问“怎么安装/重装 Pensieve”：
  先读本文件，再引导到 `init`
- 问“怎么更新 Pensieve”：
  先读本文件，再引导到 `upgrade`
- 问“怎么清理旧结构/旧 graph”：
  先读本文件，再引导到 `migrate`
- 问“安装后怎么确认正常”：
  先读本文件，再引导到 `doctor`
