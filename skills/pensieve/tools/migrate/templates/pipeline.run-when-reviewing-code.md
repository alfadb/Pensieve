---
id: run-when-reviewing-code
type: pipeline
title: Code Review Pipeline
status: active
created: 2026-02-11
updated: 2026-02-28
tags: [pensieve, pipeline, review]
name: run-when-reviewing-code
description: Code review stage flow — first explore commit history and code hotspots, extract candidates for capture, then follow a fixed Task Blueprint to produce a high-signal taste review conclusion. Trigger words — review, code review, inspect code.

stages: [tasks]
gate: auto
---

# Code Review Pipeline

This pipeline handles task orchestration only. Review criteria and underlying rationale are kept in Knowledge to avoid duplication in this file.

**Knowledge reference**: `.claude/skills/pensieve/knowledge/taste-review/content.md`

**Context Links (at least one)**:
- Based on: [[knowledge/taste-review/content]]
- Led to: none
- Related: none

---

## Signal Assessment Rules

The value of a review report depends on its signal-to-noise ratio — too many low-signal issues drown out the truly important ones.

- Only report high-signal issues: reproducible, localizable, affecting correctness / stability / user-visible behavior.
- Candidate issues must be verified before entering the final report, because unverified speculation wastes fix time.
- Default confidence threshold: `>= 80` to enter the final report.
- Do not report pure style suggestions, subjective preferences, or risk items based on guesswork.

---

## Task Blueprint (create tasks in order)

### Task 1: Baseline exploration (commit history + actual code)

**Goal**: Identify hotspots and capture candidates first to avoid blind review

**Read input**:
1. `git log` (default last 30 commits; can be overridden by user-specified range)
2. Actual code (prioritize recently high-churn files)
3. `.claude/skills/pensieve/knowledge/taste-review/content.md`

**Steps**:
1. Summarize high-frequency files/modules and main change types from recent commits
2. Read corresponding code and identify complexity hotspots and areas with unclear boundaries
3. Output two lists:
   - Files to review (by priority)
   - Capture candidates (annotated with suggested type: `knowledge/decision/maxim/pipeline`, each with evidence)

**Completion criteria**: Actionable review scope + capture candidate list (both with evidence)

---

### Task 2: Prepare review context

**Goal**: Define review boundaries to avoid missed items

**Read input**:
1. User-specified files / commits / PR range (if any)
2. Task 1 output: files to review and candidate information
3. `.claude/skills/pensieve/knowledge/taste-review/content.md`

**Steps**:
1. Merge user-specified range with Task 1 findings to determine final review scope
2. Identify technical language, business constraints, and risk points
3. Finalize the review file list (by priority)

**Completion criteria**: Scope is clear, with a finalized file list

---

### Task 3: Review each file and record evidence

**Goal**: Produce a candidate issue list (with evidence and confidence)

**Read input**:
1. Task 2 output: finalized file list
2. `.claude/skills/pensieve/knowledge/taste-review/content.md`

**Steps**:
1. Run the review checklist on each file (theory and rationale are in Knowledge; not duplicated here)
2. Record only "possibly real" candidate issues, with confidence (0-100)
3. Annotate each candidate issue with precise code location and evidence
4. Record user-visible behavior change risk (if any)

**Completion criteria**: Candidate issue list (with confidence, evidence, and location)

---

### Task 4: Verify candidate issues and filter false positives

**Goal**: Keep only high-signal, verifiable issues

**Read input**:
1. Task 3 candidate issue list
2. Corresponding code context and rule rationale

**Steps**:
1. Verify each candidate issue for real reproducibility
2. Update final confidence for each issue and remove items `<80`
3. Remove issues with insufficient evidence, unclear scope, or that rely on guesswork
4. Produce the "verified issue list"

**Completion criteria**: High-signal issue list (each is localizable, explainable, confidence >= 80)

---

### Task 5: Generate actionable review report

**Goal**: Output directly actionable fix suggestions with priority

**Read input**:
1. Task 4 verified issue list

**Steps**:
1. Summarize critical issues by severity level (CRITICAL -> WARNING)
2. Provide specific fix suggestions or rewrite directions for each issue
3. Clearly state user-visible behavior changes and regression risks
4. If no issues, explicitly output "no high-signal issues"

**Completion criteria**: Report contains only verified issues, with a clear fix order

---

### Task 6: Capture reusable conclusions (optional)

**Goal**: Capture reusable conclusions into one of the four existing types

**Read input**:
1. Task 5 review report

**Steps**:
1. If the conclusion is a project choice, capture it as a `decision`
2. If the conclusion is a general external method, capture it as `knowledge`
3. Add `Based on / Led to / Related` links in the captured entry (at least one, if it is a decision)
4. If no reusable conclusions, explicitly record "no new captures"

**Completion criteria**: Capture result is explicit (written or explicitly skipped)

---

## Failure Fallback

Each exception scenario has a corresponding handling approach to avoid producing misleading conclusions with insufficient information.

1. Cannot retrieve commit history (not a Git project or no history): Mark `SKIPPED` and continue to Task 2 (review based on existing code only).
2. Review scope is unclear: Return missing information and stop first; do not enter Task 3 — reviewing with unclear scope easily drifts off focus.
3. Cannot verify a candidate issue: Mark "unverifiable" and filter it out; do not include in the final report.
4. If all candidates are filtered out: Output "no high-signal issues". Padding with low-quality suggestions to meet a quota would undermine the report's credibility.

## Execution Rules (for loop)

1. When this pipeline is triggered, create tasks in order: Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6.
2. Default 1:1 mapping when creating tasks; do not merge or skip steps.
3. If information is missing, fill it in within the current task; do not create additional phases.
