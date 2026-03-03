# Tool Boundaries

Each tool has a clear scope of responsibility. When routed to the wrong tool, redirect according to this table.

## Scope of Responsibility

| Tool | Responsible for | Not responsible for |
|------|------|--------|
| `upgrade` | Version sync + plugin config key alignment | Does not give PASS/FAIL, does not perform structure migration or per-file semantic review |
| `migrate` | Structure migration + key file alignment + residue cleanup | Does not update plugin versions, does not give PASS/FAIL |
| `doctor` | Read-only check + compliance report | Does not modify user data files, does not perform migration (only auto-maintains `SKILL.md` and auto memory `MEMORY.md` guidance block) |
| `self-improve` | Capture lessons into four types of user data | Does not perform migration/checks |
| `init` | Initialize project directories + seed files + baseline exploration and code review (read-only) | Does not perform migration cleanup, does not write captured lessons directly |
| `loop` | Decompose complex tasks + sub-agent iterative execution | Small tasks run directly, do not open loop |

## Routing Quick Reference

| User intent | Correct tool | Common misroute |
|----------|----------|-----------|
| Update plugin version / plugin compatibility issue | `upgrade` | `init`, `doctor`, `migrate` |
| Migrate old data / clean old paths / key file alignment | `migrate` | `upgrade`, `init` |
| New project first-time setup / fill seed files / generate initial review baseline | `init` | `upgrade` (unless legacy data exists) |
| Compliance check after initialization | `doctor` (required) | Skipping doctor and going straight to development |
| Compliance check / PASS-FAIL graded report | `doctor` | `upgrade`, `self-improve` |
| Capture lessons / write maxim / decision / pipeline | `self-improve` | `doctor`, `upgrade` |
| Complex task decomposition and auto-execution | `loop` | Direct execution (for small tasks) |
| Execute a specific pipeline | `loop` (load pipeline) | Direct execution (should go through loop) |

## Negative Examples

| User says | Should NOT | Should redirect to |
|--------|------|------|
| "There's an old skills/pensieve/ in the project, migrate it for me" | Continue init | `migrate` |
| "Give me a PASS/FAIL check result first" | init or upgrade giving the conclusion | `doctor` |
| "After init, write the candidates directly into knowledge/decision" | init writes directly | `self-improve` |
| "Run doctor first, then decide whether to migrate" | Force switching to `migrate` first | `doctor` (if report flags migration/old paths/old keys, then run `migrate`) |
| "Check and fix at the same time" | doctor batch-modifying user data files | First `doctor` to report, then fix manually (only `SKILL.md`/auto memory auto-maintained) |
| "Capture everything from this session automatically, no confirmation needed" | Auto-capture | `self-improve` (can write directly) |
| "Change 1 copy file, also run loop" | Open loop | Complete directly |
| "Version is already latest, proceed directly to migration" | Bypass version check | Stop and ask about `doctor` self-check |
| "Skip the quick check and give me PASS directly" | Skip frontmatter quick check | Must run `check-frontmatter.sh` first |
| "Haven't confirmed the requirements yet, create 10 tasks first" | Skip confirmation and split directly | Confirm the goal first, then generate tasks |
| "While you're at it, migrate the old directories too" | self-improve performs migration | `migrate` |
| "During migration, also give me a PASS/FAIL verdict" | migrate gives compliance conclusion | First `migrate`, then `doctor` |
