---
phase: 59-mounted-governance-workflows
plan: 59-03
subsystem: ui
tags: [phoenix-liveview, governance, audience-confirm, change-request]

requires:
  - phase: 59-02
    provides: Preview governance UX and Continue to submit CTA expectation
  - phase: 59-01
    provides: Governance loader, blast_radius_panel, approval_expectation_assigns
provides:
  - Edit and archive confirm surfaces with apply vs submit_change_request fork
  - Shared Governance helpers for approval requirement and mutation command map
  - Prod LiveView tests for governed confirm submit and partial-visibility block
affects:
  - 59-04 CR show audience-mutation evidence

tech-stack:
  added: []
  patterns:
    - "Confirm re-assesses blast radius on mount and enforces governance_mode at submit"
    - "submit_change_request navigates to ChangeRequestLive.Show with unchanged-audience flash"

key-files:
  created:
    - rulestead_admin/test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/live/audience_live/governance.ex
    - rulestead_admin/lib/rulestead_admin/live/audience_live/edit_confirm.ex
    - rulestead_admin/lib/rulestead_admin/live/audience_live/archive_confirm.ex
    - rulestead_admin/test/rulestead_admin/live/audience_live/archive_confirm_test.exs

key-decisions:
  - "Apply allowed for :unrestricted and :direct_apply; submit only when :change_request"
  - "Archive confirm load_preview now passes preview_fingerprint for stale enforcement"
  - "Flash on CR show verified via redirect + submitted status (Shell does not render flash in test HTML)"

patterns-established:
  - "GovernanceTestPolicy in tests seeds with TestPolicy then swaps policy after fixture load"
  - "Partial visibility confirm reached via facade preview URL when preview blocks Continue link"

requirements-completed: [ADM-01, ADM-02, ADM-03]

duration: 18min
completed: 2026-05-27
---

# Phase 59 Plan 03: Audience Confirm Governance Actions Summary

**Edit and archive confirm LiveViews enforce blast-radius governance: direct apply below threshold, Submit change request above threshold, and fail-closed blocked state with prod LiveView proof.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T17:38:00Z
- **Completed:** 2026-05-27T17:40:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `EditConfirm` and `ArchiveConfirm` load governance context on mount, branch UI by `@governance_mode`, and handle `submit_change_request` with `Rulestead.submit_change_request/1`.
- `Governance` exports `build_approval_requirement/3`, `audience_mutation_command_map/4`, `merge_approval_expectations/2`, and `ensure_governance_mode/2`.
- Prod tests assert no Apply when governed, Submit CR redirect to `/change-requests/`, and partial visibility blocks both actions.

## Task Commits

1. **Task 59-03-01: Edit confirm apply vs submit_change_request** - `820fabd` (feat)
2. **Task 59-03-02: Archive confirm parity** - `c54f4fd` (feat)

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/live/audience_live/governance.ex` - Shared confirm submit helpers
- `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_confirm.ex` - Governed confirm UI and events
- `rulestead_admin/lib/rulestead_admin/live/audience_live/archive_confirm.ex` - Archive parity + fingerprint-aware preview load
- `rulestead_admin/test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs` - Prod submit, partial visibility, policy modules
- `rulestead_admin/test/rulestead_admin/live/audience_live/archive_confirm_test.exs` - Prod archive governed confirm tests

## Decisions Made

- Direct apply handler accepts `:unrestricted` and `:direct_apply` (not only `:direct_apply`).
- Archive flash copy uses "Audience archive is unchanged until..." variant per operation.
- Governed submit tests assert CR show landing (flash string set in LiveView but not rendered in test Shell layout).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Seed prod fixtures before GovernanceTestPolicy**
- **Found during:** Task 59-03-01 (test setup)
- **Issue:** `change_request_required?` true blocked `publish_ruleset!` during seed
- **Fix:** Seed with ConnCase TestPolicy, then swap to GovernanceTestPolicy
- **Files modified:** `edit_confirm_governance_test.exs`
- **Verification:** All 3 governance tests pass
- **Committed in:** `820fabd`

**2. [Rule 3 - Blocking] Partial visibility test cannot extract confirm href from blocked preview**
- **Found during:** Task 59-03-01 (partial visibility test)
- **Issue:** Blocked preview hides Continue link; `extract_confirm_href` returned nil
- **Fix:** Build confirm URL via `Rulestead.preview_audience_impact/3` facade helper
- **Files modified:** `edit_confirm_governance_test.exs`
- **Verification:** Partial visibility test passes
- **Committed in:** `820fabd`

**3. [Rule 1 - Bug] Archive confirm ignored preview fingerprint in load**
- **Found during:** Task 59-03-02 (parity with edit_confirm)
- **Issue:** Archive confirm checked query params but did not pass fingerprint to preview API
- **Fix:** Merge fingerprint opts into `preview_audience_impact/3` call
- **Files modified:** `archive_confirm.ex`
- **Verification:** Archive confirm tests pass (including existing direct-apply test)
- **Committed in:** `c54f4fd`

---

**Total deviations:** 3 auto-fixed (2 blocking test/setup, 1 bug)
**Impact on plan:** Test and correctness fixes only; no scope change.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for `59-04` CR show frozen blast-radius evidence for `apply_audience_mutation`.
- Confirm surfaces no longer expose Apply when above threshold; operators land on CR show after submit.

## Self-Check: PASSED

- `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs test/rulestead_admin/live/audience_live/archive_confirm_test.exs` — 6 tests, 0 failures
- `grep submit_change_request rulestead_admin/lib/rulestead_admin/live/audience_live/edit_confirm.ex archive_confirm.ex` — both present
- `git log --oneline --grep="59-03"` — 2 feat commits

---
*Phase: 59-mounted-governance-workflows*
*Completed: 2026-05-27*
