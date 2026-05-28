# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and remote-config platform for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages: `rulestead` for runtime evaluation and `rulestead_admin` for the mounted operator UI. It gives Phoenix teams deterministic evaluation, explicit context, explainability, lifecycle hygiene, and a self-hosted admin plane that stays aligned with host-app auth and deployment workflows.

## Current State

- `v1.0.0` shipped on 2026-05-21 across Phases 26-28.
- The product now has a frozen public API boundary, canonical mounted-admin RBAC, and a proven Compose-backed end-to-end demo with Phoenix + Next.js/OpenFeature integration.
- `v1.1.0` shipped on 2026-05-23 across Phases 29-34, delivering the bounded tenancy seam, mounted-admin tenant scope, audit tenant provenance enforcement, public promotion-plan tenant-scope closure, compare preview-identity carry-through, and milestone auditability backfill without widening the product shape.
- `v1.2.0` shipped on 2026-05-24 across Phases 35-40, delivering host-owned ownership metadata, bounded archive-readiness guidance, a governed mounted lifecycle cleanup flow, and release-facing lifecycle docs plus verification without widening the sibling-package release model.
- `v1.3.0` shipped on 2026-05-25 across Phases 41-44, closing release-truth drift, authored-state parity, mounted companion verification, and OpenFeature companion proof without widening the linked sibling-package release model.
- `v1.4.0` shipped on 2026-05-26 across Phases 45-48, restoring the mounted companion boot/runtime contract, the repo-root `mounted_admin_contract` proof bar, and the release/support-truth chain without widening the sibling-package product shape.
- `v1.5.0` shipped on 2026-05-27 across Phases 49-52, adding host-owned guardrail signal contracts, fail-closed guarded rollout decisions, governed/audited hold or rollback behavior, mounted guardrail explanation surfaces, and bounded proof/docs truth without turning Rulestead into an observability product.
- `v1.6.0` shipped on 2026-05-27 across Phases 53-56, deepening reusable audience targeting with impact previews, dependency inventory and fail-closed validation, mounted preview-confirm-audit workflows, explain trace carry-through, and bounded proof/docs/support truth without widening the sibling-package release model.
- `v1.7.0` shipped on 2026-05-27 across Phases 57-60: blast-radius threshold contract, change-request integration, mounted governance workflows, and proof/docs/support-truth closure (`mix verify.phase60`, release-contract drift guards, payload-first quickstart parity).
- `v1.8.0` shipped on 2026-05-27 across Phases 61-64: authored auto-advance policy contract, scheduled orchestration with fail-closed eligibility and protected-env governance, mounted rollouts auto-advance panel and timeline labeling, and proof/docs/support-truth closure (`mix verify.phase64`, release-contract drift guards, host seam + flow guides, `guarded_rollout_auto_advance` CI scope).
- `v1.9.0` shipped on 2026-05-28 across Phases 65-68: host-supplied preview evidence resolver seam, evidence carry-through and GOV-05 boundary, mounted sample cohort and impression summary UX, and proof/docs/support-truth closure (`mix verify.phase68`, release-contract drift guards, host seam + flow guides, `host_preview_evidence` CI scope).
- `v1.10.0` shipped on 2026-05-28 across Phases 69-72: post-GA planning truth, doc/API honesty, `mix verify.phase72` / `mix verify.adopter` proof umbrella, `post_ga_band_closure` CI scope, and public band-complete signaling — no new product APIs.
- **Phase 73 complete (2026-05-28):** Context `traits:` → `attributes` back-compat, quickstart doc honesty guards, and MAINTAINING.md live public-surface contract (CTX-01, CTX-02, DOC-01; closes INV-MAINT-01).

<details>
<summary>Shipped: v1.11 Integration Spine (2026-05-28)</summary>

**Goal:** Close the first-hour Phoenix integration gap (INV-INTRO-01) with a single intro spine — supervision → config → Plug → first flag with lifecycle fields — without new product APIs.

**Delivered:** Phases 76–78; see `.planning/v1.11-MILESTONE-AUDIT.md`

**Proof:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

</details>

<details>
<summary>Shipped: v1.10.1 Support-truth & Contract Honesty (2026-05-28)</summary>

**Goal:** Close the last adopter-trust leaks in docs, API catalog, and contract tests — no new product APIs.

**Delivered:** Phases 73–75; see `.planning/v1.10.1-MILESTONE-AUDIT.md`

</details>

## Post-GA Band Status

v1.1–v1.9 feature band is **complete**. v1.10.x is patches and support truth only. See `guides/introduction/product-boundary.md` and `.planning/DEFERRED.md` for v2 triggers.

## Next Milestone Goals

**Path-to-done (canonical):** See [`.planning/threads/2026-05-28-path-to-done-milestones.md`](.planning/threads/2026-05-28-path-to-done-milestones.md).

| Order | Milestone | Notes |
|-------|-----------|-------|
| 1 | **v1.10.1 — Support-truth & contract honesty** | **Complete** (2026-05-28) — Phases 73–75; see `v1.10.1-MILESTONE-AUDIT.md` |
| 2 | **v1.11 — Integration spine (docs-only)** | **Active** — Phases 76–78; first-hour Phoenix path; INV-INTRO-01 |
| 3+ | **v2.0+ wedges (triggered only)** | GOV-02-ext → ROL-08 → ADM-06 per `.planning/DEFERRED.md` |
| — | **Maintenance** | After v1.10.x + optional v2: patches only unless product direction changes |

**Done band (2026-05-28 assessment):** ~91–94% for stated post-GA scope; feature band v1.1–v1.9 verified in `lib/` + contract tests.

**Next action:** `/gsd-discuss-phase 76` or `/gsd-plan-phase 76` for integration spine (Phase 76)

<details>
<summary>Latest shipped: v1.10.0 Post-GA Band Truth & Adopter Closure (2026-05-28)</summary>

**Goal:** Close the post-GA adopter-trust band with docs, proof bars, and planning alignment — not new product features.

**Delivered:**

- Post-v1.9 band assessment and JTBD/planning truth refresh with ~94–96% done-band verdict
- `product-boundary.md`, `footguns.md`, payload-first + `Rulestead.Runtime` quickstart honesty
- `mix verify.phase72`, `mix verify.adopter`, `post_ga_band_closure` CI scope, `scripts/demo/proof.sh`
- `v1.10.0-MILESTONE-AUDIT.md` (`band_complete`); v1.9 phase archive

</details>

<details>
<summary>Previous: v1.9.0 Host-Supplied Preview Evidence (2026-05-28)</summary>

**Goal:** Close the reusable-targeting preview gap with host-supplied bounded sample cohorts and impression summaries through an explicit seam—without claiming authoritative population counts or widening blast-radius governance.

**Delivered:**
- `PreviewEvidence` behaviour, ImpactPreview schema v2, Fake/Ecto wiring, and contract tests with GOV-05 boundary.
- Audit and change-request carry-through for support-safe preview evidence summaries.
- Mounted audience preview flows with honest uncertainty copy and forbidden observability overclaim guards.
- `mix verify.phase68`, release-contract drift guards, host seam + flow guides, `host_preview_evidence` CI scope.

</details>

<details>
<summary>Previous: v1.8.0 Guarded Rollout Auto-Advance (2026-05-27)</summary>

**Goal:** Complete the guarded rollout story by letting staged rollouts automatically advance when host-supplied guardrails remain healthy for a configured observation window—without turning Rulestead into an observability product.

**Delivered:**
- Authored auto-advance policy with observation window and explicit next-stage plan; fail-closed eligibility on v1.5 guardrails.
- `ScheduledExecution` / Oban observation-window ticks with governed `advance_rollout`, idempotency, and protected-env change-request parity.
- Mounted rollouts auto-advance panel, pending observation, and `guardrail_automation` timeline distinction.
- `mix verify.phase64`, release-contract drift guards, host seam + flow guides, optional `guarded_rollout_auto_advance` CI scope.

</details>

<details>
<summary>Previous: v1.7.0 Blast-Radius Governance (2026-05-27)</summary>

**Goal:** Close the reusable-targeting safety arc by routing high-blast-radius protected-environment audience edits through governed change requests after v1.6 preview and dependency truth are proven.

**Delivered:**
- Blast-radius threshold contract over preview/dependency payloads with fail-closed protected-environment semantics.
- Audience mutation change-request integration reusing the existing governed envelope.
- Mounted proposal/review workflows with policy-aware blast-radius visibility.
- `mix verify.phase60`, release-contract drift guards, and payload-first quickstart parity.

</details>

<details>
<summary>Assessment: 2026-05-27 next-milestone review (87% done band)</summary>

See [`.planning/threads/2026-05-27-next-milestone-assessment.md`](/Users/jon/projects/rulestead/.planning/threads/2026-05-27-next-milestone-assessment.md) for adopter-facing evidence, ranking, and open investigations.

</details>

<details>
<summary>Previous milestone: v1.6.0 Reusable Targeting Deepening (shipped 2026-05-27)</summary>

**Goal:** Deepen already-shipped reusable audience targeting with impact previews, dependency visibility, explainability, and bounded mounted operator workflows while preserving deterministic snapshots and the linked sibling-package release design.

**Delivered:**
- Core audience dependency inventory, reference counts, and fail-closed validation for referenced, archived, missing, stale, or tenant-mismatched audiences.
- Impact preview and confirmation contract for audience edits, archive/delete attempts, and protected mutation paths.
- Promotion, manifest, compare, explainability, and mounted admin surfaces that make reusable audience dependencies visible and supportable.

</details>

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Strategic Arc (Future Milestones)

To provide a clear path forward for Rulestead as a "batteries included" feature-management platform, the following strategic arc captures the shipped path to GA and the current post-GA ordering (see `.planning/MILESTONE-ARC.md` for the decision record and tradeoffs):

- **v0.6.0: Multi-environment Sync & Tenancy**
  - Focus: Environment promotion (Dev->Staging->Prod), diffing, GitOps export/import, and explicit multi-tenant helpers.
  - Value: Provide comprehensive tooling for complex SaaS environments and organizational rollouts, matching enterprise developer expectations.
- **v1.0.0: General Availability & RBAC**
  - Focus: Role-Based Access Control, API lockdown, security hardening, and complete reference documentation.
  - Value: A reliable, trusted, "done" system without feature creep that fulfills the Elixir-native platform promise.
- **v1.2.0: Lifecycle Hygiene & Ownership**
  - Focus: Ownership metadata, lifecycle state, archive-readiness guidance, cleanup workbench UX, and docs that teach “flag from birth to retirement.”
  - Value: Closed the biggest everyday trust and cleanup gap before adding more complex automation or reuse layers.
- **v1.3.0: Adopter Truth & Proof Closure**
  - Focus: Align docs, install truth, migrations, and verification evidence with the actual post-GA product surface.
  - Value: Removed the highest-friction trust gap for serious adopters before adding another differentiated wedge.
- **v1.4.0: Mounted Companion Proof Reclosure**
  - Focus: Restore the runnable mounted companion proof bar, reconcile sibling-package boot/runtime truth, and re-close the remaining support-surface gap.
  - Value: Shipped on 2026-05-26; it finished the last meaningful adopter-trust repair before the next differentiated feature.
- **v1.5.0: Guarded Rollout Foundations**
  - Focus: Host-supplied rollout guardrail signals, stage hold/rollback, and explicit audited health-gated rollout behavior.
  - Value: The strongest next differentiator once the mounted companion support surface is fully credible again.
- **v1.6.0: Reusable Targeting Deepening**
  - Focus: Deepen the already-shipped audience reuse model with impact previews, dependency visibility, and bounded operator ergonomics.
  - Value: Shipped on 2026-05-27; reusable audience changes are now previewable, dependency-aware, explainable, and supportable without runtime lookup drift.

## Release Posture

- First public Hex release planning was intentionally delayed until the platform had credible multi-environment and governance depth.
- Public distribution shape: publish both sibling packages together on Hex, with `rulestead_admin` documented as the mounted admin companion rather than a standalone control-plane product.
- General Availability shipped in `v1.0.0` on 2026-05-21.

## Requirements

### Active

- **CTX-01**, **CTX-02**, **API-01** through **API-03**, **DOC-01**, **DOC-02**, **VER-01** through **VER-03**, **AUD-01**, **AUD-02** — v1.10.1 support-truth & contract honesty (Phases 73-75)

### Validated

- ✓ **IMP-05**, **IMP-06**, **IMP-07**, **GOV-05**, **ADM-05**, **VER-01** through **VER-03** — host-supplied preview evidence contract, governance boundary, mounted workflows, and proof/docs support truth — `v1.9.0`, Phases 65-68 (2026-05-28)
- ✓ **ROL-04** through **ROL-07**, **ORC-01**, **ORC-02**, **AUD-03**, **AUD-04**, **ADM-04**, **VER-01** through **VER-03** — guarded rollout auto-advance (`v1.8.0`, Phases 61-64)
- ✓ **ROL-07** (governance slice): Protected-env parity for auto-advance mutations — Phase 63
- ✓ **AUD-04**: Automation vs manual distinction in mounted timeline — Phase 63
- ✓ **ADM-04**: Mounted auto-advance toggle, pending observation, bounded prerequisite copy — Phase 63
- ✓ **VER-01** through **VER-03**: Proof, docs, host seam, and release-contract support truth — Phase 64 (`mix verify.phase64`, release-contract drift guards, host seam + flow guides, `guarded_rollout_auto_advance` CI scope) — `v1.8.0`
- ✓ **ROL-06**, **ORC-01**, **ORC-02**, **AUD-03** — Phase 62: observation-window ticks, governed execute orchestration, protected-env CR routing, automation audit evidence

- ✓ Deterministic payload-first evaluation with explicit context, explainability, and property-tested bucketing — `v0.1.0`
- ✓ Snapshot-backed runtime reads with refresh, diagnostics, and public telemetry events — `v0.1.0`
- ✓ Sibling-package release shape with `rulestead` core and mounted `rulestead_admin` UI — `v0.1.0`
- ✓ Installer, Plug/LiveView/Oban seams, and fake-backed test helpers — `v0.1.0`
- ✓ Mounted admin workflows for authoring, simulation, rollouts, kill switch, audit, and redaction/auth seams — `v0.1.0`
- ✓ Release-grade docs, API stability posture, verification trio, and gated publish workflow — `v0.1.0`
- ✓ Govern production mutations with change requests, approvals, and self-approval guards — `v0.2.0`
- ✓ Schedule future admin mutations with durable execution, idempotent recovery, and clear operator status — `v0.2.0`
- ✓ Add signed webhook ingress and outbound notification hooks for high-impact governance events — `v0.2.0`
- ✓ Close the `v0.1.0` verification and publish-evidence carryover items without destabilizing the shipped release line — `v0.2.0`
- ✓ Integrate standard OpenFeature API provider (`ECO` requirements) — `v0.3.0`
- ✓ Build lifecycle hygiene tools with code references and stale flag detection (`LCH` requirements) — `v0.3.0`
- ✓ Support formal experiments on top of existing flags with deterministic assignment and lifecycle controls (`EXP-01` to `EXP-03`) — `v0.4.0`
- ✓ Ingest evaluation impressions and conversion events with a public analytics tracking seam (`ANA-01`, `ANA-02`) — `v0.4.0`
- ✓ Expose experimentation reporting and guardrail metrics in the mounted Admin UI (`ANA-03`) — `v0.4.0`
- ✓ Add Redis-backed runtime storage and degraded-read fallbacks for distributed deployments (`STO-01`, `STO-02`) — `v0.5.0`
- ✓ Stream invalidation across nodes through the notifier seam with first-class PubSub wiring (`INV-01`, `INV-02`) — `v0.5.0`
- ✓ Surface infrastructure health and additive sync telemetry for operators (`INF-01`, `INF-02`) — `v0.5.0`
- ✓ Compare authored environment state and execute governed whole-flag promotion, including immutable history and re-apply (`PROM-01` to `PROM-04`) — `v0.6.0`
- ✓ Export, validate, diff, and import GitOps-friendly environment manifests (`MAN-01` to `MAN-04`) — `v0.6.0`
- ✓ Freeze the public API surface, package docs cleanly, and ship the FunWithFlags migration path (`API-01`, `API-02`, `DOC-01`, `DOC-02`) — `v1.0.0`
- ✓ Enforce canonical Viewer / Editor / Admin RBAC through the host-owned policy seam (`SEC-01`, `SEC-02`, `SEC-03`) — `v1.0.0`
- ✓ Prove the Docker-backed Phoenix + Next.js/OpenFeature demo stack end to end (`GA-01`, `GA-02`) — `v1.0.0`
- ✓ Support explicit tenant scope across runtime, admin, promotion, and manifest flows without environment-per-tenant topology (`TEN-01`, `TEN-02`, `TEN-03`) — `v1.1.0`
- ✓ Make ownership metadata, lifecycle guidance, cleanup review, and lifecycle docs first-class without widening the product shape (`LIF-01` to `LIF-05`) — `v1.2.0`
- ✓ Align release docs, installation guidance, and support-facing truth with the shipped post-GA package posture (`DOC-01`, `DOC-02`) — `v1.3.0`
- ✓ Reconcile runtime schema, migrations, and installer truth for lifecycle and ownership authored-state parity (`PAR-01`, `PAR-02`) — `v1.3.0`
- ✓ Restore mounted-admin contract truth and sibling-package verification credibility (`ADM-01`, `VER-01`) — `v1.3.0`
- ✓ Establish a runnable bounded proof path for `open_feature_rulestead` (`OFE-01`) — `v1.3.0`
- ✓ Re-close the mounted companion boot/runtime seam, bounded proof bar, CI/release semantics, and support-truth chain (`PKG-01`, `PKG-02`, `ADM-01`, `VER-01`, `DOC-01`) — `v1.4.0`
- ✓ Establish bounded guarded rollout foundations (`ROL-01`, `ROL-02`, `ROL-03`, `AUD-01`, `AUD-02`, `ADM-01`, `VER-01`) — `v1.5.0`
- ✓ Deepen reusable audience targeting with impact previews, dependency truth, mounted workflows, and support truth (`IMP-01` to `IMP-04`, `DEP-01` to `DEP-04`, `ADM-01` to `ADM-04`, `VER-01` to `VER-03`) — `v1.6.0`
- ✓ Blast-radius threshold contract for protected-environment audience mutations with fail-closed preview/dependency evaluation (`GOV-01` to `GOV-04`) — `v1.7.0`
- ✓ Audience mutation change-request integration reusing the governed envelope (`CRQ-01` to `CRQ-03`) — `v1.7.0`
- ✓ Mounted governance workflows for blast-radius proposal, review, and policy-aware visibility (`ADM-01` to `ADM-03`) — `v1.7.0`
- ✓ Blast-radius governance proof, docs, quickstart parity, and release-contract truth (`VER-01` to `VER-03`) — `v1.7.0`
- ✓ Authored auto-advance policy persistence with observation window and next-stage plan (`ROL-04` contract slice) — Phase 61
- ✓ Pure fail-closed auto-advance eligibility evaluation composing existing guardrail decisions (`ROL-05`) — Phase 61
- ✓ v1.5 guarded rollout hold/rollback preserved when auto-advance policy enabled (`ROL-07` contract slice) — Phase 61

### Out of Scope

- Broadening `rulestead_admin` beyond the mounted sibling-package design into a standalone control-plane product — explicitly disallowed by the current release design.
- Rulestead-owned identity or team-directory truth for lifecycle owners — host applications continue to own identity and accountability mapping.
- Automatic archival or automated code removal based on lifecycle heuristics — archive readiness remains advisory and explicit.
- Re-planning reusable audiences as a net-new milestone wedge — audience reuse is already part of the shipped ruleset, admin, compare, and manifest surfaces.

## Context

- `v0.1.0` through `v1.0.0` are now archived, covering the core runtime, admin UX, governance workflows, ecosystem seams, experimentation analytics, Redis-backed distribution, environment promotion, GitOps manifests, API lockdown, RBAC, and the GA demo stack.
- `v1.0.0` shipped across Phases 26-28, delivering the public API freeze, canonical RBAC, and the verified GA demo environment.
- `v1.1.0` shipped across Phases 29-34 as the first deliberate post-GA milestone, proving tenancy can stay bounded inside helper seams, reviewed-artifact validation, mounted-admin scope, public promotion replay/apply, and audit provenance without changing the release shape.
- `v1.2.0` shipped across Phases 35-40, proving ownership metadata, archive-readiness guidance, mounted cleanup preview/confirm flows, and lifecycle release surfaces can stay explicit, host-friendly, and sibling-package aligned.
- `v1.3.0` shipped across Phases 41-44, proving release-facing support truth, authored-state parity, mounted companion verification, and bounded OpenFeature proof can align without widening the product shape.
- `v1.4.0` shipped across Phases 45-48, proving the mounted companion boot/runtime seam, bounded proof bar, CI semantics, and support-truth surfaces can be reclosed cleanly without broadening the admin posture.
- `v1.5.0` shipped across Phases 49-52, proving bounded guarded rollout foundations can stay host-supplied, fail-closed, governed, audited, mounted-workflow-friendly, and explicitly documented without broadening into observability or standalone-admin scope.
- `v1.6.0` shipped across Phases 53-56, proving reusable audience targeting can be deepened with snapshot-local evaluation, impact previews, one core dependency truth, mounted preview-confirm-audit workflows, and aligned proof/docs without widening the sibling-package product shape.
- `v1.7.0` shipped across Phases 57-60, proving blast-radius governance can route high-impact protected-environment audience edits through the existing change-request envelope with threshold evaluation, mounted proposal/review UX, and aligned proof/docs without observability-backed counts or a parallel governance workflow.
- `v1.8.0` shipped across Phases 61-64, proving guarded rollouts can auto-advance after observation windows with fail-closed guardrails, governed orchestration, mounted operator UX, and aligned proof/docs.
- `v1.9.0` shipped across Phases 65-68, proving hosts can supply bounded preview evidence through an explicit resolver seam with audit carry-through, mounted rendering, and GOV-05 reference-count governance unchanged by impression richness.
- The project remains a linked-version, two-package monorepo. Phase numbering continues at 73 (v1.10.1 support-truth).
- Post-GA feature band v1.1–v1.9 is complete; v1.10.0 closed band truth; v1.10.1 closes contract/catalog honesty.

## Constraints

- **Release design**: Keep the linked-version sibling-package release shape — the runtime and admin packages evolve together.
- **Security**: Maintain default-deny mutation security and strict audit logs.
- **Tenancy scope**: Ship explicit tenant-aware helpers and validation only; do not introduce tenant-partitioned authored storage, environment-per-tenant topology, or implicit all-tenant mutation behavior.
- **Lifecycle ownership**: Treat owner references as host-owned opaque metadata; do not create a Rulestead-owned identity directory or team graph.
- **Operator trust**: Lifecycle guidance must be advisory, explicit, and previewable; never auto-archive based on heuristics.
- **Guarded rollout scope**: Any future rollout guardrails must stay host-supplied and must not widen Rulestead into an observability platform.
- **Support truth**: Public docs, install guidance, migrations, and verification evidence must agree before new differentiated milestone work claims the surface is ready.
- **Reusable targeting scope**: Future targeting work should deepen existing audience reuse safely; do not restate shipped audience support as if it were a greenfield milestone.
- **Reusable targeting preview truth**: Impact previews must declare their basis and uncertainty; Rulestead must not claim authoritative affected-user counts unless the host supplied bounded sample or impression evidence through explicit seams.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make `v0.3.0` focused on Ecosystem Integration & Lifecycle Hygiene | Tackling tech debt via code references and providing OpenFeature APIs are major confidence boosters for large-scale enterprise adoption over experimenting/analytics right now. | Validated |
| Keep infrastructure health node-local by default and accept peer data only through an explicit host seam | Prevents the admin UI from implying undiscovered cluster health while preserving extension points for larger deployments. | Validated |
| Emit additive sync/invalidation telemetry aliases instead of renaming shipped runtime events | Preserves compatibility for existing telemetry consumers while satisfying the new observability contract. | Validated |
| Mount diagnostics inside the existing `rulestead_admin` router macro | Keeps diagnostics inside the current session, policy, and linked-version admin envelope. | Validated |
| Reuse the existing governed-action envelope for protected-environment promotion | Keeps approvals, scheduling, audit linkage, and operator review on one path instead of splitting promotion into a parallel workflow. | Validated |
| Model re-apply-version as a fresh forward promotion from immutable history | Preserves authored-truth semantics and avoids hidden rollback shortcuts that drift from compare/apply behavior. | Validated |
| Target the first public Hex release for after `v0.6.0`, not at `v0.1.0` and not only at `v1.0.0` | `v0.6.0` completed the multi-environment/GitOps story, while `v1.0.0` delivered the stronger GA-level stability promises. | Validated |
| Activate tenancy as `v1.1.0`, not as a silent Phase 25 carryover | Keeps the first post-GA milestone explicit, preserves current phase numbering, and aligns the roadmap with the current JTBD gap analysis. | Validated |
| Activate lifecycle hygiene and ownership as `v1.2.0` ahead of guarded rollout and reusable targeting | Closes the strongest everyday trust/cleanup gap first, fits the sibling-package architecture cleanly, and keeps more complex automation layered on a calmer operator foundation. | Validated |
| Close adopter-truth and proof-posture drift before guarded rollout foundations | Current repo evidence showed public docs and runnable proof had drifted from planning truth; restoring support trust was higher leverage than adding the next differentiated control-plane feature first. | Validated |
| Re-prioritize the next milestone to mounted companion proof reclosure after `v1.3.0` | Repo-local verification still showed the named mounted companion proof bar failing, while reusable audiences were already shipped and guarded rollout remained a better follow-on than an immediate next move. | Validated |
| Activate `v1.4.0` as a bounded proof-reclosure milestone instead of reopening feature direction | The remaining highest-leverage gap was narrow and support-facing: restore mounted companion proof credibility before layering new differentiated capability. | Validated |
| Keep `v1.5.0` as the next candidate after shipping `v1.4.0` | With the mounted companion proof surface repaired, guarded rollout again becomes the strongest differentiated follow-on while reusable targeting stays a later deepening pass. | Validated |
| Activate `v1.5.0` as a bounded guarded-rollout milestone instead of reopening milestone selection | The milestone arc, repo state, and prior research all pointed to guarded rollout as the next highest-leverage differentiator as long as host-owned observability and mounted companion boundaries stayed explicit. | Validated |
| Ship guarded rollout foundations as host-owned, fail-closed, and mounted-workflow bounded | Keeps rollout safety useful without turning Rulestead into an observability product, standalone control plane, or time-based routing engine. | Validated |
| Activate `v1.6.0` as reusable targeting deepening instead of adding a new targeting primitive | Reusable audiences are already shipped; the highest-leverage next work is blast-radius safety, dependency visibility, and explainability for existing audience reuse. | Validated |
| Keep reusable targeting previews authored-state and explicit-sample based | Preserves deterministic evaluation, host-owned identity/observability truth, and honest support claims while still giving operators useful impact evidence. | Validated |
| Activate `v1.7.0` as blast-radius governance after v1.6 reusable targeting deepening | v1.6 made blast radius visible; protected-environment audience edits still need threshold-based change-request routing before auto-advance rollouts or preset ergonomics. | Validated |
| Post-v1.7 assessment: activate `v1.8.0` ROL-04 next; defer IMP-05 and ADM-05 | GOV-01 and quickstart parity shipped in v1.7; largest remaining differentiated gap is guarded rollout auto-advance (hold/rollback already shipped). | Validated |
| Activate `v1.8.0` as guarded rollout auto-advance after v1.7 blast-radius governance | Completes v1.5 hold/rollback story; reuses `ScheduledExecution` and governed `advance_rollout`; fail-closed on weak signals; no observability product widening. | Validated |
| Activate `v1.9.0` as host-supplied preview evidence after v1.8 auto-advance | Core accepts samples but mounted does not wire host evidence; closes last reusable-targeting preview gap without changing GOV thresholds or claiming population counts. | Validated |
| Defer v2.0.0 until a deferred trigger is real; ship v1.10.1 support-truth first | Repo assessment found quickstart `traits:`/`attributes:` mismatch and api_stability drift; post-GA feature band is code-complete (~91–94% done). | Validated |
| Path-to-done = support-truth → integration docs → optional v2 wedges → stop | 2026-05-28 milestone assessment; canonical sequence in path-to-done thread. | Active |

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-ROADMAP.md), [.planning/milestones/v1.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-ROADMAP.md), [.planning/milestones/v1.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-ROADMAP.md), [.planning/milestones/v1.7.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-ROADMAP.md), [.planning/milestones/v1.8.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.8.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-REQUIREMENTS.md), [.planning/milestones/v1.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-REQUIREMENTS.md), [.planning/milestones/v1.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-REQUIREMENTS.md), [.planning/milestones/v1.7.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-REQUIREMENTS.md), [.planning/milestones/v1.8.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.8.0-REQUIREMENTS.md)

## Historical Context

<details>
<summary>Initialization snapshot</summary>

Rulestead closes the gap between FunWithFlags and heavier external platforms such as LaunchDarkly, Unleash, and Flagsmith by delivering multivariate values, ordered rules, deterministic bucketing, first-class explainability, lifecycle hygiene, and an intuitive self-hosted admin plane for Phoenix teams.

Future roadmap candidates identified before and during `v0.1.0` include governance flows, scheduled changes, webhooks, multi-tenant helpers, OpenTelemetry bridging, import/export expansion, and experimentation-focused capabilities.

</details>

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-28 after Phase 73 completion (CTX-01, CTX-02, DOC-01)*
