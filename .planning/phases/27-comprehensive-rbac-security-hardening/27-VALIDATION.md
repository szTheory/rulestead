# Phase 27: Comprehensive RBAC & Security Hardening - Validation Plan

## Goal
Verify that Phase 27 delivers strict, dependency-free RBAC across the core API and mounted admin UI using the existing host-owned policy seam, while preserving fail-closed behavior, protected-environment governance, and the sibling-package mounted-admin posture.

## Dimension 1: Canonical Role and Vocabulary Contract (SEC-01, SEC-02)
- [ ] **Canonical public roles only:** Verify Viewer, Editor, and Admin are the only canonical product roles exposed in code contracts, docs, and operator-facing copy.
- [ ] **Compatibility alias boundary:** Verify legacy names survive only as temporary backend normalization inputs and do not leak back out as product truth.
- [ ] **Stable host seam preserved:** Verify `Rulestead.Admin.Policy.can?/4` remains the stable host-owned authorization callback and no third-party framework or DSL is introduced.
- [ ] **Closed capability vocabulary:** Verify backend authorization exposes one bounded action/resource/environment capability model that downstream slices reuse.

## Dimension 2: Core Enforcement and Protected/Governed Behavior (SEC-02, SEC-03)
- [ ] **Fail-closed normalization:** Verify malformed or missing actor/resource/environment inputs fail closed.
- [ ] **Direct mutation enforcement:** Verify Viewers cannot mutate and Editors/Admins are enforced according to the canonical capability matrix.
- [ ] **Protected/governed execution posture:** Verify production/protected actions remain Admin-only or proposal-only where required, with approval requirement semantics preserved.
- [ ] **Denied audit visibility:** Verify blocked writes still append normalized denied audit evidence.
- [ ] **Real/Fake parity:** Verify Ecto and Fake store paths enforce the same RBAC outcomes.

## Dimension 3: Mounted Admin Mutation Surfaces (SEC-03)
- [ ] **Mount-time read gate:** Verify actors with no admin read scope at all are denied from entering the mounted admin.
- [ ] **Mutation-first route handling:** Verify `/new`, `/:key/edit`, `/:key/kill`, and `/:key/cleanup` are explicitly redirected, hard-denied, or rendered with the intended blocked/proposal-only posture.
- [ ] **Execution/review surfaces:** Verify change request execute/approve/schedule, schedule recovery actions, and webhook management surfaces consume backend-derived capability truth.
- [ ] **Accessible reasons:** Verify blocked controls expose readable, environment-aware reason text and do not rely on hover-only disclosure.

## Dimension 4: Mounted Admin Read Routes and Capability Teaching (SEC-01, SEC-03)
- [ ] **Read-oriented route visibility:** Verify useful read routes remain available to authorized readers where the phase context expects them to remain visible.
- [ ] **Shared capability summaries:** Verify browse, compare, audit, diagnostics, webhook review, and schedule index/detail routes all reuse the same capability posture rather than inventing route-local role semantics.
- [ ] **No UI/backend drift:** Verify read-route explanations do not claim mutation authority that the backend would deny.

## Dimension 5: Docs, Product Shape, and Phase Boundary Safety
- [ ] **Canonical docs vocabulary:** Verify `rulestead_admin/README.md`, `rulestead/doc/admin-ui.md`, and `rulestead/doc/api_stability.md` teach only Viewer / Editor / Admin as the canonical role model.
- [ ] **Host-owned seam guidance:** Verify docs explicitly preserve the host-owned `can?/4` integration seam and do not imply library-owned identity/session ownership.
- [ ] **No future-scope auth system drift:** Verify the phase does not introduce custom role builders, arbitrary permission graphs, policy DSLs, or standalone `rulestead_admin` product positioning.

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/admin_security_contract_test.exs test/rulestead/admin_governance_policy_test.exs test/rulestead/release_contract_test.exs`
- `cd rulestead && mix test test/rulestead/store/compare_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/store/webhook_outbound_contract_test.exs test/rulestead/store/webhook_outbound_adapter_contract_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live test/rulestead_admin/integration/admin_mount_test.exs`
- `rg -n "Viewer|Editor|Admin|can\\?/4|host-owned|compatibility" rulestead_admin/README.md rulestead/doc/admin-ui.md rulestead/doc/api_stability.md`

## Source Coverage Audit

### Goal Coverage
- [x] **ROADMAP goal:** `27-01` establishes the bounded RBAC contract, `27-02` enforces it across core/protected actions, `27-03` hardens mutation-first mounted surfaces, and `27-04` broadens the same truth to read routes and docs.

### Requirement Coverage
- [x] **SEC-01:** Covered by `27-01` canonical role/vocabulary work and `27-04` docs/read-route teaching.
- [x] **SEC-02:** Covered by `27-01` seam/vocabulary work and `27-02` pure-Elixir backend enforcement parity.
- [x] **SEC-03:** Covered by `27-02` backend enforcement and `27-03` / `27-04` mounted-admin capability projection.

### Research Coverage
- [x] **Closed vocabulary on the existing seam:** Covered by `27-01`.
- [x] **Compatibility alias demotion:** Covered by `27-01`.
- [x] **Protected/governed backend parity:** Covered by `27-02`.
- [x] **Hybrid mounted-admin posture:** Covered by `27-03` and `27-04`.
- [x] **Host docs and mounted product shape:** Covered by `27-04`.

### Context Decision Coverage
- [x] **D-01 to D-05:** Implemented in `27-01`.
- [x] **D-06 to D-14:** Implemented in `27-01` and `27-04`.
- [x] **D-15 to D-19:** Implemented in `27-02`.
- [x] **D-20 to D-24:** Implemented in `27-03` and `27-04`.
- [x] **D-25 to D-28:** Implemented across all slices through fail-closed scope, env-sensitive posture, and bounded phase scope.
