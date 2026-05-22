# Phase 30: Mounted Admin Tenant Scope Closure - Validation Plan

## Goal
Verify that Phase 30 closes the mounted-admin tenant-scoping gap by preserving explicit tenant scope through mounted session helpers, shell chrome, and compare summary/drill-in flows without drifting into Phase 31 audit-provenance automation, standalone `rulestead_admin` publishing, or speculative tenancy expansion.

## Dimension 1: Mounted Session Tenant Resolution (TEN-01, TEN-03)
- [ ] **Host-bounded tenant catalog:** Verify mounted admin resolves tenants only from host-provided session inputs, not from authored storage or compare payloads.
- [ ] **Precedence contract preserved:** Verify tenant resolution follows URL first if allowed, remembered tenant second if allowed, otherwise host default or first allowed tenant, otherwise fail closed.
- [ ] **Invalid tenant cannot widen scope:** Verify invalid tenant params or remembered state never broaden mounted scope outside the allowed tenant set.

## Dimension 2: Visible Scope Separation (TEN-01, TEN-03)
- [ ] **Tenant and environment stay separate axes:** Verify mounted assigns, helper APIs, and shell chrome keep tenant distinct from environment.
- [ ] **No implicit all-tenant mode:** Verify shell and route behavior never imply or default to cross-tenant operator scope.
- [ ] **Single-tenant presentation stays bounded:** Verify exactly-one-tenant cases render read-only scope copy rather than a misleading switcher.

## Dimension 3: Compare Route Carry-Through (TEN-01, TEN-03)
- [ ] **Summary routes preserve tenant:** Verify compare summary URLs keep `tenant` together with `env`, `source_env`, `target_env`, and optional `compare_token`.
- [ ] **Drill-in routes preserve tenant:** Verify flag drill-in compare routes and stale-preview links keep the same explicit tenant scope.
- [ ] **Shared helper ownership preserved:** Verify mounted compare pages rely on `Session.current_path/3` and `Session.env_links/3` instead of page-local query assembly.

## Dimension 4: Shared Compare Seam Compliance (TEN-01, TEN-03)
- [ ] **Public compare facade carries tenant:** Verify mounted compare pages pass `tenant_key:` through `Rulestead.compare_environments/3`.
- [ ] **Compare token stays tenant-scoped:** Verify compare-token expectations continue to treat `tenant_key` as part of the canonical compare scope.
- [ ] **Adapter parity preserved:** Verify fake and ecto compare contracts remain aligned when tenant-aware compare scope is used.

## Dimension 5: Product Shape and Phase Boundary Safety
- [ ] **Strict Phase 30 boundary:** Verify the phase stops at mounted-admin scope closure and compare carry-through only.
- [ ] **No Phase 31 automation drift:** Verify audit mutation/apply provenance auto-merge work is not pulled into this phase.
- [ ] **Sibling-package posture preserved:** Verify `rulestead_admin` remains a mounted sibling package and is not prepared for standalone publishing.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`
- `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs`

## Source Coverage Audit

### Goal Coverage
- [x] **ROADMAP goal:** `30-01` closes mounted session and shell tenant scope; `30-02` closes compare summary/drill-in tenant carry-through and targeted verification.

### Requirement Coverage
- [x] **TEN-01:** Covered by mounted session resolution, visible operator scope, and compare route carry-through.
- [x] **TEN-03:** Covered by explicit tenant-aware compare seam usage and fail-closed mounted-admin scope handling.

### Research Coverage
- [x] **Mounted gap is local to `rulestead_admin`:** Covered by `30-01` session/shell work and `30-02` compare LiveView carry-through.
- [x] **Core compare seam is already tenant-aware:** Covered by `30-02` targeted compare regression coverage.
- [x] **Targeted verification is sufficient:** Covered by the listed mounted-admin and core compare test commands.
