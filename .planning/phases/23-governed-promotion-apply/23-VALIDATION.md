# Phase 23: Governed Promotion Apply - Validation Plan

## Goal
Verify that Phase 23 adds a safe, governed, and operator-truthful environment promotion flow across `rulestead` and `rulestead_admin`, covering direct whole-flag apply, protected-target governance, immutable environment-version history, and explicit re-apply-version behavior without drifting into GitOps or tenancy work.

## Dimension 1: Direct Apply Correctness (PROM-03)
- [ ] **Whole-flag authored apply:** Verify direct promotion copies authored desired state rather than runtime snapshots, kill-switch runtime truth, or telemetry artifacts.
- [ ] **Transactional snapshot regeneration:** Verify successful direct apply commits authored target state, immutable environment-version history, and target runtime snapshot regeneration as one authoritative write.
- [ ] **Bounded scope only:** Verify direct apply remains limited to a bounded selected flag set and does not become an unbounded apply-all console.

## Dimension 2: Governed Promotion Safety (PROM-04)
- [ ] **First-class governed action:** Verify promotion is accepted across change-request, scheduled-execution, policy, authorizer, approval-requirement, and governed-action persistence surfaces.
- [ ] **Stored-snapshot execution:** Verify approved and scheduled promotion execute from the exact reviewed bundle snapshot instead of recomputing latest source intent.
- [ ] **Schedule-time revalidation:** Verify compare-token and dependency checks are re-run before governed execution mutation.

## Dimension 3: Audit, Re-apply, and History Truth
- [ ] **Promotion-specific audit linkage:** Verify audit metadata records source env, target env, compare token, selected flags, governance linkage, and immutable environment-version ids.
- [ ] **Immutable history artifact:** Verify each successful promotion produces a usable environment-version source for later re-apply.
- [ ] **Fresh re-apply semantics:** Verify `reapply_version` behaves as a fresh promotion/governed write rather than reusing `rollback_audit_event/1`.

## Dimension 4: Mounted Admin Operator Flow
- [ ] **Mounted compare entrypoint:** Verify the compare summary remains the promotion starting point and branches into direct apply or governed request based on target protection.
- [ ] **Governed review continuity:** Verify change-request and schedule detail screens render exact promotion context from backend truth without inventing a separate promotion console.
- [ ] **Explicit re-apply entrypoint:** Verify prior environment-version linkage on review/detail screens deep-links into the mounted compare/review flow for "Re-apply version".

## Verification Evidence
Primary evidence should come from:

- `cd rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/environment_version_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/governance_facade_contract_test.exs test/rulestead/governance_safety_contract_test.exs test/rulestead/store/scheduled_execution_adapter_contract_test.exs test/rulestead/audit_event_governance_test.exs test/rulestead/promotion/reapply_version_test.exs`
- `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs test/rulestead_admin/live/change_request_live/show_test.exs test/rulestead_admin/live/schedule_live/show_test.exs`
