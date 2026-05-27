# Milestone Arc: Post-v1.6.0 Closeout

**Last updated:** 2026-05-27 after post-v1.7 assessment (see `.planning/threads/2026-05-27-post-v1.7-milestone-assessment.md`)
**Selection posture:** Default to the highest-priority candidate below unless the user explicitly chooses a materially different direction. Shift low-impact milestone-selection preference left inside GSD instead of re-opening the full tradeoff set every time.

## Active Milestone

- **Active:** `v1.9.0 — Host-Supplied Preview Evidence` (`IMP-05`) — Phases 65-68 (initialized 2026-05-27)
- **Last shipped:** `v1.8.0 — Guarded Rollout Auto-Advance` on 2026-05-27 (Phases 61-64)
- **After v1.9:** defer `ADM-06` presets / `ROL-08` baseline comparison

## Candidate Ranking

### 1. `v1.2.0 — Lifecycle Hygiene & Ownership`

**Status:** shipped on 2026-05-24
**Why it won:**

- Solves daily trust and cleanup pain instead of later-stage scale pain.
- Fits the existing Elixir/Phoenix shape cleanly: metadata and lifecycle contracts in `rulestead`, mounted workflow and operator UX in `rulestead_admin`, host identity still host-owned.
- Builds directly on already-shipped code references, auditability, explainability, governance, and mounted admin seams.
- Matches mature platform lessons from Unleash, LaunchDarkly, GrowthBook, Flipper, and the local JTBD/persona docs: owner, lifecycle state, stale guidance, and safe retirement need to feel first-class.

**Recommended shape:**

- First-class ownership metadata and lifecycle defaults on flags
- Explicit lifecycle states and expected-lifetime guidance
- Archive-readiness guidance that combines code references, last evaluation, and lifecycle metadata
- Calm cleanup UX across CLI, docs, and mounted admin filters/workbench

**Key tradeoffs:**

- Strong operator value, lower marketing flash than guarded rollouts
- Easy to overbuild into noisy heuristics or a mini work-management system if not kept narrow

**Guardrails:**

- Keep runtime evaluation independent from lifecycle scans and ownership lookups
- Treat owner references as opaque host-owned metadata, not a new Rulestead identity model
- Keep lifecycle/archive guidance advisory; never auto-archive
- Preserve the linked-version sibling-package model and avoid standalone-admin drift

### 2. `v1.3.0 — Adopter Truth & Proof Closure`

**Status:** shipped on 2026-05-25
**Why it won:**

- Planning truth had outrun public package docs and runnable proof in a few important places.
- A serious adopter was more likely to get blocked by conflicting release/install/test signals than by the absence of another differentiated feature.
- Closing support-truth drift before rollout work preserved later roadmap credibility instead of layering new capability on top of a partially trustworthy release surface.

**Recommended shape:**

- Align root/package docs with the actual post-`v1.0.0` release posture
- Reconcile lifecycle ownership schema, migrations, and installer truth
- Restore green or honestly bounded verification across `rulestead`, `rulestead_admin`, and the OpenFeature bridge
- Keep the work bounded to proof, docs, and support-truth rather than expanding into a redesign milestone

**Key tradeoffs:**

- Lower marketing flash than guarded rollout
- Higher adopter trust and lower support friction per unit of work

**Guardrails:**

- Do not use the milestone as an excuse to widen scope into unrelated polish
- Fix proof truth, not vanity metrics
- Keep the sibling-package release model and mounted-admin posture unchanged

### 3. `v1.4.0 — Mounted Companion Proof Reclosure`

**Status:** shipped on 2026-05-26
**Why it won:**

- The repo remained broad and credible, but the documented mounted companion proof bar had become the last materially broken adopter-facing proof surface.
- A serious adopter is more likely to be blocked by a broken named proof path than by the absence of guardrail automation.
- The work is narrow, support-facing, and preserves the existing sibling-package product shape instead of widening it.

**Recommended shape:**

- Restore a passing `mounted_admin_contract` proof bar from the repo root
- Reconcile runtime boot/package-boundary truth for `rulestead_admin`
- Keep root/package docs and proof posture language aligned with the actually runnable mounted companion surface

**Key tradeoffs:**

- Lower marketing flash than guarded rollout
- Higher adopter trust per unit of work than another new differentiator at that point

**Guardrails:**

- Keep the milestone bounded to proof closure, support truth, and boot/runtime coherence
- Do not widen the work into admin redesign or unrelated feature expansion
- Preserve the linked-version sibling-package model and mounted-admin posture

### 4. `v1.5.0 - Guarded Rollout Foundations`

**Status:** shipped on 2026-05-27
**Why it was activated next:**

- It offers the strongest product differentiation once the support-truth surface is credible.
- The work now lands on a calmer base: docs, migrations, installer truth, and bounded verification no longer fight each other.
- Its main risk remains scope drift into observability or control-plane expansion, so the guardrails stay essential.

**Shipped shape:**

- Host-supplied rollout-signal behaviour seam
- Stage-level monitoring windows with explicit `hold` / `roll back`
- Audit-first explanation inside the existing rollout workflow

**Key tradeoffs:**

- Strong differentiation and release-safety story
- High risk of scope drift into observability product, anomaly detection platform, or standalone control plane

**Guardrails:**

- Keep metrics host-supplied; do not own telemetry backends
- Fail closed on stale, weak, or missing signal data
- Preserve deterministic sticky rollout semantics; never use time-based gradual rollout for user-facing rollout

### 5. `v1.6.0 - Reusable Targeting Deepening`

**Status:** shipped on 2026-05-27
**Why it shipped when it did:**

- Reusable audiences already exist in shipped runtime/admin/promotion surfaces, so the next value here is deepening ergonomics and blast-radius safety rather than introducing the concept
- Guarded rollout foundations shipped in `v1.5.0`, so rollout safety now has enough base support for targeting dependency visibility to become the next trust gap
- Introduces indirection across explainability, compare, promotion, import/export, and dependency visibility

**Activated shape:**

- Audience impact previews and reference counts before edits
- Stronger dependency visibility and explainability for existing audience reuse
- Promotion, manifest, compare, explainability, archive/delete, and guarded-rollout interaction validation that fails closed on missing, archived, incompatible, stale, or tenant-mismatched audience references
- Mounted admin workflows that show "used by" scope, preview basis, affected references, confirmation state, and audit evidence
- Any presets remain deferred unless draft-only, bounded, and non-inheriting after safety surfaces are complete

**Key tradeoffs:**

- Good product leverage once operators have accumulated repeated targeting logic
- Easy to create blast-radius surprises and hidden dependency graphs

**Guardrails:**

- Compile shared assets into snapshots for local deterministic evaluation
- Fail closed when referenced assets are missing or incompatible
- Avoid live inheritance graphs, workflow-engine behavior, and release-orchestration drift

### 6. `v1.7.0 — Blast-Radius Governance`

**Status:** shipped on 2026-05-27
**Why it is next:**

- v1.6 delivered impact previews and dependency truth; protected-environment audience edits still lack threshold-based change-request routing (GOV-01)
- Natural closure of the reusable-targeting safety arc: preview → dependency visibility → governed brakes
- Lower scope-drift risk than auto-advance rollouts (ROL-04), which v1.5 explicitly deferred as a later layer

**Recommended shape:**

- Blast-radius threshold contract evaluated over preview/dependency payloads (reference counts, rollout/lifecycle hints)
- High-blast-radius audience mutations in protected environments route through existing change-request envelope
- Mounted proposal/approval UX; audit includes preview fingerprint and threshold context
- Bundle quickstart/doc support truth in verification phase (README payload-first API)

**Key tradeoffs:**

- Strong Tech Lead / release-owner value; lower marketing flash than ROL-04
- Must not widen into generic workflow engine or blast-radius dashboards

**Guardrails:**

- Reuse existing change requests, approvals, and governed-action envelope — no parallel governance path
- Require fresh preview token/fingerprint before proposal (build on v1.6 IMP contract)
- Keep host auth and identity host-owned; thresholds are authored-state based, not observability-backed population counts

### 7. `v1.8.0 — Guarded Rollout Auto-Advance` (ROL-04)

**Status:** active (initialized 2026-05-27)
**Why it follows GOV-01:**

- Completes v1.5 guarded rollout story (hold/rollback shipped; auto-advance deferred)
- Strongest remaining differentiator once shared-audience governance closes
- Higher trust risk — requires healthy guardrail provider and observation windows

**Guardrails:**

- Fail closed on stale, weak, or missing signals; never assume healthy
- Governed + audited stage advancement only; preserve deterministic sticky rollout semantics
- Do not widen into observability product or time-based gradual rollout

## Cross-Candidate Architecture Guidance

- Preserve `rulestead` as runtime/domain contract and `rulestead_admin` as the mounted operator companion
- Keep host auth, identity, tenant catalog truth, and observability ownership in the host app
- Prefer additive, explicit behaviours and `Ecto.Multi`-backed authored-state mutations over implicit magic
- Maintain deterministic local evaluation, explainability, auditability, and shareable URL-driven admin state
- Favor simple-mode defaults and progressive disclosure in the admin UI

## Sources

- `.planning/research/JTBD-MAP.md`
- `.planning/research/V1_2_0_LIFECYCLE_HYGIENE_OWNERSHIP_MEMO.md`
- `.planning/research/v1.2.0-guarded-rollout-foundations-recommendation.md`
- `.planning/research/v1.2.0-reusable-targeting-assets-memo.md`
- `.planning/threads/2026-05-25-next-milestone-assessment.md`
- `.planning/threads/2026-05-27-next-milestone-assessment.md`
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-engineering-dna-from-prior-libs.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
