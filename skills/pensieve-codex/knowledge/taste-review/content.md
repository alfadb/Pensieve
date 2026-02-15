# Taste Review Knowledge Base

Core philosophy, warning signs, and classic examples for code review.

## Sources

- Linus Torvalds TED Talk + Linux Kernel Coding Style
- John Ousterhout — "A Philosophy of Software Design"
- Google Engineering Practices

## Supporting Resources

The `source/` directory can hold project‑specific references. Pull language‑specific style guides from the official repository:

**Google Style Guides**: https://github.com/google/styleguide

| Language | File |
|----------|------|
| C++ | `cppguide.html` |
| Java | `javaguide.html` |
| Python | `pyguide.md` |
| JavaScript | `jsguide.html` |
| TypeScript | `tsguide.html` |
| Shell | `shellguide.md` |
| C# | `csharp-style.md` |

Example: if the project uses Python and TypeScript, you can pull the guides:
```bash
mkdir -p source/google-style-guides
curl -o source/google-style-guides/pyguide.md https://raw.githubusercontent.com/google/styleguide/gh-pages/pyguide.md
curl -o source/google-style-guides/tsguide.html https://raw.githubusercontent.com/google/styleguide/gh-pages/tsguide.html
```

## Summary

Code review references from three sources: Linus’ taste philosophy, Ousterhout’s complexity management, and Google’s code health standards.

## When to Use

- You need theoretical grounding for code review
- You want to justify code quality conclusions with known engineering standards
- You want shared vocabulary for reviewing changes

---

# Linus: Taste Philosophy

## Core Quote

> "I'm a big believer in 'taste'. It's not about rules. It's about knowing what to do."

### What “Taste” Means

- Seeing the simple design hidden inside complexity
- Avoiding unnecessary special cases
- Preferring solutions that make problems disappear structurally
- Making code obvious to the next reader

## Common Taste Signals (Good)

- The code reads like a story with a single clear path
- The “default path” handles most cases without branching
- Data structures match the problem shape
- Interfaces make invalid states unrepresentable

## Common Taste Smells (Bad)

- Many branches for “one more edge case”
- Deep indentation / nested conditions
- Functions that both parse, validate, transform, and output
- Workarounds that patch symptoms downstream
- Adding abstraction “just in case”

## Linus-style Heuristics

1. **If you need more than 3 levels of indentation, you're screwed.**
2. **Special cases are poison.** Rewrite so they go away.
3. **Data structure matters more than code.** Change the shape, simplify the logic.
4. **Talk is cheap. Show me the code.**

---

# Ousterhout: Complexity

## Definition

Complexity is anything that makes it harder to understand or modify a system.

## Symptoms

- “Unknown unknowns” — hidden side effects
- “Information overload” — too much to hold in head at once
- “Inconsistency” — similar things done in different ways

## Strategy

- Pull complexity out of callers into the module that owns the knowledge
- Use clear, stable abstractions
- Avoid “tactical programming” that ships local hacks

---

# Google: Code Health

## Principles

- Correctness first
- Readability is a feature
- Maintainability matters more than cleverness

## Review Focus

- Does it work as intended?
- Is it easy to understand?
- Is it consistent with existing patterns?
- Does it add tests where behavior matters?

---

# Practical Review Checklist

## 1) Behavior & Contracts

- Any user-visible behavior change? Was it explicitly intended?
- API/CLI/UX contracts stable?
- Error handling consistent and actionable?

## 2) Structure & Data Flow

- Can special cases be removed by redesigning input/data shape?
- Can branches be reduced by normalizing data earlier?
- Is the “happy path” obvious?

## 3) Naming & Readability

- Names reflect responsibilities?
- Functions do one thing?
- Indentation shallow?

## 4) Tests & Verification

- Tests cover stable behavior users rely on?
- Fast local checks exist (unit tests / lint / typecheck)?

## 5) Risk & Rollout

- Any migration concerns?
- Backward compatibility?
- Feature flags needed?

