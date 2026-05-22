# Phase 29: Tenancy Helpers & Validation - Patterns

**Generated:** 2026-05-21

## Reusable Patterns

### 1. Explicit scope resolution pattern

Current best example:
- `rulestead_admin/lib/rulestead_admin/live/session.ex`

Pattern:
- resolve from URL first
- fall back to remembered state
- fall back to a bounded default
- reject invalid explicit selections instead of broadening scope

Phase 29 use:
- tenant resolution in mounted admin should mirror this environment resolver shape

### 2. Bounded normalization seam pattern

Current best examples:
- `rulestead/lib/rulestead/tenancy.ex`
- `rulestead/lib/rulestead/audit_event.ex`
- `rulestead/lib/rulestead/store/command.ex`

Pattern:
- normalize once at the seam
- keep downstream callers on canonical, bounded values
- strip or reject unbounded session/socket/request baggage

Phase 29 use:
- tenant provenance should be normalized in one place and reused by plans, apply flows, and audit events

### 3. Preview-first reviewed-artifact pattern

Current best examples:
- `rulestead/lib/rulestead/manifest/import.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/promotion/apply.ex`

Pattern:
- preview creates the reviewed envelope
- apply revalidates exact reviewed scope and fingerprints
- stale or blocker conditions stop mutation before the store boundary

Phase 29 use:
- tenant scope must behave like existing environment/compare-token review discipline

### 4. Deterministic evaluator extension pattern

Current best examples:
- `rulestead/lib/rulestead/evaluator.ex`
- `rulestead/test/rulestead/evaluator_property_test.exs`

Pattern:
- keep authored rule topology stable
- add behavior through explicit helper seams
- protect determinism with targeted property tests

Phase 29 use:
- tenant-scoped subject composition must be opt-in and regression-tested, not ambient

## Likely File Clusters

### Runtime seam cluster
- `rulestead/lib/rulestead/tenancy.ex`
- `rulestead/lib/rulestead/tenancy/single_tenant.ex`
- `rulestead/lib/rulestead/phoenix.ex`
- `rulestead/lib/rulestead/live_view.ex`
- `rulestead/lib/rulestead/oban.ex`
- `rulestead/lib/rulestead/evaluator.ex`

### Validation and persistence cluster
- `rulestead/lib/rulestead/manifest/import.ex`
- `rulestead/lib/rulestead/manifest/plan.ex`
- `rulestead/lib/rulestead/promotion/compare.ex`
- `rulestead/lib/rulestead/promotion/apply.ex`
- `rulestead/lib/rulestead/store/command.ex`
- `rulestead/lib/rulestead/audit_event.ex`

### Mounted admin cluster
- `rulestead_admin/lib/rulestead_admin/live/session.ex`
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`
- `rulestead/lib/rulestead/admin/authorizer.ex`

## Verification Concentration

- runtime normalization and single-tenant default behavior
- deterministic tenant bucketing and explicit rebucketing only when opted in
- exact tenant finding vocabulary across compare/import/apply
- bounded provenance fields in plans and audit metadata
- mounted admin invalid-tenant fail-closed behavior and visible current-tenant state
