# Phase 25: Tenancy Helpers & Validation - Validation Plan

## Goal
Verify that Phase 25 adds explicit tenant-aware scoping, validation, bucketing hooks, audit metadata, and mounted admin safety seams without introducing tenant-partitioned storage, environment-per-tenant topology, tenant inheritance, or standalone `rulestead_admin` product work.

## Dimension 1: Tenancy Seam and Safe Default (TEN-01, TEN-03)
- [ ] **Explicit tenancy seam:** Verify a bounded `Rulestead.Tenancy` seam exists, is host-configurable, and is the single place for tenant resolution, same-tenant checks, and scope normalization instead of hidden helper-local defaults.
- [ ] **Validated config registration:** Verify tenancy registration lives in an explicit top-level `:tenancy` block in `Rulestead.Config` and is covered by config and release-contract tests.
- [ ] **Single-tenant ergonomic default:** Verify `Rulestead.Tenancy.SingleTenant` is the default path and existing single-tenant callers keep working without extra config or required tenant setup.
- [ ] **No topology widening:** Verify the phase does not add tenant-partitioned storage, per-tenant environments, tenant inheritance, or tenant-cloned manifest trees.

## Dimension 2: Runtime, Helper, and Bucketing Behavior (TEN-01, TEN-03)
- [ ] **Explicit request/socket/job propagation:** Verify Phoenix, LiveView, and Oban seams keep `tenant_key` explicit, bounded, and normalized through the shared tenancy seam.
- [ ] **Deterministic tenant-aware bucketing:** Verify `bucket_by: :tenant` and any additive tenant-aware bucketing helper preserve deterministic rollout and experiment assignment, existing salts, and strict/permissive missing-identity behavior.
- [ ] **Fail-closed same-tenant guards:** Verify missing or mismatched tenant scope is treated as denied/non-applicable rather than widening to implicit all-tenant behavior.

## Dimension 3: Preview-first Validation and Saved-plan Scope (TEN-02, TEN-03)
- [ ] **Tenant-sensitive preview blockers:** Verify import and promotion preview paths surface tenant mismatch, same-tenant failure, or scope-widening findings before any apply happens.
- [ ] **Bounded saved-plan tenant metadata:** Verify import and promote saved plans carry explicit environment-plus-tenant scope metadata only in bounded form and do not serialize tenant-owned data, session baggage, or future topology state.
- [ ] **Apply-time scope revalidation:** Verify import or promote apply rejects stale or mismatched tenant scope even when the saved plan artifact itself is otherwise structurally valid.
- [ ] **Promotion apply parity:** Verify Fake and Ecto promotion/apply paths reject the same tenant-sensitive mismatches and persist the same bounded scope metadata when apply is valid.

## Dimension 4: Audit Metadata and Mounted Admin Scope (TEN-01, TEN-03)
- [ ] **Tenant-aware audit metadata:** Verify audit events and normalized command metadata include bounded tenant scope where relevant while continuing to drop sensitive session/socket keys.
- [ ] **Mounted admin tenant scope seam:** Verify mounted admin session resolution can accept explicit tenant scope alongside environment scope, produce deterministic links/state, and stay inside the current mounted-package posture.
- [ ] **Cross-tenant leakage denial:** Verify mounted admin and authorizer seams fail closed on wrong-tenant or invalid tenant scope rather than implicitly broadening access.
- [ ] **Stable policy callback preserved:** Verify tenant-aware authorization input does not change the public `Rulestead.Admin.Policy.can?/4` callback shape and instead flows through normalized resource/context metadata.

## Dimension 5: Phase Boundary and Product Shape Safety
- [ ] **Strict Phase 25 boundary:** Verify the shipped work stays inside tenancy helpers, validation, audit metadata, and minimum mounted scope seams only.
- [ ] **No standalone admin-product drift:** Verify `rulestead_admin` remains a mounted sibling package and Phase 25 does not create fleet dashboards, standalone admin release work, or broad tenancy middleware.
- [ ] **Preview-first reuse maintained:** Verify tenant validation extends the existing compare/import/promote preview-first contracts instead of inventing a new tenant-only apply path.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/config_test.exs test/rulestead/tenancy_test.exs test/rulestead/tenancy_property_test.exs test/rulestead/release_contract_test.exs test/rulestead/oban_test.exs test/rulestead/evaluator_test.exs test/rulestead/evaluator_property_test.exs`
- `cd rulestead && mix test test/rulestead/manifest/import_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/promotion/compare_test.exs`
- `cd rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/release_contract_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs`

## Source Coverage Audit

### Goal Coverage
- [x] **ROADMAP goal:** `25-01` adds the explicit tenancy seam, safe single-tenant default, and tenant-aware bucketing hooks; `25-02` adds validation, audit metadata, and mounted admin tenant scope seams without new topology.

### Requirement Coverage
- [x] **TEN-01:** Covered by `25-01` runtime/helper seam work and `25-02` mounted admin scope seam.
- [x] **TEN-02:** Covered by `25-02` tenant-aware preview/apply validation for import and promotion.
- [x] **TEN-03:** Covered by `25-01` single-tenant default plus bucketing hooks and `25-02` bounded saved-plan/audit metadata.

### Research Coverage
- [x] **Minimal host-configured seam with `SingleTenant` default:** Covered by `25-01`.
- [x] **Reuse current `%Rulestead.Context{}` and preview-first flows:** Covered by `25-01` and `25-02`.
- [x] **Bounded metadata and fail-closed admin posture:** Covered by `25-02`.
- [x] **Resolved config and metadata boundary choices:** Covered by the updated `25-RESEARCH.md` resolved decisions plus `25-01` config/release-contract work and `25-02` saved-plan/audit scope work.

### Context Decision Coverage
- [x] **D-01 to D-06:** Implemented in `25-01` Task 1.
- [x] **D-07 to D-08:** Implemented in `25-01` Task 2.
- [x] **D-09 to D-10:** Implemented in `25-02` Task 1.
- [x] **D-11 to D-13:** Implemented in `25-02` Task 2.
