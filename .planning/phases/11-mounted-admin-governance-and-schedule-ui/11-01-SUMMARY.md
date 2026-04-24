---
phase: 11-mounted-admin-governance-and-schedule-ui
plan: 01
subsystem: rulestead_admin
tags: [mounted-admin, governance-ui, schedule-ui, shell-navigation, tdd]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: change-request route vocabulary and governance actions
  - phase: 10-scheduled-changes-and-durable-execution
    provides: scheduled execution route vocabulary and durable schedule concepts
provides:
  - mounted route contracts for change-request and schedule pages
  - route-backed Phase 11 LiveView stubs with canonical env query handling
  - shell-level governance navigation that preserves mount path and env scope
affects: [phase-11-governance-review-ui, phase-11-schedule-ui, phase-11-verification]
tech-stack:
  added: []
  patterns: [tdd, mounted-liveview routing, canonical query-state, shared-shell navigation]
key-files:
  created:
    - rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex
    - rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex
    - rulestead_admin/lib/rulestead_admin/live/schedule_live/index.ex
    - rulestead_admin/lib/rulestead_admin/live/schedule_live/show.ex
    - rulestead_admin/test/rulestead_admin/live/governance_route_contract_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/router.ex
    - rulestead_admin/lib/rulestead_admin/components/shell.ex
    - rulestead_admin/test/rulestead_admin/router_test.exs
key-decisions:
  - "Phase 11 starts with route-owned placeholder screens rather than inline governance workspaces on existing flag pages."
  - "All governance and schedule links are built from the mounted admin path plus canonical `?env=` state through `Session.current_path/2`."
  - "Shell navigation stays lightweight and optional so the mounted package does not grow standalone-app chrome."
patterns-established:
  - "New mounted workflow pages use `handle_params/3` plus `Session.resolve/3` to normalize env state before rendering."
  - "Shared shell navigation accepts env-aware link structs so future mounted pages can opt in without hardcoding route prefixes."
requirements-completed: [GOV-05, SCH-03]
duration: 24min
completed: 2026-04-24
---

# Phase 11 Plan 01: Mounted Governance Routes Summary

**Mounted governance and schedule route contracts with canonical env state and shared shell navigation**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-04-24T13:37:00-04:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added mounted `change-requests` and `schedule` routes under the existing `rulestead_admin "/admin/flags"` seam, keeping them ahead of the dynamic `/:key` routes.
- Created four route-backed Phase 11 LiveView stubs that normalize `?env=` through the shared session helper and link operators between queue, review, schedule, audit, and flag inventory pages.
- Extended `Shell.page/1` with optional governance navigation so mounted workflow pages can expose stable cross-links without introducing standalone-admin chrome.

## Task Commits

1. **Task 1: Add mounted governance and schedule route contracts**
   - `2124d9d` `test(11-01): add failing governance route contract tests`
   - `4709270` `feat(11-01): add mounted governance route stubs`
2. **Task 2: Extend the shared shell with governance navigation without breaking calm operator posture**
   - `6b2d6ca` `feat(11-01): add governance shell navigation`

## Verification

- `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/governance_route_contract_test.exs`
  - Passed: `4 tests, 0 failures`
  - Warning only: deprecated `Phoenix.ConnTest` usage from existing test style.

## Decisions Made

- Kept the Phase 11 pages as explicit route homes with placeholder copy instead of embedding approval or schedule workflows into the existing flag pages early.
- Used shared shell navigation inputs rather than hardcoding route chrome inside each LiveView template.
- Preserved mount awareness by deriving every cross-link from `Session.current_path/2` and the mounted admin path.

## Deviations from Plan

None.

## Deferred Issues

- The placeholder route homes intentionally stop short of loading real change-request and scheduled-execution data; that lands in `11-02` and `11-03`.

## Known Stubs

- `RulesteadAdmin.Live.ChangeRequestLive.Index`
- `RulesteadAdmin.Live.ChangeRequestLive.Show`
- `RulesteadAdmin.Live.ScheduleLive.Index`
- `RulesteadAdmin.Live.ScheduleLive.Show`

## Self-Check: PASSED
