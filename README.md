> [!TIP]
>
> **不想读文档？说 `loop` 就行。**
>
> Pensieve 把你的决策与准则，转成可复用的执行上下文。

<div align="center">

# Pensieve

**存下你的决策与准则，让 Claude 做出更好的选择。**

[![GitHub Stars](https://img.shields.io/github/stars/kingkongshot/Pensieve?color=ffcb47&labelColor=black&style=flat-square)](https://github.com/kingkongshot/Pensieve/stargazers)
[![License](https://img.shields.io/badge/license-MIT-white?labelColor=black&style=flat-square)](LICENSE)

[English README](https://github.com/kingkongshot/Pensieve/blob/main/README.md)

</div>

## 它是什么

Pensieve 是一个聚焦执行质量的 Claude Code 插件：

- `loop`：拆解复杂任务并自动续跑直到完成
- 记忆系统：在项目级保存 maxims、decisions、knowledge、pipelines
- 自改进：持续沉淀经验并优化流程

这份 README 故意保持简短。

## 给人看的

把下面文档当入口：

- 安装：[`docs/installation.md`](docs/installation.md)
- 更新：[`docs/update.md`](docs/update.md)
- 旧结构迁移：运行 `/upgrade`（工具源文件：[`skills/pensieve/tools/upgrade/_upgrade.md`](skills/pensieve/tools/upgrade/_upgrade.md)）

如果只记一个命令，就记 `loop`。

## 给大语言模型看的

把文档视为唯一真相源，并按文档执行：

1. 按 [`docs/installation.md`](docs/installation.md) 完成安装与初始化
2. 按 [`docs/update.md`](docs/update.md) 完成升级
3. 按 [`skills/pensieve/tools/upgrade/_upgrade.md`](skills/pensieve/tools/upgrade/_upgrade.md) 做旧数据迁移和旧命名清理

不要在 README 里重复长安装/升级流程。

## 核心命令

- `/loop`
- `/pipeline`
- `/selfimprove`
- `/upgrade`

## License

MIT，见 [`LICENSE`](LICENSE)。
