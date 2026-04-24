---
phase: 11-mounted-admin-governance-and-schedule-ui
plan: 02
subsystem: rulestead_admin
tags: [governance-ui, change-requests, flag-detail, liveview, tdd]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: change-request lifecycle, approval records, and audited mutation verbs
  - phase: 11-mounted-admin-governance-and-schedule-ui
    plan: 01
    provides: mounted change-request routes and shell navigation
provides:
  - public change-request read helpers on the root facade
  - dedicated change-request queue and diff-first review page
  - compact flag-detail governance and scheduled-change preview cards
affects: [phase-11-governance-review-ui, phase-11-flag-detail-summaries, phase-11-verification]
tech-stack:
  added: []
  patterns: [tdd, diff-first review, preview-confirm-audit, route-backed summary cards]
key-files:
  created:
    - rulestead_admin/test/rulestead_admin/live/change_request_live/index_test.exs
    - rulestead_admin/test/rulestead_admin/live/change_request_live/show_test.exs
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/test/rulestead/governance_facade_contract_test.exs
    - rulestead_admin/lib/rulestead_admin/live/change_request_live/index.ex
    - rulestead_admin/lib/rulestead_admin/live/change_request_live/show.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex
    - rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs
key-decisions:
  - "Mounted admin reads change requests only through `Rulestead.fetch_change_request/1` and `Rulestead.list_change_requests/1`, not store adapters."
  - "Approve/reject and execute/schedule remain separate route-backed actions, with explicit confirmation and reason capture before mutation."
  - "Flag detail surfaces governance work as compact previews with deep links rather than inline review workspaces."
patterns-established:
  - "Change-request detail uses a lightweight pending-action state machine to preserve preview -> confirm -> audit without separate confirmation routes."
  - "Flag detail preview cards stay redaction-safe by truncating to a few route-backed entries sourced from public list facades."
requirements-completed: [GOV-05, SCH-03]
duration: 58min
completed: 2026-04-24
---

# Phase 11 Plan 02: Governed Review UI Summary

**Change-request queue and diff-first review workflow with calm flag-detail governance summaries**

## Performance

- **Duration:** 58 min
- **Completed:** 2026-04-24T13:48:00-04:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added public root-facade read helpers for change requests and proved them through the governance facade contract suite.
- Implemented a dedicated mounted change-request queue with status/action/resource filters, canonical `?env=` links, and deep links into the review route and related flag.
- Built a diff-first review page that keeps approval separate from execute/schedule, requires explicit reason capture in the confirm step, and returns visible audit-linked state after mutation.
- Extended flag detail with compact `Open change requests` and `Scheduled changes` cards so operators can discover governance work without turning the page into a workflow hub.

## Task Commits

1. **Task 1 and Task 2: Add governed review surfaces**
   - `3de3afa` `feat(11-02): add governed review surfaces`

## Verification

- `cd rulestead && mix test test/rulestead/governance_facade_contract_test.exs`
  - Passed: `4 tests, 0 failures`
- `cd rulestead_admin && mix test test/rulestead_admin/live/change_request_live/index_test.exs test/rulestead_admin/live/change_request_live/show_test.exs test/rulestead_admin/live/flag_live/show_test.exs`
  - Passed: `8 tests, 0 failures`
  - Warnings only: existing deprecated `Phoenix.ConnTest` usage in test modules.

## Decisions Made

- Kept the review page on one mounted route with a lightweight confirmation state rather than splitting every action into a separate child route.
- Limited the flag-detail previews to a few route-backed rows so the page stays read-oriented while still advertising open governance work.
- Reused the schedule route as the destination for post-approval scheduling evidence instead of inventing a second scheduling-specific workflow surface.

## Deviations from Plan

None.

## Deferred Issues

- Accessibility, sibling-package mount verification, and docs updates remain in `11-04`.

## Known Stubs

None.

## Self-Check: PASSED
