---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
plan: 04
subsystem: api
tags: [elixir, ecto, governance, audit, telemetry, testing]
requires:
  - phase: 09-02
    provides: governance persistence tables, audit correlation fields, and change request command structs
  - phase: 09-03
    provides: governance authorizer hooks and approval requirement snapshots
provides:
  - public governance facade verbs on `Rulestead`
  - fake and ecto governance transition parity
  - correlated audit and telemetry metadata for change request lifecycle events
affects: [phase-09, governance-ui, scheduled-execution, webhook-carryover]
tech-stack:
  added: []
  patterns: [command-first governance facade, correlated audit plus telemetry metadata, backend parity contract tests]
key-files:
  created: [.planning/phases/09-governance-core-contracts-change-requests-and-approval-polic/09-04-SUMMARY.md]
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/telemetry.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/test/rulestead/governance_facade_contract_test.exs
    - rulestead/test/rulestead/store/governance_adapter_contract_test.exs
key-decisions:
  - "Governed mutations stay inside the existing `admin_write/2` authorization and redaction envelope instead of creating a parallel facade path."
  - "Approve and execute remain separate store operations so later scheduling flows can execute already-approved work without changing the contract."
patterns-established:
  - "Governance transitions emit immutable audit rows keyed by shared `change_request_id` and `correlation_id`."
  - "Parity tests run the same lifecycle assertions against `Rulestead.Fake` and `Rulestead.Store.Ecto`."
requirements-completed: [GOV-01, GOV-02, GOV-03, GOV-04]
duration: 15m
completed: 2026-04-24
---

# Phase 09 Plan 04: Governance facade verbs and adapter-parity change request execution summary

**Public governance facade verbs with fake and ecto change-request lifecycle parity, correlated audit rows, and canonical `change_request.*` telemetry metadata**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-24T10:53:53-04:00
- **Completed:** 2026-04-24T11:08:59-04:00
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added command-first governed change-request verbs and governance authorization entrypoints to `Rulestead`.
- Routed governance writes through the existing admin authorization and redaction path while exposing canonical governance telemetry metadata.
- Implemented submit, approve, reject, cancel, execute, fetch, and list parity across the fake and ecto adapters with one shared contract suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add public governance verbs and canonical telemetry wiring at the root facade** - `ab5c37f` (test), `5a4b4a8` (feat)
2. **Task 2: Implement Ecto and Fake adapter parity for governance state transitions** - `4c69b71` (test), `468199d` (feat)

## Files Created/Modified
- `rulestead/lib/rulestead.ex` - exposes governance verbs and governance-specific authorization wrappers through the root facade.
- `rulestead/lib/rulestead/telemetry.ex` - allows canonical governance metadata fields for correlated admin telemetry.
- `rulestead/lib/rulestead/fake.ex` - mirrors full change-request lifecycle behavior and correlated audit state in memory.
- `rulestead/lib/rulestead/store/command.ex` - fixes optional governance list filters so omitted values stay `nil`.
- `rulestead/lib/rulestead/store/ecto.ex` - persists governance transitions, approvals, audit events, and execution-side publish mutations transactionally.
- `rulestead/test/rulestead/governance_facade_contract_test.exs` - locks the public facade contract and typed governance denial behavior.
- `rulestead/test/rulestead/store/governance_adapter_contract_test.exs` - proves fake and ecto parity for submit, approve, reject, cancel, execute, fetch, and list behavior.

## Decisions Made

- Kept governance execution inside the existing admin mutation envelope so Phase 7 authorization and redaction guarantees continue to apply.
- Preserved a two-step approval then execute lifecycle instead of collapsing them, matching the Phase 9 contract and Phase 10 scheduling needs.
- Used one backend-parity contract suite rather than adapter-specific expectations to prevent governance drift.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored `nil` semantics for optional governance list filters**
- **Found during:** Task 2 (Implement Ecto and Fake adapter parity for governance state transitions)
- **Issue:** `GovernanceSupport.normalize_string/1` converted omitted filter values into the literal string `"nil"`, causing change-request listing filters to exclude valid rows.
- **Fix:** Added a `nil` clause before string normalization so optional governance filters remain unset.
- **Files modified:** `rulestead/lib/rulestead/store/command.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/store/governance_adapter_contract_test.exs`
- **Committed in:** `468199d` (part of task commit)

**2. [Rule 3 - Blocking] Normalized raw-table Ecto governance update and diff paths**
- **Found during:** Task 2 (Implement Ecto and Fake adapter parity for governance state transitions)
- **Issue:** The raw-table change-request update path used unsupported `update_all ... returning`, and the publish diff helper assumed pre-normalized rule-position maps instead of ruleset structs during governed execution.
- **Fix:** Switched change-request updates to fetch-after-update, normalized ruleset position diff inputs, and moved list filters to conditional query composition for Ecto-safe optional filtering.
- **Files modified:** `rulestead/lib/rulestead/store/ecto.ex`
- **Verification:** `cd rulestead && mix test test/rulestead/governance_facade_contract_test.exs test/rulestead/admin_security_contract_test.exs test/rulestead/store/governance_adapter_contract_test.exs`
- **Committed in:** `468199d` (part of task commit)

---

**Total deviations:** 2 auto-fixed (1 rule-1, 1 rule-3)
**Impact on plan:** All fixes were required for governance adapter correctness and parity. No scope creep.

## Issues Encountered

- The Ecto adapter used raw table queries for governance persistence, which exposed `update_all` and nullable-filter constraints that do not appear in schema-backed paths.
- Governed execution reused existing publish audit diff helpers, which required broader normalization to accept ruleset structs as well as pre-shaped audit state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 09-05 can now build UI or orchestration flows against a stable public governance contract.
Correlated audit, telemetry, and backend parity are in place for scheduling and webhook follow-on work.

## Self-Check: PASSED
