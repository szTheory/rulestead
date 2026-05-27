---
phase: 49-guardrail-signal-contract
plan: 01
subsystem: guardrails
tags: [guardrail-contract, host-seam, fail-closed, metadata]
requires: []
provides:
  - host-owned guardrail provider seam
  - explicit guardrail query and normalized signal fact primitives
  - audit and telemetry compatible guardrail metadata envelope
affects: [runtime contract, metadata normalization, contract tests]
tech-stack:
  added: []
  patterns: [host-owned seam, bounded fail-closed vocabulary, reused tenant provenance envelope]
key-files:
  created:
    - rulestead/lib/rulestead/guardrails.ex
    - rulestead/lib/rulestead/guardrails/provider.ex
    - rulestead/lib/rulestead/guardrails/query.ex
    - rulestead/lib/rulestead/guardrails/signal_fact.ex
    - rulestead/test/rulestead/guardrails/contract_test.exs
    - rulestead/test/rulestead/guardrails/metadata_contract_test.exs
  modified:
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/audit_event.ex
    - rulestead/lib/rulestead/telemetry.ex
key-decisions:
  - "Kept provider ownership entirely in the host app by exposing a behavior-only seam and one configured provider hook."
  - "Normalized weak or missing signal inputs into one bounded `SignalFact` contract instead of preserving provider-specific health strings."
  - "Reused tenant provenance and validation vocabulary from `Store.Command.GovernanceSupport` so later guardrail evidence does not invent a second scope dialect."
patterns-established:
  - "Guardrail runtime facts should always carry explicit environment, tenant, freshness, sample-size, and threshold fields before later phases attempt decision logic."
requirements-completed: [ROL-01]
duration: 45min
completed: 2026-05-26
---

# Phase 49 Plan 01 Summary

**Phase 49 now has one explicit, host-owned, fail-closed guardrail signal contract in `rulestead`.**

## Accomplishments

- Added `Rulestead.Guardrails`, `Provider`, `Query`, and `SignalFact` so host apps can supply rollout signal facts through a behavior seam without making `rulestead` own provider adapters or metrics fetching.
- Locked the bounded normalization vocabulary for `provider_missing`, `unsupported_scope`, `stale`, `insufficient_sample`, `healthy`, and `breached`, with explicit environment, tenant, freshness, sample-size, and threshold semantics on the core contract.
- Extended command, audit, and telemetry helpers so guardrail scope and evidence metadata reuse the existing tenant provenance, scope source, validation, and bounded evidence envelope.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs`
- `rg -n "provider_missing|unsupported_scope|insufficient_sample|stale|breached|healthy" /Users/jon/projects/rulestead/rulestead/lib/rulestead/guardrails /Users/jon/projects/rulestead/rulestead/test/rulestead/guardrails/contract_test.exs`
- `rg -n "tenant_key|environment_key|freshness|sample" /Users/jon/projects/rulestead/rulestead/lib/rulestead/guardrails/query.ex /Users/jon/projects/rulestead/rulestead/lib/rulestead/guardrails/signal_fact.ex`
- `rg -n "scope_source|validation|tenant|evidence" /Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex /Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex /Users/jon/projects/rulestead/rulestead/lib/rulestead/telemetry.ex /Users/jon/projects/rulestead/rulestead/test/rulestead/guardrails/metadata_contract_test.exs`

## Task Commits

No new commit was created during this execution run.

## Next Phase Readiness

Wave 2 can attach guardrail definitions directly to rollout authored state without reopening the runtime seam or metadata vocabulary.
