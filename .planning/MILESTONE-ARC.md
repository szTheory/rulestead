# Milestone Arc: Post-v1.1.0

**Last updated:** 2026-05-23 during `gsd-new-milestone`
**Selection posture:** Default to the highest-priority candidate below unless the user explicitly chooses a materially different direction. Shift low-impact milestone-selection preference left inside GSD instead of re-opening the full tradeoff set every time.

## Current Recommendation

- **Activate now:** `v1.2.0 — Lifecycle Hygiene & Ownership`
- **Why now:** This is the clearest everyday JTBD gap after GA and bounded tenancy. It improves operator trust, cleanup safety, and least-surprise UX without widening the linked-version, two-package product shape.

## Candidate Ranking

### 1. `v1.2.0 — Lifecycle Hygiene & Ownership`

**Status:** active candidate selected on 2026-05-23
**Why it wins now:**

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

### 2. `v1.3.0 — Guarded Rollout Foundations`

**Status:** immediate follow-on candidate
**Why it is next, not now:**

- High-value differentiator, but it depends on stronger operator trust, clear threshold semantics, and disciplined host-supplied signals
- More complex and more surprising if pulled left before the lifecycle/cleanup loop is fully credible

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

### 3. `v1.4.0 — Reusable Targeting Assets`

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
