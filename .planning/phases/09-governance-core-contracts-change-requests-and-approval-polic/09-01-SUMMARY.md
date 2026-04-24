---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
plan: 01
subsystem: api
tags: [governance, change-requests, approvals, audit, testing]
requires:
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: host-owned policy seam, redaction rules, and audit correlation constraints
  - phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
    provides: release-grade contract discipline for core package APIs
provides:
  - governance change request contract with fixed lifecycle states and governed action atoms
  - approval requirement snapshot with explicit required approvals and self-approval posture
  - approval contract serialization with shared correlation identifiers
affects: [phase-09-store, phase-09-policy, phase-09-facade]
tech-stack:
  added: []
  patterns: [plain domain structs, explicit policy snapshots, contract-first tests]
key-files:
  created:
    - rulestead/lib/rulestead/governance/change_request.ex
    - rulestead/lib/rulestead/governance/approval.ex
    - rulestead/lib/rulestead/governance/approval_requirement.ex
    - rulestead/test/rulestead/governance/change_request_contract_test.exs
  modified: []
key-decisions:
  - "Governance contracts keep actor identity host-supplied and never infer it from admin sessions or sockets."
  - "Change requests serialize only structured governance facts: action, resource, environment, actor summary, command snapshot, approval requirement, and correlation ID."
  - "Self-approval posture is explicit contract data via `self_approval_allowed?`, not a derived UI or role-side effect."
patterns-established:
  - "Governance contracts expose fixed atom lists through helper functions before persistence or UI wiring."
  - "Approval and change-request records share a correlation model through explicit `correlation_id` fields and serializer surfaces."
requirements-completed: []
duration: 3min
completed: 2026-04-24
---

# Phase 9 Plan 01: Governance Contract Summary

**Governance change-request, approval, and approval-requirement contracts with fixed lifecycle atoms and shared correlation serialization**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-24T14:33:53Z
- **Completed:** 2026-04-24T14:37:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Rulestead.Governance.ChangeRequest` with exact lifecycle states, governed action atoms, and structured serialization.
- Added `Rulestead.Governance.ApprovalRequirement` and `Rulestead.Governance.Approval` contracts for explicit approval counts, self-approval posture, reviewer identity, and shared correlation IDs.
- Locked the Phase 9 governance language with focused ExUnit contract tests in the core package only.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define the governance domain contracts and canonical lifecycle vocabulary** - `00346eb` (test), `dbaec35` (feat)
2. **Task 2: Add executable contract tests that freeze the governance nouns and state model** - `29031a8` (test), `b934f6a` (feat)

## Files Created/Modified

- `rulestead/lib/rulestead/governance/change_request.ex` - Canonical governed mutation struct, lifecycle helpers, and serializer
- `rulestead/lib/rulestead/governance/approval.ex` - Reviewer decision contract, decision atoms, and serializer
- `rulestead/lib/rulestead/governance/approval_requirement.ex` - Approval policy snapshot with explicit self-approval posture
- `rulestead/test/rulestead/governance/change_request_contract_test.exs` - Contract suite freezing governance vocabulary and correlation semantics

## Decisions Made

- Kept governance actor data as a host-supplied summary map with `id`, `type`, and `display` only.
- Normalized resource and environment identifiers to string-friendly contract fields while keeping governed actions and states as atoms.
- Excluded admin-session, scheduler, webhook, and request-object concerns from the Phase 9 language layer.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 2 needed an `Approval.serialize/1` function to freeze shared correlation semantics. This was added as the minimal contract surface required by the new tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 9 store and policy plans can persist and enforce these contracts without reopening naming, state, or self-approval decisions.
- No blockers found for `09-02`.

## Self-Check: PASSED

---
*Phase: 09-governance-core-contracts-change-requests-and-approval-polic*
*Completed: 2026-04-24*
