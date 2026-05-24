# Milestone Arc: Post-v1.2.0

**Last updated:** 2026-05-24 during milestone v1.3.0 initialization
**Selection posture:** Default to the highest-priority candidate below unless the user explicitly chooses a materially different direction. Shift low-impact milestone-selection preference left inside GSD instead of re-opening the full tradeoff set every time.

## Active Milestone

- **Activated now:** `v1.3.0 — Adopter Truth & Proof Closure`
- **Why now:** The product surface is already broad enough that the highest-leverage next step is to make the public release story, install path, migrations, and verification evidence agree with each other before adding another differentiated control-plane wedge.

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

**Status:** active on 2026-05-24
**Why it is next now:**

- Planning truth currently outruns public package docs and runnable proof in a few important places.
- A serious adopter is more likely to get blocked by conflicting release/install/test signals than by the absence of another differentiated feature.
- Closing support-truth drift now keeps later guarded rollout work credible instead of layering it onto a partially trustworthy release surface.

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

### 3. `v1.4.0 — Guarded Rollout Foundations`

**Status:** next differentiator after `v1.3.0`
**Why it moved back one slot:**

- Still high-value, but it depends on stronger operator trust, clear threshold semantics, and disciplined host-supplied signals.
- It is a poor next move if docs, migrations, and verification still disagree about the current shipped surface.

**Recommended shape if activated later:**

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

### 4. `v1.5.0 — Reusable Targeting Assets`

**Status:** top medium-term candidate after guarded rollout
**Why it is later:**

- Solves scale and duplication pain, but not the biggest current trust/operability gap
- Introduces indirection across explainability, compare, promotion, import/export, and dependency visibility

**Recommended shape if activated later:**

- Shared audiences first
- Any templates remain draft-based, bounded, and non-inheriting
- Impact previews and reference counts before edits

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
- `prompts/rulestead-admin-ux-and-operator-ia.md`
- `prompts/rulestead-engineering-dna-from-prior-libs.md`
- `prompts/rulestead-host-app-integration-seam.md`
- `prompts/rulestead-personas-jtbd-and-onboarding.md`
- `prompts/rulestead-testing-and-e2e-strategy.md`
