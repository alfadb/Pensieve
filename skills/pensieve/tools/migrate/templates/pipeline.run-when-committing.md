---
id: run-when-committing
type: pipeline
title: Commit Pipeline
status: active
created: 2026-02-28
updated: 2026-02-28
tags: [pensieve, pipeline, commit, self-improve]
name: run-when-committing
description: Mandatory commit-stage flow — first determine whether there are insights worth capturing; if so, run self-improve to capture them, then make atomic commits. Trigger words — commit, git commit.

stages: [tasks]
gate: auto
---

# Commit Pipeline

Before committing, automatically extract insights from the session context + diff and capture them, then execute atomic commits. Do not ask for user confirmation at any point.

**Self-improve reference**: `<SYSTEM_SKILL_ROOT>/tools/self-improve/_self-improve.md`

**Context Links (at least one)**:
- Based on: [[knowledge/taste-review/content]]
- Related: none

---

## Signal Assessment Rules

The value of capturing insights lies in reuse next time; unverified guesses would mislead future decisions.

- Only capture insights that are "reusable and evidence-backed"; unverifiable guesses are not stored.
- Classification follows the semantic hierarchy: IS -> `knowledge`, WANT -> `decision`, MUST -> `maxim`.
- Assign by semantics rather than defaulting to "knowledge first", because misclassification leads to a mismatch in binding strength (something that should be MUST written as knowledge is easily overlooked later).

---

## Task Blueprint (create tasks in order)

### Task 1: Decide whether to capture — determine if there are insights worth capturing

**Goal**: Quickly determine whether this commit contains experience worth capturing; if not, skip directly to Task 3

**Read input**:
1. `git diff --cached` (changes about to be committed)
2. Current session context

**Steps**:
1. Run `git diff --cached --stat` to understand the scope of changes
2. Review the current session and check for the following signals (any one triggers capture):
   - Identified a bug root cause (debugging session)
   - Made an architectural or design decision (considered multiple approaches)
   - Discovered a new pattern or anti-pattern
   - Exploration produced a "symptom -> root cause -> localization" mapping
   - Clarified boundaries, ownership, or constraints
   - Discovered a capability that does not exist / has been deprecated in the system
3. If none of the above signals exist (purely mechanical changes: formatting, renaming, dependency upgrades, simple fixes), mark "skip capture" and jump directly to Task 3

**Completion criteria**: Clearly determined "needs capture" or "skip capture", with a one-line rationale

---

### Task 2: Auto-capture — extract insights and write them

**Goal**: Extract insights from session context + diff and write to user data without asking the user

**Read input**:
1. Task 1 determination result (skip this Task if "skip")
2. `git diff --cached`
3. Current session context
4. `<SYSTEM_SKILL_ROOT>/tools/self-improve/_self-improve.md`

**Steps**:
1. Read `_self-improve.md` and follow its Phase 1 (extract and classify) + Phase 2 (read spec + write)
2. Extract core insights from the session (can be multiple)
3. For each insight, first determine the semantic layer and classify (IS->knowledge, WANT->decision, MUST->maxim; may land in multiple layers simultaneously if needed)
4. Read the target type's README and generate content per spec
5. Type-specific requirements:
   - `decision`: Include the "exploration effort-saving trio" (what to skip asking / skip searching next time / invalidation conditions)
   - Exploration-type `knowledge`: Include (state transitions / symptom->root cause->localization / boundaries and ownership / anti-patterns / verification signals)
   - `pipeline`: Must meet conditions (recurring + non-interchangeable + verifiable)
6. Write to the target path and add context links
7. Run project-level SKILL maintenance:
   ```
   bash <SYSTEM_SKILL_ROOT>/tools/project-skill/scripts/maintain-project-skill.sh --event self-improve --note "auto-improve: {files}"
   ```
8. Output a brief summary (write path + capture type)

**DO NOT**: Do not ask for user confirmation, do not show drafts awaiting approval — write directly

**Completion criteria**: Insights have been written to user data (or explicitly determined unnecessary); project-level `SKILL.md` has been synced

---

### Task 3: Atomic commit

**Goal**: Execute atomic git commits

**Read input**:
1. `git diff --cached`
2. User's commit intent (commit message or context)

**Steps**:
1. Analyze staged changes and cluster by change reason
2. If multiple independent change groups exist, commit them separately (one atomic commit per group)
3. Commit message conventions:
   - Title: imperative mood, <50 characters, specific
   - Body: explain "why" rather than "what"
4. Execute `git commit`

**Completion criteria**: All staged changes have been committed; each commit is independent and can be reverted

---

## Failure Fallback

1. `git diff --cached` is empty: Skip Task 2/Task 3 and output "no staged changes, nothing to commit".
2. Capture step fails: Log the blocking reason, skip capture, and continue to Task 3; append "suggest running `doctor`" at the end.
3. Project-level SKILL maintenance fails: Keep already-captured content, report the failed command and retry suggestion, do not roll back already-written files.

## Execution Rules (for loop)

1. When this pipeline is triggered, execute in order: Task 1 -> Task 2 -> Task 3.
2. When Task 1 determines "skip capture", jump directly to Task 3.
3. Do not ask for user confirmation at any point (both self-improve and commit execute automatically).
4. If user data structure anomalies are detected (missing directories / corrupted format), skip capture, only execute commit, and suggest running `doctor` afterwards.
