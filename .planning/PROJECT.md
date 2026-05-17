# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and remote-config platform for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages: `rulestead` for runtime evaluation and `rulestead_admin` for the mounted operator UI. It gives Phoenix teams deterministic evaluation, explicit context, explainability, lifecycle hygiene, and a self-hosted admin plane that stays aligned with host-app auth and deployment workflows.

## Current State

- `v0.5.0` shipped on 2026-05-17 across Phases 19-21.
- Runtime deployments can now use Redis-backed snapshot distribution, PubSub invalidation, and mounted infrastructure diagnostics without breaking the linked-version two-package release model.
- The next planning target is `v0.6.0` for multi-environment sync, GitOps-friendly promotion flows, and explicit tenancy helpers.

## Current Milestone: v0.6.0 (Planning)

**Previous Milestone (v0.5.0) Complete:** Rulestead now supports Redis-backed runtime state, notifier-driven cross-node invalidation, and operator-visible infrastructure health for distributed deployments.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Strategic Arc (Future Milestones)

To provide a clear path forward for Rulestead as a "batteries included" feature-management platform, the following long-term strategic arc outlines our planned evolution toward a stable 1.0 release (detailed further in `.planning/research/EPIC_ARC.md`):

- **v0.6.0: Multi-environment Sync & Tenancy**
  - Focus: Environment promotion (Dev->Staging->Prod), diffing, GitOps export/import, and explicit multi-tenant helpers.
  - Value: Provide comprehensive tooling for complex SaaS environments and organizational rollouts, matching enterprise developer expectations.
- **v1.0.0: General Availability & RBAC**
  - Focus: Role-Based Access Control, API lockdown, security hardening, and complete reference documentation.
  - Value: A reliable, trusted, "done" system without feature creep that fulfills the Elixir-native platform promise.

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

### Active

- Promote rulesets safely across Dev, Staging, and Prod with explicit diffing and approval-friendly workflows.
- Import and export environment state in a GitOps-friendly format that remains reproducible in CI.
- Add explicit tenancy helpers that preserve the current sibling-package release design without turning `rulestead_admin` into a standalone product.

## Next Milestone Goals

- Define environment promotion, drift detection, and comparison workflows for `v0.6.0`.
- Establish import/export seams that fit host-app release engineering and audit expectations.
- Add tenant-aware primitives only where they strengthen the current linked-version platform model.

### Out of Scope

- Role-based access control, API lockdown, and GA hardening — slated for `v1.0.0`.
- Publishing or broadening the `rulestead_admin` package beyond the mounted sibling-package design — explicitly disallowed by the current release design.

## Context

- `v0.1.0` through `v0.5.0` are now archived, covering the core runtime, admin UX, governance workflows, ecosystem seams, experimentation analytics, Redis-backed distribution, and infrastructure diagnostics.
- `v0.5.0` shipped in a single day across 7 completed plans and 24 product/planning files changed in the final milestone execution range.
- The next focus is defining `v0.6.0` requirements and roadmap slices for multi-environment sync and tenancy.
- The project remains a linked-version, two-package monorepo.

## Constraints

- **Release design**: Keep the linked-version sibling-package release shape — the runtime and admin packages evolve together.
- **Security**: Maintain default-deny mutation security and strict audit logs.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make `v0.3.0` focused on Ecosystem Integration & Lifecycle Hygiene | Tackling tech debt via code references and providing OpenFeature APIs are major confidence boosters for large-scale enterprise adoption over experimenting/analytics right now. | Validated |
| Keep infrastructure health node-local by default and accept peer data only through an explicit host seam | Prevents the admin UI from implying undiscovered cluster health while preserving extension points for larger deployments. | Validated |
| Emit additive sync/invalidation telemetry aliases instead of renaming shipped runtime events | Preserves compatibility for existing telemetry consumers while satisfying the new observability contract. | Validated |
| Mount diagnostics inside the existing `rulestead_admin` router macro | Keeps diagnostics inside the current session, policy, and linked-version admin envelope. | Validated |

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md)

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
*Last updated: 2026-05-18 after shipping milestone v0.5.0*
