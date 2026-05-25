# Thread: 2026-05-24 Next Milestone Assessment

## Status

- Superseded by `.planning/threads/2026-05-25-next-milestone-assessment.md`
- Updated: 2026-05-25

## Assessment Lens

- Scope: full sibling-package product (`rulestead` + `rulestead_admin`) with `open_feature_rulestead`, shared guides, and demo counted as supporting adoption surfaces
- Audience: serious Phoenix SaaS adopters, not phase-count completion

## Current Verdict

- Rough done band: **83%**
- Band label: **strong, meaningful wedges remain**
- The product surface is already credible for real Phoenix teams:
  - deterministic runtime evaluation
  - mounted admin for authoring, rollout, kill switch, audit, compare, diagnostics, and lifecycle cleanup
  - shared docs and local demo path
- The highest-leverage remaining gap is **support truth and proof posture**, not another differentiator first

## Recommended Next Milestone

- **Pick:** `v1.3.0 — Adopter Truth & Proof Closure`
- Why now:
  - current repo evidence shows adopter-facing drift between planning claims, package docs, and test/install truth
  - a serious adopter is more likely to get blocked by conflicting release messaging or red verification than by the absence of guarded rollout automation
  - guarded rollout remains valuable, but it compounds risk if layered on top of support-truth drift

## Done Enough For The Recommended Milestone

- root and package READMEs agree with the actual post-`v1.0.0` release posture
- install/onboarding guides reflect the real current package and migration story
- runtime schema, migrations, and lifecycle ownership contract agree end to end
- `rulestead` and `rulestead_admin` tests are green again, or any intentionally deferred failures are explicitly documented and bounded
- `open_feature_rulestead` has a runnable documented proof path instead of a dead-end package stub
- support-truth docs stop implying stronger proof than the repo currently provides

## Ranking After Assessment

1. `v1.3.0 — Adopter Truth & Proof Closure`
2. `v1.4.0 — Guarded Rollout Foundations`
3. `v1.5.0 — Reusable Targeting Assets`
4. OpenFeature bridge polish only after the core proof/docs/release story is coherent

## Evidence That Changed The Recommendation

- Planning says GA shipped in `v1.0.0` on 2026-05-21, but public docs still say the first Hex release is planned after `v0.6.0`.
- `rulestead` tests currently fail on `flags.ownership` / `flags.lifecycle` schema drift between code and migrations.
- `rulestead_admin` tests currently fail on admin contract drift in the lifecycle form and rollout permission UI.
- `open_feature_rulestead` test execution currently stops on unavailable test dependencies.

## Open Investigations

- Is the runtime schema drift an installer/migration omission, a repo fixture mismatch, or a backfill that never landed in migrations?
- Should `open_feature_rulestead` stay a first-class adopter surface now, or remain a lower-priority bridge until the core sibling-package proof posture is closed?
- Does the current docs tree need a release-train clarification after the milestone is repaired, or is simple GA/post-GA wording enough?

## Graduation Candidates

These belong in the next active phase `NN-LEARNINGS.md` once a milestone starts:

- Planning truth must not outrun package README and install-guide truth after GA decisions change.
- Lifecycle/ownership work is not complete if the repo migrations do not prove the same authored shape as the Ecto schemas and tests.
- Admin contract tests should be treated as product-surface truth, not just UI implementation details, because they expose support-truth drift fast.

## 2026-05-25 Update

- This thread was validated by the shipped `v1.3.0` work, but its follow-on ordering is now outdated.
- See `.planning/threads/2026-05-25-next-milestone-assessment.md` for the refreshed ranking after repo-local proof-bar verification.
