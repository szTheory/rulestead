# Phase 57 Research: Blast-Radius Threshold Contract

**Researched:** 2026-05-27  
**Phase:** 57 — Blast-Radius Threshold Contract  
**Requirements:** GOV-01, GOV-02, GOV-03, GOV-04

---

## Executive Summary

Phase 57 adds a **pure governance evaluator** (`Rulestead.Governance.BlastRadiusThreshold`) that classifies audience-mutation blast radius in protected environments using v1.6 preview and dependency payloads. The module plugs into the existing apply pipeline **after** fresh-preview validation and **before** dependency apply validation in both Fake and Ecto stores. Protected environments are detected via `Rulestead.Promotion.Compare.protected_target?/1` (`prod` / `production`), replacing the placeholder `protected_shared_targeting?` boolean gate.

No change-request wiring ships in Phase 57 — assessment maps are stable for Phase 58 embedding.

---

## Codebase Findings

### Apply pipeline (current)

```
schema → fresh preview → ensure_protected_audience_confirmation (placeholder) → dependency validation → mutate → audit
```

**Target pipeline (Phase 57):**

```
schema → fresh preview → BlastRadiusThreshold.validate_protected_apply/3 → dependency validation → mutate → audit
```

Both `fake.ex:3460` and `ecto.ex` (Multi.run chain ~691) call `ensure_protected_audience_confirmation/1` which only blocks when `protected_shared_targeting?: true` — not environment-aware.

### Reusable modules

| Module | Role for Phase 57 |
|--------|-------------------|
| `ImpactPreview` | `build/1`, `preview_fingerprint/1`, `schema_version/1`, `finding/4` |
| `AudienceDependencies` | `summarize/2`, `reference_keys/1`; `rollout_context` / `lifecycle_context` with `available?: false` |
| `DependencyValidator` | `validate/2`, `blockers?/1`, `to_error/2` — pattern for findings → error |
| `Compare.protected_target?/1` | Protected env detection (`prod`, `production`) |
| `ChangeRequest.governed_actions/0` | **Unchanged** — no `:apply_audience_mutation` in Phase 57 |

### Error contract

Use `StoreError.invalid_command/2` → `%Rulestead.Error{type: :invalid_command}`. Stable finding codes in metadata:

- `blast_radius_above_threshold`
- `blast_radius_indeterminate`
- `blast_radius_missing_preview_inputs`
- `blast_radius_unresolved_dependency_truth`

### Scoring defaults (locked)

| Condition (protected env) | Verdict |
|---------------------------|---------|
| Any indeterminate input | `:indeterminate` → block |
| `operation == "archive"` and `reference_count > 0` | `:above_threshold` |
| `operation == "update"` and `reference_count > 2` | `:above_threshold` |
| Otherwise | `:below_threshold` |

Non-protected environments: assess may run for telemetry but **must not block** direct apply.

### Indeterminate triggers

- Missing/blank `preview_fingerprint` or wrong `preview_schema_version`
- Stale fingerprint (handled upstream; threshold must not bypass)
- `affected_reference_keys` mismatch vs preview keys
- `DependencyValidator.blockers?/1` on dependency entries
- Any reference with `rollout_context.available? == false` or `lifecycle_context.available? == false`
- `hidden_reference_count > 0` without visibility to resolve
- Unknown env classification → treat as protected (fail-closed)

### Test fixtures

- `audience_impact_contract_test.exs` — Fake path; `seed_audience_reference!` yields 1 reference
- `ecto_audience_impact_contract_test.exs` — Ecto path; same fixture pattern
- Existing test at line 250 blocks `protected_shared_targeting?: true` — must migrate to production env threshold tests

### New files

| File | Purpose |
|------|---------|
| `lib/rulestead/governance/blast_radius_threshold.ex` | Pure assess + validate_protected_apply |
| `test/rulestead/governance/blast_radius_threshold_test.exs` | Unit tests for all verdict paths |

### Modified files

| File | Change |
|------|--------|
| `lib/rulestead/fake.ex` | Replace placeholder gate; threshold audit metadata |
| `lib/rulestead/store/ecto.ex` | Same integration |
| `lib/rulestead.ex` | Optional `assess_audience_blast_radius/2` public read API |
| `test/rulestead/store/audience_impact_contract_test.exs` | Threshold cases |
| `test/rulestead/store/ecto_audience_impact_contract_test.exs` | Parity cases |

---

## Implementation Approach

### Plan split (4 plans)

1. **Pure evaluator** — `BlastRadiusThreshold` module + unit tests
2. **Fake integration** — pipeline hook + blocked audit metadata
3. **Ecto integration** — same contract in Multi pipeline
4. **Facade + contract proof** — public assess API + extended contract tests for GOV-01..04

### Assessment payload shape (stable for Phase 58)

```elixir
%{
  verdict: :below_threshold | :above_threshold | :indeterminate,
  reference_count: non_neg_integer(),
  distinct_flag_count: non_neg_integer(),
  rollout_hints: [map()],
  lifecycle_hints: [map()],
  threshold_profile: :default,
  operation: String.t(),
  environment_key: String.t(),
  preview_fingerprint: String.t(),
  breach_reasons: [%{code: String.t(), observed: term(), limit: term(), remediation: String.t()}],
  protected_environment?: boolean(),
  authoritative_population_count?: false
}
```

### Anti-patterns to avoid

- GenServer threshold state
- Duplicating assess logic in Fake vs Ecto
- New `Rulestead.Error` `:type` without api_stability update
- Adding `:apply_audience_mutation` to `ChangeRequest.governed_actions/0`
- Blocking non-protected environments on above-threshold verdicts
- Defaulting to `:below_threshold` on missing data

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` |
| **Contract command** | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs` |
| **Full phase command** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs` |
| **Estimated runtime** | ~30 seconds |

### Per-requirement verification map

| REQ-ID | Verification | Command |
|--------|--------------|---------|
| GOV-01 | Above-threshold blocked in production; remediation mentions change request | contract tests + unit tests |
| GOV-02 | Assessment uses preview refs, rollout/lifecycle hints, no population counts | unit test on assess payload |
| GOV-03 | Below-threshold allows apply in prod; above blocks; non-prod bypass | contract tests both stores |
| GOV-04 | Indeterminate on stale/missing/unresolved inputs | unit + contract tests |

### Wave 0 requirements

Existing ExUnit + contract test infrastructure covers all requirements. No Wave 0 stubs needed.

---

## RESEARCH COMPLETE
