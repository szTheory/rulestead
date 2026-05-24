# Feature Research: Rulestead v1.3.0 - Adopter Truth & Proof Closure

**Project:** Rulestead v1.3.0 - Adopter Truth & Proof Closure
**Researched:** 2026-05-24

## Table Stakes For This Milestone

### Release Truth

- Root README, `rulestead/README.md`, and `rulestead_admin/README.md` describe the actual post-`v1.0.0` GA posture instead of the pre-GA `after v0.6.0` plan.
- Install and onboarding docs point to a real current package/migration story instead of a future-state placeholder.
- Support-facing docs stay honest about what is proved today versus what is still bounded or deferred.

### Runtime Contract Parity

- Runtime schema, Ecto migrations, and installer output agree on the lifecycle/ownership fields the authored contract already expects.
- Lifecycle ownership fields remain host-owned and explicit across authored-state writes, reads, and migrations.
- Migration truth is additive and reproducible; adopters should not need to infer missing columns from failing tests.

### Companion Proof

- Mounted admin contract tests reflect the intended host-facing lifecycle and permission behavior rather than stale UI assumptions.
- `open_feature_rulestead` has a runnable documented proof path and does not dead-end on missing test/dependency setup.
- Verification commands across sibling packages are green or explicitly documented as bounded with a credible reason.

## Differentiators For This Milestone

- Treating proof coherence itself as a product requirement for adopter trust.
- Keeping the sibling-package release model intact while tightening the support surface across runtime, companion admin, and companion bridge.
- Encoding support-truth obligations explicitly in planning rather than burying them as generic cleanup.

## Anti-Features

- No new rollout, targeting, or experimentation capabilities.
- No standalone `rulestead_admin` publish posture.
- No observability-product expansion or hosted control-plane work.
- No broad docs rewrite detached from concrete repo truth.

## User Outcomes This Milestone Should Unlock

- A serious adopter can read the docs and get the same product story the tests and migrations prove.
- A maintainer can point to one coherent release posture across root docs, package docs, installer behavior, and verification tasks.
- Future differentiated milestones inherit a trustworthy base instead of compounding support drift.

## Sources

- `.planning/MILESTONE-ARC.md`
- `.planning/threads/2026-05-24-next-milestone-assessment.md`
- `.planning/threads/2026-05-24-proof-posture-drift.md`
- `README.md`
- `rulestead/README.md`
- `rulestead_admin/README.md`
- `open_feature_rulestead/README.md`
