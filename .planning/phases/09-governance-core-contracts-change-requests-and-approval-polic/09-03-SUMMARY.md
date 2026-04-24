---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
plan: 03
subsystem: api
tags: [governance, policy, approvals, auth, testing]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: governance domain contracts and store command vocabulary from 09-01 and 09-02
provides:
  - host-owned governance policy hooks for change-request and self-approval decisions
  - authorizer approval-requirement snapshots for governed actions
  - default production self-approval denial and change-request-required enforcement
affects: [phase-09-facade, phase-09-store-adapters, phase-11-governance-ui]
tech-stack:
  added: []
  patterns: [optional host policy callbacks, fail-closed governance decisions, approval snapshot resolution]
key-files:
  created:
    - rulestead/test/rulestead/admin_governance_policy_test.exs
  modified:
    - rulestead/lib/rulestead/admin/policy.ex
    - rulestead/lib/rulestead/admin/authorizer.ex
    - rulestead/lib/rulestead/governance/approval_requirement.ex
key-decisions:
  - "Governance policy stays on the existing actor/action/resource/environment seam through optional callbacks instead of bundled auth context."
  - "Missing or failing governance hooks default to the stricter production posture: change requests required and self-approval denied."
patterns-established:
  - "Governed actions resolve to an explicit `ApprovalRequirement` snapshot before adapters run."
  - "Governance denials reuse the existing typed auth error envelope and denied-audit payload style."
requirements-completed: [GOV-02, GOV-03]
duration: 5min
completed: 2026-04-24
---

# Phase 9 Plan 03: Governance Policy Seam Summary

**Host-owned governance callbacks and authorizer snapshots that require production change requests selectively and deny production self-approval by default**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T14:45:22Z
- **Completed:** 2026-04-24T14:50:26Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added optional `Rulestead.Admin.Policy` callbacks for `change_request_required?/4` and `allow_self_approval?/4` without changing the host-owned auth seam.
- Extended `Rulestead.Governance.ApprovalRequirement` to persist resolved change-request posture alongside required approvals and self-approval state.
- Added governed authorizer entrypoints that return approval snapshots, deny direct production execution when a change request is required, and fail closed on production self-approval.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend the admin policy behavior with governance hooks that preserve the host seam** - `43be8c7` (test), `6763801` (feat)
2. **Task 2: Teach the authorizer to resolve governance policy and fail closed on self-approval** - `815243c` (test), `339f231` (feat)

## Files Created/Modified

- `rulestead/lib/rulestead/admin/policy.ex` - Adds optional governance callbacks on the existing host seam.
- `rulestead/lib/rulestead/admin/authorizer.ex` - Resolves governed approval requirements and denies unsafe production paths with typed auth errors.
- `rulestead/lib/rulestead/governance/approval_requirement.ex` - Stores `change_request_required?` alongside required approvals and self-approval posture.
- `rulestead/test/rulestead/admin_governance_policy_test.exs` - Locks the new policy seam and authorizer governance behavior with focused tests.

## Decisions Made

- Kept governance decisions on the existing actor/action/resource/environment callback shape rather than introducing request or identity wrapper structs.
- Used explicit authorizer functions to return `ApprovalRequirement` snapshots so later phases can persist and audit the resolved posture instead of recomputing it.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Verification still emits the pre-existing Phase `09-02` behaviour warnings for unimplemented governance store callbacks in `Rulestead.Fake` and `Rulestead.Store.Ecto`. This plan did not widen or change that adapter scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase `09-04` can consume the resolved approval snapshots and new authorizer entrypoints when wiring the facade and adapter parity for change-request flows.
- The host-owned `can?/4` seam still compiles for existing policies, and hosts can opt into finer governance control by implementing the new optional callbacks.

## Self-Check: PASSED

---
*Phase: 09-governance-core-contracts-change-requests-and-approval-polic*
*Completed: 2026-04-24*
