---
description: Structural migration and legacy residue cleanup. Only handles user data directory migration, key seed file alignment, and historical residue cleanup; no version upgrade or health check grading.
---

# Migrate Tool

> Tool boundaries: see `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | Shared rules: see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

## Tool Contract

### Use when
- User requests migrating legacy version user data
- User requests cleaning up old paths / old graph / old README residue
- Doctor reports migration-type MUST_FIX (old path coexistence, key file drift, historical residue not cleaned up)

### Failure fallback
- Migration conflict: output `*.migrated.*` file list, require manual merge
- Template missing: stop and suggest fixing plugin installation
- File system write failure: output failed paths and retry command

## Execution Principles
1. **Only does structural migration**: directory migration, key file alignment, residue cleanup.
2. **No version actions**: does not execute marketplace/plugin update.
3. **No health check conclusions**: does not output PASS/PASS_WITH_WARNINGS/FAIL.
4. **Doctor is post-migration**: after migration completes, guide the user to manually run doctor.

## Standard Execution

```bash
bash <SYSTEM_SKILL_ROOT>/tools/migrate/scripts/run-migrate.sh
```

Optional: dry run only (no writes)

```bash
bash <SYSTEM_SKILL_ROOT>/tools/migrate/scripts/run-migrate.sh --dry-run
```

## Output Requirements

After migration completes, must output:
- Directory/file migration statistics
- Conflict file list (if any)
- Report and summary paths
- Clear next-step command (manually run doctor):

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/run-doctor.sh --strict
```
