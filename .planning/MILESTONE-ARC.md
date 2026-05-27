# Milestone Arc: Post-v1.5.0 Closeout

**Last updated:** 2026-05-27 during milestone v1.6.0 activation
**Selection posture:** Default to the highest-priority candidate below unless the user explicitly chooses a materially different direction. Shift low-impact milestone-selection preference left inside GSD instead of re-opening the full tradeoff set every time.

## Active Milestone

- **Active now:** `v1.6.0 - Reusable Targeting Deepening`
- **Why it is active:** With guarded rollout foundations shipped, the next highest-leverage product gap is making already-shipped reusable audience targeting safer to edit, easier to inspect, and clearer to explain without introducing hidden inheritance graphs or standalone control-plane behavior.
- **Scope posture:** Deepen impact previews, dependency visibility, promotion/manifest validation, mounted operator ergonomics, and support truth for existing reusable audiences.
- **Next queued candidate:** none selected; choose after `v1.6.0` closeout based on audit findings.

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

**Status:** active as of 2026-05-27
**Why it is active now:**

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
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-engineering-dna-from-prior-libs.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
