# Self-Improve Pipeline

---
description: Capture reusable learnings into project Pensieve user data. Trigger on loop completion or user intents like "capture", "record", "save".
---

You are helping capture learnings and patterns into Pensieve user data categories: `maxim / decision / pipeline / knowledge`.

你在帮助把经验与模式沉淀到 Pensieve 的四类用户数据中：`maxim / decision / pipeline / knowledge`。

**System prompts** (tools/scripts/system knowledge) live in the plugin and are updated only via plugin updates.

**User data** lives in project-level `.claude/pensieve/` and is never overwritten by the plugin.

## Scope / 职责边界（Hard Rule）

- `/selfimprove` only handles capture and refinement, not full migration audits.
- `/selfimprove` 只负责沉淀与改进，不负责全量迁移体检。
- Migration and structure compliance checks belong to `/doctor`.
- 迁移与结构合规体检由 `/doctor` 负责。
- If major structure/path issues are found, recommend `/doctor` first, then `/upgrade` if needed.
- 若发现旧路径并行、目录缺失或大面积格式问题，先建议运行 `/doctor`，必要时转 `/upgrade`。

## Core Principles / 核心原则

- **User confirmation required / 必须用户确认**: Never auto-capture.
- **Read before write / 先读后写**: Read target README before writing.
- **Stable categories / 分类稳定**: Only use `maxim / decision / pipeline / knowledge`.
- **Conclusion first / 结论优先**: Title + opening line must stand alone.
- **Traceable links / 关系可追溯**: Use `基于/导致/相关` links.
- **One maxim per file / 准则单文件**: Do not rely on `custom.md` index.
- **Pipeline is orchestration / 流程只做编排**: Keep theory in linked files.

## Link Strength / 关联强度（Hard Rule）

- `decision`: at least one valid link is required.
- `pipeline`: at least one valid link is required.
- `knowledge`: links are recommended.
- `maxim`: source links are recommended.

## Phase 1: Understand Intent / 理解意图

**Goal / 目标**: Clarify what should be captured.

**Actions / 行动**:
1. Identify source: loop deviation, runtime pattern, explicit user intent, or external reference.
2. Distill one core conclusion sentence.
3. Decide the most suitable category.

## Phase 2: Propose Category and Confirm / 分类建议并确认

**Goal / 目标**: Give minimal and correct categorization.

**Actions / 行动**:
1. Match against categories:
   - `maxim`: cross-context long-term principle
   - `decision`: context-specific project choice
   - `pipeline`: executable workflow blueprint
   - `knowledge`: external method/reference
2. Present recommendation and ask user confirmation.
3. Do not write anything before confirmation.

**Path Rules / 路径规则**:
- `maxim`: `.claude/pensieve/maxims/{one-sentence-conclusion}.md`
- `decision`: `.claude/pensieve/decisions/{date}-{conclusion}.md`
- `pipeline`: `.claude/pensieve/pipelines/run-when-*.md`
- `knowledge`: `.claude/pensieve/knowledge/{name}/content.md`

## Phase 3: Read Target Spec / 读取目标规范

**Goal / 目标**: Follow existing rules, no new concepts.

**Actions / 行动**:
1. Read target README:
   - `<SYSTEM_SKILL_ROOT>/maxims/README.md`
   - `<SYSTEM_SKILL_ROOT>/decisions/README.md`
   - `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
   - `<SYSTEM_SKILL_ROOT>/knowledge/README.md`
2. Apply link-strength rules to draft.

## Phase 4: Draft / 草稿输出

**Goal / 目标**: Produce write-ready content.

**Actions / 行动**:
1. Use conclusion-style title.
2. Keep a one-line conclusion near top.
3. Include essential body and key references only.
4. Apply link requirements:
   - decision/pipeline: at least one valid `[[...]]`
   - knowledge/maxim: optional but recommended
5. For pipeline drafts, self-check:
   - Which paragraphs do not affect task orchestration?
   - Have those paragraphs been moved to `knowledge/decision/maxim` with links?
6. Show draft and wait for user confirmation.

## Phase 5: Write and Backlink / 写入与回链

**Goal / 目标**: Persist content and keep graph connected.

**Actions / 行动**:
1. Write to target path.
2. If a new `maxim` is added, link to related `decision/knowledge/pipeline`.
3. Add reverse links in related notes when needed.
4. Confirm written paths and changed links to user.

## Related Files

- `maxims/README.md` — Maxim format and criteria
- `decisions/README.md` — Decision format and criteria
- `pipelines/README.md` — Pipeline format and criteria
- `knowledge/README.md` — Knowledge format and criteria
