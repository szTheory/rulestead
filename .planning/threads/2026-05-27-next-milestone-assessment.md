# Thread: 2026-05-27 Next Milestone Assessment

## Status

- Closed — superseded by `2026-05-27-post-v1.7-milestone-assessment.md` (v1.7 shipped; GOV-01 and quickstart closed)
- Updated: 2026-05-27

## Assessment Lens

- Scope: full sibling-package product (`rulestead`, `rulestead_admin`, and `open_feature_rulestead`) plus shared guides and demo as adoption surfaces
- Audience: serious Phoenix SaaS adopters evaluating whether the library is done enough to trust in a real app
- Evidence posture: prefer repo-local source, tests, guides, and runnable proof bars over milestone names or aspirational planning prose

## Current Verdict

- Rough done band: **87%**
- Band label: **strong, approaching upper band; a few important-but-narrow wedges remain**
- The library is broad and credible for real Phoenix teams:
  - pure evaluator + ETS snapshot runtime, variants, typed config, explain API
  - full mounted admin (flags, rollouts, kill switch, audit, compare, audiences, experiments, diagnostics)
  - governance change requests, promotion/manifest, lifecycle cleanup, tenancy helpers
  - guarded rollout hold/rollback foundations (v1.5) with host-supplied guardrail seam
  - audience impact previews, dependency inventory, mounted preview-confirm-audit (v1.6)
  - Docker demo + CI smoke, OpenFeature sibling package, installer golden contract
- Remaining delta is **important-but-narrow wedges**, not missing foundational product shape

## Confidence Caveats

- `.planning/research/JTBD-MAP.md` body is stale (last reviewed 2026-05-21); delta section updated 2026-05-27
- Root `.planning/REQUIREMENTS.md` does not exist until next `/gsd-new-milestone`
- README/getting-started teach `Rulestead.enabled?("flag", conn)` but shipped contract is payload-first per `guides/flows/evaluation.md` — docs drift, not missing product

## Adopter Coverage Summary

| Flow | Status |
|------|--------|
| Runtime evaluation + explain | Well served |
| Mounted authoring + RBAC | Well served |
| Governed prod mutations (flags/rollouts) | Well served |
| Environment compare + promotion + GitOps | Well served |
| Lifecycle hygiene + cleanup | Well served (v1.2) |
| Tenancy scope | Well served (v1.1) |
| Guarded rollout hold/rollback | Well served (v1.5; host wires guardrail provider) |
| Reusable audiences + blast-radius preview | Well served (v1.6) |
| Protected-env audience governance by threshold | **Still rough — GOV-01 gap** |
| Auto-advance guarded rollouts | **Not built — ROL-04 deferred** |
| 15-minute quickstart / onboarding | Partially served (README API mismatch) |
| Milestone proof in default CI | Bounded (phase56/guarded_rollout scopes manual) |

## Recommended Next Milestone

- **Pick:** `v1.7.0 — Blast-Radius Governance`
- **Primary requirement:** GOV-01 (protected-environment audience edits require governed approval based on blast-radius thresholds after preview tokens and dependency truth are proven)
- Why now:
  - v1.6 made shared-audience blast radius visible; protected prod edits still lack threshold-based change-request routing
  - `.planning/research/FEATURES.md` dependency chain: impact preview → governed audience updates
  - `ensure_protected_audience_confirmation/1` in store fail-closes on `protected_shared_targeting?` without full change-request integration (`rulestead/lib/rulestead/store/ecto.ex`)
  - Lower scope-drift risk than ROL-04 auto-advance (v1.5 explicitly deferred auto-advance as a later layer)

## Done Enough For v1.7.0

- Protected-env audience edits above configurable reference/rollout thresholds route through existing change-request envelope
- Preview fingerprint + dependency truth required before proposal
- Mounted proposal/approval UX for high-blast-radius audience mutations
- Audit evidence includes preview summary and threshold breach context
- README/getting-started aligned with payload-first evaluation contract (bundled VER, not standalone milestone)
- Sibling-package release model unchanged

## Ranking After Assessment

1. `v1.7.0 — Blast-Radius Governance` (GOV-01) — **activate now**
2. `v1.8.0 — Guarded Rollout Auto-Advance` (ROL-04)
3. Quickstart support truth (bundle into v1.7 VER)
4. `IMP-05` — richer host-supplied preview evidence (v1.9 or defer)
5. `ADM-05` — draft targeting presets (defer; scope creep risk)

## Evidence That Changed The Recommendation

- v1.4–v1.6 milestones shipped since 2026-05-25 assessment; prior proof-closure and guarded-rollout/targeting gaps are closed
- Audience preview→confirm→audit shipped in v1.6 but governed threshold routing for protected environments explicitly deferred as GOV-01
- No `auto_advance` implementation in repo; ROL-04 remains unbuilt
- README quickstart API mismatch confirmed against `guides/flows/evaluation.md` and `rulestead/lib/rulestead.ex`

## Diminishing-Returns Judgment

- **Verdict:** Finish the last 2–3 important wedges (GOV-01, ROL-04, quickstart truth), then mostly stop (~92–95% band)
- **High leverage:** GOV-01, ROL-04, quickstart truth
- **Adjacent/polish:** IMP-05, default-CI milestone gates, MAINTAINING vs test.sh file list drift
- **Overbuilding risk:** ADM-05 presets, observability dashboards, standalone admin, stats engine

## Open Investigations

- Should quickstart fix get a `release_contract_test.exs` string guard?
- GOV-01 threshold semantics: reference count only vs include active rollout/lifecycle weighting?
- Does ROL-04 require Oban scheduling or can it reuse existing governed-action scheduling seam?

## Graduation Candidates

For next active phase `NN-LEARNINGS.md` once v1.7 starts:

- Documented proof bars are product contract, not CI trivia; a red proof command is adopter-facing support drift
- Milestone ordering must re-base on runnable repo evidence whenever a "closed" support surface still fails its named proof path
- Governed audience updates are the natural post-preview layer after impact previews and dependency truth ship
- Auto-advance guarded rollouts remain a later layer after hold/rollback foundations prove trustworthy

## Blunt Maintainer Takeaway

Build v1.7.0 Blast-Radius Governance next. v1.6 gave operators eyes; they still lack governed brakes on high-impact shared-audience edits in protected environments. ROL-04 is the best differentiator after that—not before. Fix README quickstart as part of v1.7 verification. Do not start ADM-05 presets yet.

## Next Step

Run `/gsd-new-milestone v1.7.0 Blast-Radius Governance` (phase numbering continues at 57).
