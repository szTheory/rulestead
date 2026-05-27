---
phase: 49-guardrail-signal-contract
plan: 03
subsystem: compare-export
tags: [compare, manifest, durability, serialization]
requires: [49-01, 49-02]
provides:
  - compare durability for rollout guardrails
  - manifest/export durability for rollout guardrails
  - proof that Phase 49 remains contract-only
affects: [compare projection, manifest export, store serialization, contract tests]
tech-stack:
  added: []
  patterns: [canonical projection parity, bounded manifest shape, phase-scope drift guard]
key-files:
  created: []
  modified:
    - rulestead/lib/rulestead/promotion/compare.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/rulestead/store/compare_contract_test.exs
    - rulestead/test/rulestead/store/manifest_export_contract_test.exs
    - rulestead/test/rulestead/manifest/export_test.exs
key-decisions:
  - "Preserved the authored guardrail fields through compare and export by extending the existing rollout serialization path rather than adding a parallel projection."
  - "Kept Phase 49 bounded by explicitly proving compare output excludes Phase 50 action-state tokens."
patterns-established:
  - "New authored rollout fields must survive store serialization, compare projection, and manifest export before the phase can claim contract completeness."
requirements-completed: [ROL-01]
duration: 25min
completed: 2026-05-26
---

# Phase 49 Plan 03 Summary

**The Phase 49 guardrail contract now survives compare and manifest/export surfaces intact.**

## Accomplishments

- Extended compare canonicalization and store serialization so rollout guardrails persist with explicit threshold, freshness, sample-size, and scope fields across both Ecto and fake adapters.
- Updated manifest/export proof to keep `guardrails` under rollout payloads with the same bounded authored fields instead of dropping or reshaping them.
- Added compare proof that surfaces guardrail drift while keeping Phase 50 action-state terms absent from the contract-only Phase 49 surface.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store/compare_contract_test.exs test/rulestead/store/manifest_export_contract_test.exs test/rulestead/manifest/export_test.exs`
- `rg -n "guardrails|threshold|freshness|min_sample|tenant_scope|environment_scope" /Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex /Users/jon/projects/rulestead/rulestead/test/rulestead/store/compare_contract_test.exs /Users/jon/projects/rulestead/rulestead/test/rulestead/store/manifest_export_contract_test.exs`
- `! rg -n "rollback_triggered|held|monitoring_window" /Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex /Users/jon/projects/rulestead/rulestead/test/rulestead/store/compare_contract_test.exs`

## Task Commits

No new commit was created during this execution run.

## Next Phase Readiness

Phase 50 can consume one durable authored and runtime guardrail contract for decision-engine work without reopening compare or manifest parity.
