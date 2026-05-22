---
phase: 22-environment-compare-conflict-model
plan: 02
subsystem: ui
tags: [liveview, admin, compare, accessibility, promotion]
requires:
  - phase: 22-environment-compare-conflict-model
    provides: canonical backend compare payload and scoped compare token semantics
provides:
  - mounted compare summary route inside the existing admin session envelope
  - per-flag compare drill-in route with stale-preview disclosure
  - accessibility and read-only regression coverage for compare routes
affects: [23-governed-promotion-apply, rulestead_admin]
tech-stack:
  added: []
  patterns: [read-only compare routes, URL-backed source-target state, findings-first compare drill-in]
key-files:
  created:
    - rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex
    - rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex
    - rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs
    - rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs
    - rulestead_admin/test/rulestead_admin/live/environment_compare_live/accessibility_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/router.ex
    - rulestead_admin/lib/rulestead_admin/components/audit_components.ex
key-decisions:
  - "Kept compare routes under `/admin/flags/compare` so they inherit the existing live_session policy and environment shell."
  - "Used explicit `source_env`, `target_env`, and optional `compare_token` query params instead of hidden session compare state."
  - "Extended `AuditComponents.diff_card/1` to render source/current target/proposed target slices behind accessible disclosure."
patterns-established:
  - "Summary route stays findings-first and read-only; drill-in owns detailed authored-state inspection."
  - "Stale preview handling is surfaced as a blocker banner when the provided compare token no longer matches the scoped authored state."
requirements-completed: [PROM-01, PROM-02]
duration: 1h20m
completed: 2026-05-18
---

# Phase 22: Environment Compare & Conflict Model Summary

**Mounted compare summary and per-flag drill-in routes that render the canonical payload without exposing apply controls**

## Performance

- **Duration:** 1h20m
- **Started:** 2026-05-18T17:21:00Z
- **Completed:** 2026-05-18T19:31:05Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added mounted `/admin/flags/compare` and `/admin/flags/compare/:key` LiveViews inside the existing admin router macro.
- Rendered findings-first compare surfaces with explicit `source`, `current target`, and `proposed target after apply` directionality.
- Added focused LiveView and accessibility coverage for URL-backed environment state, stale-preview disclosure, and read-only posture.

## Task Commits

No commits were created in this workspace run. The repository already contained unrelated user and build-tree changes, so the Phase 22 UI work was left uncommitted to avoid bundling external modifications into the plan artifacts.

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` - compare summary LiveView with findings buckets, token metadata, and drill-in links
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` - per-flag drill-in LiveView with stale-preview banner and structured diff disclosure
- `rulestead_admin/lib/rulestead_admin/router.ex` - mounted compare routes inside the existing admin session envelope
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` - extended diff card to support source/current-target/proposed-target compare slices
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` - summary route coverage
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` - drill-in route coverage
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/accessibility_test.exs` - accessibility and disclosure-label coverage

## Decisions Made

- Reused `Shell.page`, `OperatorComponents`, `FlagComponents`, and `AuditComponents` instead of introducing a second compare-only component system.
- Kept environment selection entirely URL-backed so compare links remain shareable and deterministic.
- Forced stale-preview coverage through an explicit mismatched `compare_token` in tests rather than inventing non-contract staleness behavior in the UI.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Tightened compare route tests to reject only real mutation controls**
- **Found during:** Task 2 verification
- **Issue:** broad `refute html =~ "Publish"` assertions matched benign copy such as `published source state`
- **Fix:** narrowed the assertions to control-like tokens such as `>Publish<` and `>Apply<`
- **Files modified:** `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs`, `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs`
- **Verification:** targeted admin compare tests passed after the assertion update
- **Committed in:** not committed

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Improved test precision only. No product-scope change.

## Issues Encountered

- The first executor agent for Wave 2 stalled after creating test scaffolding, so the implementation and final verification were completed in the main context.
- Test seeding emitted a Redis publisher error log because the fake publish path still notifies a Redis telemetry handler that expects `Rulestead.Repo` to be running. The compare tests still passed, but that background warning should be cleaned up separately if it becomes noisy elsewhere.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 23 can wire governed apply entry points onto the existing compare summary and drill-in routes without redefining compare semantics.
- The admin compare UI already surfaces target risk framing, stale-preview blockers, and typed findings in a reusable mounted shape.

---
*Phase: 22-environment-compare-conflict-model*
*Completed: 2026-05-18*
