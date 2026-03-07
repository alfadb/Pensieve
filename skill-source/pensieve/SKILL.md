---
name: pensieve
description: 项目知识库与工作流路由。knowledge 里有之前探索过的文件位置、模块边界、调用链路，可直接复用不必重新定位；decisions/maxims 是已定论的架构决定和编码准则，应遵守而非重新讨论；pipelines 是可复用的工作流程。完成任务后用 self-improve 沉淀新发现。提供 init、upgrade、migrate、doctor、self-improve、loop 六个工具。
---

# Pensieve

将用户请求路由到正确的工具。不确定时先确认。

## 意图判断

1. **显式意图优先**：用户明确说了工具名或触发词，直接路由。
2. **会话阶段推断**（未显式指定时）：
   - 新项目或空白上下文 → `init` | 版本不确定 → `upgrade` | 迁移/残留不确定 → `migrate`
   - 探索代码库或定位问题 → 先查 `knowledge/`，探索后用 `self-improve` 写入
   - 开发完成或复盘信号 → `self-improve` | 复杂任务需拆解 → `loop`
3. **不确定时先确认**。

<example>
User: "帮我初始化 pensieve" → Route: .src/tools/init.md
User: "检查一下数据有没有问题" → Route: .src/tools/doctor.md
User: "这个需求比较复杂，用 loop 跑" → Route: .src/tools/loop.md
User: "怎么安装 Pensieve" → Read: .src/references/skill-lifecycle.md, then route to init
User: "怎么更新 Pensieve" → Read: .src/references/skill-lifecycle.md, then route to upgrade
</example>

## 全局规则（摘要）

1. **边界优先**：版本/兼容问题走 `upgrade`；迁移/残留清理走 `migrate`。
2. **先确认再执行**：用户未显式下达时先确认。
3. **链接保持连通**：`decision/pipeline` 至少一条 `[[...]]` 链接。
4. **先读规范再写数据**：创建/检查用户数据前先读 `.src/references/` 里的对应规范。

> 完整规则见 `.src/references/shared-rules.md`

## 工具执行协议

执行任一工具前，先读取其 `### Use when` 确认适用场景。工具边界与重定向见 `.src/references/tool-boundaries.md`。

## 路由表

| 意图 | 工具规范（先读） | 触发词 |
|------|------------------|--------|
| 初始化 | `.src/tools/init.md` | init, 初始化 |
| 版本更新 | `.src/tools/upgrade.md` | upgrade, 版本 |
| 结构迁移 | `.src/tools/migrate.md` | migrate, 迁移, 清理旧路径 |
| 检查 | `.src/tools/doctor.md` | doctor, 检查, 检查格式 |
| 沉淀经验 | `.src/tools/self-improve.md` | self-improve, 沉淀, 复盘 |
| 循环执行 | `.src/tools/loop.md` | loop, 循环执行, 执行 pipeline |

## 自身运维

当用户问的是 Pensieve 自己怎么安装、更新、重装、卸载，而不是业务数据怎么写：

1. 先读 `.src/references/skill-lifecycle.md`
2. 再按动作路由：
   安装/重装 → `init`
   更新 → `upgrade`
   旧结构清理 → `migrate`
   安装后校验 → `doctor`

## 路由失败回退

1. **意图不明确**：返回候选路由并要求用户确认。
2. **工具入口不可读**：停止并报告缺失路径。
3. **输入不完整**：先补齐再执行。

`.src/` 位于系统 skill 根目录；`.state/` 位于 project 根目录；当前用户数据根目录下的 `maxims/`、`decisions/`、`knowledge/`、`pipelines/`、`loop/` 是用户数据目录。
