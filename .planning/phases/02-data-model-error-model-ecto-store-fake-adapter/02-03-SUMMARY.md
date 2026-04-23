---
phase: 02-data-model-error-model-ecto-store-fake-adapter
plan: 03
subsystem: database
tags: [elixir, ecto, postgres, schemas, rulesets, migrations]
requires:
  - phase: 02-01
    provides: repo, sandbox, and migration-capable test harness
  - phase: 02-02
    provides: key-first store contract and error taxonomy
provides:
  - relational authoring schemas for flags, environments, audiences, and audit history
  - immutable per-environment ruleset versions with embedded ordered rule documents
  - authoring-store migrations with UUID defaults, uniqueness constraints, and default environment seeds
affects: [phase-02-adapters, phase-03-evaluator, phase-06-admin]
tech-stack:
  added: []
  patterns: [relational flag identity plus environment joins, immutable ruleset versions, embedded ordered rule graph]
key-files:
  created:
    - rulestead/lib/rulestead/flag.ex
    - rulestead/lib/rulestead/environment.ex
    - rulestead/lib/rulestead/flag_environment.ex
    - rulestead/lib/rulestead/audience.ex
    - rulestead/lib/rulestead/audit_event.ex
    - rulestead/lib/rulestead/ruleset.ex
    - rulestead/lib/rulestead/ruleset/rule.ex
    - rulestead/lib/rulestead/ruleset/condition.ex
    - rulestead/lib/rulestead/ruleset/variant.ex
    - rulestead/lib/rulestead/ruleset/rollout.ex
    - rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs
    - rulestead/priv/repo/migrations/20260423020200_seed_default_environments.exs
  modified:
    - .planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-03-SUMMARY.md
key-decisions:
  - "Keep one canonical flags table and one flag_environments join table so environment behavior diverges without duplicating the flag identity."
  - "Persist the ruleset as a versioned row per flag_environment with embedded ordered rule documents rather than normalizing rules into standalone tables."
  - "Enforce published-ruleset immutability and append-only audit rows in the database so later adapters inherit the same correctness boundary."
patterns-established:
  - "Schema Pattern: thin Ecto schemas own fields, associations, embeds, and validation only."
  - "Ruleset Pattern: rules, conditions, variants, and rollout config live inside the rulesets document boundary."
  - "Migration Pattern: authoring tables use UUID primary keys with database defaults and explicit constraint coverage for public invariants."
requirements-completed: [STORE-01, ADMIN-08]
duration: 6 min
completed: 2026-04-23
---

# Phase 2 Plan 03 Summary

**Authoring-store schemas and migrations for shared flag identity, per-environment activation, and immutable embedded ruleset versions**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-23T18:57:30Z
- **Completed:** 2026-04-23T19:03:25Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added relational schemas for canonical flags, explicit environments, per-environment behavior anchors, reusable audiences, and append-only audit history rows.
- Added versioned `Ruleset` storage with embedded ordered `Rule`, `Condition`, `Variant`, and `Rollout` documents plus changeset validation for audience references, rollout shape, and 100-weight variants.
- Added Phase 2 authoring migrations with `gen_random_uuid()` defaults, uniqueness and enum-like check constraints, published-ruleset immutability protection, append-only audit triggers, and idempotent default environment seeds.

## Task Commits

1. **Task 1: Create the relational authoring schemas around flag identity and environment scope** - `dfe81f1` (`feat`)
2. **Task 2: Create immutable ruleset schemas with embedded ordered rule graphs** - `8c1e7ca` (`feat`)
3. **Task 3: Add migrations for authoring tables, constraints, and default environments** - `7705db8` (`feat`)

## Files Created/Modified

- `rulestead/lib/rulestead/flag.ex` - Canonical flag identity, lifecycle fields, and global validations.
- `rulestead/lib/rulestead/environment.ex` - First-class environment schema supporting seeded and host-defined keys.
- `rulestead/lib/rulestead/flag_environment.ex` - Per-environment activation row linking one flag to one environment and one active ruleset.
- `rulestead/lib/rulestead/audience.ex` - Reusable relational audience definition store.
- `rulestead/lib/rulestead/audit_event.ex` - Append-oriented audit row shape for later authoring history.
- `rulestead/lib/rulestead/ruleset.ex` - Immutable per-environment ruleset version with embedded JSON-backed rule graph.
- `rulestead/lib/rulestead/ruleset/rule.ex` - Ordered rule schema with strategy-specific validation.
- `rulestead/lib/rulestead/ruleset/condition.ex` - Embedded condition predicate schema.
- `rulestead/lib/rulestead/ruleset/variant.ex` - Embedded variant schema with weight validation.
- `rulestead/lib/rulestead/ruleset/rollout.ex` - Embedded rollout config with bucket strategy and percentage validation.
- `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs` - Authoring tables, constraints, and immutability triggers.
- `rulestead/priv/repo/migrations/20260423020200_seed_default_environments.exs` - Idempotent seed for development, staging, production, and test environments.
- `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-03-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Scoped ruleset versions to `flag_environment` so publication remains environment-specific while preserving one canonical flag identity.
- Used embedded schemas for rule documents and relational tables for reusable entities to match the locked Phase 2 hybrid boundary.
- Chose database triggers for published ruleset immutability and audit-event append-only protection because these are correctness guarantees, not adapter conventions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing schema `t()` types referenced by changeset specs**
- **Found during:** Task 1 (Create the relational authoring schemas around flag identity and environment scope)
- **Issue:** The initial schema modules referenced `t()` in `@spec` declarations without defining the type, which caused compilation to fail.
- **Fix:** Added `@type t :: %__MODULE__{}` to each new relational schema module.
- **Files modified:** `rulestead/lib/rulestead/flag.ex`, `rulestead/lib/rulestead/environment.ex`, `rulestead/lib/rulestead/flag_environment.ex`, `rulestead/lib/rulestead/audience.ex`, `rulestead/lib/rulestead/audit_event.ex`
- **Verification:** `cd rulestead && mix compile`
- **Committed in:** `dfe81f1` (part of Task 1 commit)

**2. [Rule 1 - Bug] Reworked ruleset publish validation to avoid guard-time `get_field/2` compilation**
- **Found during:** Task 2 (Create immutable ruleset schemas with embedded ordered rule graphs)
- **Issue:** The first `Ruleset` implementation used `get_field/2` inside a guard, which Elixir does not allow.
- **Fix:** Moved `status` and `published_at` reads into normal control flow before the `case` expression.
- **Files modified:** `rulestead/lib/rulestead/ruleset.ex`
- **Verification:** `cd rulestead && mix compile`
- **Committed in:** `8c1e7ca` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bug fixes)
**Impact on plan:** Both fixes were required for the owned schema files to compile. No scope creep beyond the plan’s authoring model.

## Issues Encountered

- The plan’s targeted schema smoke files (`test/rulestead/schema/*.exs`) do not exist in the current repo state, so verification fell back to `mix compile`, `MIX_ENV=test mix ecto.drop/create/migrate`, and the existing ExUnit suite.
- Database tasks require `MIX_ENV=test` in this repo because only `config/test.exs` defines the repo database settings.
- A parallel `git commit` attempt briefly hit `.git/index.lock`; the remaining task commit was retried serially after the other commit completed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 2 now has the persistent authoring boundary the fake and Ecto adapters can share.
- The next plans can implement adapter behavior against stable table names, association shapes, and ruleset validation semantics without reopening the data model.

## Self-Check: PASSED

- Found `rulestead/lib/rulestead/flag.ex`
- Found `rulestead/lib/rulestead/environment.ex`
- Found `rulestead/lib/rulestead/flag_environment.ex`
- Found `rulestead/lib/rulestead/ruleset.ex`
- Found `rulestead/priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs`
- Found `rulestead/priv/repo/migrations/20260423020200_seed_default_environments.exs`
- Found commit `dfe81f1`
- Found commit `8c1e7ca`
- Found commit `7705db8`

---
*Phase: 02-data-model-error-model-ecto-store-fake-adapter*
*Completed: 2026-04-23*
