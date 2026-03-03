---
description: Version upgrade and plugin configuration key alignment. Only performs version comparison, pulls latest, and cleans up plugin keys; no structural migration or pre-upgrade health check. After upgrade completes, guides the user to manually run doctor.
---

# Upgrade Tool

> Tool boundaries: see `<SYSTEM_SKILL_ROOT>/references/tool-boundaries.md` | Shared rules: see `<SYSTEM_SKILL_ROOT>/references/shared-rules.md`

## Tool Contract

### Use when
- User requests upgrading Pensieve
- User requests confirming pre/post upgrade version changes
- User requests fixing plugin compatibility or enabledPlugins key drift

### Failure fallback
- `claude` command unavailable: stop and return installation/environment issue
- Version pull failed: return failure log path, stop subsequent actions
- settings.json syntax error: output warning and preserve original file

## Execution Principles (Simplified)
1. **Script results are the source of truth**: the summary/report from `run-upgrade.sh` is the sole fact source; do not add manual inference.
2. **No pre-upgrade structure checks**: the upgrade stage does not run doctor, does not output PASS/FAIL.
3. **Upgrade only does version actions**: version comparison, pull latest, plugin key / old plugin name cleanup.
4. **Doctor is post-upgrade**: after upgrade completes, only guide the user to manually run doctor.
5. **Structural migration goes through migrate**: old path migration, key file alignment, and residue cleanup are handled by `migrate`.

## Standard Execution

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/run-upgrade.sh
```

Optional: dry run only (no writes)

```bash
bash <SYSTEM_SKILL_ROOT>/tools/upgrade/scripts/run-upgrade.sh --dry-run
```

## Output Requirements

After upgrade completes, must output:
- Pre-upgrade version and post-upgrade version
- Whether a version change occurred
- Plugin configuration alignment statistics
- Report and summary file paths
- Clear next-step command (manually run doctor):

```bash
bash <SYSTEM_SKILL_ROOT>/tools/doctor/scripts/run-doctor.sh --strict
```

## Constraints
- Upgrade must not invoke doctor during execution
- Upgrade must not output doctor-grade conclusions (PASS/PASS_WITH_WARNINGS/FAIL)
- Upgrade must not perform user data structural migration (migration must go through `migrate`)
