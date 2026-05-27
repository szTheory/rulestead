# Requirements: v1.8.0 - Guarded Rollout Auto-Advance

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions - booleans, variants, and remote config - with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.8.0 Requirements

### Auto-Advance Contract (`ROL`)

- [x] **ROL-04**: Operators can enable opt-in auto-advance on a staged rollout with a configured observation window and explicit authored next-stage plan; advancement occurs only when all guardrails resolve `:healthy` after the window closes.
- [x] **ROL-05**: Auto-advance evaluation preserves v1.5 fail-closed guardrail semantics and never assumes healthy on `:pending_data`, `:held`, stale, weak, or missing host signals.
- [x] **ROL-06**: Protected-environment auto-advance uses the same change-request and approval envelope as manual `advance_rollout` when policy requires governed advancement.
- [x] **ROL-07**: Automatic hold and rollback from v1.5 remain unchanged; auto-advance does not bypass, weaken, or race them.

### Orchestration (`ORC`)

- [x] **ORC-01**: Observation-window close schedules guardrail evaluation and governed `advance_rollout` through the existing `ScheduledExecution` / Oban worker pattern—not a parallel mutation or ad-hoc worker path.
- [x] **ORC-02**: Scheduling and execution are idempotent when a tick races manual advance, rollback, hold, cancellation, or duplicate scheduled ticks.

### Audited Automation (`AUD`)

- [x] **AUD-03**: Successful auto-advance records auditable evidence with guardrail facts, observation window, triggering source `guardrail_automation`, and stage transition context in the existing audit envelope.
- [x] **AUD-04**: Operators can distinguish automatic guardrail-driven advancement from manual rollout actions in audit and timeline surfaces with remediation guidance preserved.

### Mounted Auto-Advance (`ADM`)

- [x] **ADM-04**: Mounted rollout screens expose auto-advance toggle, observation-window and pending-observation state, and bounded copy when prerequisites or guardrail health block automation—without implying Rulestead-owned observability or fleet dashboards.

### Verification And Support Truth (`VER`)

- [x] **VER-01**: Repo-local proof covers healthy auto-advance, fail-closed non-advance, protected-env governance parity, idempotency races, and stale-signal behavior (`mix verify.phase64` or extended guarded-rollout proof scope).
- [x] **VER-02**: Public docs, host-app integration seam subsection, and release-contract checks describe bounded auto-advance scope, observation-window semantics, and host-owned metrics responsibilities.
- [x] **VER-03**: Support truth preserves the linked-version sibling-package model; release-contract allows bounded auto-advance claims only where implemented and keeps forbidden overclaim phrases.

## Future Requirements

### Deferred Beyond v1.8.0

- **IMP-05**: Audience previews can compare richer host-supplied impression summaries or sample cohorts when the host explicitly provides bounded, redacted evidence through an existing seam.
- **ADM-05**: Optional targeting presets can generate concrete draft audiences or rules for common patterns without live inheritance or ongoing propagation.
- **ROL-05** (v1.5 memo): Guardrails can compare rollout health against bounded baselines or cohorts without embedding a bespoke statistics engine.
- **GOV-02-ext**: Host-configurable threshold profiles per environment or tenant beyond the bounded default blast-radius contract.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Auto-advance policy and stage plan | `rulestead` owns authored rollout auto-advance contract and pure evaluation policy | low-frequency semantic | high | high | merge-blocking policy and fail-closed proof | `core` |
| Observation-window orchestration | `rulestead` owns scheduling ticks and governed `advance_rollout` execution | low-frequency semantic | high | high | merge-blocking idempotency and governance proof | `core` |
| Mounted auto-advance UX | `rulestead_admin` owns presentation inside host-mounted policy envelope | native screen | high | medium | mounted toggle, pending state, and timeline proof | `companion` |
| Metrics warehouse, alerting backend, or fleet observability dashboards | no route owner inside current product boundary | defer | high | high | n/a | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Auto-advance authored contract and pure policy in `rulestead` | `core` | In scope |
| Scheduled evaluation ticks and governed advance execution in `rulestead` | `core` | In scope |
| Mounted auto-advance toggle, pending state, and timeline copy in `rulestead_admin` | `companion` | In scope |
| Host-app seam docs, proof commands, release-contract checks | `example/docs-only` | In scope |
| Rulestead-owned metrics ingestion, anomaly detection, time-based gradual rollout, standalone admin | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| Auto-advance policy | deterministic tests for opt-in policy, stage plan, fail-closed non-advance, and preserved hold/rollback | host-app walkthrough with wired guardrail provider |
| Orchestration | scheduled tick, healthy advance, idempotency race, protected-env change-request path | operator walkthrough of pending observation |
| Mounted UX | LiveView tests for toggle, pending state, blocked automation copy, automation timeline distinction | browser smoke on rollout detail |
| Docs and support truth | release-contract checks, extended guarded-rollout proof scope | maintainer spot-check against host seam doc |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Rebuild / Setup Expectation | Rough-Edge Docs Required |
|---------|----------------------------|-------------------------------|-----------------------------|--------------------------|
| Auto-advance policy | Non-healthy guardrails block advance with explicit reasons; no silent skip | Missing stage plan, observation window, or signal provider fails closed | Normal linked-version package update | yes |
| Governed auto-advance execution | Protected-env policy routes through change requests when required | Missing governance wiring surfaces existing setup guidance | Host policy seam unchanged | yes |
| Mounted auto-advance UX | Toggle disabled or pending state shown when prerequisites missing | Missing guardrail wiring renders bounded fallback copy | Mounted admin under linked packages as before | yes |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rulestead-owned metrics ingestion, storage, dashboards, or anomaly detection | Violates host-owned observability boundary |
| Time-based or non-sticky gradual rollout semantics | Breaks deterministic rollout posture from v1.5 |
| Impression-weighted guardrail thresholds or observability-backed blast-radius counts | Pulls product into analytics/observability ownership |
| Draft targeting presets (ADM-05) | Deferred until auto-advance story completes |
| Richer host-supplied audience preview evidence (IMP-05) | Integrator-opt-in; defer to v1.9 or later |
| Standalone `rulestead_admin` control plane | Conflicts with mounted sibling-package design |
| Parallel guardrail worker or mutation path outside `ScheduledExecution` | Would split governed-action envelope |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROL-04 | Phase 61 | Complete |
| ROL-05 | Phase 61 | Complete |
| ROL-07 | Phase 61 | Complete |
| ROL-06 | Phase 62 | Complete |
| ORC-01 | Phase 62 | Complete |
| ORC-02 | Phase 62 | Complete |
| AUD-03 | Phase 62 | Complete |
| ADM-04 | Phase 63 | Complete |
| AUD-04 | Phase 63 | Complete |
| VER-01 | Phase 64 | Complete |
| VER-02 | Phase 64 | Complete |
| VER-03 | Phase 64 | Complete |

**Coverage:**

- v1.8.0 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after Phase 64 completion*
