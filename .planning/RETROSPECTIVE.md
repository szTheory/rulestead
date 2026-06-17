# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.18 — CI/CD Reliability

**Shipped:** 2026-06-17
**Phases:** 6 (incl. inserted 119.1) | **Plans:** 14 | **Tasks:** 20

### What Was Built
- Repo-specific `119-CI-CD-AUDIT.md`: workflow/job/step inventory, live required-check baseline, rerun catalog, live CI timing + local Mix/ExUnit diagnostics, cache/PLT posture, release-trust evidence, and a keep/optimize/move/quarantine/delete classification ledger.
- Workflow topology + cache hygiene: `openfeature-companion` wired into the `release_gate` aggregate with skipped→success transforms (no pending trap), cross-lane mix cache fallback removed, lint/PLT cache keys scoped, and scripts-first version/cache/repro observability.
- Mix/ExUnit performance: the dominant published-Hex smoke test relocated behind an opt-in `@tag :published_hex_smoke` (default lane ~42s → ~5s) while staying reachable on a named scope; evidence-gated async audit (0 recommended flips); partitioning rejected with evidence (FUT-01).
- Browser/demo determinism: Playwright trace/retry mismatch fixed at root cause (retain-on-failure), `verify.sh` failure-output block, SHA-pinned CI `upload-artifact`; all 15 specs confirmed KEEP.
- DX + closeout: `mix ci` fast-loop alias, `MAINTAINING.md` command ladder + 9-row CI Failure Triage table, `123-CI-CD-CLOSEOUT.md` before/after ledger with honest p95/cache gaps, and a D-14 anti-drift guard in `release_contract_test.exs`.

### What Worked
- Audit-first sequencing: Phase 119 produced repo-specific evidence before any behavior change, so every later optimization cited a measured baseline rather than a guess.
- Evidence gates kept the milestone honest — async flips and test partitioning were both *rejected* with documented hazards instead of being adopted for cosmetic speed.
- Conservative posture preserved release-gate trust: the `release_gate` aggregate, post-publish proof, mounted/OpenFeature proofs, and the adopter contract all stayed intact while the default test lane got ~8× faster.

### What Was Inefficient
- The orphaned CIDX-01/02/03 requirements forced an inserted Phase 119.1 (verify-audit-deliverable) and four audit iterations before the milestone reached `passed` — the audit deliverable should have carried explicit per-requirement traceability the first time.
- SUMMARY `requirements_completed` frontmatter was left empty or mis-spelled (`requirements-completed`) across several phases, so coverage had to be confirmed manually against each VERIFICATION.md table at close — and produced `"One-liner:"` placeholders that had to be hand-corrected in MILESTONES.md.
- The v1.18-kickoff archival silently broke `lint.sh` (a path-pinned admin-foundations guard pointed at an archived v1.17 contract); discovered only at closeout, fixed by relocating the contract to `brandbook/admin-foundations-contract.md`.

### Patterns Established
- Opt-in heavy tests: gate the slowest network-dependent proof behind an env-tagged scope, keep it reachable on a named lane, and assert it still runs there — speed without hiding risk.
- Required-check hygiene: aggregate gate with skipped→success transforms + `if: always()` to avoid the path-gated/docs-only pending trap.
- Anti-drift guards: assert maintainer-facing docs (MAINTAINING triage table) from a contract test so DX docs cannot silently drift from `scripts/ci/*` microcopy.

### Key Lessons
1. Audit deliverables must carry explicit per-requirement traceability up front; an audit that "covers" a requirement without naming its REQ-ID orphans it and costs an inserted verification phase later.
2. Frontmatter conventions (`requirements_completed`) need a single enforced spelling — mixed/empty values quietly degrade the close-out extraction and require manual repair.
3. Archival is a code-affecting operation: moving planning docs can break path-pinned CI guards, so milestone close should re-run lint, not just the planning audit.

### Cost Observations
- 6 phases, 14 plans, 20 tasks; 113 commits, 182 files (+13,998 / −15,726) over 3 days.
- Closeout extraction produced 6 placeholder one-liners (empty SUMMARY frontmatter) requiring manual MILESTONES.md repair.
- Known deferred items at close: 0 open artifacts; 3 non-blocking tech-debt notes recorded in the audit (doc-drift, docs-only adopter-contract run, frontmatter convention).

## Milestone: v1.17 — Admin Design System Stress Test

**Shipped:** 2026-06-15
**Phases:** 6 | **Plans:** 19 | **Tasks:** 33

### What Was Built
- Demo-hosted Phoenix LiveView matrix rendering real admin components with deterministic stress fixtures and source-boundary tests.
- Playwright evidence for the real Phoenix admin UI matrix across theme, viewport, reduced-motion, keyboard, overflow, screenshot, and static-fixture preservation paths.
- Breakpoint exception ledger and stdlib source guard now make admin foundation drift auditable in CI.
- Reusable admin composite families with explicit provenance, guardrail, governance, uncertainty, trace, and authored-state labels.
- Route-cluster IA review plus deterministic UI matrix route examples for the Phase 117 flow set.
- Playwright route-flow evidence for primary admin clusters, command palette reachability, kill-switch focus order, mobile containment, and generated screenshots.
- Stdlib CI guard that protects matrix/workflow evidence hooks, generated screenshot posture, selected contrast proof, fixture-health coverage, and visual-baseline exclusions.
- Reusable v1.17 evidence map with exact backend URL, generated screenshot counts, deterministic assertion results, and guard-chain output.

### What Worked
- Rendering real Phoenix components in a dev-hosted matrix avoided duplicating markup in static fixtures, keeping evidence truthful to the running app.
- Relying on deterministic Playwright assertions (contrast, overflow, focus, roles) rather than brittle pixel baselines allowed for rapid iteration without test maintenance overhead.
- Grouping foundation hardening, primitive/composite polish, and IA flow into distinct phases provided a clear sequence from atomic rules to full-page layouts.

### What Was Inefficient
- Playwright combination runs experienced occasional transient flakiness, suggesting a need for stronger isolation or retries in CI.
- Manual visual review is still required for the generated Playwright screenshots, as automated diffing was intentionally excluded.

### Patterns Established
- UI matrix as a dev-only route serving as the definitive contract for component states.
- Assertions over screenshots: prefer programmatic Playwright checks for accessibility and layout rules, leaving screenshots strictly as artifacts for human review.

### Key Lessons
1. A repo-native component matrix provides much higher confidence than static HTML fixtures when building LiveView UIs.
2. Design system stress testing is most effective when it includes rare states (empty, error, long-label, reduced-motion) upfront.
3. It's possible to build rigorous UI tests without resorting to costly pixel-perfect diffing tools.

### Cost Observations
- 6 phases, 19 plans, 33 tasks executed smoothly.
- Known deferred items at close: 2 (UAT and Verification gaps acknowledged).

## Milestone: v1.16 — Brand-Faithful UI Iteration

**Shipped:** 2026-06-13
**Phases:** 7 | **Plans:** 8

### What Was Built

- Rulestead-owned admin, fixture, brandbook, and demo launcher surfaces now match the v1.15 identity across light, dark, and system modes.
- Static fixtures expose the shipped wordmark, copied logo assets are drift-checked, and logo/contrast guards run in the normal lint path.
- Shared admin primitive tokens now align primary foregrounds, soft-primary states, and focus/selection rings with the frozen mineral palette.
- Browser evidence covers admin route clusters, demo launcher, FleetDesk, fixtures, desktop/mobile widths, theme modes, logo visibility, theme controls, and overflow absence.
- Phase 112.1 closed the audit-discovered FleetDesk dynamic URL gap and added click-through proof plus a build/release rollouts evidence row.
- Canonical verification/validation artifacts were backfilled so the milestone audit now passes.

### What Worked

- The UI-SPEC boundary kept FleetDesk host-branded while letting Rulestead-owned surfaces inherit the v1.15 identity.
- Reusable guard scripts (`check_*`) made token/logo/contrast drift cheap to verify after every visual correction.
- Compose-backed Playwright evidence caught a real dynamic-port bug that screenshots alone would have missed.

### What Was Inefficient

- Initial closeout marked v1.16 complete before canonical `VERIFICATION.md`, `VALIDATION.md`, and summary frontmatter were present.
- `milestone.complete` auto-extracted weak accomplishments from summary bodies and duplicated the existing v1.16 `MILESTONES.md` entry, requiring manual cleanup.

### Patterns Established

- Treat demo launcher navigation as runtime URL plumbing, not a fixed local-port assumption.
- Keep visual evidence broad and assertion-heavy rather than committing brittle pixel baselines.
- Backfill audit artifacts as first-class closeout work rather than accepting verification-record gaps as silent debt.

### Key Lessons

1. A milestone can be functionally shipped while still failing the planning audit; closeout needs both product evidence and canonical traceability.
2. Host-brand boundaries need browser assertions, not just copy in a UI-SPEC.
3. Dynamic compose ports are useful audit pressure: they expose hidden localhost assumptions before release.

### Cost Observations

- Same-day milestone with one inserted gap-closure phase.
- Fresh closeout proof: deterministic guard chain, backend page-controller regression, and `scripts/demo/verify.sh` with compose smoke plus 105 Playwright tests.

## Milestone: v1.11.1 — Gap Closure

**Shipped:** 2026-05-29
**Phases:** 3 | **Plans:** 3

### What Was Built

- Lifecycle deep-link anchor fix (`#6-create-your-first-flag-lifecycle-required`) with contract test regression guard.
- Phase 76/77 `VERIFICATION.md` backfill and `77-VALIDATION.md` status refresh.
- DOC-01 `evaluation.md` Runtime string guard in `intro_integration_spine_contract_test.exs`; `76-VALIDATION.md` Nyquist artifact.

### What Worked

- Thin gap-closure phases (one plan each) closed audit deferrals without guide churn or `verify.phase76.ex` edits.
- Nyquist VALIDATION backfill pattern from Phases 77/79 applied to Phase 76 without re-running shipped work.
- Contract test module accumulates per-guide assertions — spine + evaluation — in one merge-gate file.

### What Was Inefficient

- Original v1.11 audit (`gaps_found`) predated gap closure; requires re-audit to flip status to `passed`.
- `milestone.complete` CLI phase filter would have included archived `<details>` phases if run with `milestone: v1.11` in STATE.

### Patterns Established

- Gap-closure milestones as v1.11.1 patch band separate from v1.11 integration spine (76–78) archive.
- Defer contract guards to follow-on phase when grep proof ships first (DOC-01 Phase 80 → Phase 81).

### Key Lessons

1. Audit `gaps_found` should spawn a dedicated gap-closure band before declaring milestone maintenance-complete.
2. Numbered Markdown heading slugs are required for GitHub/HexDocs cross-doc deep links.
3. VERIFICATION backfill + contract guard extension can ship as docs/test-only without API changes.

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
| v1.16 | 7 | 8 | Closed brand-faithful UI iteration with browser evidence and audit traceability backfill |
| v1.18 | 6 | 14 | First non-product (CI/CD reliability) milestone: audit-first sequencing + evidence-gated rejection of cosmetic speedups |

### Cumulative Quality

| Milestone | Phase verify gates | Release-contract guards | Deferred at close |
|-----------|-------------------|-------------------------|-------------------|
| v1.5.0 | verify.phase52 | guarded rollout drift guards | 2 |
| v1.6.0 | verify.phase54–56 | reusable targeting drift guards | 4 |
| v1.7.0 | verify.phase60 | blast-radius governance drift guards | 3 |
| v1.16 | v1.16 audit passed | brand/token/logo/contrast guards + demo verifier | 1 |
| v1.18 | v1.18 audit passed (iter 4) | release_gate aggregate + post-publish proof + D-14 MAINTAINING anti-drift guard | 0 |

### Top Lessons (Verified Across Milestones)

1. Support-truth and proof closure milestones pay down adopter friction before differentiated features land.
2. Core owns contracts and validation; mounted admin owns presentation — the sibling-package split scales across feature families.
3. Fail-closed validation at publish/mutation boundaries prevents broken snapshots better than post-hoc operator warnings.
