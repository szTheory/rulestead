# Pitfalls Research: Rulestead v1.3.0 - Adopter Truth & Proof Closure

**Project:** Rulestead v1.3.0 - Adopter Truth & Proof Closure
**Researched:** 2026-05-24

## Major Pitfalls

### 1. Solving Proof Drift With Narrative Only

Updating planning or README copy without reconciling migrations, installer behavior, and runnable verification preserves the underlying support-truth gap.

**Prevention:** Every docs claim in this milestone should map to a test, migration, generator path, or explicitly bounded caveat.

### 2. Smuggling In New Product Scope

Guarded rollout, targeting reuse, or broad admin polish can easily hide inside a “proof closure” milestone and blow up sequencing.

**Prevention:** Keep scope limited to docs, schema/migration parity, mounted contract truth, and bridge proof.

### 3. Treating Admin Test Drift As Cosmetic

The mounted admin contract is adopter-facing because it defines the host seam. Field-name and permission drift are support-truth issues, not minor UI cleanup.

**Prevention:** Resolve the contract deliberately and record the supported behavior once.

### 4. Leaving Companion Surfaces Half-Supported

If `open_feature_rulestead` remains in the repo and release story, a broken or undocumented proof path becomes an adoption trap.

**Prevention:** Either make the bridge runnable and documented in a bounded way or document its exact support limits.

### 5. Breaking Package Boundaries While Closing Drift

It is easy to fix support gaps by letting admin or bridge concerns leak into `rulestead` core responsibilities.

**Prevention:** Keep runtime/domain truth in `rulestead`, mounted operator truth in `rulestead_admin`, and bridge proof in `open_feature_rulestead`.

## Warning Signs

- Docs mention planned future releases instead of shipped dates.
- Migration files do not match public Ecto schema fields.
- Contract tests are rewritten to pass without clarifying intended support behavior.
- OpenFeature proof is postponed again as “later polish” while remaining in the public surface.

## Sources

- `.planning/threads/2026-05-24-next-milestone-assessment.md`
- `.planning/threads/2026-05-24-proof-posture-drift.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
- `prompts/rulestead-host-app-integration-seam.md`
