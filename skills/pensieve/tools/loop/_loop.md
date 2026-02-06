---
description: Auto-loop task execution. Trigger when user says "use loop", "loop mode", or similar.
---

# Loop 流程

You are orchestrating an automated task execution loop. Break complex work into discrete tasks, then execute them via subagents while the Stop Hook handles continuation.

## 核心原则

- **上下文隔离**：每个 task 由 subagent 执行，避免主窗口上下文膨胀
- **原子任务**：每个 task 必须可独立执行与验证
- **用户确认**：生成 tasks 前必须确认上下文理解
- **清晰交接**：subagent 只执行一个 task 后返回；Stop Hook 触发下一个

> **Path notes**: The script paths below are relative to the plugin root (parent of `skills/pensieve/`). Scripts self‑locate and can run from any working directory.
>
> **Important**: In real installations, the plugin lives in Claude Code's plugin cache, not inside your repo.
> The SessionStart hook injects the absolute system skill path into context.
>
> Terms used below:
> - `<SYSTEM_SKILL_ROOT>`: injected system skill path (e.g. `/.../plugins/.../skills/pensieve`)
> - `<USER_DATA_ROOT>`: project user data directory (e.g. `<project>/.claude/pensieve`)

---

## Phase 0: Simple Task Check

**Before starting the loop, assess task complexity.**

If the task meets all of these, **recommend completing directly**:
- Only 1–2 files involved
- Scope is clear, no exploration needed
- Likely 1 task to finish

**Suggested phrasing**:
> This looks simple; finishing directly will be faster. Do you want to do it now or run a loop?

If user chooses direct completion → do not run loop
If user insists on loop → continue to Phase 1

---

## Phase 1: 初始化

**Goal**: Create the task list and loop directory structure

**Actions**:
1. Create a placeholder task to obtain the task list ID:
   ```
   TaskCreate subject="Initialize loop" description="1. Initialize loop directory 2. Build task context 3. Generate and execute tasks"
   # Returns { taskListId: "abc-123-uuid", taskId: "1" }
   ```
   ⚠️ **You must use the real taskListId** (e.g. `5e600100-9157-4888-...`), not "default".
   If you didn't see taskListId:
   - Ensure you actually invoked the TaskCreate tool (not just printed the text)
   - Expand the tool output (e.g., `ctrl+o`) to view JSON
   - Copy `taskListId` from the JSON

2. Get the real taskListId (more natural for AI, avoids guessing):
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/find-task-list-id.sh "Initialize loop"
   ```

3. Run the init script to create the loop directory and agent prompt:
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh <taskListId> <slug>
   ```
   **slug**: a short English identifier based on the task (e.g., `snake-game`, `auth-module`).

   **IMPORTANT**: Do **not** run this with `run_in_background: true`. You need the `LOOP_DIR` output immediately for Phase 2.

   Script output (remember these two values):
   ```
   TASK_LIST_ID=abc-123-uuid
   LOOP_DIR=.claude/pensieve/loop/2026-01-27-login
   ```

---

## Phase 2: 激活 Stop Hook

**Goal**: Ensure Stop Hook can detect the active loop

Since `0.3.2`, `init-loop.sh` writes a loop marker at `/tmp/pensieve-loop-<taskListId>`. Stop Hook uses this marker to take over.

**Important**: You no longer need `bind-loop.sh` (no background process / `run_in_background: true`).

---

## Phase 3: 记录上下文

**目标**：在生成任务前记录对话上下文

**Actions**:
1. Create and write `LOOP_DIR/_context.md` (Phase 1 no longer creates a template file to avoid "Read before Write" friction):

```markdown
# Conversation Context

## Pre-Context

### Interaction History
| Turn | Model Attempt | User Feedback |
|------|----------------|---------------|
| 1 | ... | ... |

### Final Consensus
- Goal: XXX
- Scope: YYY
- Constraints: ZZZ

### Understanding & Assumptions
- Expected modules involved
- Expected implementation approach
- Expected difficulties

### Document References
| Type | Path |
|------|------|
| requirements | none / path |
| design | none / path |
| plan | none / path |
```

2. **Present the context summary to the user and confirm understanding before proceeding**

3. **Create requirements/design docs as needed** (use templates):

   | Condition | Needed | Template |
   |----------|--------|----------|
   | 6+ tasks / multi‑day / multi‑module | requirements | `loop/REQUIREMENTS.template.md` |
   | Multiple options / decision impacts later work | design | `loop/DESIGN.template.md` |

   After creation, fill the paths into `_context.md` under "Document References".

---

## Phase 4: 生成任务

**目标**：将工作拆分为原子可执行任务

**关键**：未获得 Phase 3 的用户确认不得继续。

### Get available pipelines (for task design)

Before splitting tasks, list all project pipelines and descriptions to see if any are reusable:

```bash
bash <SYSTEM_SKILL_ROOT>/tools/pipeline/scripts/list-pipelines.sh
```

If a relevant pipeline exists, base task design on it; otherwise split normally.

### Task granularity standard

**Core test: Can an agent execute without asking questions?**

- Yes → good granularity
- No → split further or add details

Each task must:
- Specify files/components to create or modify
- Include concrete build/change/test actions

### 行动

1. Split tasks with the above granularity
2. Create tasks incrementally (each task builds on the previous)
3. **Present the task list to the user for confirmation**

---

## Phase 5: 执行任务

**Goal**: Run each task via isolated subagents

**Actions**:
1. Launch a general‑purpose agent for the first pending task:

```
Task(
  subagent_type: "general-purpose",
  prompt: "Read .claude/pensieve/loop/{date}-{slug}/_agent-prompt.md and execute task_id={id}"
)
```

The agent prompt template (`_agent-prompt.md`) is generated by init-loop.sh and includes:
- Role definition (Linus Torvalds)
- Context + maxims file paths
- Execution flow and constraints

2. Subagent reads the prompt → TaskGet → execute → return
3. Stop Hook detects pending tasks → injects reinforcement → main window executes mechanically

---

## Phase 6: 收尾

**Goal**: End the loop and self‑improve based on execution experience

**Actions**:
1. When all tasks are complete, Stop Hook prompts the main window about self‑improve and provides the path to `tools/self-improve/_self-improve.md`. Regardless of the answer, the loop stops.
2. To end a loop early (`<taskListId>` is from Phase 1):

   ✅ **Correct**:
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh <taskListId>
   ```

   ❌ **Incorrect** (missing task_list_id):
   ```bash
   bash <SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh
   ```

---

## 阶段选择指南

| 任务特征 | 阶段组合 |
|----------|----------|
| 明确、小范围 | tasks |
| 需要了解代码 | plan → tasks |
| 需要技术设计 | plan → design → tasks |
| 需求不明确 | plan → requirements → design → tasks |

---

## 相关文件

- `tools/loop/README.md` — 详细文档
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/init-loop.sh` — 初始化 loop 目录
- `<SYSTEM_SKILL_ROOT>/tools/loop/scripts/end-loop.sh` — 手动结束 loop
