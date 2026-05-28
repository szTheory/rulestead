# Phase 74: API Stability Catalog Sync - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 74-api-stability-catalog-sync
**Mode:** assumptions
**Areas analyzed:** Catalog sync strategy, Supported adopter facades, Drift guards, Execution shape, Non-goals

## Assumptions Presented

### Catalog sync strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Manual update from `release_contract_test.exs` constants; no generate-from-contract tool | Confident | `@root_exports`, `@telemetry_events`, struct/config tests in `release_contract_test.exs`; Phase 64/72 support-truth pattern |
| Sync doc to match post-GA exports, callbacks, error types, config keys | Confident | Grep/diff: `@root_exports` vs `api_stability.md` function list; missing `:tenancy`, `:snapshot_not_found` |

### Supported adopter facades (API-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Rulestead.Runtime` = supported facade with closed function list; internals non-public | Likely | `runtime.ex` exports; `@moduledoc false`; `product-boundary.md`, quickstart, `post_ga_band_contract_test.exs` |
| `Rulestead.TestHelpers` public; `Rulestead.Fake` only as implementation behind helpers | Likely | `guides/recipes/testing.md`; extending-rulestead does not broaden Fake |
| New "Supported adopter facades (post-GA)" section; qualify "no other modules public" line | Confident | Contradiction between doc line 40–41 and Runtime teaching |

### Drift guards (API-02 + VER-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Bidirectional guards in `release_contract_test.exs` | Confident | Existing telemetry test is code→doc only (`for event <- @telemetry_events`) |
| `@documented_supported_facades` asserted in guide | Confident | No module-list assert today |

### Execution shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two slices: 74-01 prose, 74-02 tests | Likely | Phase 73 73-01/73-02 precedent |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## External Research

Not performed — codebase evidence sufficient.
