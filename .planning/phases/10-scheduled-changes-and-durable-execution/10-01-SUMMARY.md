---
phase: 10-scheduled-changes-and-durable-execution
plan: 01
subsystem: scheduling
tags: [scheduled-execution, governance, ecto, store-contracts, tdd]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: fixed governance lifecycle, actor-chain, and correlation vocabulary
provides:
  - durable scheduled execution and execution attempt state tables
  - canonical scheduling domain contracts with replay identity and redacted metadata
  - explicit schedule-first store callbacks and command structs for later adapter work
affects: [phase-10-executor, phase-10-action-integration, phase-11-schedule-ui]
tech-stack:
  added: []
  patterns: [tdd, durable product-owned state, explicit scheduling lifecycle, key-first governance commands]
key-files:
  created:
    - rulestead/priv/repo/migrations/TIMESTAMP_create_rulestead_scheduled_executions_and_attempts.exs
    - rulestead/lib/rulestead/governance/scheduled_execution.ex
    - rulestead/lib/rulestead/governance/execution_attempt.ex
    - rulestead/test/rulestead/store/command_scheduled_execution_test.exs
  modified:
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
key-decisions:
  - "Scheduled execution is product-owned state with explicit lifecycle checks and replay identity; Oban linkage stays secondary."
  - "The scheduling contract is bounded to publish_ruleset, advance_rollout, engage_kill_switch, and release_kill_switch with execution_mode constrained to change_request, policy_bypass, or emergency_bypass."
  - "Scheduling metadata, actor summaries, and attempt details are normalized and stripped of session-shaped fields at contract boundaries."
patterns-established:
  - "Scheduled execution contracts mirror persisted field names and preserve operator-facing timing, provenance, and failure details."
  - "Schedule-first commands follow the existing governance command style: explicit identifiers, actor, reason, metadata, and normalized string-keyed maps."
requirements-completed: [SCH-01, SCH-04]
duration: 12min
completed: 2026-04-24
---

# Phase 10 Plan 01: Scheduled Execution Contracts Summary

**Durable scheduled execution substrate with explicit lifecycle state, replay identity, and schedule-first command contracts**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-04-24T16:16:24Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added durable `scheduled_executions` and `execution_attempts` tables with foreign-key linkage, explicit state constraints, unique replay identity, and operator-facing timing/failure fields.
- Added `Rulestead.Governance.ScheduledExecution` and `Rulestead.Governance.ExecutionAttempt` contracts that normalize actor-chain data, bounded action vocabulary, and redacted serialized metadata.
- Extended `Rulestead.Store` and `Rulestead.Store.Command` with schedule-first callbacks and command structs for schedule, cancel, requeue, execute, fetch, and list flows.

## Task Commits

1. **Task 1: Create the scheduled-execution lifecycle schema and domain contracts**
   - `58267dd` `test(10-01): add failing scheduled execution contracts test`
   - `18ddf23` `feat(10-01): add durable scheduled execution contracts`
2. **Task 2: Extend the store behavior and command layer for schedule-first governance**
   - `68eeab5` `feat(10-01): extend schedule-first store contracts`

## Verification

- `cd rulestead && mix test test/rulestead/store/command_scheduled_execution_test.exs`
  - Passed: `5 tests, 0 failures`
  - Warnings only: `Rulestead.Store.Ecto` and `Rulestead.Fake` do not implement the new scheduled-execution callbacks yet. That parity work is deferred to later Phase 10 plans.
- Boundary check on the Phase 10 files found no `rulestead_admin`, webhook, or LiveView references in the newly added scheduling files.

## Decisions Made

- Kept the durable scheduling record as the operator-facing source of truth instead of encoding lifecycle state in Oban jobs.
- Limited the Phase 10 contract to the four planned governed actions and the three explicit execution modes from the phase context.
- Stripped session-shaped fields from serialized scheduled execution and attempt metadata to preserve the existing governance security posture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Cleared a stale git index lock during the RED commit**
- **Found during:** Task 1 commit
- **Issue:** `git commit` initially failed with `.git/index.lock` present even though no active git process owned the lock.
- **Fix:** Verified the lock was stale, retried the commit once the lock was gone, and continued without touching unrelated worktree changes.
- **Files modified:** None
- **Commit:** Not applicable

None otherwise - plan executed within the defined Phase 10 scope.

## Deferred Issues

- New `Rulestead.Store` callback warnings remain until later Phase 10 plans implement the scheduled-execution surface in `Rulestead.Store.Ecto` and `Rulestead.Fake`.

## Known Stubs

None.

## Self-Check: PASSED
