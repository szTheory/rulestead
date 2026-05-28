# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.10.0 — Post-GA Band Truth & Adopter Closure

**Shipped:** 2026-05-28
**Phases:** 4 | **Plans:** 0 (verification-driven)

### What Was Built

- Post-v1.9 band assessment declaring v1.1–v1.9 feature band complete (~94–96% done band for serious Phoenix SaaS adopters).
- `product-boundary.md`, `footguns.md`, and payload-first `Rulestead.Runtime` quickstart honesty across README, getting-started, and api_stability header.
- `mix verify.phase72` / `mix verify.adopter` flat merge gate, `post_ga_band_closure` CI scope, and `post_ga_band_contract_test.exs`.
- `scripts/demo/proof.sh` bounded adopter proof path; README band-complete section; `v1.10.0-MILESTONE-AUDIT.md` with `band_complete`.

### What Worked

- Verification-driven closure without new product APIs kept scope honest and shippable in one day.
- Flat union on phase68 core avoided kitchen-sink `mix verify.all` while still proving band closure.
- Explicit v2 deferred triggers in `DEFERRED.md` prevent reopening v1.7–v1.9 arcs as false gaps.

### What Was Inefficient

- Phases 69–72 used VERIFICATION.md only (no PLAN/SUMMARY artifacts) — acceptable for support-truth band but weaker traceability than feature milestones.
- `gsd-sdk milestone.complete` recorded empty accomplishments until manual MILESTONES.md backfill.

### Patterns Established

- `mix verify.adopter` as the integrator-facing alias; phase72 remains the implementation gate.
- Diminishing-returns stop rule: v1.10.x = patches only; v2 picks one wedge by trigger.
- Release contract tests guard support truth separately from feature delivery.

### Key Lessons

1. Band-closure milestones should lead with assessment + docs + proof — not feature creep.
2. Adopter trust at ~94–96% is sufficient to declare post-GA band complete when proof spine is green.
3. Milestone audits (`band_complete`) close the loop on support-truth claims without widening product shape.

### Cost Observations

- Single-day closure across 4 phases; ~96 files in recent git range.
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

## Milestone: v1.9.0 — Host-Supplied Preview Evidence

**Shipped:** 2026-05-28
**Phases:** 4 | **Plans:** 16 | **Tasks:** 12

### What Was Built

- `PreviewEvidence` behaviour with bounded sample/impression payloads, fail-closed limits, and deterministic ImpactPreview schema v2 fingerprints.
- Audit and change-request carry-through for support-safe preview evidence summaries with GOV-05 reference-count-only blast-radius boundary.
- Mounted audience preview flows rendering host-supplied evidence with honest uncertainty copy and forbidden observability overclaim guards.
- `mix verify.phase68` merge gate, release-contract drift guards, host seam + flow guides, and `host_preview_evidence` CI scope.

### What Worked

- Mirroring `Guardrails.Provider` for `PreviewEvidence` kept the host seam teachable and testable with `Rulestead.Fake.PreviewEvidenceResolver`.
- The four-phase split (contract → carry-through → mounted UX → proof/docs) preserved core-vs-companion boundaries established in v1.6–v1.8.
- GOV-05 contract tests early prevented impression-weighted governance creep before mounted UX shipped.

### What Was Inefficient

- No formal `v1.9.0-MILESTONE-AUDIT.md` before close (fourth consecutive milestone without audit artifact).
- `gsd-sdk milestone.complete` warned about a missing STATE.md field — planning doc formats should stay aligned with gsd-tools expectations.

### Patterns Established

- Opt-in resolver returns `{:ok, %{}}` when unconfigured; richer evidence never bypasses stale fingerprint rejection.
- Union sample merge capped at 25 rows with command rows first; impression fingerprint included in deterministic preview token.
- Blast-radius `assess/2` ignores impression summaries and sample cohort sizes — governance stays reference-count based.

### Key Lessons

1. Closing the reusable-targeting preview arc (v1.6 previews → v1.7 governance → v1.9 host evidence) is faster when each layer extends the prior envelope.
2. Host-owned observability truth must stay explicit — previews declare basis and uncertainty; Rulestead never claims population counts.
3. Support-truth phases remain non-negotiable — `mix verify.phase68` and MAINTAINING drift guards prevent preview evidence from feeling experimental.

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases (~91 files, ~8.5k LOC in milestone git range).
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

## Milestone: v1.8.0 — Guarded Rollout Auto-Advance

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 32

### What Was Built

- Authored auto-advance policy with observation window, explicit next-stage plan, and fail-closed eligibility on v1.5 guardrails.
- `ScheduledExecution` observation-window ticks orchestrating governed `advance_rollout` with idempotency, protected-env change-request routing, and `guardrail_automation` audit evidence.
- Mounted rollouts auto-advance panel (six fail-closed modes), policy save gated on `:advance_rollout`, and timeline distinction for automation vs manual actions.
- `mix verify.phase64` merge gate, release-contract drift guards, host seam + flow guides, and optional `guarded_rollout_auto_advance` CI scope.

### What Worked

- Reusing `ScheduledExecution` and the existing governed-action envelope avoided a parallel mutation path and kept v1.5 hold/rollback semantics intact.
- The four-phase split (authored contract → orchestration → mounted UX → proof/docs) matched v1.5–v1.7 rhythm and preserved core-vs-companion boundaries.
- Fail-open schedule hook on `advance_rollout` plus fail-closed eligibility at tick execute balanced operator progress with safety.

### What Was Inefficient

- No formal `v1.8.0-MILESTONE-AUDIT.md` before close (third consecutive milestone without audit artifact).
- `gsd-sdk milestone.complete` warned about a missing STATE.md field — planning doc formats should stay aligned with gsd-tools expectations.

### Patterns Established

- `RolloutAutoAdvance.Schedule` as the shared idempotency and command-snapshot contract across Ecto and Fake.
- Fresh guardrail signals fetched at tick execute; schedule snapshot intentionally empty for signal facts.
- Protected-env auto-advance submits change requests at execute time without auto-approve; non-protected paths direct-advance through the orchestrator.

### Key Lessons

1. Completing a multi-milestone arc (v1.5 foundations → v1.7 governance → v1.8 auto-advance) is faster when each layer reuses the prior envelope instead of inventing parallel workflows.
2. Mounted UX should derive fail-closed modes from core truth (guardrails, policy, scheduled ticks) rather than inferring healthy fleet state.
3. Support-truth phases remain non-negotiable — `mix verify.phase64` and release-contract guards prevent auto-advance from feeling experimental.

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

## Milestone: v1.7.0 — Blast-Radius Governance

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 8

### What Was Built

- Pure `BlastRadiusThreshold` evaluator with fail-closed protected-environment semantics and facade `assess_audience_blast_radius/2`.
- Audience mutation change-request integration reusing `:apply_audience_mutation` on the existing governed envelope.
- Mounted governance loader, blast-radius panel, preview/confirm branching, and change-request show evidence with policy-aware visibility.
- `mix verify.phase60` merge gate, release-contract drift guards, governance flow guides, and optional `blast_radius_governance` CI scope.

### What Worked

- Reusing the v1.6 preview/dependency payloads as threshold inputs kept the milestone bounded and honest about preview basis limits.
- The four-phase split (threshold contract → change requests → mounted UX → proof/docs) mirrored v1.6 and preserved core-vs-companion boundaries.
- Frozen blast-radius metadata on change-request show plus live visibility tier on approve avoided re-assess drift while keeping policy enforcement current.

### What Was Inefficient

- No formal milestone audit artifact was produced before close (same gap as v1.6); run `/gsd-audit-milestone` before future closes when time allows.
- CLI milestone close surfaced a STATE.md field mismatch warning; planning doc formats should stay aligned with gsd-tools expectations.

### Patterns Established

- Threshold evaluation consumes authored-state preview fingerprints only — no observability-backed population counts.
- Protected-environment audience mutations branch: direct apply below threshold, change request above threshold, fail-closed when inputs are stale or unresolved.
- Governance UX reuses existing audience preview/confirm routes instead of introducing parallel admin flows.

### Key Lessons

1. Closing a safety arc (preview → dependency → governance) is faster when each layer builds on the prior milestone's contracts.
2. Change-request metadata should freeze assessment evidence at submit time; approve gates may still consult live policy visibility.
3. Support-truth phases remain essential — quickstart API parity and drift guards prevent governance features from feeling "admin-only."

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

## Milestone: v1.6.0 — Reusable Targeting Deepening

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 22

### What Was Built

- Pure audience impact previews with scoped fingerprints, redacted sample evidence, and authored-state dependency summaries.
- Snapshot-local reusable audience compilation and deterministic segment_match evaluation traces.
- Canonical audience dependency inventory with fail-closed publish, archive/delete, promotion, compare, replay, and manifest validation.
- Mounted audience library, preview-confirm-audit mutation flows, explain/simulate trace carry-through, and compare dependency findings.
- `mix verify.phase56` merge gate, release-contract drift guards, flow guide updates, and optional CI proof scope.

### What Worked

- Four equal-sized phases (core contract → dependency truth → mounted UX → proof/docs) kept core-vs-companion boundaries explicit.
- Reusing the `mix verify.phaseNN` pattern gave each phase a crisp merge gate and handoff checklist.
- Treating reusable audiences as already shipped avoided greenfield scope creep and kept the milestone focused on blast-radius safety.

### What Was Inefficient

- No milestone audit artifact was produced before close; future milestones should run `/gsd-audit-milestone` for a formal gap check.
- Same-day execution compressed timeline metrics; velocity tables remain sparse until session timing is captured consistently.

### Patterns Established

- Preview tokens/fingerprints with stale revalidation on every durable audience mutation.
- One core dependency projection consumed by Ecto, Fake, promotion, manifest, and mounted read surfaces.
- Optional CI proof scopes mirror prior `guarded_rollout_foundations` without changing default CI behavior.

### Key Lessons

1. Deepening an existing primitive (audiences) is faster and safer than inventing a parallel targeting model.
2. Honest preview basis labels matter as much as the preview payload — operators trust authored-state impact over false precision.
3. Handoff checklists between core and mounted phases prevent presentation drift from domain truth.

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 4 (see STATE.md Deferred Items).

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.5.0 | 4 | 8 | Introduced guarded rollout foundations with host-owned signal seam |
| v1.6.0 | 4 | 16 | Deepened reusable targeting with equal core/mounted/proof phase split |
| v1.7.0 | 4 | 16 | Closed reusable-targeting safety arc with blast-radius governance via change requests |

### Cumulative Quality

| Milestone | Phase verify gates | Release-contract guards | Deferred at close |
|-----------|-------------------|-------------------------|-------------------|
| v1.5.0 | verify.phase52 | guarded rollout drift guards | 2 |
| v1.6.0 | verify.phase54–56 | reusable targeting drift guards | 4 |
| v1.7.0 | verify.phase60 | blast-radius governance drift guards | 3 |

### Top Lessons (Verified Across Milestones)

1. Support-truth and proof closure milestones pay down adopter friction before differentiated features land.
2. Core owns contracts and validation; mounted admin owns presentation — the sibling-package split scales across feature families.
3. Fail-closed validation at publish/mutation boundaries prevents broken snapshots better than post-hoc operator warnings.
