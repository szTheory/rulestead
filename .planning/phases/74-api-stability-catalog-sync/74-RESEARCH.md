# Phase 74: API Stability Catalog Sync — Research

**Researched:** 2026-05-28  
**Phase:** 74-api-stability-catalog-sync  
**Requirements:** API-01, API-02, API-03, VER-03

## Summary

Phase 74 closes INV-API-01 by aligning `guides/api_stability.md` with constants already enforced in `release_contract_test.exs`, then adding symmetric doc→code guards so catalog drift cannot merge silently. The implementation pattern is proven in Phases 60, 64, 68, 72, and 73: test module attributes remain the single source of truth; prose follows; bidirectional substring asserts avoid fragile markdown parsers.

## Key Findings

### Drift inventory (test vs doc)

| Surface | `release_contract_test.exs` | `api_stability.md` today |
|---------|----------------------------|---------------------------|
| Root exports | 57 arities incl. audience/governance | Missing `apply_audience_mutation`, `preview_audience_impact`, `list_audience_dependencies` |
| Store callbacks | 17 incl. audience trio | Store section lists 14 only |
| Policy callbacks | `can?/4`, `allow_self_approval?/4`, `change_request_required?/4` | Only `can?/4` |
| Error `:type` | includes `:snapshot_not_found` | omitted |
| Config top-level | includes `:tenancy` | omitted |
| Config nested | `:tenancy` → `:module` | omitted |
| Telemetry events | 16 events | complete (code→doc test exists) |
| Runtime facade | 6 functions exported | not in catalog; doc says "no other Rulestead.*" |
| TestHelpers | 5 helpers in `testing.md` | not in catalog |

### Recommended assert strategy (API-02)

1. **Keep constants at top of `release_contract_test.exs`** — do not split to another module unless file size forces it (currently ~950 lines; still manageable).

2. **Code → doc (extend):**
   - New test: every `@root_exports` name appears in contract as `` `name` `` or `` `name/arity` `` (use function atom only for grep stability).
   - New test: every `@store_callbacks` atom appears under Store section.
   - New test: every `Policy.behaviour_info(:callbacks)` atom appears under Policy section.
   - New test: every `Error.leaf_types/0` atom appears in closed `:type` list.
   - New test: `:tenancy` and `tenancy.module` (or equivalent prose) in Host Config section.
   - Existing telemetry loop stays unchanged.

3. **Doc → code (new):**
   - `@documented_supported_facades` = `["Rulestead.Runtime", "Rulestead.TestHelpers"]` — assert each module string appears in contract.
   - `@documented_runtime_functions` = `evaluate`, `enabled?`, `get_value`, `get_variant`, `explain`, `diagnostics` — assert in contract (facade section).
   - `@documented_test_helper_functions` = macros/helpers from `testing.md` — assert listed in contract or cross-ref to testing guide.

4. **Avoid:** parsing markdown tables; use substring asserts on function names and module strings only.

### Product-boundary posture (API-03)

`product-boundary.md` already lists snapshot runtime in the in-scope table but lacks semver language. Add a short **Runtime semver** subsection: supported keyed lookup path for Phoenix snapshot-cache apps; `Rulestead.Runtime` function catalog stable on `0.1.x`; `Rulestead.Runtime.Cache` and siblings remain non-public.

### Optional `post_ga_band_contract_test.exs`

Only if a single assertion keeps band closure readable — e.g. `product_boundary` contains `Rulestead.Runtime` and `0.1.x` semver language. Primary guards stay in `release_contract_test.exs` per CONTEXT D-12.

## Validation Architecture

| Requirement | Verification | Command |
|-------------|--------------|---------|
| API-01 | Catalog prose contains all test-maintained surfaces | `grep` + file read after 74-01 |
| API-02 | Bidirectional tests green | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| API-03 | Runtime/TestHelpers posture in api_stability + product-boundary | grep + release_contract / optional post_ga |
| VER-03 | Same as API-02 | same command |

**Wave 0:** Not required — test file and guides exist.  
**Quick run:** `cd rulestead && mix test test/rulestead/release_contract_test.exs`  
**Full suite:** `cd rulestead && mix test` before merge

## Risks

| Risk | Mitigation |
|------|------------|
| Over-broad "public" by listing implementation modules | Facade-only section; explicit non-public Runtime internals |
| Brittle doc asserts on wording | Assert function atoms and module strings, not prose paragraphs |
| Phase scope creep into verify.phase74 | CONTEXT D-14/D-17 forbid; proof = release_contract_test only |

## RESEARCH COMPLETE
