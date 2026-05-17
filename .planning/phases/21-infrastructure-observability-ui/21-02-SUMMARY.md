---
phase: 21-infrastructure-observability-ui
plan: 02
subsystem: ui
tags: [phoenix-liveview, diagnostics, accessibility, observability]
requires:
  - phase: 20-pubsub-distributed-invalidation
    provides: bounded invalidation and sync telemetry consumed by the runtime health seam
  - phase: 21-01
    provides: public infrastructure health facade for the mounted admin UI
provides:
  - mounted diagnostics liveview inside the existing admin session and policy envelope
  - summary-first infrastructure health rendering for current-node cache freshness and adapter status
  - accessibility regression coverage for diagnostics loading and degraded states
affects: [rulestead_admin router, operator components, infrastructure observability UI]
tech-stack:
  added: []
  patterns: [connected-only async health load, mounted-admin diagnostics route, named a11y regions]
key-files:
  created:
    - rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex
    - rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs
    - rulestead_admin/test/rulestead_admin/live/diagnostics_live/accessibility_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/router.ex
    - rulestead_admin/lib/rulestead_admin/components/operator_components.ex
key-decisions:
  - "Mounted diagnostics at `/diagnostics` inside the existing `rulestead_admin` macro so the route inherits the current session and policy checks."
  - "Kept the page explicitly current-node by default and rendered a critical empty state when the selected environment has no runtime snapshot instead of implying cluster-wide health."
patterns-established:
  - "Diagnostics LiveViews should load backend health through the public `Rulestead.infrastructure_health/0` facade instead of reaching into runtime internals."
  - "Operator status surfaces should expose named regions for topology and summary content so async and degraded states remain navigable to assistive technology."
requirements-completed: [INF-01]
duration: 5min
completed: 2026-05-17
---

# Phase 21 Plan 02: Admin Diagnostics UI Summary

**Mounted infrastructure health screen with summary-first current-node diagnostics, explicit stale/missing-state copy, and accessibility coverage in `rulestead_admin`.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-17T20:50:20Z
- **Completed:** 2026-05-17T20:54:49Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a mounted `/diagnostics` LiveView under the existing admin router macro, preserving the environment picker and session/policy envelope.
- Rendered current-node cache age, sync latency, snapshot version, refresh state, and Repo/Redis/PubSub health through the public runtime health seam.
- Locked the diagnostics page with focused LiveView and accessibility regression coverage, including refresh and missing-snapshot states.

## Task Commits

1. **Task 1: Mount the diagnostics LiveView and render a summary-first health page** - `fbf94a6` (test), `80fff67` (feat)
2. **Task 2: Lock the diagnostics screen accessibility and mounted-admin behavior** - `bd4fcfa` (test), `17cd7b2` (feat)

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/router.ex` - mounted the diagnostics route before the flag detail catch-all.
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` - added reusable named-region support and a status-list helper used by diagnostics.
- `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex` - implemented the connected-only async diagnostics page and explicit degraded-state rendering.
- `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs` - covered route wiring, summary-first rendering, refresh behavior, and missing-snapshot copy.
- `rulestead_admin/test/rulestead_admin/live/diagnostics_live/accessibility_test.exs` - covered accessibility for async-loaded and degraded diagnostics states.

## Decisions Made

- Mounted diagnostics inside the existing admin macro instead of creating a separate scope so Phase 21 keeps the same authz/session behavior as the rest of `rulestead_admin`.
- Used the public `Rulestead.infrastructure_health/0` seam with connected-only async loading so disconnected mount stays light and the UI never implies undiscovered peer health.

## Verification

- `cd rulestead_admin && mix test test/rulestead_admin/live/diagnostics_live/index_test.exs`
  Result: `3 tests, 0 failures`
- `cd rulestead_admin && mix test test/rulestead_admin/live/diagnostics_live/accessibility_test.exs`
  Result: `2 tests, 0 failures`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched the new linked runtime dependency so admin tests could compile**
- **Found during:** Task 1 (diagnostics LiveView RED run)
- **Issue:** `rulestead_admin` test execution stopped because the linked `rulestead` package now depends on `redix`, which had not been fetched in this checkout.
- **Fix:** Ran `mix deps.get` in `rulestead_admin` to fetch the missing dependency before continuing the targeted diagnostics test cycle.
- **Files modified:** none committed for this plan
- **Verification:** targeted diagnostics tests compiled and ran successfully afterward
- **Committed in:** not applicable

### Execution Adjustment

- The plan’s documented commands used `mix test ... -x`, but this Mix version does not support `-x`.
- Verification used the same targeted test file commands without `-x`.

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The blocking fix only restored the local test environment needed to execute the planned admin slice.

## Issues Encountered

- `rulestead_admin/mix.lock` was updated locally by `mix deps.get` when fetching `redix` for the linked runtime package. It was left out of this plan’s commits to stay within the requested file scope.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 21 now has both the backend health seam and the mounted diagnostics UI needed to satisfy INF-01.
- No follow-up blocker remains inside the admin diagnostics slice.

## Self-Check

PASSED
