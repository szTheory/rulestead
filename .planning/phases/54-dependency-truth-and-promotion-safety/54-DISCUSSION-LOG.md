# Phase 54: Dependency Truth And Promotion Safety - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `54-CONTEXT.md`; this log preserves the assumptions analysis.

**Date:** 2026-05-27
**Phase:** 54-dependency-truth-and-promotion-safety
**Mode:** assumptions
**Areas analyzed:** Dependency Inventory Model, Fail-Closed Validation Contract, Scope Semantics And Deterministic Output, Authorization-Safe Read Behavior, Public Surface For Downstream Operator Workflows

## Assumptions Presented

### Dependency Inventory Model
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 54 should establish a persisted core-owned dependency inventory/read model as canonical truth rather than ad hoc reconstruction. | Likely | `rulestead/lib/rulestead/targeting/audience_dependencies.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `.planning/research/PITFALLS.md`, `.planning/research/SUMMARY.md` |

### Fail-Closed Validation Contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| One shared dependency validator should be reused at ruleset publish, audience mutation, promotion apply, and manifest apply/validate chokepoints. | Likely | `rulestead/lib/rulestead/promotion/apply.ex`, `rulestead/lib/rulestead/manifest/import.ex`, `rulestead/lib/rulestead/manifest/validate.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/ruleset/rule.ex` |

### Scope Semantics And Deterministic Output
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Dependency outputs should always include explicit environment and tenant scope and sort by stable semantic keys. | Confident | `.planning/REQUIREMENTS.md` (DEP-04), `.planning/ROADMAP.md` (Phase 54 success criteria), `rulestead/lib/rulestead/targeting/audience_dependencies.ex` |

### Authorization-Safe Read Behavior
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Dependency inventory reads should return policy-safe redacted partial truth rather than all-or-nothing denial. | Unclear | `.planning/REQUIREMENTS.md` (DEP-01), `.planning/research/PITFALLS.md`, `rulestead/lib/rulestead/admin/policy.ex`, `rulestead/lib/rulestead/admin/authorizer.ex`, `rulestead/lib/rulestead/admin/redaction.ex` |

### Public Surface For Downstream Operator Workflows
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 54 should add explicit dependency-inventory read APIs/store callbacks with Fake/Ecto parity, not internal-only usage. | Likely | `rulestead/lib/rulestead/store.ex`, `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/fake.ex`, `rulestead/test/rulestead/release_contract_test.exs` |

## Corrections Made

No corrections — all assumptions confirmed.

