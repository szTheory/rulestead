---
phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
plan: 05
subsystem: observability
tags: [telemetry, exdoc, runtime-cache, ecto, hot-path]
requires:
  - phase: 04-02
    provides: runtime ETS cache and keyed runtime facade
  - phase: 04-03
    provides: refresh loop and degraded runtime semantics
  - phase: 04-04
    provides: stale-serving and backup-aware runtime behavior
provides:
  - Phase 4 telemetry wrapper with safe handler fan-out
  - Public telemetry event catalog guide in guides/flows
  - Warm-cache integration proof for zero-query runtime evaluation
affects: [phase-05-host-seams, phase-06-admin-ui, telemetry-contract]
tech-stack:
  added: []
  patterns: [versioned telemetry contract, bounded metadata spine, safe telemetry attachment]
key-files:
  created:
    - rulestead/lib/rulestead/telemetry.ex
    - rulestead/test/rulestead/telemetry_test.exs
    - rulestead/test/rulestead/integration/runtime_hot_path_test.exs
    - guides/flows/telemetry.md
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/runtime.ex
    - rulestead/lib/rulestead/runtime/refresh.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/mix.exs
key-decisions:
  - "Centralized Phase 4 telemetry shaping in Rulestead.Telemetry so runtime, store, and admin-coarse events share one bounded metadata spine."
  - "Kept handler isolation explicit via Rulestead.Telemetry.attach_many/4 instead of changing global :telemetry.attach/4 semantics."
  - "Proved the DB-free runtime hot path against the Ecto adapter, not just the fake store, so the roadmap claim is exercised on the real authoring-store path."
patterns-established:
  - "Telemetry events are emitted from public facades and refresh/store boundaries, not from arbitrary deep internals."
  - "Runtime snapshot payloads must serialize authored rulesets into plain maps before entering hot-path evaluation."
requirements-completed: [TEL-01, TEL-02, TEL-04]
duration: 28min
completed: 2026-04-23
---

# Phase 4 Plan 05: Telemetry Contract Summary

**Versioned Phase 4 telemetry spans, safe handler attachment, and an Ecto-backed zero-query warm-cache runtime proof**

## Performance

- **Duration:** 28 min
- **Started:** 2026-04-23T21:11:00Z
- **Completed:** 2026-04-23T21:39:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added `Rulestead.Telemetry` with `span/3`, safe fan-out attachment helpers, and shared metadata shaping for the locked Phase 4 event families.
- Instrumented the pure evaluator, keyed runtime facade, refresh loop, store boundaries, snapshot publication/apply, and admin-coarse mutations with bounded redacted metadata.
- Published the flow guide in `guides/flows/telemetry.md`, wired it into ExDoc extras, and added an integration test proving warm-cache runtime evaluation performs zero repo queries.

## Task Commits

1. **Task 1: Instrument the public runtime and store surfaces through `Rulestead.Telemetry`** - `6049b19` (`test`)
2. **Task 1: Instrument the public runtime and store surfaces through `Rulestead.Telemetry`** - `c44fd40` (`feat`)
3. **Task 2: Publish the event catalog guide and prove the hot path stays DB-free** - `87bfde6` (`test`)
4. **Task 2: Publish the event catalog guide and prove the hot path stays DB-free** - `61b0956` (`feat`)

## Files Created/Modified

- `rulestead/lib/rulestead/telemetry.ex` - shared telemetry wrapper, metadata builder, and safe handler registry
- `rulestead/lib/rulestead.ex` - pure evaluator, store facade, and admin-coarse mutation instrumentation
- `rulestead/lib/rulestead/runtime.ex` - keyed runtime eval/cache/stale-use instrumentation
- `rulestead/lib/rulestead/runtime/refresh.ex` - refresh/store-read/apply instrumentation
- `rulestead/lib/rulestead/fake.ex` - fake snapshot publication telemetry
- `rulestead/lib/rulestead/store/ecto.ex` - Ecto snapshot publication telemetry and plain-map ruleset serialization
- `rulestead/test/rulestead/telemetry_test.exs` - event catalog, metadata spine, redaction, and safe-handler coverage
- `rulestead/test/rulestead/integration/runtime_hot_path_test.exs` - zero-query warm-cache proof on the Ecto-backed runtime path
- `guides/flows/telemetry.md` - public Phase 4 event catalog and handler-safety contract
- `rulestead/mix.exs` - ExDoc extras updated to surface the telemetry flow guide

## Decisions Made

- Used `Rulestead.Telemetry.attach_many/4` as the supported handler-isolation path so misbehaving observers cannot raise back into runtime/store/admin operations.
- Treated the Phase 4 metadata spine as an allowlist, dropping raw values, raw attributes, and framework structs at emission time instead of relying on downstream consumers to redact.
- Locked the hot-path proof against the real Ecto adapter, which exposed and fixed authored ruleset struct leakage inside serialized runtime snapshots.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized Ecto snapshot rulesets into plain maps**
- **Found during:** Task 2 (Publish the event catalog guide and prove the hot path stays DB-free)
- **Issue:** The Ecto-backed runtime snapshot path stored embedded `Rulestead.Ruleset.*` structs in serialized rulesets, which broke keyed runtime evaluation on the real warm-cache path.
- **Fix:** Added explicit rule/condition/variant/rollout serialization in `Rulestead.Store.Ecto` before snapshot publication.
- **Files modified:** `rulestead/lib/rulestead/store/ecto.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/telemetry_test.exs test/rulestead/integration/runtime_hot_path_test.exs --include telemetry`
- **Committed in:** `61b0956`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was necessary to satisfy the plan’s Ecto-backed hot-path proof. No scope creep beyond the plan boundary.

## Issues Encountered

- The refresh loop fetches snapshots directly from the configured store adapter, so store-read telemetry needed to be instrumented at that boundary in addition to the root public store facade.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 5 consumers can attach safe handlers to the locked telemetry contract without risking runtime failures.
- The runtime/store telemetry surface is documented and exercised, and the keyed runtime path is proven DB-free after cache warmup.

## Self-Check

PASSED

---
*Phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring*
*Completed: 2026-04-23*
