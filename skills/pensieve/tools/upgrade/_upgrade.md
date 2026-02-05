# Upgrade Tool

---
description: Guide user data upgrade to project-level `.claude/pensieve/` structure
---

You are the Upgrade Tool. Your job is to **explain the ideal user data directory structure** and guide how to migrate data from the old structure to the new one. You do not decide user content; you only define paths and rules.

## Target Structure (Project-Level, Never Overwritten by Plugin)

```
<project>/.claude/pensieve/
  maxims/      # user/team maxims (e.g. custom.md)
  decisions/   # decision records (ADR)
  knowledge/   # user references
  pipelines/   # project-level pipelines
  loop/        # loop artifacts (one dir per loop)
```

## Migration Principles

- **System capability lives inside the plugin**: contents under `<SYSTEM_SKILL_ROOT>/` are updated via plugin updates; do not move or overwrite.
- **Old system files are no longer needed**: system-built files in old locations can be removed after migration (only delete old copies in the project; never touch plugin internals).
- **User data is project-level**: migrate only user‑authored content into `.claude/pensieve/`.
- **Do not overwrite existing user data**: if target files exist, keep them; add suffixes or ask for confirmation.
- **Preserve structure**: keep subdirectory hierarchy and filenames as much as possible.
- **Seed initial content from templates**: initial maxims and pipeline templates are stored in the plugin and copied during upgrade/init.
- **If versions diverge**: when user files differ from system versions, **read both versions first**, then read the README in that directory, and merge/migrate **according to the README’s rules**.

## Common Old Locations for “User Data”

May exist in:

- `skills/pensieve/` or its subdirectories inside the project repo
- User‑placed `maxims/`, `decisions/`, `knowledge/`, `pipelines/`, `loop/` folders

### What to migrate

- **User‑authored files** (non‑system):
  - `maxims/custom.md` or other files without `_` prefix
  - `decisions/*.md`
  - `knowledge/*`
  - `pipelines/*.md`
  - `loop/*`

> Older versions shipped `maxims/_linus.md` and `pipelines/review.md` inside the plugin. If you still use them, copy their content into:
> - `.claude/pensieve/maxims/custom.md` (maxims)
> - `.claude/pensieve/pipelines/review.md` (pipeline)
> Then delete the old copies to avoid future overwrite.

### Template Locations (Plugin)

- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/maxims.initial.md`
- `<SYSTEM_SKILL_ROOT>/tools/upgrade/templates/pipeline.review.md`

### What NOT to migrate

- **System files** (usually prefixed with `_`):
  - `pipelines/_*.md`
  - `maxims/_*.md`
  - system knowledge (plugin‑managed)
  - system README/templates/scripts from old locations

## Clean Up Old System Files (Project Only)

After migration, delete old system copies inside the project to avoid confusion (**project copies only**):

- `<project>/skills/pensieve/` (old versions placed system capabilities in repo)
- `<project>/.claude/skills/pensieve/` (old versions placed skill in project)
- System README and `_*.md` prompts in old locations

> If unsure whether a file is an old system copy, back it up before deleting.

## Migration Steps (Best done by an LLM)

1. Scan old locations for user content (using “What to migrate” rules)
2. Create target directories:
   - `mkdir -p .claude/pensieve/{maxims,decisions,knowledge,pipelines,loop}`
3. **Merge maxims**:
   - If `.claude/pensieve/maxims/custom.md` is missing → copy from template
   - If it exists and old maxims exist → append with a “migrated content” marker
4. **Migrate the preset pipeline (must compare content)**:
   - If `.claude/pensieve/pipelines/review.md` is missing → copy from template
   - If it exists → **read and compare**:
     - Same content → skip
     - Different → create `review.migrated.md`, and add a merge note at the top of `review.md` or append the diff
5. Move/copy user files to target directories (preserve relative structure)
6. On conflicts (same filename):
   - **Do not skip**; always read and decide whether to merge
   - Same content → skip
   - Different → append to existing file with a “migrated content” marker, or create `*.migrated.md` and prompt for merge
7. Clean up old system files (see list above)
8. Output a migration report (old path → new path)

## Plugin Update Commands (Two Steps)

After migration, run in this order:

```bash
claude plugin marketplace update pensieve-claude-plugin
claude plugin update pensieve@pensieve-claude-plugin --scope user
```

## Constraints

- Do not delete system files
- Do not modify plugin system content
- Only operate on user data
