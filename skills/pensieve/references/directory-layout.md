# Project-Level Directory Conventions

For structure migration history and determination rules, see `tools/doctor/migrations/README.md` (single source of truth).

## Current Target Structure

Only active root directory: `<project>/.claude/skills/pensieve/`

```
.claude/skills/pensieve/
  maxims/      # Team maxims (one standalone file per maxim)
  decisions/   # Decision records (ADR, date-conclusion naming)
  knowledge/   # External reference knowledge (one subdirectory/content.md per topic)
  pipelines/   # Project-level pipelines (must use run-when-*.md naming)
  loop/        # Loop execution artifacts (one date-slug directory per loop run)
```

## Key Seed Files

Seeded during initialization by `init` (idempotent, never overwrites existing files):

- `pipelines/run-when-reviewing-code.md` — code review workflow
- `pipelines/run-when-committing.md` — commit workflow
- `knowledge/taste-review/content.md` — review knowledge base
- `maxims/*.md` — initial maxims (seeded from templates)

## Auto-Maintained Files

- `SKILL.md` — project-level routing + graph (auto-updated by tools)
- `~/.claude/projects/<project>/memory/MEMORY.md` — Claude Code auto memory entry (auto-maintains Pensieve guidance block)

## Legacy Paths (deprecated)

The following paths are remnants from older versions and should be cleaned up after migration:

- `<project>/skills/pensieve/` — old mixed system+user data directory
- `<project>/.claude/pensieve/` — early user data directory
- `<user-home>/.claude/skills/pensieve/` — old user-level data directory (should be deleted)
- `<user-home>/.claude/pensieve/` — earlier user-level data directory (should be deleted)
- `<project>/.claude/skills/pensieve/{_pensieve-graph.md,pensieve-graph.md,graph.md}` — old standalone graph files (should be deleted)
