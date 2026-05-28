# Thread: 2026-05-25 Next Milestone Assessment

## Status

- **Superseded** — 2026-05-28 by `.planning/threads/2026-05-28-path-to-done-milestones.md`
- Updated: 2026-05-25

## Assessment Lens

- Scope: full sibling-package product (`rulestead`, `rulestead_admin`, and `open_feature_rulestead`) plus shared guides and demo as adoption surfaces
- Audience: serious Phoenix SaaS adopters evaluating whether the library is done enough to trust in a real app
- Evidence posture: prefer repo-local source, tests, guides, and runnable proof bars over milestone names or aspirational planning prose

## Current Verdict

- Rough done band: **85%**
- Band label: **strong, meaningful wedges remain**
- The library is already broad and credible for real Phoenix teams:
  - deterministic runtime evaluation, variants, and typed config
  - mounted admin authoring, rollout, kill switch, audit, compare, diagnostics, and lifecycle flows
  - shared guides, installer path, bounded demo, and a runnable OpenFeature provider proof bar
- The remaining delta is mostly **important-but-narrow support-surface closure**, not missing foundational product shape

## Recommended Next Milestone

- **Pick:** `v1.4.0 — Mounted Companion Proof Reclosure`
- Why now:
  - the documented mounted-admin proof bar currently fails in repo-local verification even after `v1.3.0` shipped
  - a serious adopter is more likely to get blocked by a broken documented proof path than by the absence of guardrail-driven rollout automation
  - guarded rollout still looks like the strongest differentiator, but it should land on top of a fully credible mounted companion support surface

## Done Enough For The Recommended Milestone

- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` passes again from the repo root
- package-boundary/runtime boot truth for the mounted companion is repaired so `rulestead_admin` no longer claims a proof bar it cannot boot
- root and package docs describe the mounted companion proof posture honestly and consistently
- compile-time/runtime warnings that undermine the mounted companion support story are either fixed or explicitly bounded as non-contract surfaces
- the sibling-package release model and mounted-admin posture stay unchanged

## Ranking After Assessment

1. `v1.4.0 — Mounted Companion Proof Reclosure`
2. `v1.5.0 — Guarded Rollout Foundations`
3. `v1.6.0 — Reusable Targeting Deepening`
4. Long-tail docs and operator-polish follow-ons only after the above stay coherent

## Evidence That Changed The Recommendation

- The OpenFeature companion proof bar passes:
  - `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh`
- The documented mounted-admin proof bar currently fails at application boot:
  - `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`
  - failure: `UndefinedFunctionError` for `Rulestead.Redis.enabled?/0` during `Rulestead.Application.start/2`
- Reusable audiences are not a future concept:
  - shipped schema in `rulestead/lib/rulestead/audience.ex`
  - ruleset support for `segment_match` + `audience_key`
  - admin rule editor audience library and validation
  - promotion / manifest dependency handling for audiences
- Guarded rollout foundations are still not present beyond manual rollout controls, preview, risky-jump confirmation, and kill-switch flows

## Open Investigations

- Why does the mounted-admin proof bar boot into a runtime shape where `Rulestead.Redis` is not available even though the module exists in the sibling package source?
- Are the current compile warnings around notifier/Redis visibility purely package compilation noise, or do they reveal a release-shape/configuration gap that adopters can hit?
- Does the next proof-closure milestone need to include warning-budget cleanup for the mounted companion, or only the hard proof-bar failure and support-truth docs?

## Graduation Candidates

These belong in the next active phase `NN-LEARNINGS.md` once a milestone starts:

- Documented proof bars are product contract, not CI trivia; a red proof command is adopter-facing support drift.
- Reusable audiences already exist across runtime, admin, compare, and manifest surfaces, so future targeting work should deepen blast-radius safety and ergonomics instead of reintroducing the concept as net-new capability.
- Milestone ordering must be re-based on runnable repo evidence whenever a “closed” support surface still fails its named proof path.
