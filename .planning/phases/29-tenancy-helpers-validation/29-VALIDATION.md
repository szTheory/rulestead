# Phase 29: Tenancy Helpers & Validation - Validation Plan

## Goal
Verify that Phase 29 completes the bounded tenancy contract across runtime helpers, reviewed-artifact validation, audit metadata, and mounted admin scope without introducing tenant-partitioned storage, environment-per-tenant topology, implicit all-tenant behavior, or standalone `rulestead_admin` drift.

## Dimension 1: Tenancy Seam and Runtime Scope Discipline (TEN-01, TEN-03)
- [ ] **Bounded seam preserved:** Verify `Rulestead.Tenancy` remains the single explicit seam for tenant normalization, same-tenant checks, and bucket-identity composition rather than new ad hoc helpers.
- [ ] **Single-tenant default preserved:** Verify `Rulestead.Tenancy.SingleTenant` still keeps existing single-tenant callers working without required multi-tenant setup.
- [ ] **Explicit runtime propagation:** Verify Plug, LiveView, and Oban context helpers keep `tenant_key` explicit and bounded across runtime handoff points.
- [ ] **No topology widening:** Verify the phase does not add tenant-partitioned storage, environment-per-tenant topology, or tenant inheritance.

## Dimension 2: Bucketing and Identity Semantics (TEN-01, TEN-03)
- [ ] **Tenant bucket path remains deterministic:** Verify `bucket_by: :tenant` keeps deterministic hashing and current strict/permissive missing-identity posture.
- [ ] **Tenant-scoped subject composition is explicit:** Verify any tenant-local subject composition is host opt-in and does not silently rebucket legacy `:subject` rules.
- [ ] **No hidden fallback chains:** Verify the evaluator does not introduce ambient tenant inference or extra bucket enums beyond the locked context.

## Dimension 3: Preview-first Tenant Validation and Reviewed Scope Revalidation (TEN-02, TEN-03)
- [ ] **Shared tenant finding vocabulary:** Verify compare, import, promotion, and apply surfaces reuse `widened_tenant_scope`, `mismatched_tenant_scope`, and `tenant_scope_drifted`.
- [ ] **Preview blocks unsafe scope:** Verify import and promotion preview paths surface tenant widening or mismatch before mutation.
- [ ] **Apply revalidates exact reviewed scope:** Verify saved plan or compare-driven apply rejects tenant drift even when the rest of the artifact is structurally valid.
- [ ] **Adapter parity preserved:** Verify Fake and Ecto apply paths reject the same tenant-sensitive invalid states.

## Dimension 4: Bounded Tenant Provenance in Plans and Audit (TEN-02, TEN-03)
- [ ] **Saved plans stay bounded:** Verify plans persist stable tenant identity and bounded provenance only, with no tenant labels, catalogs, or session baggage.
- [ ] **Audit metadata stays bounded:** Verify audit metadata carries the same bounded tenant provenance vocabulary while still scrubbing sensitive session/socket data.
- [ ] **One metadata dialect:** Verify plan, apply, and audit surfaces do not invent conflicting tenant provenance shapes.

## Dimension 5: Mounted Admin Tenant Scope and Fail-Closed Operator UX (TEN-01, TEN-03)
- [ ] **Host-owned allowed tenant catalog:** Verify mounted admin consumes a host-provided allowed tenant set and does not discover tenant options from Rulestead internals.
- [ ] **Environment and tenant stay separate:** Verify mounted routes, remembered state, and shell presentation keep `env` and `tenant` as separate visible selectors/params.
- [ ] **Invalid tenant fails closed:** Verify invalid URL or remembered tenant scope does not silently broaden into all-tenant access.
- [ ] **Policy callback shape preserved:** Verify tenant-aware authorization inputs do not change the public `Rulestead.Admin.Policy.can?/4` callback signature.

## Dimension 6: Product Shape and Phase Boundary Safety
- [ ] **Strict Phase 29 boundary:** Verify the shipped work stays inside helper seams, validation, metadata, and mounted admin scope only.
- [ ] **Sibling-package posture preserved:** Verify `rulestead_admin` remains a mounted sibling package and does not become a standalone tenancy control plane.
- [ ] **No implicit all-tenant behavior:** Verify no operator or apply path introduces a default all-tenant mutation mode.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/tenancy_test.exs test/rulestead/tenancy_property_test.exs test/rulestead/evaluator_test.exs test/rulestead/evaluator_property_test.exs test/rulestead/plug_test.exs test/rulestead/live_view_test.exs test/rulestead/oban_test.exs`
- `cd rulestead && mix test test/rulestead/manifest/import_test.exs test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/audit_event_governance_test.exs test/rulestead/release_contract_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs`

## Source Coverage Audit

### Goal Coverage
- [x] **ROADMAP goal:** `29-01` completes the bounded runtime tenancy seam and explicit identity hooks; `29-02` completes tenant-aware validation, provenance metadata, and mounted admin scope without widening product shape.

### Requirement Coverage
- [x] **TEN-01:** Covered by `29-01` runtime scope discipline and `29-02` mounted admin scope/authorization inputs.
- [x] **TEN-02:** Covered by `29-02` preview/apply tenant validation and reviewed-scope revalidation.
- [x] **TEN-03:** Covered by `29-01` seam/default/bucketing work and `29-02` bounded tenant provenance.

### Research Coverage
- [x] **Existing seam should be completed, not rebuilt:** Covered by `29-01`.
- [x] **Reviewed-artifact tenant validation should be shared and exact-scope:** Covered by `29-02`.
- [x] **Mounted admin should mirror environment-resolution patterns:** Covered by `29-02`.
- [x] **Bounded tenant provenance only:** Covered by `29-02`.
