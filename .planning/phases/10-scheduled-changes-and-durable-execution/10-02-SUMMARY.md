---
phase: 10-scheduled-changes-and-durable-execution
plan: 02
subsystem: database
tags: [oban, scheduled-execution, ecto, fake, governance, testing]
requires:
  - phase: 10-01
    provides: durable scheduled execution schema and store contracts
provides:
  - transactional scheduled execution enqueue through Oban
  - dedicated scheduled execution worker that reloads durable state before execution
  - Ecto and Fake parity for execute, cancel, fetch, list, retry exhaustion, and requeue semantics
affects: [phase-10, phase-11, scheduled-operations, governance]
tech-stack:
  added: []
  patterns: [schedule-first persistence, oban-as-delivery-only, append-only execution attempts]
key-files:
  created: [rulestead/lib/rulestead/oban.ex, rulestead/lib/rulestead/oban/scheduled_execution_worker.ex]
  modified: [rulestead/lib/rulestead/store/ecto.ex, rulestead/lib/rulestead/fake.ex, rulestead/test/rulestead/oban_scheduled_execution_test.exs, rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs]
key-decisions:
  - "Scheduled executions remain the product source of truth while Oban carries delivery intent only."
  - "Retry history is append-only by scheduled_execution_id, and exhausted retries quarantine instead of silently looping."
patterns-established:
  - "Scheduled worker pattern: Oban jobs carry bounded metadata plus scheduled_execution_id and reload durable state before mutation."
  - "Adapter parity pattern: Ecto and Fake share the same scheduled execution lifecycle vocabulary and replay semantics."
requirements-completed: [SCH-02, SCH-04]
duration: 9 min
completed: 2026-04-24
---

# Phase 10 Plan 02: Scheduled Changes and Durable Execution Summary

**Transactional Oban scheduling with a dedicated worker, durable retry history, and quarantined recovery semantics across Ecto and Fake adapters**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-24T16:22:59Z
- **Completed:** 2026-04-24T16:32:19Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `Rulestead.Oban.scheduled_execution_job/2` and `Rulestead.Oban.ScheduledExecutionWorker` so scheduled work is queued through the existing Oban seam with bounded metadata and durable identity.
- Made the Ecto schedule path transactional: scheduled execution rows and due-later Oban jobs are written in one persistence flow, and execution/retry/requeue/cancel/fetch/list semantics now operate against durable scheduled state.
- Brought `Rulestead.Fake` to parity and proved the shared lifecycle contract with adapter tests covering transient retries, quarantine, explicit requeue, replay safety, and operator-visible list/fetch payloads.

## Task Commits

Each task was committed atomically:

1. **Task 1-2 RED: scheduled execution durability tests** - `33488d8` (test)
2. **Task 1-2 GREEN: durable worker and adapter execution semantics** - `ea304e7` (feat)

**Plan metadata:** recorded in the final docs commit for this plan

## Files Created/Modified
- `rulestead/lib/rulestead/oban.ex` - builds scheduled execution jobs with bounded args, queue selection, and retry policy.
- `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` - reloads scheduled execution state from the store and executes through the store contract.
- `rulestead/lib/rulestead/store/ecto.ex` - adds transactional enqueue, durable execution attempts, quarantine/requeue/cancel/fetch/list behavior, and replay-safe execution handling.
- `rulestead/lib/rulestead/fake.ex` - mirrors scheduled execution lifecycle transitions and normalized payloads in-memory.
- `rulestead/test/rulestead/oban_scheduled_execution_test.exs` - verifies transactional enqueue shape and worker delegation.
- `rulestead/test/rulestead/store/scheduled_execution_adapter_contract_test.exs` - proves shared adapter semantics for retry, quarantine, requeue, cancel, fetch, and list operations.

## Decisions Made
- Reused the existing Oban seam rather than introducing a second executor substrate, keeping Oban as delivery plumbing and scheduled executions as the durable system of record.
- Preserved `scheduled_execution_id` across retry exhaustion and explicit requeue so replay safety and operator workflows remain tied to one durable record.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed the split `execute_governed_change/2` clause warning**
- **Found during:** Verification after Task 2
- **Issue:** The fallback clause for `execute_governed_change/2` had been separated from the earlier publish-specific clause, producing a compile warning during plan verification.
- **Fix:** Moved the fallback clause adjacent to the specific clause group so verification runs cleanly.
- **Files modified:** `rulestead/lib/rulestead/store/ecto.ex`
- **Verification:** `mix test test/rulestead/oban_scheduled_execution_test.exs` and `mix test test/rulestead/store/scheduled_execution_adapter_contract_test.exs`
- **Committed in:** `ea304e7` (part of task commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** No scope creep. The fix kept the implementation warning-free and aligned with the planned behavior.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 10 now has a durable scheduled executor that survives retries and restarts without turning Oban rows into the product state of record.
- Phase 11 can consume normalized scheduled execution fetch/list payloads without adapter-specific branching.

## Self-Check: PASSED
- Verified summary file exists.
- Verified `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` exists.
- Verified task commits `33488d8` and `ea304e7` exist in git history.
