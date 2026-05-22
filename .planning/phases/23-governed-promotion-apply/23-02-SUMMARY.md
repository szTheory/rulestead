---
phase: 23-governed-promotion-apply
plan: 02
subsystem: backend
tags: [promotion, governance, approvals, policy, ecto]
requires:
  - phase: 23-governed-promotion-apply
    provides: direct promotion apply bundle, immutable environment versions, adapter parity
provides:
  - promotion as a first-class governed action across approval and policy surfaces
  - persistence constraints for promotion-backed change requests and scheduled executions
  - durable governed promotion snapshots captured at submission time
affects: [23-governed-promotion-apply, governance, rulestead]
tech-stack:
  added: [ecto migrations]
  patterns: [governed action parity, stored reviewed bundle snapshots]
key-files:
  created:
    - rulestead/priv/repo/migrations/20260518234600_extend_rulestead_change_request_actions_for_promotion.exs
    - rulestead/priv/repo/migrations/20260518234700_extend_rulestead_scheduled_execution_actions_for_promotion.exs
  modified:
    - rulestead/lib/rulestead/governance/approval_requirement.ex
    - rulestead/lib/rulestead/admin/authorizer.ex
    - rulestead/lib/rulestead/admin/policy.ex
    - rulestead/lib/rulestead/governance/change_request.ex
    - rulestead/lib/rulestead/governance/scheduled_execution.ex
    - rulestead/test/rulestead/governance_facade_contract_test.exs
    - rulestead/test/rulestead/governance_safety_contract_test.exs
key-decisions:
  - "Promotion reuses the existing governed-action surfaces instead of introducing a parallel approval flow."
  - "Governed promotion stores the reviewed promotion bundle snapshot directly in command_snapshot for later execution."
patterns-established:
  - "Every governed-action allowlist and DB constraint must move together when promotion vocabulary expands."
  - "Protected-target promotion submission persists reviewed compare state rather than recomputing source intent later."
requirements-completed: [PROM-03, PROM-04]
duration: 35m
completed: 2026-05-18
---

# Phase 23: Governed Promotion Apply Summary

**Promotion now participates in the existing governed action model, with reviewed bundle snapshots persisted for later protected-target execution**

## Performance

- **Duration:** 35m
- **Completed:** 2026-05-18
- **Tasks:** 1
- **Files modified:** 9

## Accomplishments

- Added `promote_environment` across governance approval, policy, authorization, and persistence vocabularies.
- Extended change request and scheduled execution constraints so promotion is a valid governed action in the database layer.
- Added governance contract coverage proving promotion submission is accepted and treated as governed work.

## Task Commits

No commits were created in this workspace run because the repository already contained unrelated user and build-tree changes.

## Files Created/Modified

- `rulestead/lib/rulestead/governance/approval_requirement.ex` - promotion added to approval requirement action handling
- `rulestead/lib/rulestead/admin/authorizer.ex` - promotion accepted by existing authorization surface
- `rulestead/lib/rulestead/admin/policy.ex` - promotion added to governed policy checks
- `rulestead/lib/rulestead/governance/change_request.ex` - promotion added to change-request action vocabulary
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` - promotion added to scheduled execution action vocabulary
- `rulestead/priv/repo/migrations/20260518234600_extend_rulestead_change_request_actions_for_promotion.exs` - widened change request action constraint
- `rulestead/priv/repo/migrations/20260518234700_extend_rulestead_scheduled_execution_actions_for_promotion.exs` - widened scheduled execution action constraint
- `rulestead/test/rulestead/governance_facade_contract_test.exs` - governed promotion submission coverage
- `rulestead/test/rulestead/governance_safety_contract_test.exs` - protected-target promotion governance safety coverage

## Decisions Made

- Kept promotion inside the current governance rails rather than adding promotion-specific approval types.
- Used follow-on migrations to extend action constraints so existing installs can evolve without rewriting original migrations.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None beyond normal migration/test verification.

## User Setup Required

None for review. Environments using the Ecto store still need the new migrations applied.

## Next Phase Readiness

- Protected-target promotion can now execute from persisted governed state.
- The stored reviewed bundle snapshot is available for schedule-time safety checks and audit linkage.

---
*Phase: 23-governed-promotion-apply*
*Completed: 2026-05-18*
