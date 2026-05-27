---
phase: 59-mounted-governance-workflows
plan: 59-02
subsystem: ui
tags: [phoenix-liveview, governance, audience-preview, blast-radius]

requires:
  - phase: 59-01
    provides: GovernanceComponents.blast_radius_panel and AudienceLive.Governance.load_governance_context
provides:
  - Edit and archive preview surfaces with governance callout, blast-radius panel, and CTA branching
  - Prod LiveView tests asserting governed preview copy and Continue to submit CTA
affects:
  - 59-03 confirm apply/submit fork
  - 59-04 CR show evidence

tech-stack:
  added: []
  patterns:
    - "Preview loads governance context after preview_audience_impact success"
    - "Governance panel and change-request callout render above impact_preview"

key-files:
  created:
    - rulestead_admin/test/rulestead_admin/live/audience_live/archive_preview_test.exs
  modified:
    - rulestead_admin/lib/rulestead_admin/live/audience_live/edit_preview.ex
    - rulestead_admin/lib/rulestead_admin/live/audience_live/archive_preview.ex
    - rulestead_admin/test/rulestead_admin/live/audience_live/edit_preview_test.exs

key-decisions:
  - "Archive governed callout uses archive-specific copy; direct-apply CTA remains Continue to archive confirm"
  - "Prod test seeds put_environment!(prod) before flags; archive threshold 0 triggers change_request with one reference"

patterns-established:
  - "Protected preview: change_request callout + blast_radius_panel + Continue to submit before impact_preview"
  - "Blocked governance_mode hides Continue link; Back to audience only"

requirements-completed: [ADM-01, ADM-02]

duration: 12min
completed: 2026-05-27
---

# Phase 59 Plan 02: Audience Preview Governance UX Summary

**Edit and archive preview LiveViews load blast-radius assessment, show governance evidence above impact preview, and branch Continue CTA copy for protected above-threshold mutations.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T17:24:00Z
- **Completed:** 2026-05-27T17:36:29Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- `EditPreview` pipes successful impact preview through `Governance.load_governance_context/3` with `operation: :update`.
- `ArchivePreview` mirrors governance panel, callout, and CTA branching with `operation: :archive`.
- Prod LiveView tests assert `Change request required`, `Governance required`, `Continue to submit`, and absence of direct-apply CTA strings.

## Task Commits

1. **Task 59-02-01: Edit preview governance panel and CTA** - `2274f53` (feat)
2. **Task 59-02-02: Archive preview parity** - `48f478a` (feat)

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/live/audience_live/edit_preview.ex` - Governance loader, panel, callout, CTA branching
- `rulestead_admin/lib/rulestead_admin/live/audience_live/archive_preview.ex` - Archive parity for governance UX
- `rulestead_admin/test/rulestead_admin/live/audience_live/edit_preview_test.exs` - Prod above-threshold update preview test
- `rulestead_admin/test/rulestead_admin/live/audience_live/archive_preview_test.exs` - Prod archive with references governed test

## Decisions Made

- Archive direct-apply path keeps **Continue to archive confirm** (not edit's "Continue to confirm") per existing archive copy.
- Prod test fixture seeds `put_environment!(prod)` explicitly; Fake does not auto-create prod on `put_flag!`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Seed prod environment before prod-scoped flags**
- **Found during:** Task 59-02-01 (governance in prod test setup)
- **Issue:** `put_flag!` with `environment_keys: ["prod"]` raised `environment was not found`
- **Fix:** Call `Control.put_environment!(%{key: "prod", name: "Production"})` in prod seed helpers
- **Files modified:** `edit_preview_test.exs`, `archive_preview_test.exs`
- **Verification:** `mix test` edit_preview + archive_preview — 5 tests, 0 failures
- **Committed in:** `2274f53`, `48f478a`

---

**Total deviations:** 1 auto-fixed (blocking test fixture)
**Impact on plan:** Test-only addition; no production code scope change.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for `59-03` confirm apply/submit fork on edit and archive confirm LiveViews.
- Preview surfaces set operator expectation; confirm must re-assess and swap Apply vs Submit change request.

## Self-Check: PASSED

- `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs test/rulestead_admin/live/audience_live/archive_preview_test.exs` — 5 tests, 0 failures
- `grep load_governance_context edit_preview.ex archive_preview.ex` — both present
- `grep blast_radius_panel edit_preview.ex archive_preview.ex` — both present
- `git log --oneline --grep="59-02"` — 2 feat commits

---
*Phase: 59-mounted-governance-workflows*
*Completed: 2026-05-27*
