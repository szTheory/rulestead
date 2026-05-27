---
phase: 49-guardrail-signal-contract
plan: 02
subsystem: ruleset
tags: [authored-state, rollout, guardrails, validation]
requires: [49-01]
provides:
  - rollout-authored guardrail embed
  - schema validation for threshold freshness sample-size and scope fields
  - fixture coverage for valid and invalid guardrail payloads
affects: [ruleset schema, rollout authored state, validation tests]
tech-stack:
  added: []
  patterns: [ecto embedded schema, closed enums, authored-state-first validation]
key-files:
  created: [rulestead/lib/rulestead/ruleset/guardrail.ex]
  modified:
    - rulestead/lib/rulestead/ruleset/rollout.ex
    - rulestead/test/support/store_fixtures.ex
    - rulestead/test/rulestead/ruleset_validation_test.exs
key-decisions:
  - "Stored guardrails inside the existing rollout embed so draft and publish flows carry one canonical authored contract."
  - "Kept guardrail fields closed and scalar with `Ecto.Enum` plus number validation instead of freeform metadata maps."
patterns-established:
  - "Rollout safety contracts should be rejected at the schema boundary when threshold, freshness, sample-size, or scope semantics are malformed."
requirements-completed: [ROL-01]
duration: 20min
completed: 2026-05-26
---

# Phase 49 Plan 02 Summary

**Guardrails now live inside rollout authored state and are validated before they can enter draft or publish flows.**

## Accomplishments

- Added `Rulestead.Ruleset.Guardrail` as a dedicated embedded schema with explicit `signal_key`, `threshold_operator`, `threshold_value`, `freshness_window_seconds`, `min_sample_size`, `environment_scope`, and `tenant_scope` fields.
- Extended `Rulestead.Ruleset.Rollout` to own `embeds_many :guardrails` so rollout safety data travels with the same authored artifact as rollout configuration.
- Updated shared fixtures and ruleset validation tests to prove valid guardrails serialize cleanly and malformed threshold, freshness, and sample contracts are rejected.

## Verification

- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/ruleset_validation_test.exs`
- `rg -n "guardrails|threshold|freshness|min_sample|tenant_scope" /Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/guardrail.ex /Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rollout.ex /Users/jon/projects/rulestead/rulestead/test/support/store_fixtures.ex`
- `rg -n "guardrail" /Users/jon/projects/rulestead/rulestead/test/rulestead/ruleset_validation_test.exs`

## Task Commits

No new commit was created during this execution run.

## Next Phase Readiness

Wave 3 can now prove that the authored guardrail contract survives compare and export surfaces without mutation or omission.
