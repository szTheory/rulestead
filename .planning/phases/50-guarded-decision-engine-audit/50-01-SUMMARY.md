---
phase: 50-guarded-decision-engine-audit
plan: 01
subsystem: guarded-rollout
tags: [guardrail-decision, rollout, audit, governance, fail-closed]
requires: [49-01, 49-02, 49-03]
provides:
  - guarded rollout decision reducer
  - durable guardrail decision persistence
  - public and store entrypoints for advancement, evaluation, and status reads
  - automatic hold and rollback behavior through the existing audit/governance envelope
affects: [runtime contract, store adapters, governance execution, audit evidence, migration]
tech-stack:
  added: [Ecto migration]
  patterns: [append-only operational truth, command-first mutation spine, stable-snapshot rollback, bounded guardrail evidence]
key-files:
  created:
    - rulestead/lib/rulestead/guardrail_decision.ex
    - rulestead/lib/rulestead/guardrails/decision.ex
    - rulestead/priv/repo/migrations/20260526110000_add_guardrail_decisions.exs
    - rulestead/test/rulestead/guarded_rollout_test.exs
    - rulestead/test/rulestead/guardrails/decision_test.exs
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
key-decisions:
  - "Modeled guardrail decision state as operational truth in durable decision records, not authored rollout config."
  - "Mapped recoverable weak evidence to `pending_data` during active monitoring and sticky `held` after the monitoring window closes."
  - "Kept terminal seam faults fail-closed as holds and limited automatic rollback to confirmed threshold breaches with an exact stable target."
  - "Restored rollback targets from the recorded last stable authored snapshot for the same rollout identity and scope."
  - "Kept automatic interventions system-originated, correlation-linked, and inside the existing command/store/audit spine."
patterns-established:
  - "Bad or missing data pauses; proven regression restores the last known-good stage."
requirements-completed: [ROL-02, ROL-03, AUD-01, AUD-02]
duration: 1h20m
completed: 2026-05-26
commit: c4dd3fb
---

# Phase 50 Plan 01 Summary

**Phase 50 now has a real guarded rollout decision engine and audit-backed intervention path in `rulestead`.**

## Accomplishments

- Added `Rulestead.Guardrails.Decision` to reduce normalized Phase 49 signal facts into explicit `healthy`, `pending_data`, `held`, and `rollback_triggered` states.
- Added durable `guardrail_decisions` operational records and a public/store command surface for `advance_rollout`, `evaluate_guarded_rollout`, and `fetch_guardrail_status`.
- Implemented Ecto and fake adapter parity for healthy advancement, fail-closed hold, confirmed-breach rollback, and current status reads.
- Preserved sticky rollout semantics by rolling back to the exact last stable authored snapshot when one exists, and degrading to hold when no stable target exists.
- Routed automatic hold and rollback through bounded system provenance, audit links, guardrail evidence, and the existing governed/scheduled execution path.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/decision_test.exs test/rulestead/guarded_rollout_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/governance/change_request_contract_test.exs test/rulestead/store/command_governance_test.exs test/rulestead/scheduled_execution_conflict_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs test/rulestead/audit_event_governance_test.exs test/rulestead/store/ecto_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/manifest/export_test.exs test/rulestead/store/compare_contract_test.exs test/rulestead/store/manifest_export_contract_test.exs test/rulestead/ruleset_validation_test.exs`

## Task Commits

- `c4dd3fb` — `Implement guarded rollout decision engine`

## Next Phase Readiness

Phase 51 can plan mounted rollout workflow surfaces against the existing `fetch_guardrail_status` read path, durable decision records, and audit-linked automatic intervention events without letting LiveView own decision truth.
