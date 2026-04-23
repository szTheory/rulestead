---
phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring
plan: 04
subsystem: runtime
tags: [runtime, backup, ets, pubsub, cluster, resilience, testing]
requires:
  - phase: 04-02
    provides: runtime startup and diagnostics baseline
  - phase: 04-03
    provides: versioned refresh loop with pubsub invalidation
provides:
  - Optional flat-file runtime backup bootstrap with quarantine semantics
  - Outage and offline-restart proof tests for last-known-good serving
  - Two-node peer-cluster convergence harness for runtime refresh verification
affects: [phase-04-telemetry, phase-05-host-app-seams, runtime-ops]
tech-stack:
  added: []
  patterns: [versioned flat-file backup, disk-bootstrap-before-refresh, peer-node runtime convergence tests]
key-files:
  created:
    - rulestead/lib/rulestead/runtime/backup.ex
    - rulestead/lib/rulestead/runtime/backup/file_store.ex
    - rulestead/lib/rulestead/runtime/cluster_case.ex
    - rulestead/test/rulestead/runtime/backup_test.exs
    - rulestead/test/rulestead/runtime/stale_serving_test.exs
    - rulestead/test/rulestead/runtime/cluster_refresh_test.exs
  modified:
    - rulestead/lib/rulestead/runtime/cache.ex
    - rulestead/lib/rulestead/runtime/refresh.ex
    - rulestead/lib/rulestead/runtime/supervisor.ex
key-decisions:
  - "Backup stays optional and flat-file only; restore is opportunistic and never blocks startup."
  - "Refresh failure preserves the current runtime source so disk-restored nodes remain visibly disk-backed while stale."
  - "Multi-node convergence is proven with OTP peer nodes and a test-only store proxy, not shared ETS state."
patterns-established:
  - "Runtime bootstrap pattern: register environment, attempt disk restore, then refresh from store."
  - "Operational proof pattern: outage tests drive named refresh workers directly while cluster tests use peer nodes."
requirements-completed: [STORE-05, STORE-06]
duration: 32min
completed: 2026-04-23
---

# Phase 04 Plan 04: Snapshot Backup and Runtime Resilience Summary

**Optional flat-file snapshot backup with quarantine-safe restore, stale-serving outage coverage, and peer-node refresh convergence proof**

## Performance

- **Duration:** 32 min
- **Started:** 2026-04-23T20:38:00Z
- **Completed:** 2026-04-23T21:10:11Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `Rulestead.Runtime.Backup` and `Rulestead.Runtime.Backup.FileStore` so runtime snapshots can persist to disk, restore before first refresh, quarantine corrupt backups, and retain a single rollback generation.
- Extended runtime metadata handling so backup status is visible and stale nodes keep their actual source (`:disk` or `:ets`) instead of collapsing everything to generic stale state.
- Added executable resilience proofs for stale serving during store outages, offline restart from backup, and two-node PubSub-driven convergence using OTP peer nodes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement optional flat-file snapshot backup with safe boot restore** - `76edaa7` (`feat`)
2. **Task 2: Prove stale serving, offline restart, and two-node refresh convergence** - `10e1063` (`feat`)

## Files Created/Modified
- `rulestead/lib/rulestead/runtime/backup.ex` - Backup orchestration for restore/persist decisions and cache metadata updates.
- `rulestead/lib/rulestead/runtime/backup/file_store.ex` - Versioned flat-file backend with checksum validation, quarantine, and previous-generation rotation.
- `rulestead/lib/rulestead/runtime/cache.ex` - Backup status metadata, disk source preservation, and ETS creation race hardening.
- `rulestead/lib/rulestead/runtime/refresh.ex` - Restore-before-refresh bootstrap and persist-after-apply flow.
- `rulestead/lib/rulestead/runtime/supervisor.ex` - Optional refresh-worker naming for deterministic resilience tests.
- `rulestead/lib/rulestead/runtime/cluster_case.ex` - Peer-node runtime harness and controller-backed store proxy for convergence tests.
- `rulestead/test/rulestead/runtime/backup_test.exs` - Restore, quarantine, disabled-backup, and generation-rotation coverage.
- `rulestead/test/rulestead/runtime/stale_serving_test.exs` - Stale serving and offline restart proof coverage.
- `rulestead/test/rulestead/runtime/cluster_refresh_test.exs` - Two-node convergence proof with bounded-time assertion.

## Decisions Made

- Used a test-only store proxy in the cluster harness so each node still compiles and applies snapshots locally while the controller node remains the single source of authored snapshots.
- Kept the backup file format private to `FileStore` and scoped to compiled runtime snapshots only, avoiding any second persistence path for authored rules or cache internals.
- Preserved named refresh workers as a test-only opt-in via supervisor options instead of changing the production runtime naming model.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve restored disk provenance during failed refreshes**
- **Found during:** Task 2 (stale serving and offline restart proofs)
- **Issue:** `Cache.mark_refresh_failed/2` rewrote any populated runtime source to `:ets`, so disk-restored nodes lost their actual provenance after the first failed refresh.
- **Fix:** Kept existing `:disk` or `:ets` source when a snapshot already exists and only fall back to `:none` for empty environments.
- **Files modified:** `rulestead/lib/rulestead/runtime/cache.ex`
- **Verification:** `mix test test/rulestead/runtime/stale_serving_test.exs`
- **Committed in:** `10e1063`

**2. [Rule 1 - Bug] Harden ETS table creation against concurrent ensure calls**
- **Found during:** Task 2 (offline restart proof)
- **Issue:** rapid reset/restart flows could race `:ets.new/2` and raise `ArgumentError` even though the named table already existed.
- **Fix:** wrapped table creation with a narrow rescue so concurrent callers accept the already-created table.
- **Files modified:** `rulestead/lib/rulestead/runtime/cache.ex`
- **Verification:** `mix test test/rulestead/runtime/stale_serving_test.exs test/rulestead/runtime/cluster_refresh_test.exs --timeout 300000`
- **Committed in:** `10e1063`

**3. [Rule 3 - Blocking] Bootstrap peer nodes with code paths and atom-safe snapshot decoding**
- **Found during:** Task 2 (two-node convergence proof)
- **Issue:** OTP peer nodes could not load the local app paths by default, and safe snapshot decoding failed remotely until the payload atoms were present on the peer.
- **Fix:** pushed the current BEAM paths into peer nodes, started pubsub/runtime detached from RPC handlers, and preloaded snapshot payload atoms in the test-only cluster store proxy before remote compile.
- **Files modified:** `rulestead/lib/rulestead/runtime/cluster_case.ex`
- **Verification:** `mix test test/rulestead/runtime/cluster_refresh_test.exs --timeout 300000`
- **Committed in:** `10e1063`

---

**Total deviations:** 3 auto-fixed (2 bug fixes, 1 blocking harness fix)
**Impact on plan:** All deviations were required to make the resilience proofs deterministic and truthful. No scope creep beyond the plan's runtime/test harness boundary.

## Issues Encountered

- Peer-node pubsub and runtime processes died when started directly over RPC because `start_link` linked them to short-lived RPC handlers. The harness now starts those trees detached and waits for readiness explicitly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 runtime work now has executable coverage for bootstrap backup, stale serving, offline restart, and cross-node convergence.
- Telemetry and diagnostics follow-up work can build on the now-verified backup and outage semantics without changing the runtime contract.

## Self-Check

PASSED - summary file created, task commits `76edaa7` and `10e1063` exist, and verification suites passed without editing `ROADMAP.md` or `STATE.md`.

---
*Phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring*
*Completed: 2026-04-23*
