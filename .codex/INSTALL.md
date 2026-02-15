# 在 Codex CLI 中安装 Pensieve

Pensieve（本仓库）原始形态是 Claude Code plugin，但其 `skills/` 目录可以被 Codex 通过原生 skill discovery 直接使用。

## 安装

1. 克隆仓库到 Codex 全局目录：

```bash
git clone https://github.com/alfadb/Pensieve.git ~/.codex/pensieve
```

2. 建立 skills 软链接（参考 superpowers 安装方式）：

```bash
mkdir -p ~/.agents/skills
ln -s ~/.codex/pensieve/skills ~/.agents/skills/pensieve
```

3. 重启 Codex CLI（退出并重新启动），让其重新发现 skills。

## 验证

```bash
ls -la ~/.agents/skills/pensieve
ls -la ~/.agents/skills/pensieve/pensieve/SKILL.md
ls -la ~/.agents/skills/pensieve/pensieve-codex/SKILL.md
```

## 使用（Codex 版）

Pensieve-codex 的项目数据目录固定在项目内：`<project>/.codex/pensieve/`。

初始化（每个项目首次一次）：

```bash
bash ~/.agents/skills/pensieve/pensieve-codex/tools/init/scripts/init-project-data.sh
```

开始 loop：

- 在 Codex 对话里直接说：`loop`
- 或者说：`用 loop 完成这个任务`

（手动一键初始化 + 创建 loop 目录，便于排查问题）：

```bash
bash ~/.agents/skills/pensieve/pensieve-codex/tools/loop/scripts/start-loop.sh
```

## 更新

```bash
cd ~/.codex/pensieve && git pull
```

## 卸载

```bash
rm ~/.agents/skills/pensieve
```

（可选）删除本地克隆：

```bash
rm -rf ~/.codex/pensieve
```
