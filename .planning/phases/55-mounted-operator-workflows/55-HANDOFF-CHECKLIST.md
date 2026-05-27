# Phase 55 Handoff Checklist

Use this checklist before starting Phase 56 documentation and before any release/support communication that references mounted operator workflows.

## Core Truth Boundary

- [ ] Confirm dependency truth remains owned by `rulestead` (`DependencyInventory`, `DependencyValidator`, impact preview, promotion/compare gates).
- [ ] Confirm `rulestead_admin` remains presentation-only and does not introduce domain validation paths or Repo access in LiveViews.
- [ ] Confirm no runtime evaluator hot-path dependency lookups were added (runtime purity remains snapshot-local).
- [ ] Phase 55 plans reference [54-HANDOFF-CHECKLIST.md](../54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md) as the upstream boundary contract.

## Scope Semantics

- [ ] Verify audience list/detail and used-by tables carry explicit `environment_key` and `tenant_key` scope in every row.
- [ ] Verify compare dependency findings links preserve `env` and `tenant` query params.
- [ ] Verify support-facing copy does not collapse same-name audiences across environment/tenant scope.

## Fail-Closed Enforcement

- [ ] Verify audience edit/archive flows require preview → confirm → audit with core-issued `audprev_*` fingerprints.
- [ ] Verify delete preview has no apply CTA and states archive as the retirement path.
- [ ] Verify compare surfaces remain read-only (no Apply/Publish controls on compare routes).
- [ ] Verify stale preview redirects surface drift copy before confirm.

## Redaction And Support Safety

- [ ] Verify `DependencyVisibility.visibility_resolver/1` gates used-by flag keys; denied reads show operator copy, not real keys.
- [ ] Verify explain permalinks include only flag, environment, tenant, and targeting key — never raw traits.
- [ ] Verify audience trace labels use support-safe statuses (`matched`, `missed`, `missing from snapshot`, `archived`).

## Mounted Presentation-Only

- [ ] Confirm audience mutation validation and impact evidence are issued by core preview/apply APIs.
- [ ] Confirm flag explain/simulate/rules surfaces render core `audience_trace` without recomputing match logic in admin.
- [ ] Confirm compare `dependency_findings` are rendered from core compare results without standalone promotion UI.

## Release And Verification Guardrail

- [ ] Run `cd rulestead && mix verify.phase55`.
- [ ] Run `cd rulestead_admin && mix test` for full mounted regression coverage.
- [ ] Confirm release contract asserts no `RulesteadAdmin` module references in `rulestead` package files.
- [ ] Confirm Phase 56 implementation plan references this checklist as the mounted-vs-core boundary for docs work.
