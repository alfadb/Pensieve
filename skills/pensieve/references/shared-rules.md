# Shared Rules

Cross-cutting hard rules for all tools. Each tool file references this document instead of inlining rules.

## Version-Related Routing (Hard Rule)

`upgrade` is responsible only for version actions; `migrate` is responsible only for migration actions; neither is responsible for project health-check conclusions.

- When "update version/plugin compatibility issues" are involved, route to `upgrade`.
- When "migrate old data/clean up old residue" is involved, route to `migrate`.
- `init` / `doctor` / `self-improve` / `loop` do not require `upgrade` or `migrate` to run first.
- Project health check (PASS/FAIL, MUST_FIX/SHOULD_FIX) is output exclusively by `doctor`.
- After `init` completes, `doctor` must be run once.
- Recommended order (as needed): `upgrade` (version only) → `migrate` (migration only) → `doctor` (health check) → `self-improve` (capture lessons).

## Confirm Before Executing (Hard Rule)

When the user has not explicitly issued a tool command, confirm with one sentence before executing. Auto-starting based on candidate intent is prohibited.

- Loop Phase 2 context summary must be confirmed by the user before entering Phase 3.
- Self-Improve can write directly when explicitly triggered or pipeline-triggered, with no extra confirmation needed.
- Write operations follow each tool's own spec; no additional global "draft then write" hard constraint is imposed.

## Semantic Link Rules (Hard Rule)

Three link relationship types: `based-on` / `leads-to` / `related`.

Association strength requirements:
- `decision`: **at least one valid `[[...]]` link is required**
- `pipeline`: **at least one valid `[[...]]` link is required**
- `knowledge`: links are recommended (may be empty)
- `maxim`: source links are recommended (may be empty)

If a loop output becomes a `decision` or `pipeline`, links must be filled in before wrap-up.

## Data Boundary

- **System capabilities** (updated with the plugin): `<SYSTEM_SKILL_ROOT>/` (`skills/pensieve/` inside the plugin, managed by the plugin)
  - Contains tools / scripts / system knowledge / format READMEs
  - Does not contain built-in pipelines / maxims content
- **User data** (project-level, not overwritten by default): `<USER_DATA_ROOT>/` (`<project>/.claude/skills/pensieve/`)
  - Only exception: `migrate` may back up then overwrite key files (`run-when-*.md`, `knowledge/taste-review/content.md`) when aligning content.
  - Full directory structure in `<SYSTEM_SKILL_ROOT>/references/directory-layout.md`

Path conventions (injected by SessionStart hook):
- `<SYSTEM_SKILL_ROOT>` = absolute path to `skills/pensieve/` inside the plugin
- `<USER_DATA_ROOT>` = absolute path to project-level `.claude/skills/pensieve/`

## Spec Source (Read Before Write)

Before creating or checking any type of user data, read the corresponding format spec README:

1. `<SYSTEM_SKILL_ROOT>/maxims/README.md`
2. `<SYSTEM_SKILL_ROOT>/decisions/README.md`
3. `<SYSTEM_SKILL_ROOT>/pipelines/README.md`
4. `<SYSTEM_SKILL_ROOT>/knowledge/README.md`

Constraints:
- If the spec does not explicitly state `must / required / hard rule / at least one`, it must not be classified as MUST_FIX.
- Limited inference based on the spec is allowed, but must be labeled as "inferred item".

## State Machine (Hard Rule)

User data state is determined by a shared engine to avoid per-tool ad-hoc inference:

- `EMPTY`: root directory or key category directories are missing
- `SEEDED`: directories exist, but key seed files are missing
- `ALIGNED`: no MUST_FIX issues
- `DRIFTED`: MUST_FIX issues exist (but not `EMPTY/SEEDED`)

Constraints:
- State determination is implemented by the core module (`tools/core/pensieve_core.py`); tool-side code must not re-implement a separate set of state-determination if-branches.

## Confidence Requirements (Pipeline Output Quality)

Each candidate issue in pipeline output is tagged with a confidence score (0-100):

| Range | Action |
|------|------|
| >= 80 | Include in the final report |
| 50-79 | Label as "to be verified", do not present as a definitive conclusion |
| < 50 | Discard |

Only issues with >= 80 confidence are reported as definitive conclusions.
