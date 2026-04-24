---
phase: 09-governance-core-contracts-change-requests-and-approval-polic
plan: 02
subsystem: database
tags: [governance, change-requests, approvals, audit, ecto, store-contracts]
requires:
  - phase: 09-governance-core-contracts-change-requests-and-approval-polic
    provides: fixed governance domain contracts and shared correlation vocabulary from 09-01
provides:
  - durable change request and approval persistence tables with correlation-safe constraints
  - immutable audit metadata normalization for governance transitions
  - explicit governance store callbacks and actor-bearing command structs
affects: [phase-09-policy, phase-09-store-adapters, phase-09-root-facade]
tech-stack:
  added: []
  patterns: [tdd, append-only audit correlation, key-first governance commands]
key-files:
  created:
    - rulestead/priv/repo/migrations/TIMESTAMP_create_rulestead_change_requests_and_approvals.exs
    - rulestead/test/rulestead/audit_event_governance_test.exs
    - rulestead/test/rulestead/store/command_governance_test.exs
  modified:
    - rulestead/lib/rulestead/audit_event.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
key-decisions:
  - "Governance persistence stays limited to change-request and approval rows; scheduled-change and webhook tables remain out of scope for later phases."
  - "Immutable audit rows promote governance correlation fields to top-level metadata while stripping session-shaped data from persisted context."
  - "Governance store commands normalize actor and metadata inputs into string-keyed maps so later adapters and facades share one mutation envelope."
patterns-established:
  - "Governance commands follow the existing key-first store style: explicit identifiers, top-level scope fields, actor, reason, and metadata."
  - "Governance correlation fields use shared names across durable tables and audit metadata: change_request_id, approval_id, governance_action, execution_stage, and correlation_id."
requirements-completed: [GOV-01, GOV-04]
duration: 5min
completed: 2026-04-24
---

# Phase 9 Plan 02: Governance Persistence and Store Contract Summary

**Change-request and approval tables, governance audit-correlation metadata, and key-first store commands for governed mutations**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T14:39:10Z
- **Completed:** 2026-04-24T14:44:13Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added durable `change_requests` and `approvals` tables with foreign-key linkage, reviewer uniqueness, and correlation indexes.
- Extended `Rulestead.AuditEvent.metadata/1` to persist governance correlation fields while dropping session-shaped data from immutable audit context.
- Expanded `Rulestead.Store` and `Rulestead.Store.Command` with explicit governance callbacks plus normalized write/read command structs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the governance persistence model and immutable correlation fields** - `6ce6904` (test), `18a46ca` (feat)
2. **Task 2: Expand the store behavior and command layer for governance operations** - `1337eed` (test), `52f21e4` (feat)

## Files Created/Modified

- `rulestead/priv/repo/migrations/TIMESTAMP_create_rulestead_change_requests_and_approvals.exs` - Adds durable governance tables, foreign keys, status constraints, and correlation-safe indexes.
- `rulestead/lib/rulestead/audit_event.ex` - Normalizes governance correlation metadata and strips session-shaped fields from persisted audit context.
- `rulestead/lib/rulestead/store.ex` - Declares the governance store callback surface for submit, review, execution, fetch, and list operations.
- `rulestead/lib/rulestead/store/command.ex` - Adds normalized governance command structs and shared input-normalization helpers.
- `rulestead/test/rulestead/audit_event_governance_test.exs` - Locks governance audit metadata serialization and session-field stripping.
- `rulestead/test/rulestead/store/command_governance_test.exs` - Freezes governance callback and command constructor contracts.

## Decisions Made

- Kept governance persistence focused on the Phase 9 substrate only; no scheduled-change or webhook schema was introduced.
- Promoted governance correlation fields into top-level audit metadata instead of leaving them buried in nested context maps.
- Normalized governance command metadata and actor summaries at construction time so later adapters do not have to guess at shape.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Adding new `Rulestead.Store` callbacks causes compile-time behaviour warnings in `Rulestead.Fake` and `Rulestead.Store.Ecto` until later Phase 9 adapter work implements them. Tests still pass and no adapter behavior was changed in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase `09-03` can extend policy seams against fixed governance command names and correlation fields.
- Phase `09-04` should implement the new governance callbacks in `Fake` and `Store.Ecto` to eliminate the current behaviour warnings and wire the durable schema end-to-end.

## Self-Check: PASSED

---
*Phase: 09-governance-core-contracts-change-requests-and-approval-polic*
*Completed: 2026-04-24*
