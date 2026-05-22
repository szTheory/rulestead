---
phase: 23-governed-promotion-apply
plan: 01
subsystem: backend
tags: [promotion, store, ecto, fake, snapshots, history]
requires:
  - phase: 22-environment-compare-conflict-model
    provides: canonical compare payload, compare token semantics, and dependency closure review truth
provides:
  - direct promotion apply facade backed by compare revalidation
  - immutable environment-version persistence for authored promotion history
  - transactional Ecto/Fake promotion apply parity with runtime snapshot regeneration
affects: [23-governed-promotion-apply, rulestead]
tech-stack:
  added: [ecto schema, ecto migration]
  patterns: [compare-before-mutate, immutable authored history, adapter contract parity]
key-files:
  created:
    - rulestead/lib/rulestead/environment_version.ex
    - rulestead/lib/rulestead/promotion/apply.ex
    - rulestead/priv/repo/migrations/20260518193000_create_rulestead_environment_versions.exs
    - rulestead/test/rulestead/environment_version_test.exs
    - rulestead/test/rulestead/promotion/apply_test.exs
    - rulestead/test/rulestead/store/promotion_apply_contract_test.exs
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/store/redis.ex
key-decisions:
  - "Kept apply as a first-class backend command so later governed and admin flows can reuse one mutation contract."
  - "Persisted authored environment versions separately from runtime snapshots so re-apply history stays distinct from runtime publication artifacts."
  - "Required both Ecto and Fake to return the same apply result shape before moving to later governed slices."
patterns-established:
  - "Promotion apply revalidates compare context before any mutation and rejects protected targets in the direct path."
  - "One successful apply writes authored target state, immutable environment history, and the regenerated runtime snapshot as one authoritative transaction."
requirements-completed: [PROM-03]
duration: 2h10m
completed: 2026-05-18
---

# Phase 23: Governed Promotion Apply Summary

**Shipped the direct promotion apply backend contract for non-protected targets, including immutable authored history and adapter-parity coverage**

## Performance

- **Duration:** 2h10m
- **Completed:** 2026-05-18
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added `Rulestead.apply_promotion/1` and `/2` as the public direct-apply facade, backed by a new `Rulestead.Store.Command.ApplyPromotion` command and `Rulestead.Promotion.Apply` compare revalidation module.
- Added `Rulestead.EnvironmentVersion` plus a migration so every successful apply records immutable authored target state and promotion linkage metadata.
- Implemented transactional direct apply in `Rulestead.Store.Ecto` and matching in-memory behavior in `Rulestead.Fake`, including authored target mutation, environment-version insertion, and target runtime snapshot regeneration.
- Added targeted tests for apply normalization, stale-preview rejection, environment-version persistence, and adapter parity.

## Task Commits

No commits were created in this workspace run. The repository already contained unrelated user and build-tree changes, so the Phase 23 slice was left uncommitted to avoid bundling external modifications into the execution artifact.

## Files Created/Modified

- `rulestead/lib/rulestead.ex` - added the public promotion apply facade
- `rulestead/lib/rulestead/store.ex` - extended the store behavior with `apply_promotion/1`
- `rulestead/lib/rulestead/store/command.ex` - added the first-class `ApplyPromotion` command contract
- `rulestead/lib/rulestead/promotion/apply.ex` - added compare revalidation and canonical bundle normalization
- `rulestead/lib/rulestead/environment_version.ex` - added immutable authored history schema and validation
- `rulestead/lib/rulestead/store/ecto.ex` - added transactional direct apply, environment-version persistence, and snapshot regeneration
- `rulestead/lib/rulestead/fake.ex` - added direct apply parity, in-memory environment-version storage, and ruleset/value normalization
- `rulestead/lib/rulestead/store/redis.ex` - added the read-only unsupported callback stub for promotion apply
- `rulestead/priv/repo/migrations/20260518193000_create_rulestead_environment_versions.exs` - created the persistence boundary for authored environment versions
- `rulestead/test/rulestead/promotion/apply_test.exs` - apply normalization and stale-preview coverage
- `rulestead/test/rulestead/environment_version_test.exs` - environment-version schema coverage
- `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` - Ecto/Fake contract parity coverage

## Decisions Made

- Kept the direct path explicitly blocked for protected targets so Phase 23 governance work can layer on top without weakening PROM-04.
- Stored authored promotion bundles in normalized map form for environment-version history while recasting rulesets through schema boundaries for adapter parity on fetch.
- Matched Fake to Ecto at the contract boundary instead of loosening the tests, which keeps later governed slices honest.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired fake adapter nested environment-version writes**
- **Found during:** contract-test verification
- **Issue:** first promotion apply into an environment crashed because the fake adapter wrote into a missing nested map
- **Fix:** switched the state update to `Map.update` semantics, mirroring runtime snapshot storage
- **Files modified:** `rulestead/lib/rulestead/fake.ex`
- **Verification:** `mix test test/rulestead/store/promotion_apply_contract_test.exs --trace`
- **Committed in:** not committed

**2. [Rule 3 - Blocking] Normalized fake ruleset payloads to match the Ecto contract**
- **Found during:** adapter parity verification
- **Issue:** fake apply stored recast rules and embedded values in a shape that drifted from fetched Ecto payloads
- **Fix:** recast promoted rulesets through `Ruleset.changeset/2` and normalized embedded value maps during serialization
- **Files modified:** `rulestead/lib/rulestead/fake.ex`
- **Verification:** `mix test test/rulestead/store/promotion_apply_contract_test.exs --trace`
- **Committed in:** not committed

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Improved adapter parity only. No scope expansion.

## Issues Encountered

- The initial delegated execution only partially completed the slice, so the remaining store implementation and verification were finished in the main context.
- Targeted test runs emit the existing `Rulestead.AllowPolicy` test-support redefinition warning; it did not affect the promotion apply behavior.

## User Setup Required

None for code review. The new migration must still be run in environments that use the Ecto store.

## Next Phase Readiness

- Phase 23 can now add governed submission, scheduling, audit linkage, and re-apply flows on top of one reusable backend apply contract.
- The direct path already returns the compare token, applied flag scope, immutable environment version id/version, and runtime snapshot version needed for later governance and admin surfaces.

---
*Phase: 23-governed-promotion-apply*
*Completed: 2026-05-18*
