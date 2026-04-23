---
phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
plan: 01
subsystem: database
tags: [ecto, postgres, snapshots, fake-adapter, tdd]
requires:
  - phase: 02-data-model-error-model-ecto-store-fake-adapter
    provides: key-first store commands, authoring schemas, and adapter contract posture
  - phase: 03-context-rules-deterministic-bucketing-pure-evaluator
    provides: stable authored flag payload shape for snapshot serialization
provides:
  - immutable runtime snapshot persistence for each environment publish
  - environment-keyed snapshot fetch contract with monotonic versioning
  - shared adapter parity tests for snapshot publication and retrieval
affects: [runtime-refresh, ets-cache, diagnostics, explain, telemetry]
tech-stack:
  added: []
  patterns:
    - append-only runtime snapshot table with immutable rows
    - publish transaction persists authoring state and environment snapshot together
    - fake and Ecto adapters prove parity through one shared contract suite
key-files:
  created:
    - rulestead/lib/rulestead/runtime_snapshot.ex
    - rulestead/priv/repo/migrations/20260423020300_create_rulestead_runtime_snapshots.exs
    - rulestead/test/rulestead/runtime_snapshot_test.exs
    - rulestead/test/rulestead/store/command_test.exs
  modified:
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/store_error.ex
    - rulestead/test/support/store_contract_case.ex
    - rulestead/test/support/store_fixtures.ex
    - rulestead/test/rulestead/store/ecto_contract_test.exs
key-decisions:
  - "Runtime snapshot versioning is environment-scoped and monotonic instead of reusing per-flag ruleset versions."
  - "Snapshot payloads serialize the full active environment view as an Erlang term binary keyed by flag key."
  - "Snapshot fetch normalizes metadata keys so the fake and Ecto adapters return the same contract."
patterns-established:
  - "Publishes now create append-only runtime snapshot artifacts that future refresh workers can fetch directly."
  - "Store contract expansions must carry explicit typed not-found behavior and shared adapter parity coverage."
requirements-completed: [STORE-02]
duration: 6min
completed: 2026-04-24
---

# Phase 4 Plan 1: Persisted Snapshot Foundation Summary

**Immutable environment snapshots with monotonic versions now publish alongside rulesets and can be fetched directly from both store adapters**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-24T00:36:00Z
- **Completed:** 2026-04-24T00:42:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Added the append-only `runtime_snapshots` persistence boundary, including a migration, schema validations, and an environment-keyed store command.
- Made `publish_ruleset/1` persist a fresh environment snapshot and exposed `fetch_snapshot/1` with a stable payload shape in both Ecto and fake adapters.
- Extended the shared store contract suite so both adapters prove immediate snapshot fetchability and monotonic latest-version behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the persisted runtime snapshot schema and store contract** - `0cba9bf`, `b13177e`
2. **Task 2: Implement snapshot publication and parity in the Ecto and fake adapters** - `95a6132`, `bf8b741`

**Plan metadata:** committed separately as `docs(04-01): complete persisted snapshot foundation plan`

_Note: TDD tasks used test -> feat commit pairs._

## Files Created/Modified
- `rulestead/lib/rulestead/runtime_snapshot.ex` - Ecto schema and validation boundary for persisted runtime snapshots.
- `rulestead/priv/repo/migrations/20260423020300_create_rulestead_runtime_snapshots.exs` - Append-only snapshot table, version constraint, and immutability triggers.
- `rulestead/lib/rulestead/store.ex` - Added the environment-keyed snapshot fetch callback.
- `rulestead/lib/rulestead/store/command.ex` - Added `FetchSnapshot` for key-first runtime snapshot lookup.
- `rulestead/lib/rulestead/store/ecto.ex` - Publishes and fetches runtime snapshots through the Ecto adapter.
- `rulestead/lib/rulestead/fake.ex` - Mirrors the snapshot contract and monotonic versioning in memory.
- `rulestead/test/support/store_contract_case.ex` - Shared parity tests for snapshot publication and retrieval.
- `rulestead/test/rulestead/store/ecto_contract_test.exs` - Resets snapshot rows during adapter contract setup.
- `rulestead/test/rulestead/runtime_snapshot_test.exs` - Schema and validation tests for the new persistence boundary.
- `rulestead/test/rulestead/store/command_test.exs` - Contract tests for the new callback and command struct.

## Decisions Made

- Environment snapshots advance their own version sequence so runtime refresh can compare one monotonic counter per environment.
- Snapshot payloads capture the active published environment view, not a single flag row, so runtime code can refresh without row-by-row authoring reads.
- `fetch_snapshot/1` returns normalized metadata and typed not-found errors to preserve adapter-neutral behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added typed snapshot not-found behavior**
- **Found during:** Task 2 (Implement snapshot publication and parity in the Ecto and fake adapters)
- **Issue:** The new `fetch_snapshot/1` contract needed a typed miss path to stay consistent with the existing store semantics and avoid `nil`-style ambiguity.
- **Fix:** Added `StoreError.snapshot_not_found/2` and used it from both adapters.
- **Files modified:** `rulestead/lib/rulestead/store_error.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`
- **Verification:** `MIX_ENV=test mix test test/rulestead/store/ecto_contract_test.exs test/rulestead/store/fake_contract_test.exs`
- **Committed in:** `bf8b741`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The deviation tightened the new store surface without expanding scope beyond snapshot correctness.

## Issues Encountered

- The plan's reset command needed `MIX_ENV=test` in this repo because the database name is only configured in `config/test.exs`. Verification passed once the environment matched the project config.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 runtime refresh work can now fetch one immutable, versioned artifact per environment from either adapter.
- The next plan can build ETS compilation and diagnostics on top of the new snapshot payload without reshaping store publication semantics.

## Self-Check: PASSED

- Found `rulestead/lib/rulestead/runtime_snapshot.ex`
- Found `rulestead/priv/repo/migrations/20260423020300_create_rulestead_runtime_snapshots.exs`
- Found commits `0cba9bf`, `b13177e`, `95a6132`, and `bf8b741`

---
*Phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring*
*Completed: 2026-04-24*
