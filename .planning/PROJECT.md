# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and remote-config platform for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages: `rulestead` for runtime evaluation and `rulestead_admin` for the mounted operator UI. It gives Phoenix teams deterministic evaluation, explicit context, explainability, lifecycle hygiene, and a self-hosted admin plane that stays aligned with host-app auth and deployment workflows.

## Current State

- `v1.0.0` shipped on 2026-05-21 across Phases 26-28.
- The product now has a frozen public API boundary, canonical mounted-admin RBAC, and a proven Compose-backed end-to-end demo with Phoenix + Next.js/OpenFeature integration.
- `v1.1.0` has completed Phase 29 on 2026-05-21, delivering the bounded tenancy seam, tenant-aware reviewed-artifact validation, and mounted-admin tenant scope without widening the product shape.

## Current Milestone: v1.1.0 Tenancy Helpers & Validation

**Goal:** Finish the smallest coherent tenancy-aware seam so runtime, admin, promotion, and manifest workflows can carry explicit tenant scope safely in real SaaS environments.

**Target features:**
- Minimal `Rulestead.Tenancy` seam with a safe `SingleTenant` default and additive tenant-aware bucketing hooks.
- Tenant-aware preview/apply validation for import and promotion, with bounded tenant scope metadata in saved plans and audit trails.
- Minimum mounted-admin tenant scope handling that stays explicit, fail-closed, and aligned with the linked-version two-package model.

**Why now:** Post-GA adoption pressure is most likely to come from multi-tenant SaaS teams. Tenancy is the highest-value immediate JTBD gap that fits the current architecture and can be finished without drifting into a standalone control plane or tenant-partitioned topology.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Strategic Arc (Future Milestones)

To provide a clear path forward for Rulestead as a "batteries included" feature-management platform, the following strategic arc captures the shipped path to GA and the open post-GA slot (detailed further in `.planning/research/EPIC_ARC.md`):

- **v0.6.0: Multi-environment Sync & Tenancy**
  - Focus: Environment promotion (Dev->Staging->Prod), diffing, GitOps export/import, and explicit multi-tenant helpers.
  - Value: Provide comprehensive tooling for complex SaaS environments and organizational rollouts, matching enterprise developer expectations.
- **v1.0.0: General Availability & RBAC**
  - Focus: Role-Based Access Control, API lockdown, security hardening, and complete reference documentation.
  - Value: A reliable, trusted, "done" system without feature creep that fulfills the Elixir-native platform promise.
- **Post-GA milestone: TBD**
  - Focus: Define the first post-GA roadmap deliberately instead of inheriting pre-GA assumptions wholesale.
  - Value: Avoid accidental scope carryover after the GA boundary.

## Release Posture

- First public Hex release planning was intentionally delayed until the platform had credible multi-environment and governance depth.
- Public distribution shape: publish both sibling packages together on Hex, with `rulestead_admin` documented as the mounted admin companion rather than a standalone control-plane product.
- General Availability shipped in `v1.0.0` on 2026-05-21.

## Requirements

### Validated

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

### Active

No active milestone requirements. `v1.1.0` is ready for milestone closeout and next-milestone definition.

## Next Milestone Goals

- Restore the old Phase 25 tenancy carryover as an explicit post-GA milestone with fresh numbering, not as an inherited pre-GA leftover.
- Keep the phase boundary tight around helper seams, validation, audit metadata, and minimum mounted-admin scope handling.
- Preserve the sibling-package release model and avoid tenant-partitioned storage or standalone admin drift.

### Out of Scope

- Broadening `rulestead_admin` beyond the mounted sibling-package design into a standalone control-plane product — explicitly disallowed by the current release design.

## Context

- `v0.1.0` through `v1.0.0` are now archived, covering the core runtime, admin UX, governance workflows, ecosystem seams, experimentation analytics, Redis-backed distribution, environment promotion, GitOps manifests, API lockdown, RBAC, and the GA demo stack.
- `v1.0.0` shipped across Phases 26-28, delivering the public API freeze, canonical RBAC, and the verified GA demo environment.
- The current focus is `v1.1.0`, which intentionally activates tenancy as the first post-GA milestone after reviewing the new JTBD gap map and confirming it is still the highest-value near-term fit.
- Phase 29 is now complete and verified. The tenancy work stayed inside helper seams, reviewed-artifact validation, bounded metadata, and mounted-admin scope.
- The project remains a linked-version, two-package monorepo.

## Constraints

- **Release design**: Keep the linked-version sibling-package release shape — the runtime and admin packages evolve together.
- **Security**: Maintain default-deny mutation security and strict audit logs.
- **Tenancy scope**: Ship explicit tenant-aware helpers and validation only; do not introduce tenant-partitioned authored storage, environment-per-tenant topology, or implicit all-tenant mutation behavior.

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

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md)

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
*Last updated: 2026-05-21 after Phase 29 execution*
