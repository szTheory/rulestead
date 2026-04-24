---
phase: 10-scheduled-changes-and-durable-execution
plan: 03
subsystem: governance
tags: [scheduled-execution, governance, oban, ecto, fake, authorization]
requires:
  - phase: 10-01
    provides: durable scheduled execution schema and command contracts
  - phase: 10-02
    provides: transactional scheduling worker flow and fetch/list/requeue durability
provides:
  - public scheduling verbs on the root Rulestead facade
  - bounded Phase 10 governed-action vocabulary with release kill-switch support
  - explicit scheduled conflict reasons across Ecto and Fake adapters
affects: [phase-10-ui, scheduled-operator-ux, governance-policy]
tech-stack:
  added: []
  patterns: [root-facade scheduling verbs, bounded governed-action dispatch, visible scheduled conflict reasons]
key-files:
  created: [.planning/phases/10-scheduled-changes-and-durable-execution/10-03-SUMMARY.md]
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/admin/authorizer.ex
    - rulestead/lib/rulestead/admin/policy.ex
    - rulestead/lib/rulestead/governance/change_request.ex
    - rulestead/lib/rulestead/governance/approval_requirement.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/rulestead/scheduled_execution_facade_contract_test.exs
    - rulestead/test/rulestead/admin_governance_policy_test.exs
    - rulestead/test/rulestead/governance/change_request_contract_test.exs
    - rulestead/test/rulestead/scheduled_execution_conflict_test.exs
key-decisions:
  - "Direct scheduling stays bounded to the Phase 10 action set and reuses the existing authorizer seam rather than introducing a worker-only API."
  - "Scheduled publish, rollout, and kill-switch execution fail with explicit operator-facing reasons instead of mutating toward nearest valid state."
patterns-established:
  - "Public scheduling flows through `Rulestead.admin_write/2` and store reads, keeping the core package as the only required integration surface."
  - "Ecto and Fake adapters share the same bounded scheduled-action vocabulary and conflict reason strings."
requirements-completed: [SCH-01, SCH-04]
duration: 12min
completed: 2026-04-24
---

# Phase 10 Plan 03: Scheduled Governance Facade and Bounded Conflict Handling Summary

**Root-facade scheduling verbs with bounded governed-action authorization and explicit stale/conflict failure reasons across Ecto and Fake**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-24T16:33:08Z
- **Completed:** 2026-04-24T16:45:28Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `schedule_change_request/1`, `schedule_governed_action/1`, `cancel_scheduled_execution/1`, `requeue_scheduled_execution/1`, `fetch_scheduled_execution/1`, and `list_scheduled_executions/1` to the public `Rulestead` facade.
- Aligned policy, authorizer, change-request, and approval-requirement vocabulary on the bounded Phase 10 governed actions including `release_kill_switch`.
- Routed scheduled publish, rollout, and kill-switch execution through bounded helpers with explicit `failure_reason` values for archived, unpublished, rollout-conflict, and kill-switch-conflict states.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: add failing scheduled governance tests** - `1078a8c` (`test`)
2. **Task 1: add public scheduling verbs and update the bounded governed-action vocabulary together** - `6713302` (`feat`)
3. **Task 2: integrate bounded scheduled actions and visible conflict/staleness failures** - `9a8cfdc` (`feat`)

## Files Created/Modified

- `rulestead/lib/rulestead.ex` - public scheduling facade verbs, bounded direct-scheduling authorization, and routing updates
- `rulestead/lib/rulestead/admin/authorizer.ex` - bounded governed-action vocabulary plus approval requirement resolution helper
- `rulestead/lib/rulestead/admin/policy.ex` - canonical Phase 10 governance action set
- `rulestead/lib/rulestead/governance/change_request.ex` - bounded governed-action contract without legacy `:manage_settings` fallback
- `rulestead/lib/rulestead/governance/approval_requirement.ex` - matching bounded approval requirement normalization
- `rulestead/lib/rulestead/store/ecto.ex` - bounded scheduled execution dispatch and explicit conflict validation
- `rulestead/lib/rulestead/fake.ex` - adapter parity for bounded scheduled execution conflict handling
- `rulestead/test/rulestead/scheduled_execution_facade_contract_test.exs` - root-facade scheduling coverage
- `rulestead/test/rulestead/admin_governance_policy_test.exs` - policy vocabulary coverage including `release_kill_switch`
- `rulestead/test/rulestead/governance/change_request_contract_test.exs` - canonical governance contract coverage
- `rulestead/test/rulestead/scheduled_execution_conflict_test.exs` - stale/conflicting scheduled target proofs

## Decisions Made

- Direct `schedule_governed_action/1` accepts only the bounded Phase 10 actions and enforces either `policy_bypass` via host policy or `emergency_bypass` with an explicit emergency reason.
- Scheduled execution preserves the original scheduled record on conflicts and records exact failure reasons for later operator inspection or requeue.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Conflict suite reused the same scheduled correlation ID across scenarios**
- **Found during:** Task 2
- **Issue:** The stale/conflict test reused `req-#{action}` request IDs, which triggered Ecto uniqueness violations before the intended failure assertions ran.
- **Fix:** Generated per-scenario request IDs in the test helper so Ecto and Fake both execute the same stale/conflict paths.
- **Files modified:** `rulestead/test/rulestead/scheduled_execution_conflict_test.exs`
- **Verification:** `cd rulestead && mix test test/rulestead/scheduled_execution_conflict_test.exs test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Committed in:** `9a8cfdc`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary to verify the intended bounded failure semantics. No scope creep.

## Issues Encountered

None beyond the test correlation-id collision fixed above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 10 scheduling now exposes a stable public package seam for later admin UI work without depending on `rulestead_admin`.
- Later UI and webhook phases can rely on the exact scheduled conflict vocabulary: `archived_resource`, `ruleset_not_publishable`, `rollout_stage_conflict`, `kill_switch_already_engaged`, and `kill_switch_already_released`.

## Self-Check: PASSED

- Verified summary file exists on disk.
- Verified commits `1078a8c`, `6713302`, and `9a8cfdc` exist in git history.

---
*Phase: 10-scheduled-changes-and-durable-execution*
*Completed: 2026-04-24*
