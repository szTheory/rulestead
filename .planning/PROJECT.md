# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and remote-config platform for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages: `rulestead` for runtime evaluation and `rulestead_admin` for the mounted operator UI. It gives Phoenix teams deterministic evaluation, explicit context, explainability, lifecycle hygiene, and a self-hosted admin plane that stays aligned with host-app auth and deployment workflows.

## Current Milestone: v0.2.0 Governance and Operator Confidence

**Goal:** Add governed change workflows that make production mutations safer without weakening the deterministic runtime or the sibling-package release shape.

**Target features:**
- Change requests and approvals for high-impact admin mutations, with environment-sensitive policy and immutable audit correlation.
- Scheduled changes for ruleset publishes, rollout advances, and kill-switch lifecycle actions, backed by durable execution and operator visibility.
- Webhook surfaces for signed inbound change events and outbound high-impact notifications.
- Operational closeout of the two `v0.1.0` deferred items: the remaining Phase 7 verification gap and live published-release evidence capture when Hex visibility permits it.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Requirements

### Validated

- ✓ Deterministic payload-first evaluation with explicit context, explainability, and property-tested bucketing — `v0.1.0`
- ✓ Snapshot-backed runtime reads with refresh, diagnostics, and public telemetry events — `v0.1.0`
- ✓ Sibling-package release shape with `rulestead` core and mounted `rulestead_admin` UI — `v0.1.0`
- ✓ Installer, Plug/LiveView/Oban seams, and fake-backed test helpers — `v0.1.0`
- ✓ Mounted admin workflows for authoring, simulation, rollouts, kill switch, audit, and redaction/auth seams — `v0.1.0`
- ✓ Release-grade docs, API stability posture, verification trio, and gated publish workflow — `v0.1.0`

### Active

- [ ] Govern production mutations with change requests, approvals, and self-approval guards.
- [ ] Schedule future admin mutations with durable execution, idempotent recovery, and clear operator status.
- [ ] Add signed webhook ingress and outbound notification hooks for high-impact governance events.
- [ ] Close the `v0.1.0` verification and publish-evidence carryover items without destabilizing the shipped release line.

### Out of Scope

- Experiment analytics, impression/conversion statistics, and guardrail metrics — still a later milestone after governance fundamentals land.
- Redis adapter, streaming deltas, and distributed cache expansion — not required to make the current governance milestone safe or shippable.
- Multi-tenant helpers, import/export expansion, and OpenFeature bridge work — acknowledged future scope, but not part of `v0.2.0`.
- Publishing or broadening the `rulestead_admin` package beyond the mounted sibling-package design — explicitly disallowed by the current release design.

## Context

- `v0.1.0` is archived as the first polished Hex-release milestone and already ships the runtime, authoring store, mounted admin UI, installer, docs, and release automation foundation.
- The strongest validated next-step signal in the prompt anchors and archived milestone notes is governance: approvals, scheduled changes, and webhook-connected operator workflows.
- Two closeout items carry forward from `v0.1.0`: the last Phase 7 sibling-package verification gap and the live published-artifact proof for `0.1.0` once Hex visibility allows it.
- The project remains a linked-version, two-package monorepo. Governance work must preserve the current package boundary and must not turn `rulestead_admin` into a separately prepared release target.

## Constraints

- **Release design**: Keep the linked-version sibling-package release shape — the runtime and admin packages evolve together.
- **Phase discipline**: Stay within the `v0.2.0` governance milestone; do not pull experimentation or broader ecosystem work forward.
- **Security**: High-impact admin mutations stay default-deny, redact at the boundary, and preserve immutable audit history.
- **Operator UX**: Every mutation remains preview -> confirm -> audit; governance must clarify operator intent rather than add opaque control flow.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make `v0.2.0` a governance-focused milestone | Archived `v0.1.0` docs, prompt anchors, and deferred scope all point to approvals, scheduling, and webhooks as the next coherent slice | — Pending |
| Carry the two `v0.1.0` deferred items into `v0.2.0` as bounded operational requirements | They are small, explicit debt items and should close alongside the next roadmap rather than linger outside planning | — Pending |
| Keep the runtime contract stable while expanding admin governance | Governance should make changes safer without weakening deterministic evaluation or hot-path behavior | — Pending |
| Preserve the mounted sibling-package admin design | Matches the current shipped architecture and the repo constraints in `AGENTS.md` | ✓ Good |

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md)

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
*Last updated: 2026-04-24 after starting milestone v0.2.0*
