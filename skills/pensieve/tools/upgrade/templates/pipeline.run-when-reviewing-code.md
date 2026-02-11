---
id: run-when-reviewing-code
type: pipeline
title: Code Review Pipeline
status: active
created: 2026-02-11
updated: 2026-02-11
tags: [pensieve, pipeline, review]
name: run-when-reviewing-code
description: Run when a code review is requested. Trigger words: review / code review / 代码审查 / 检查代码。
stages: [tasks]
gate: auto
---

# Code Review Pipeline（代码审查）

This pipeline focuses on orchestration only. Keep theory and deeper criteria in linked knowledge files.

该 pipeline 只负责任务编排。审查标准与理论依据放在被引用的知识文件中。

**Knowledge reference**: `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

**上下文链接（至少一条）**:
- 基于：[[knowledge/taste-review/content]]
- 导致：[[decisions/2026-xx-xx-review-policy]]
- 相关：[[decisions/2026-xx-xx-review-strategy]]

---

## Task Blueprint (Create in order)

### Task 1: Prepare Review Context

**Goal / 目标**: Clarify boundaries and avoid scope misses.

**Read Inputs / 读取输入**:
1. User-provided files / commits / PR scope
2. `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

**Steps / 执行步骤**:
1. Confirm review scope (files / commits / snippets)
2. Identify technical/business constraints and risk points
3. Output a prioritized review file list

**Done When / 完成标准**: Scope is clear and review file list is executable.

---

### Task 2: Review Files and Capture Evidence

**Goal / 目标**: Produce per-file conclusions with evidence.

**Read Inputs / 读取输入**:
1. Review file list from Task 1
2. `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

**Steps / 执行步骤**:
1. Apply checklist to each file (no duplicated theory here)
2. Record severity: PASS / WARNING / CRITICAL
3. Cite exact code locations for WARNING/CRITICAL
4. Record user-visible behavior change risk (if any)

**Done When / 完成标准**: Each file has evidence-backed conclusions and locatable high-risk issues.

---

### Task 3: Produce Actionable Report

**Goal / 目标**: Deliver actionable fixes and clear priority.

**Read Inputs / 读取输入**:
1. Review notes from Task 2

**Steps / 执行步骤**:
1. Summarize key issues by severity
2. Provide concrete fix suggestions or rewrite options
3. Call out user-visible behavior and regression risks
4. Recommend fix order (CRITICAL first, then WARNING)

**Done When / 完成标准**: Report includes findings, evidence, fix suggestions, and clear priority.

---

### Task 4: Capture Reusable Outcomes (Optional)

**Goal / 目标**: Convert reusable outcomes into existing four categories.

**Read Inputs / 读取输入**:
1. Report from Task 3

**Steps / 执行步骤**:
1. If outcome is project choice, capture in `decision`
2. If outcome is general external method, capture in `knowledge`
3. Add at least one `基于/导致/相关` link (required for decision)
4. If no reusable output, explicitly record "no capture"

**Done When / 完成标准**: Capture result is explicit (written or explicitly skipped).

---

## Execution Rules (for loop)

1. Create tasks strictly in order: Task 1 -> Task 2 -> Task 3 -> Task 4.
2. Keep default 1:1 mapping; do not merge or skip tasks.
3. If context is missing, fill it inside current task instead of adding extra phase.
