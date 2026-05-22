---
phase: 23-governed-promotion-apply
plan: 03
subsystem: backend
tags: [promotion, governance, scheduling, ecto, fake]
requires:
  - phase: 23-governed-promotion-apply
    provides: governed promotion vocabulary and persisted bundle snapshots
provides:
  - stored-snapshot execution for approved governed promotions
  - schedule-time revalidation for protected-target promotion execution
  - Ecto/Fake parity for governed and scheduled promotion execution
affects: [23-governed-promotion-apply, governance, scheduling, rulestead]
tech-stack:
  added: []
  patterns: [execute-reviewed-snapshot, scheduled revalidation, contract-schema bootstrap]
key-files:
  created: []
  modified:
    - rulestead/lib/rulestead/promotion/apply.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs
key-decisions:
  - "Approved governed promotion executes the stored reviewed bundle snapshot instead of recomputing a fresh compare."
  - "Scheduled promotion revalidates compare freshness at execution time before any target mutation."
patterns-established:
  - "Protected-target governed execution reuses the shared promotion apply path with targeted safety overrides only for the governance gate."
  - "Contract tests that hand-roll schema must explicitly track newly introduced persistence artifacts and constraints."
requirements-completed: [PROM-03, PROM-04]
duration: 1h20m
completed: 2026-05-18
---

# Phase 23: Governed Promotion Apply Summary

**Approved and scheduled protected-target promotion now execute from the reviewed snapshot, with scheduled runs revalidating freshness before mutation**

## Performance

- **Duration:** 1h20m
- **Completed:** 2026-05-18
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Wired governed promotion execution in both adapters to rebuild an `ApplyPromotion` command from stored `command_snapshot` data.
- Split approved execution from scheduled execution semantics: approved change requests apply the stored snapshot, while scheduled executions re-run stale-preview checks.
- Extended the scheduled execution contract helper schema so promotion constraints and `environment_versions` exist during adapter tests.

## Task Commits

No commits were created in this workspace run because the repository already contained unrelated user and build-tree changes.

## Files Created/Modified

- `rulestead/lib/rulestead/promotion/apply.ex` - added governed snapshot validation entrypoint alongside compare-based validation
- `rulestead/lib/rulestead/store/ecto.ex` - added governed/scheduled promotion execution wiring and shared apply reuse
- `rulestead/lib/rulestead/fake.ex` - matched governed/scheduled promotion execution semantics in the fake adapter
- `rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs` - added protected-target execution tests and completed test schema bootstrap

## Decisions Made

- Treated approved change-request execution as execution of already-reviewed intent, not a fresh compare review.
- Preserved schedule-time revalidation so delayed execution still fails safely on stale promotion previews.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired test bootstrap constraints for promotion governed actions**
- **Found during:** scheduled execution adapter verification
- **Issue:** the contract helper created or reused old check constraints that rejected `promote_environment`
- **Fix:** replaced the governed-action constraints idempotently inside the helper
- **Files modified:** `rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Verification:** `cd rulestead && mix test test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Committed in:** not committed

**2. [Rule 3 - Blocking] Added missing `environment_versions` test schema bootstrap**
- **Found during:** governed promotion execution verification
- **Issue:** Ecto execution now persisted immutable environment versions, but the contract helper never created the table
- **Fix:** added the minimal `environment_versions` table and unique index to the helper bootstrap
- **Files modified:** `rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Verification:** `cd rulestead && mix test test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Committed in:** not committed

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Required to make the contract harness reflect the current persistence boundary. No scope expansion.

## Issues Encountered

- The initial governed execution path treated approved change requests like delayed schedules and incorrectly failed on stale preview revalidation. The execution contract was split so approved requests apply the stored reviewed snapshot while scheduled executions retain freshness checks.

## User Setup Required

None for review. Ecto environments still need the already-added migrations applied.

## Next Phase Readiness

- Promotion audit linkage and environment-version reapply can now build on a stable governed execution spine.
- Mounted admin review screens can rely on exact stored bundle state for protected-target detail rendering.

---
*Phase: 23-governed-promotion-apply*
*Completed: 2026-05-18*
