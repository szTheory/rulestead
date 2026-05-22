---
phase: 23-governed-promotion-apply
plan: 05
subsystem: ui
tags: [phoenix-liveview, admin, promotion, review, reapply]
requires:
  - phase: 23-governed-promotion-apply
    provides: promotion audit linkage and backend reapply-version support
provides:
  - mounted compare-route promotion handoff for direct and governed flows
  - governed review screens that render exact promotion bundle details
  - explicit reapply-version deep links from compare, change-request, and schedule surfaces
affects: [23-governed-promotion-apply, rulestead_admin]
tech-stack:
  added: []
  patterns: [mounted admin handoff, deep-linked reapply review]
key-files:
  created: []
  modified:
    - rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex
    - rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex
    - rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex
    - rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex
    - rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs
    - rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs
    - rulestead_admin/test/rulestead_admin/live/change_request_live/show_test.exs
    - rulestead_admin/test/rulestead_admin/live/schedule_live/show_test.exs
key-decisions:
  - "Promotion stays inside the mounted admin routes rather than becoming a standalone console."
  - "Reapply-version is exposed as an explicit deep link back into the compare flow."
patterns-established:
  - "Compare is the operator entrypoint for both forward promotion and historical reapply."
  - "Governed review surfaces render stored promotion intent directly from backend truth."
requirements-completed: [PROM-03, PROM-04]
duration: 20m
completed: 2026-05-18
---

# Phase 23: Governed Promotion Apply Summary

**Mounted admin compare, change-request, and schedule routes now cover promotion review, governed handoff, and explicit reapply-version deep links**

## Performance

- **Duration:** 20m
- **Completed:** 2026-05-18
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Verified the mounted compare routes support selected-set promotion review and reapply-version deep-link handling.
- Verified change-request and schedule detail screens render promotion-specific intent and expose explicit reapply-version entrypoints.
- Confirmed the 23-05 admin slice was already green with targeted LiveView regression coverage.

## Task Commits

No commits were created in this workspace run because the repository already contained unrelated user and build-tree changes.

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` - compare-side promotion handoff
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex` - compare detail and reapply deep-link handling
- `rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex` - governed promotion detail rendering and reapply action
- `rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex` - scheduled promotion detail rendering and reapply action
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` - compare route promotion coverage
- `rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs` - reapply deep-link coverage
- `rulestead_admin/test/rulestead_admin/live/change_request_live/show_test.exs` - governed promotion review coverage
- `rulestead_admin/test/rulestead_admin/live/schedule_live/show_test.exs` - scheduled promotion detail coverage

## Decisions Made

- Accepted the existing mounted admin implementation after targeted verification instead of widening the slice with unrelated UI cleanup.

## Deviations from Plan

None - targeted verification confirmed the plan output was already implemented.

## Issues Encountered

- The admin test run emits an existing telemetry handler error from `rulestead-redis-publisher` when the fake store is active without `Rulestead.Repo` started. The targeted tests still passed and no promotion behavior failed, but the log noise remains in the suite.

## User Setup Required

None.

## Next Phase Readiness

- Phase 23 has backend and mounted admin coverage for direct promotion, governed promotion, scheduled execution, audit truth, and reapply-version entrypoints.
- The remaining work is repo hygiene and any follow-up on the existing telemetry log noise.

---
*Phase: 23-governed-promotion-apply*
*Completed: 2026-05-18*
