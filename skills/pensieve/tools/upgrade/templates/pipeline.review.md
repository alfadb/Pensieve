---
name: review
description: |
  Code review pipeline. Based on Linus Torvalds' taste philosophy, John Ousterhout's design principles, and Google Code Review standards.

  Use this pipeline when:
  - The user requests a code review
  - The user says "review", "code review", or "check my code"
  - You need to assess code quality or design decisions

  示例：
  <example>
  User: "Review this code for me"
  -> trigger this pipeline
  </example>
  <example>
  User: "Check this PR"
  -> trigger this pipeline
  </example>

signals: ["review", "code review", "check code", "code quality"]
stages: [tasks]
gate: auto
---

# 代码审查 Pipeline

This pipeline **orchestrates the review flow**. All criteria and deep rationale live in Knowledge.

**Knowledge reference**: `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

---

## Phase 0: Prepare

**Goal**: Define scope and load references

**Actions**:
1. Confirm scope (files / commits / snippets)
2. Identify language and constraints
3. Load review knowledge: `knowledge/taste-review/`

**Validation**: Scope is clear and knowledge is loaded

---

## Phase 1: Review

**Goal**: Apply the knowledge checklist and capture evidence

**Actions**:
1. For each file, run the checklist from knowledge (no theory here)
2. Record findings with severity: PASS / WARNING / CRITICAL
3. Cite exact code locations for every WARNING/CRITICAL

**Validation**: Each file has a conclusion with evidence

---

## Phase 2: Report

**Goal**: Deliver an actionable review summary

**Actions**:
1. Summarize key issues by severity
2. Provide concrete fixes or rewrites
3. Call out any user‑visible behavior changes

**Validation**: Report includes all findings and actionable suggestions
