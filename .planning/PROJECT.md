# Rulestead

## Current State

Rulestead `v0.1.0` is archived as the first polished Hex-release milestone for the sibling-package monorepo:

- `rulestead` ships the evaluator, store/runtime contracts, host-app seams, installer, telemetry surface, and release verification tasks.
- `rulestead_admin` ships the mounted operator UI for lifecycle management, simulation, rollouts, kill switch, and audit workflows.
- The documentation front door, guide set, `CONVENTIONS.md`, `api_stability.md`, and release-engineering workflow set are in place for the `0.1.0` release line.

## Shipped Outcome

The `v0.1.0` milestone delivered:

- Deterministic payload-first flag evaluation with explicit context, explainability, and property-tested bucketing.
- Snapshot-backed runtime reads with resilient refresh, diagnostics, and public telemetry events.
- A full install and host-app integration path for Plug, LiveView, and Oban.
- A mounted admin package that covers authoring, lifecycle hygiene, simulation, rollouts, kill switch, audit history, and redaction/auth seams.
- Release-grade documentation plus the verification trio, gated publish path, and recurring drift automation.

## Known Deferred Items

The milestone was closed with two explicit deferred items:

- Phase 7 still has one verification gap: the sibling-package simulation test helper needs an actor-aware write path so `07-VERIFICATION.md` can move from `gaps_found` to `passed`.
- The live published-artifact proof for `0.1.0` still needs to run after both packages are visible on Hex via `bash scripts/ci/verify_published_release.sh 0.1.0`.

## Next Milestone Goals

The next milestone should start with fresh requirements and roadmap definition, with likely promotion candidates drawn from the already-tracked future scope:

- Governance and operator confidence work such as approvals, scheduled changes, and webhooks.
- Post-release operational follow-through on publish verification and any residual release automation hardening.
- Any newly validated follow-on work discovered during the `0.1.0` release and adoption wave.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator is not fast, pure, deterministic, and explainable, nothing else matters.

## Milestone Archives

- Roadmap archive: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md)
- Requirements archive: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md)

## Historical Context

<details>
<summary>Initialization snapshot</summary>

Rulestead is a batteries-included, Elixir-native feature-flag and experimentation library for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages (`rulestead` core + `rulestead_admin` LiveView UI). It closes the gap between FunWithFlags (boolean-only) and external platforms like LaunchDarkly/Unleash/Flagsmith, delivering multivariate values, ordered rules, deterministic bucketing, first-class explainability, lifecycle hygiene, and an intuitive self-hosted admin plane.

Future roadmap candidates already identified before the `v0.1.0` archive include governance flows, scheduled changes, webhooks, multi-tenant helpers, OpenTelemetry bridging, import/export expansion, and experimentation-focused capabilities.

</details>

---
*Last updated: 2026-04-24 after archiving v0.1.0*
