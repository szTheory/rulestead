---
phase: 62-orchestration-and-governed-execution
plan: 62-02
subsystem: api
tags: [scheduled-execution, auto-advance, guardrails, governance, orchestration]

requires:
  - phase: 62-orchestration-and-governed-execution
    plan: 62-01
    provides: schedule hook, idempotency keys, command snapshot shape, RolloutAutoAdvance.Schedule helpers
provides:
  - RolloutAutoAdvance.execute_scheduled_tick/3 orchestration pipeline
  - Snapshot freshness validation against live GuardrailDecision
  - Fresh signal resolution via Guardrails.fetch_signal/2 at execute time
  - Blocked tick success finalize path (no ruleset mutation)
  - AdvanceRollout command construction from policy next_stage/next_percentage
  - Ecto and Fake execute_direct_scheduled_action automation branches
affects:
  - 62-03 protected-env change-request routing
  - 62-04 orchestration contract tests

tech-stack:
  added: []
  patterns:
    - "Store-delegated orchestration via execute_scheduled_tick(store, ...)"
    - "Blocked eligibility returns {:ok, %{outcome: :blocked}} not {:error, _}"
    - "Snapshot stale → auto_advance_superseded or rollout_stage_conflict before evaluate"

key-files:
  created:
    - rulestead/lib/rulestead/governance/rollout_auto_advance.ex
  modified:
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex

key-decisions:
  - "Use fetch_guardrail_status for snapshot freshness compare against decision stage/percentage/window_ends"
  - "Short-circuit disabled/incomplete policy to blocked outcome before signal fetch and evaluate"
  - "Advance command metadata carries guardrail_automation source, scheduled_execution_id, eligibility snapshot"

patterns-established:
  - "automation_tick?/1 guards on metadata source guardrail_automation (string or atom)"
  - "Non-automation advance_rollout scheduled ticks retain direct snapshot replay path"

requirements-completed: [ORC-01, AUD-03]

duration: 14min
completed: 2026-05-27
---

# Phase 62 Plan 02: Execute Orchestration Module Summary

**Automation ticks validate live rollout snapshots, resolve fresh guardrail signals, evaluate eligibility, and either complete blocked without mutation or build governed AdvanceRollout commands with guardrail_automation metadata.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-05-27T19:35:00Z
- **Completed:** 2026-05-27T19:49:37Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `Rulestead.Governance.RolloutAutoAdvance` with `automation_tick?/1` and `execute_scheduled_tick/3` pipeline per D-01, D-05, D-06.
- Snapshot freshness compares stage, percentage, and `monitoring_window_ends_at` against latest `GuardrailDecision` before evaluation.
- Fresh `signal_facts` resolved from active rollout rule guardrails via `Guardrails.fetch_signal/2` at execute time (empty schedule snapshot).
- Blocked eligibility returns `{:ok, %{outcome: :blocked, ...}}` for success finalize — not quarantine retry.
- Ecto and Fake `execute_direct_scheduled_action("advance_rollout", ...)` branch on automation metadata with parity outcome atoms.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RolloutAutoAdvance orchestration module** - `c5190e8` (feat)
2. **Task 2: Wire orchestrator into Ecto execute_direct_scheduled_action** - `1b618fa` (feat)
3. **Task 3: Wire orchestrator into Fake execute path** - `ba8e8d4` (feat)

**Plan metadata:** `448cbf0` (docs)

## Files Created/Modified

- `rulestead/lib/rulestead/governance/rollout_auto_advance.ex` - Execute orchestration: validate, fetch policy, resolve signals, evaluate, build advance command
- `rulestead/lib/rulestead/store/ecto.ex` - Automation tick branch in `execute_direct_scheduled_action/3`
- `rulestead/lib/rulestead/fake.ex` - Parity automation tick branch with blocked success finalize

## Decisions Made

- Re-fetch policy at execute; disabled/incomplete policy yields blocked completion without calling evaluate when policy fetch succeeds but policy is not schedulable.
- Ruleset conflict for missing rollout rule or blank `next_stage` maps to `auto_advance_ruleset_conflict` bounded error.
- Protected-environment change-request submit routing deferred to 62-03; wiring handles `:change_request_submitted` outcome atom for forward compatibility.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- PostgreSQL unavailable (`cannot_connect_now` / connection pool exhaustion) prevented running `rollout_auto_advance_contract_test.exs` and `scheduled_execution_adapter_contract_test.exs` in executor environment. `mix compile --warnings-as-errors` passes; acceptance grep checks pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **62-03**: protected-environment change-request routing via `Authorizer.approval_requirement/4` and submit-at-tick path.
- Execute orchestration core (signal fetch → evaluate → advance or blocked) is wired; contract proof remains in 62-04.

## Self-Check: PASSED

- [x] Module `Rulestead.Governance.RolloutAutoAdvance` exists
- [x] `automation_tick?/1` returns true for `%{"source" => "guardrail_automation"}`
- [x] `execute_scheduled_tick/3` exported with arity 3
- [x] Blocked path returns `{:ok, %{outcome: :blocked, ...}}` not `{:error, _}`
- [x] Ecto/Fake branch on `RolloutAutoAdvance.automation_tick?/1`
- [x] Non-automation ticks use unchanged direct advance path
- [x] `mix compile --warnings-as-errors` exits 0

---
*Phase: 62-orchestration-and-governed-execution*
*Completed: 2026-05-27*
