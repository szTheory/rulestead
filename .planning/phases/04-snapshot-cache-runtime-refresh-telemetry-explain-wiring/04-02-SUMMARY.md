---
phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
plan: 02
subsystem: infra
tags: [elixir, ets, runtime-cache, diagnostics, explain]
requires:
  - phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
    provides: persisted environment snapshots with monotonic versions
  - phase: 03-context-rules-deterministic-bucketing-pure-evaluator
    provides: pure payload-first evaluator and result contracts
provides:
  - explicit keyed runtime evaluation over ETS-compiled snapshots
  - bounded runtime diagnostics for local cache state
  - runtime explain output composed from evaluation trace and safe cache metadata
affects: [runtime-refresh, telemetry, host-app-seams, admin-simulation]
tech-stack:
  added: []
  patterns:
    - immutable environment snapshots compiled once and stored in ETS by environment plus flag key
    - runtime facade reuses the pure evaluator and only projects cache metadata at the edge
    - diagnostics and explain surfaces are bounded and redacted by design
key-files:
  created:
    - rulestead/lib/rulestead/runtime/snapshot.ex
    - rulestead/lib/rulestead/runtime/cache.ex
    - rulestead/lib/rulestead/runtime/diagnostics.ex
    - rulestead/test/rulestead/runtime/runtime_test.exs
    - rulestead/test/rulestead/runtime/diagnostics_test.exs
  modified:
    - rulestead/lib/rulestead/runtime.ex
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/explainer.ex
key-decisions:
  - "The runtime cache uses global named ETS tables keyed by {environment_key, flag_key} plus a per-environment metadata table so hot-path lookups stay store-free."
  - "Cache age is projected only from the runtime facade after pure evaluation completes, preserving the Phase 3 evaluator contract."
  - "Root diagnostics stays a zero-argument delegate to Rulestead.Runtime.diagnostics/0 instead of adding keyed overloads to the payload-first facade."
patterns-established:
  - "Compiled snapshots keep authored flag payloads intact so the runtime layer can reuse Rulestead.Evaluator without duplicating rule semantics."
  - "Explain output composes the existing human trace with sanitized runtime metadata instead of extending debug_trace with cache internals."
requirements-completed: [STORE-03, STORE-04]
duration: 3min
completed: 2026-04-23
---

# Phase 4 Plan 2: Runtime Cache Facade Summary

**ETS-backed keyed runtime evaluation with cache-age projection, bounded node-local diagnostics, and redacted runtime explain output**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-23T20:43:38Z
- **Completed:** 2026-04-23T20:46:01Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Compiled persisted environment snapshots into immutable runtime entries keyed by `flag_key` and applied them to ETS with monotonic version checks.
- Added the explicit `Rulestead.Runtime` keyed evaluation and projection helpers while leaving the Phase 3 payload-first APIs unchanged.
- Exposed bounded runtime diagnostics and explain output that surfaces snapshot/version/age facts without leaking raw caller attributes or targeting identifiers.

## Task Commits

Each task was committed atomically:

1. **Task 1: Compile persisted snapshots into ETS-backed runtime lookup state** - `d825747`, `27b71c1`
2. **Task 2: Add the runtime facade, diagnostics envelope, and explain composition** - `aced959`, `87cba97`

## Files Created/Modified
- `rulestead/lib/rulestead/runtime/snapshot.ex` - Decodes and normalizes persisted environment snapshots into runtime-ready entries.
- `rulestead/lib/rulestead/runtime/cache.ex` - Owns ETS apply, lookup, cache age, and sanitized runtime metadata helpers.
- `rulestead/lib/rulestead/runtime/diagnostics.ex` - Shapes the bounded node-local diagnostics envelope.
- `rulestead/lib/rulestead/runtime.ex` - Exposes explicit keyed runtime evaluate/projection/explain/diagnostics helpers.
- `rulestead/lib/rulestead.ex` - Adds the root `diagnostics/0` delegate only.
- `rulestead/lib/rulestead/explainer.ex` - Composes Phase 3 evaluation prose with safe runtime metadata.
- `rulestead/test/rulestead/runtime/runtime_test.exs` - Locks snapshot compilation, ETS lookup, and cache-age projection.
- `rulestead/test/rulestead/runtime/diagnostics_test.exs` - Locks keyed runtime projections, diagnostics parity, and explain redaction.

## Decisions Made

- Used one ETS table for keyed flag entries and one ETS table for per-environment metadata so runtime evaluation can stay O(1) without scanning per-flag diagnostics.
- Kept diagnostics machine-readable and environment-scoped rather than exposing per-flag dumps or internal ETS contents.
- Reused the existing explainer trace and appended runtime metadata in prose instead of introducing a second explain trace format.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added the minimal `Rulestead.Runtime.evaluate/3` entrypoint during Task 1**
- **Found during:** Task 1 (Compile persisted snapshots into ETS-backed runtime lookup state)
- **Issue:** The plan split the runtime facade into Task 2, but Task 1's acceptance criteria required proving keyed evaluation succeeds from cache state alone.
- **Fix:** Added the narrow `evaluate/3` facade in the Task 1 implementation so the ETS cache path could be verified end to end, then expanded the module with projections/diagnostics/explain in Task 2.
- **Files modified:** `rulestead/lib/rulestead/runtime.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/runtime/runtime_test.exs`
- **Committed in:** `27b71c1`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The deviation was necessary for correctness of the Task 1 verification path and did not expand scope beyond the planned runtime facade.

## Issues Encountered

- A decoder implementation typo in `Rulestead.Runtime.Snapshot` caused the first GREEN run to fail at compile time; it was fixed inline before the task commit.
- The diagnostics RED test initially had a delimiter typo; fixing it restored the intended API-level failure before implementation proceeded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 refresh orchestration can now fetch the latest persisted snapshot and apply it into the ETS runtime cache without changing evaluation semantics.
- Later host-app seams can target `Rulestead.Runtime.*` directly for explicit runtime-backed reads and diagnostics.

## Self-Check: PASSED

- Found `rulestead/lib/rulestead/runtime/snapshot.ex`
- Found `rulestead/lib/rulestead/runtime/cache.ex`
- Found `rulestead/lib/rulestead/runtime/diagnostics.ex`
- Found `rulestead/test/rulestead/runtime/runtime_test.exs`
- Found `rulestead/test/rulestead/runtime/diagnostics_test.exs`
- Found commits `d825747`, `27b71c1`, `aced959`, and `87cba97`

---
*Phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring*
*Completed: 2026-04-23*
