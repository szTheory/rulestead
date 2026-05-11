---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 07
subsystem: infra
tags: [hex, github-actions, release-verification, drift-monitoring]
requires:
  - phase: 08-05
    provides: verification trio and published-artifact harness
  - phase: 08-06
    provides: gated Hex publish choreography and maintainer handoff
provides:
  - canonical shell entrypoint for post-publish release verification
  - daily/manual drift workflow that reuses the same verification logic
  - maintainer runbook for live evidence capture and drift interpretation
affects: [release-operations, REL-03, REL-04]
tech-stack:
  added: []
  patterns: [scripts-first release verification, rolling drift issue, Hex API version resolution]
key-files:
  created:
    - .github/workflows/verify-published-release.yml
    - scripts/ci/verify_published_release.sh
  modified:
    - MAINTAINING.md
key-decisions:
  - "The drift workflow skips cleanly before the first live publish instead of opening a false drift issue on Hex 404s."
  - "The shell wrapper verifies both sibling packages are visible on Hex for the requested version before running the verification trio."
patterns-established:
  - "Release verification entrypoints stay scripts-first and runnable both locally and from GitHub Actions."
  - "Published-release drift files one rolling issue with update_existing instead of creating daily duplicates."
requirements-completed: [REL-03, REL-04]
duration: pending checkpoint
completed: 2026-04-24
---

# Phase 08 Plan 07: Post-Publish Verification Summary

**Canonical post-publish verification shell entrypoint plus a daily rolling drift monitor, with live `0.1.0` evidence still blocked on the Hex publish not being visible yet**

## Performance

- **Duration:** In progress at human verification gate
- **Started:** 2026-04-24T00:00:00Z
- **Completed:** Blocked at checkpoint
- **Tasks:** 1 complete, 1 blocked
- **Files modified:** 4

## Accomplishments

- Added `scripts/ci/verify_published_release.sh` as the canonical local and CI entrypoint for the post-publish trio.
- Added `.github/workflows/verify-published-release.yml` to resolve the latest shared Hex release, reuse the shell entrypoint, and update one rolling drift issue only on real failures.
- Updated `MAINTAINING.md` with the exact post-publish command, required evidence bundle, and the difference between release blockers and recurring drift.

## Task Commits

1. **Task 1: Add the real post-publish entrypoint and recurring drift workflow** - `027afce` (feat)
2. **Task 2: Execute the live `v0.1.0` post-publish verification and capture evidence** - blocked, no commit

## Files Created/Modified

- `.github/workflows/verify-published-release.yml` - Daily and manual published-release verifier with rolling issue mode.
- `scripts/ci/verify_published_release.sh` - Repo-root shell wrapper for Hex visibility checks plus the verification trio.
- `MAINTAINING.md` - Maintainer-facing handoff, evidence capture, and drift interpretation guidance.
- `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-07-SUMMARY.md` - Checkpoint summary for the blocked live verification wave.

## Decisions Made

- The workflow treats missing Hex packages as "not published yet" and skips instead of filing a false drift issue.
- Real drift still fails the workflow and updates one existing open issue through `JasonEtco/create-an-issue` with `update_existing: true` and `search_existing: open`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added explicit Hex visibility checks ahead of the verification trio**
- **Found during:** Task 1 (post-publish entrypoint implementation)
- **Issue:** Running the trio without first confirming both sibling packages expose the requested version on Hex could blur the live-release boundary.
- **Fix:** The shell entrypoint now queries the Hex package API for both sibling packages and fails before running Mix tasks if the requested version is not live.
- **Files modified:** `scripts/ci/verify_published_release.sh`
- **Verification:** `bash scripts/ci/verify_published_release.sh 0.1.0` now fails immediately with the Hex visibility blocker instead of pretending the live proof ran.
- **Committed in:** `027afce`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Tightened the live-release trust boundary without expanding scope beyond the plan.

## Issues Encountered

- `https://hex.pm/api/packages/rulestead` returned `404` on 2026-04-24.
- `https://hex.pm/api/packages/rulestead_admin` returned `404` on 2026-04-24.
- `bash scripts/ci/verify_published_release.sh 0.1.0` failed immediately with `published package rulestead is not visible on Hex yet: https://hex.pm/api/packages/rulestead`.
- Because the live sibling artifacts are not visible on Hex yet, Task 2 cannot be completed honestly.

## User Setup Required

None - no new external configuration was added beyond the existing Hex publish setup from 08-06.

## Next Phase Readiness

- Task 1 is committed as `027afce` and ready for the live verification handoff.
- Task 2 remains blocked until both `rulestead` and `rulestead_admin` `0.1.0` are visible on Hex, then the maintainer must run `bash scripts/ci/verify_published_release.sh 0.1.0` and attach the output plus live URLs here.

## Blocking Checkpoint

- **Blocked task:** Task 2: Execute the live `v0.1.0` post-publish verification and capture evidence
- **Reason:** Live Hex package APIs returned `404` for both sibling package names on 2026-04-24, so there is no real published `0.1.0` artifact set to verify yet.
- **Required command after publish:** `bash scripts/ci/verify_published_release.sh 0.1.0`
- **Evidence still required:** command output, Hex package URLs for both sibling packages, and the versioned HexDocs URL.

---
*Phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release*
*Completed: checkpoint pending live publish*
