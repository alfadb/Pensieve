---
name: pensieve
description: 当用户表达任何意图时**立即加载**此 skill。系统能力（tools/knowledge/scripts）位于插件内，随插件更新维护。用户数据必须位于项目级 `.claude/pensieve/`，插件不会覆盖。用户要改进 Pensieve 系统（插件内容）时，**必须**使用 Self‑Improve 工具（`tools/self-improve/_self-improve.md`）。
---

# Pensieve

将用户意图路由到正确的工具或 pipeline。

## 用户意图判断（第一步）

在调用任一工具前，先做意图分流：

1. **先看显式指令**：若用户明确说了 `loop` / `/selfimprove` / `/upgrade` / `/init` / `pipeline` / `doctor`，直接按指令路由，不做推测。
2. **再看会话阶段**（用户未显式指定时）：
   - **大量对话且已有明确结论**（目标、约束、方案已定）：候选意图为“进入开发执行”（复杂任务可建议 `loop`）。
   - **开发已完成或接近完成**（出现“复盘/沉淀/规范化/下次复用”信号）：候选意图为“进入自改进”（建议 Self‑Improve）。
   - **空白开场或新接入项目**（尚未形成开发上下文）：候选意图为“先初始化用户数据”（建议 Init）。
3. **询问优先（禁止主动执行）**：只要用户没有显式下达工具命令，必须先用一句话询问确认，再执行；不得按候选意图自动进入下一步。推荐选项：开发 / 初始化 / 自改进 / 升级整理。

## 版本更新优先级（Hard Rule）

- 版本更新前置检查统一由 `/upgrade` 负责，且是最高优先级。
- 只要用户涉及“更新版本/插件异常/版本不确定/兼容问题”，优先路由 `/upgrade`。
- 在执行 `/init` 或 `/doctor` 前，若版本状态不明，先完成 `/upgrade` 的版本检查前置。

## 工具契约执行（P0 Hard Rule）

在执行任一工具前，先读取对应 tool file 中的 `## Tool Contract`，并严格执行：

1. 只有命中 `Use when` 且不命中 `Do not use when` 才能继续。
2. 必须满足 `Required inputs`；缺失输入时先补齐，不得盲跑。
3. 输出必须满足 `Output contract`；禁止自由发挥格式。
4. 发生异常时按 `Failure fallback` 处理；不跳过失败直接进入下一阶段。

## 设计约定

- **系统能力（随插件更新）**：位于 `skills/pensieve/`
  - tools / scripts / system knowledge / 格式 README
  - **不内置 pipelines / maxims 内容**
- **用户数据（项目级，永不覆盖）**：`.claude/pensieve/`
  - `maxims/`：团队准则（每条准则一个文件）
  - `decisions/`：项目决策记录
  - `knowledge/`：外部参考知识
  - `pipelines/`：项目 pipelines（安装时种子化）
  - `loop/`：loop 运行产物（每次 loop 一个目录）

## 内置工具（6）

### 1) Init 工具

**适用场景**：
- 新项目初始化 `.claude/pensieve/` 目录与基础种子

**入口**：
- Command：`commands/init.md`
- Tool file：`tools/init/_init.md`

**触发词**：
- "init" / "initialize" / "初始化"

### 2) Loop 工具

**适用场景**：
- 任务复杂，需要拆解并自动循环执行

**入口**：
- Command：`commands/loop.md`
- Tool file：`tools/loop/_loop.md`

**触发词**：
- `loop` / "use loop"

### 3) Self‑Improve 工具

**适用场景**：
- 用户要求改进 Pensieve（pipelines/scripts/rules/behavior）
- loop 结束后做复盘与改进

**入口**：
- Command：`commands/selfimprove.md`
- Tool file：`tools/self-improve/_self-improve.md`

**触发词**：
- "self‑improve" / "improve Pensieve"

### 4) Pipeline 工具

**适用场景**：
- 用户想查看当前项目可用 pipelines

**入口**：
- Command：`commands/pipeline.md`
- Tool file：`tools/pipeline/_pipeline.md`

**触发词**：
- "pipeline" / "use pipeline"

### 5) Doctor 工具

**适用场景**：
- 升级后的强制验证（结构/格式合规）
- 安装后的可选快速体检
- 用户要求做用户数据体检

**入口**：
- Command：`commands/doctor.md`
- Tool file：`tools/doctor/_doctor.md`

**触发词**：
- "doctor" / "health check" / "检查格式" / "检查迁移"

### 6) Upgrade 工具

**适用场景**：
- 用户要求更新插件版本或确认版本状态
- 用户需要把历史数据迁移到 `.claude/pensieve/`
- 用户询问目标用户数据结构

**入口**：
- Command：`commands/upgrade.md`
- Tool file：`tools/upgrade/_upgrade.md`

**触发词**：
- "upgrade" / "migrate user data"

---

SessionStart 会在运行时注入**系统能力路径**与**项目用户数据路径**，作为单一事实源。
