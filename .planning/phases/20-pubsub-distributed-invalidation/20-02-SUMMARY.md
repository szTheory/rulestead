---
phase: 20-pubsub-distributed-invalidation
plan: 02
subsystem: runtime
tags: [pubsub, notifier, telemetry, ets, cluster, testing]
requires:
  - phase: 20-pubsub-distributed-invalidation
    provides: "Notifier seam and authoritative snapshot publication invalidations"
provides:
  - "Notifier-backed runtime refresh subscriptions for per-environment workers"
  - "Version-gated invalidation handling that preserves stale-serving ETS semantics"
  - "Invalidation telemetry coverage for received, ignored, refresh-triggered, and failed refresh outcomes"
affects: [runtime, telemetry, cluster-testing, host-config]
tech-stack:
  added: []
  patterns: [notifier-seam-subscription, monotonic-invalidation-gating, bounded-invalidation-telemetry]
key-files:
  created: [.planning/phases/20-pubsub-distributed-invalidation/20-02-SUMMARY.md]
  modified:
    - rulestead/lib/rulestead/runtime/refresh.ex
    - rulestead/lib/rulestead/runtime/supervisor.ex
    - rulestead/lib/rulestead/fake/control.ex
    - rulestead/lib/rulestead/runtime/cluster_case.ex
    - rulestead/test/rulestead/runtime/refresh_test.exs
    - rulestead/test/rulestead/runtime/cluster_refresh_test.exs
    - rulestead/test/rulestead/telemetry_test.exs
key-decisions:
  - "Refresh workers now subscribe through the configured notifier seam and only when explicit PubSub wiring is present."
  - "Invalidation notices remain advisory wake-ups; ETS data is never pre-evicted and only newer compiled snapshots apply."
  - "Invalidation observability uses a dedicated [:rulestead, :runtime, :invalidation, *] family with bounded metadata."
patterns-established:
  - "Runtime convergence pattern: advisory invalidation notice -> version gate -> serialized refresh worker -> monotonic Cache.apply/2"
  - "Test helper pattern: broadcast invalidations through Rulestead.Runtime.Notifier instead of ad hoc PubSub payloads"
requirements-completed: [INV-01, INV-02]
duration: 10min
completed: 2026-05-17
---

# Phase 20 Plan 02: Runtime Invalidation Summary

**Notifier-backed runtime refresh workers now converge on newer snapshot versions immediately while ignoring stale notices, preserving last-known-good ETS data, and emitting bounded invalidation telemetry.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-17T17:27:00Z
- **Completed:** 2026-05-17T17:37:13Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Moved runtime refresh worker subscription from direct `Phoenix.PubSub` calls onto the notifier seam and passed notifier/pubsub wiring consistently through the runtime supervisor and cluster helpers.
- Added monotonic invalidation handling that ignores duplicate, stale, out-of-order, and missing-version notices without evicting currently served ETS snapshots.
- Locked the invalidation telemetry contract with coverage for received, ignored, refresh-triggered, and failed-after-invalidation outcomes using bounded metadata only.

## Task Commits

1. **Task 1: Move runtime refresh workers onto the notifier seam and preserve monotonic stale-serving behavior**
   - `ff96a54` `test(20-02): add failing runtime invalidation coverage`
   - `4de38ce` `feat(20-02): wire runtime invalidation through notifier seam`
2. **Task 2: Lock invalidation telemetry and explicit host scaffolding**
   - `c1b3daf` `test(20-02): lock invalidation telemetry contract`

## Files Created/Modified

- `rulestead/lib/rulestead/runtime/refresh.ex` - subscribed through the notifier seam, gated invalidations by snapshot version, preserved stale-serving semantics, and emitted invalidation telemetry events.
- `rulestead/lib/rulestead/runtime/supervisor.ex` - passed configured notifier and PubSub options into per-environment refresh workers.
- `rulestead/lib/rulestead/fake/control.ex` - routed test invalidation broadcasts through `Rulestead.Runtime.Notifier.broadcast/3`.
- `rulestead/lib/rulestead/runtime/cluster_case.ex` - aligned detached cluster runtimes and helpers with explicit notifier wiring.
- `rulestead/test/rulestead/runtime/refresh_test.exs` - covered notifier subscription, newer invalidations, duplicate/stale ignores, polling fallback, and failed invalidation refresh stale-serving behavior.
- `rulestead/test/rulestead/runtime/cluster_refresh_test.exs` - verified two nodes converge through the notifier seam and stay pinned on the latest version after duplicate/stale notices.
- `rulestead/test/rulestead/telemetry_test.exs` - asserted the invalidation telemetry event family and bounded metadata contract.

## Decisions Made

- Runtime invalidation telemetry lives under `[:rulestead, :runtime, :invalidation, ...]` so operators can distinguish invalidation causes from generic cache refreshes.
- Ignored invalidation notices are classified by reason (`:stale_snapshot_version`, `:missing_snapshot_version`) instead of mutating runtime state.
- Test helpers publish through the notifier seam so cluster and single-node tests exercise the same contract as production hosts.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first RED attempt only proved version gating, which already worked through direct PubSub. The tests were tightened to assert notifier-based subscription explicitly before the runtime implementation changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Runtime workers now support immediate distributed convergence through explicit host-owned PubSub wiring and still reconcile safely by polling when PubSub is absent.
- Phase 20 follow-up work can rely on the notifier seam and invalidation telemetry contract without reopening stale-serving semantics.

## Self-Check: PASSED

- Verified `.planning/phases/20-pubsub-distributed-invalidation/20-02-SUMMARY.md` exists.
- Verified task commits `ff96a54`, `4de38ce`, and `c1b3daf` exist in git history.
