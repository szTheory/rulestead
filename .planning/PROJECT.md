# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and remote-config platform for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages: `rulestead` for runtime evaluation and `rulestead_admin` for the mounted operator UI. It gives Phoenix teams deterministic evaluation, explicit context, explainability, lifecycle hygiene, and a self-hosted admin plane that stays aligned with host-app auth and deployment workflows.

## Current Milestone: v0.4.0 (Experimentation & Analytics)

**Previous Milestone (v0.3.0) Complete:** Rulestead integrates smoothly into standard CNCF workflows via OpenFeature and introduces tooling to combat feature flag technical debt with automated code reference discovery and stale flag management.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Strategic Arc (Future Milestones)

To provide a clear path forward for Rulestead as a "batteries included" feature-management platform, the following long-term strategic arc outlines our planned evolution:

- **v0.4.0: Experimentation & Analytics**
  - Focus: A/B testing, impression/conversion statistics, and guardrail metrics.
  - Value: Enable product teams to validate hypotheses and measure impact safely.
- **v0.5.0: Advanced Delivery & Distributed Scale**
  - Focus: Redis adapter, streaming deltas, and distributed cache expansion.
  - Value: Support massive-scale distributed deployments requiring external state and real-time invalidation.
- **v0.6.0: Multi-tenant & Enterprise Expansion**
  - Focus: First-class multi-tenant helpers, advanced import/export capabilities, and broader RBAC.
  - Value: Provide comprehensive tooling for complex SaaS environments and massive organizational rollouts.

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

### Active

- Support defining formal A/B test experiments on top of existing flags (EXP-01, EXP-02, EXP-03)
- Ingest and store flag evaluation impressions and conversion events (ANA-01, ANA-02)
- Expose experiment results and guardrail metrics in the Admin UI (ANA-03)

### Out of Scope

- Redis adapter, streaming deltas, and distributed cache expansion — slated for `v0.5.0`.
- Multi-tenant helpers, import/export expansion — slated for `v0.6.0`.
- Publishing or broadening the `rulestead_admin` package beyond the mounted sibling-package design — explicitly disallowed by the current release design.

## Context

- `v0.1.0`, `v0.2.0`, and `v0.3.0` milestones are complete, establishing core runtime, admin UX, governance workflows, ecosystem integration, and lifecycle hygiene.
- The next focus (v0.4.0) will be on Experimentation & Analytics.
- The project remains a linked-version, two-package monorepo.

## Constraints

- **Release design**: Keep the linked-version sibling-package release shape — the runtime and admin packages evolve together.
- **Security**: Maintain default-deny mutation security and strict audit logs.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make `v0.3.0` focused on Ecosystem Integration & Lifecycle Hygiene | Tackling tech debt via code references and providing OpenFeature APIs are major confidence boosters for large-scale enterprise adoption over experimenting/analytics right now. | Validated |

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md)

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
*Last updated: 2026-05-14 after planning milestone v0.3.0*