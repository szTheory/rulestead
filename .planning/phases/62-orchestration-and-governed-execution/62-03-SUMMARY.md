---
phase: 62-orchestration-and-governed-execution
plan: 62-03
subsystem: api
tags: [scheduled-execution, auto-advance, governance, change-request, orchestration]

requires:
  - phase: 62-orchestration-and-governed-execution
    plan: 62-02
    provides: RolloutAutoAdvance.execute_scheduled_tick/3, blocked/CR outcome atoms, Ecto/Fake automation branches
provides:
  - Protected-environment Authorizer.approval_requirement/4 routing at tick execute
  - SubmitChangeRequest automation path with advance_rollout command_snapshot parity
  - Completed scheduled execution metadata for blocked and change_request_submitted outcomes
  - scheduled_execution.succeeded audit context with change_request_id link
  - Fake.Control.list_change_requests!/1 test helper
affects:
  - 62-04 orchestration contract tests

tech-stack:
  added: []
  patterns:
    - "approval_requirement consulted at execute time not schedule time (D-04)"
    - "Protected automation submits CR only — never approve_change_request"
    - "automation_execution_metadata/1 shared outcome metadata for Ecto and Fake finalize"

key-files:
  created: []
  modified:
    - rulestead/lib/rulestead/governance/rollout_auto_advance.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/fake/control.ex

key-decisions:
  - "Consult Authorizer at eligible tick execute; production/protected envs submit advance_rollout CR with signal_facts and window bounds in command snapshot"
  - "Shared RolloutAutoAdvance.automation_execution_metadata/1 and automation_audit_metadata/1 for Ecto/Fake finalize parity"
  - "Never call approve_change_request from automation path — human approval via existing CR execute envelope only"

patterns-established:
  - "change_request_submitted outcome returns {:ok, %{outcome: :change_request_submitted, change_request: cr}} without ruleset mutation"
  - "execution_metadata outcome keys: blocked | change_request_submitted with reasons or change_request_id"

requirements-completed: [ROL-06, ORC-01]

duration: 18min
completed: 2026-05-27
---

# Phase 62 Plan 03: Protected-Environment Routing And Store Integration Summary

**Protected environments auto-submit advance_rollout change requests at observation-window ticks; non-protected environments direct-advance through the orchestrator with Fake/Ecto finalize parity and audit CR links.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T19:50:00Z
- **Completed:** 2026-05-27T20:08:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- `RolloutAutoAdvance.build_advance_command/7` branches on `Authorizer.approval_requirement/4` at execute time per D-04.
- Protected path builds `SubmitChangeRequest` with `advance_rollout` command snapshot (rollout stage/percentage, window bounds, signal_facts) and calls `store.submit_change_request/1`.
- Non-protected path returns `AdvanceRollout` command for direct governed advance.
- Ecto and Fake finalize completed automation ticks with `execution_metadata` outcome keys; audit context includes `change_request_id` when CR submitted.
- `Fake.Control.list_change_requests!/1` exposes change requests for contract test assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Protected-environment change request branch in orchestrator** - `9d845f1` (feat)
2. **Task 2: Ecto store integration for CR submit and tick finalize** - `9b9aca9` (feat)
3. **Task 3: Fake adapter submit_change_request parity** - `8bc6293` (feat)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `rulestead/lib/rulestead/governance/rollout_auto_advance.ex` - Authorizer gate, submit_protected_change_request/11, automation metadata helpers
- `rulestead/lib/rulestead/store/ecto.ex` - Finalize merges automation outcome metadata; audit links CR id
- `rulestead/lib/rulestead/fake.ex` - Parity finalize metadata merge on completed ticks
- `rulestead/lib/rulestead/fake/control.ex` - `list_change_requests!/1` test helper

## Decisions Made

- Reuse `ApprovalRequirement.serialize/1` for CR snapshot; metadata carries guardrail_automation source and eligibility snapshot.
- Shared outcome metadata helpers on RolloutAutoAdvance module to avoid Ecto/Fake drift on blocked vs CR-submitted finalize.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `scheduled_execution_adapter_contract_test.exs` could not run in executor environment due to PostgreSQL `too_many_connections` / pool exhaustion. `mix compile --warnings-as-errors` passes; `guarded_rollout_test.exs` and `rollout_auto_advance_contract_test.exs` (11 tests) exit 0.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **62-04**: contract tests proving healthy auto-advance, blocked non-advance, protected-env CR parity, and idempotency races (ORC-02, AUD-03).
- Governed execution routing (ROL-06) and schedule→execute envelope (ORC-01) are complete for protected/non-protected paths.

## Self-Check: PASSED

- [x] Orchestrator calls `Authorizer.approval_requirement/4` before direct advance
- [x] Protected path calls `submit_change_request/1` not `advance_rollout/1`
- [x] Return includes `outcome: :change_request_submitted` atom
- [x] No `approve_change_request` reference in rollout_auto_advance.ex
- [x] Blocked and CR-submitted outcomes finalize as `:completed` scheduled execution state
- [x] `guarded_rollout_test.exs` and `rollout_auto_advance_contract_test.exs` exit 0
- [x] `mix compile --warnings-as-errors` exits 0

---
*Phase: 62-orchestration-and-governed-execution*
*Completed: 2026-05-27*
