---
name: review
description: |
  Code review pipeline. Based on Linus Torvalds' taste philosophy, John Ousterhout's design principles, and Google Code Review standards.

  Use this pipeline when:
  - The user requests a code review
  - The user says "review", "code review", or "check my code"
  - You need to assess code quality or design decisions

  Examples:
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

# Code Review Pipeline

Code review flow based on three core sources.

**Core rules**:
1. Eliminating special cases beats adding conditionals
2. **Never break userspace** — user‑visible behavior must not change
3. Expose problems early; do not hide upstream bugs with fallbacks
4. Complexity is the root of all evil

**Knowledge reference**: `<SYSTEM_SKILL_ROOT>/knowledge/taste-review/content.md`

---

## Phase 0: Pre‑Thinking

Before analyzing, ask these four questions:

| Question | Check |
|------|------|
| Is this a real problem or imagined? | Reject over‑design; solve real issues |
| Is there a simpler approach? | Always search for the simplest |
| Will it break anything? | Never break userspace |
| Is there a completely different approach? | Design it twice |

---

## Phase 1: Review Dimensions

Pick relevant dimensions to analyze:

### Data Structure Analysis
> "Bad programmers worry about the code. Good programmers worry about data structures."

- What is the core data? How do parts relate?
- Where does data flow? Who owns it?
- **Can changing data structures simplify the code?**

### Special‑Case Detection
> "Good code has no special cases."

- List all if/else branches
- Which are real business logic vs bad‑design patches?
- **Can you redesign to eliminate them?**

### Complexity Review
> "If you need more than 3 levels of indentation, redesign it."

- What is the essence of this feature? (one sentence)
- How many concepts are used? Can you halve them?

### Breakage Analysis
> "Never break userspace"

- Which existing behaviors might change?
- Is user‑visible behavior preserved?

---

## Phase 2: 8‑Step Review

### Step 1: Define Scope

```markdown
## Step 1: Review Scope
- **Type**: [files / Git commits / code snippets]
- **Size**: [X lines] [WARNING if >200 lines]
- **Primary change**: [one sentence]
```

### Step 2: Design Review

Check: ownership, library choice, module boundaries, Design It Twice

```markdown
## Step 2: Design Review
**Conclusion**: [PASS / WARNING / CRITICAL]
- Considered alternatives: [Yes/No]
```

### Step 3: Complexity Review

Check: change amplification, cognitive load, unknown unknowns, module depth

```markdown
## Step 3: Complexity Review
**Conclusion**: [PASS / WARNING / CRITICAL]
- **Change amplification**: [Yes/No]
- **Cognitive load**: [Low/Medium/High]
- **Module depth**: [Deep/Normal/Shallow]
```

### Step 4: Code Structure Review

Check: nesting depth (<=2 good, =3 warning, >3 critical), function length (<50 good, >100 critical), local variables (<=5 good, >10 warning)

```markdown
## Step 4: Code Structure Review
**Conclusion**: [PASS / WARNING / CRITICAL]
- **Max nesting**: [X levels]
- **Longest function**: [Y lines]
- **Special cases**: [N]
```

### Step 5: Naming & Comments Review

Check: naming precision, whether comments explain "why"

```markdown
## Step 5: Naming & Comments Review
**Conclusion**: [PASS / WARNING / CRITICAL]
```

### Step 6: Error Handling Review

Check: defensive defaults, fallback code, exception aggregation

```markdown
## Step 6: Error Handling Review
**Conclusion**: [PASS / WARNING / CRITICAL]
- **Defensive code**: [Yes/No]
- **Fallback code**: [Yes/No]
```

### Step 7: Breakage Analysis

Check: impacted functionality, user‑visible behavior changes

```markdown
## Step 7: Breakage Analysis
**Conclusion**: [PASS / WARNING / CRITICAL]
- **User‑visible behavior changes**: [Yes/No]
```

### Step 8: Test Review

Check: test coverage and effectiveness

```markdown
## Step 8: Test Review
**Conclusion**: [PASS / WARNING / CRITICAL]
```

---

## Phase 3: Summary Evaluation

```markdown
## Summary Evaluation

### Taste Score
[Good / OK / Bad]

### Step Summary
| Step | Conclusion |
|------|------|
| Design | [PASS/WARNING/CRITICAL] |
| Complexity | [PASS/WARNING/CRITICAL] |
| Code Structure | [PASS/WARNING/CRITICAL] |
| Naming/Comments | [PASS/WARNING/CRITICAL] |
| Error Handling | [PASS/WARNING/CRITICAL] |
| Breakage | [PASS/WARNING/CRITICAL] |
| Tests | [PASS/WARNING/CRITICAL] |

### Critical Issues
[Top 1–3 most severe issues with code references]

### Improvement Suggestions
- Current: [code snippet]
- Suggested: [rewritten snippet]
```
