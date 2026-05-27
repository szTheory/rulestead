# Phase 50: Guarded Decision Engine & Audit - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Research mode:** recommendation-first synthesis with parallel advisor passes across data-quality semantics, breach policy, automation provenance, and authored-vs-operational state boundaries

<domain>
## Phase Boundary

Evaluate guarded rollout monitoring windows against the Phase 49 normalized signal contract and trigger deterministic hold or rollback behavior through the existing governed mutation and audit envelope.

This phase decides:
- how normalized guardrail facts become rollout decision states
- when weak, stale, or missing evidence blocks automation
- when a confirmed breach restores a prior stable stage
- how automatic decisions are recorded so operators can distinguish them from manual actions

This phase does **not**:
- widen Rulestead into an observability product
- introduce auto-advance or time-based routing
- push guardrail action state into authored rollout config
- turn mounted admin into a fleet dashboard

</domain>

<decisions>
## Implementation Decisions

### Decision-state semantics
- **D-01:** Phase 50 should use a small explicit decision vocabulary centered on `healthy`, `pending_data`, `held`, and `rollback_triggered`.
- **D-02:** `pending_data` means automation cannot yet prove either healthy or breached from valid evidence. It is a real intermediate decision state, not a soft synonym for healthy.
- **D-03:** Recoverable evidence gaps such as stale data or insufficient sample may remain `pending_data` during the active monitoring window, but they must never advance the rollout.
- **D-04:** Hard seam faults such as missing provider support, unsupported signal, or unsupported scope should fail closed into sticky hold behavior rather than lingering as ambiguous “still pending” status.
- **D-05:** Phase 50 should classify weak facts into two buckets:
  - recoverable evidence gaps: primarily `stale` and `insufficient_sample`
  - terminal seam faults: `provider_missing`, `unsupported_signal`, `unsupported_scope`, and equivalent invalid-provider cases
- **D-06:** At the monitoring-window boundary, unresolved recoverable gaps should degrade from `pending_data` into sticky `held` rather than being treated as healthy by timeout.

### Hold vs rollback policy
- **D-07:** Only an explicit confirmed threshold breach is eligible to trigger automatic rollback.
- **D-08:** Fail-closed reasons such as stale, weak-sample, or unsupported-provider facts should produce `held`, never automatic rollback.
- **D-09:** Automatic rollback should restore the last stable stage snapshot only when one exists for the same rollout rule identity and explicit scope.
- **D-10:** “Last stable stage snapshot” means the most recent stage state that completed its own monitoring window in `healthy` state for the same flag, environment, tenant semantics, rollout rule identity, salt, and variant composition.
- **D-11:** If no stable predecessor snapshot exists, even a confirmed breach should degrade to `held` rather than guessing at a rollback target.
- **D-12:** The rollback target must be the recorded stable snapshot, not simply the previous ladder percentage, not reconstructed audit inversion, and not recomputed “latest good” state at execution time.
- **D-13:** Rollback behavior should preserve sticky rollout semantics by restoring prior authored stage exposure, not by introducing time-based, non-sticky, or reshuffled routing.

### Governance and audit provenance
- **D-14:** Automatic hold and rollback must remain inside the existing governed mutation and audit envelope rather than taking a parallel automation path.
- **D-15:** Phase 50 should record the automation decision itself as a first-class bounded operational record linked to the resulting governed mutation and audit rows, rather than relying on one audit row alone to carry all provenance.
- **D-16:** The actual state-changing action should still execute through the same command-first mutation spine used elsewhere in `rulestead`.
- **D-17:** Automatic interventions must be visibly system-originated, using bounded provenance such as `actor_type=system`, `source=guardrail_automation`, shared correlation ids, and normalized guardrail evidence.
- **D-18:** Audit and timeline surfaces must make manual and automatic actions distinguishable without inventing a second audit vocabulary or implying a new standalone control plane.
- **D-19:** Guardrail evidence stored durably must remain normalized and bounded: breached signal identity, threshold semantics, observed value, freshness/sample facts, explicit scope, stable-target reference when relevant, and remediation linkage. Raw metrics payloads are out of bounds.
- **D-20:** Automatic rollback should not reuse `audit.rollback` semantics. It should follow the repo’s broader “fresh forward mutation from exact prior stable truth” posture.
- **D-21:** Hold should be sticky and explicit. Whether it is implemented as a dedicated governed rollout-hold mutation or as an equivalent bounded action record, downstream agents must preserve the invariant that advancement remains blocked until a manual governed remediation clears it.

### Authored state vs operational truth
- **D-22:** Phase 50 decision state must remain outside authored rollout configuration.
- **D-23:** Authored rollout state should continue to hold guardrail definitions and stage intent only; it must not accumulate mutable Phase 50 action state such as `held`, `rollback_triggered`, or monitoring-window progress.
- **D-24:** Current guardrail health, pending/held/rollback decisions, monitoring-window progress, and evidence snapshots should be treated as operational truth derived from append-only decision/audit/stage history.
- **D-25:** If Phase 50 needs faster “current status” reads for mounted surfaces later, it may add a separate non-authored read model or status projection, but that projection must remain downstream of the append-only operational history and must not become compare/apply/export truth.
- **D-26:** Compare, promotion, export, and other authored-state workflows must remain free of mutable Phase 50 runtime/action state, consistent with the existing compare contract.

### Architecture and implementation posture
- **D-27:** The core decision logic should live in a dedicated reducer-style domain module that folds normalized guardrail facts and monitoring-window inputs into explicit decision outcomes. LiveView must not own decision truth.
- **D-28:** Mutations that persist a guardrail decision, apply a hold or rollback, and write audit evidence should run transactionally via `Ecto.Multi` where the resulting state change is authoritative.
- **D-29:** Any background triggering or retries should be bounded helpers only. They may support execution, but they must not become the primary source of truth for guardrail decisions.
- **D-30:** Downstream planning should optimize for least surprise to operators:
  - bad or missing data pauses
  - proven regression restores the last known-good stage
  - every automatic action is explicit, bounded, and replayable

### the agent's Discretion
- Exact module and schema names for the decision reducer, stable-stage snapshot record, and automation-decision persistence, provided the authored/operational boundary stays intact.
- Exact naming of automatic audit/timeline events, provided manual vs automatic actions remain clearly distinguishable and correlation-linked.
- Exact implementation shape of any disposable read model, provided it remains derivative of append-only operational history and not a second source of authored truth.
- Exact operator copy for `pending_data`, `held`, and rollback explanations, provided it preserves the distinction between weak evidence and confirmed breach.

</decisions>

<specifics>
## Specific Ideas

- The calm operator rule for this phase should be easy to memorize: bad data pauses; proven regression restores the last known-good stage.
- Use the repo’s existing authored/runtime split as the primary design guardrail:
  - authored rollout config defines what should happen
  - operational history shows what did happen
  - audit proves who or what caused it
- Learn from the broader ecosystem without copying hosted-product sprawl:
  - LaunchDarkly’s monitoring-window and explicit rollback posture are useful
  - GrowthBook’s local-eval plus host-owned metrics posture is useful
  - Unleash’s sticky gradual-rollout discipline is useful
  - Flipper’s warning about non-sticky time-based rollout is directly aligned with Rulestead’s constraints
- Avoid the common footguns:
  - treating weak or missing evidence as healthy
  - rolling back on seam failure instead of pausing
  - using “previous rung” as a fake rollback target when it was never proven stable
  - masquerading automation as a human actor
  - storing raw metrics payloads as durable truth
  - leaking mutable decision state into authored compare/apply/export surfaces

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 50 goal, success criteria, and milestone split
- `.planning/REQUIREMENTS.md` — `ROL-02`, `ROL-03`, `AUD-01`, and `AUD-02`
- `.planning/PROJECT.md` — milestone framing, host-owned observability boundary, and mounted companion posture
- `.planning/STATE.md` — active milestone status

### Prior locked decisions
- `.planning/phases/49-guardrail-signal-contract/49-CONTEXT.md` — normalized guardrail contract, fail-closed vocabulary, explicit scope, and authored-state expectations
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — re-apply/rollback posture, exact reviewed artifact discipline, and authored-vs-runtime separation
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — rollout explicitness, sticky exposure posture, append-only audit semantics, and operator calm UX
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` — explicit tenant/environment scope posture
- `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` — support-truth discipline

### Prompt anchors
- `prompts/rulestead-host-app-integration-seam.md` — host-owned seam and optional bounded worker posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — append-only audit, telemetry vs audit distinction, correlation ids, and transactional audit writes
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed posture, immutable audit, and host-owned auth boundary
- `prompts/rulestead-admin-ux-and-operator-ia.md` — rollout/operator workflow posture and calm mounted-admin IA
- `prompts/rulestead-domain-language-field-guide.md` — canonical rollout, hold, rollback, and operator vocabulary
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — command-first mutation spine, `Ecto.Multi` discipline, and recommendation-first architecture defaults
- `prompts/elixir_feature_flags_research_brief.md` — feature-flag ecosystem lessons, stickiness, explainability, and rollout footguns
- `prompts/rulestead-testing-and-e2e-strategy.md` — rollout/hold/rollback verification expectations

### Existing code and contracts
- `rulestead/lib/rulestead/guardrails.ex` — provider seam and host-owned signal fetch boundary
- `rulestead/lib/rulestead/guardrails/query.ex` — explicit signal query semantics and scope
- `rulestead/lib/rulestead/guardrails/signal_fact.ex` — normalized fact statuses and reasons
- `rulestead/lib/rulestead/ruleset/guardrail.ex` — authored guardrail definition shape
- `rulestead/lib/rulestead/ruleset/rollout.ex` — authored rollout embed shape
- `rulestead/lib/rulestead/store/command.ex` — normalized governance and guardrail metadata helpers
- `rulestead/lib/rulestead/audit_event.ex` — append-only audit metadata normalization, including guardrail evidence
- `rulestead/lib/rulestead/governance/change_request.ex` — governed mutation vocabulary
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — durable execution vocabulary and boundaries
- `rulestead/lib/rulestead/store/ecto.ex` — transactional mutation spine and existing governed execution path
- `rulestead/lib/rulestead/fake.ex` — fake-adapter execution path and audit semantics
- `rulestead/lib/rulestead/promotion/compare.ex` — authored-state projection discipline
- `rulestead/test/rulestead/guardrails/contract_test.exs` — bounded fact normalization contract
- `rulestead/test/rulestead/store/compare_contract_test.exs` — explicit rejection of Phase 50 action-state leakage into compare/authored projections
- `rulestead/test/rulestead/scheduled_execution_conflict_test.exs` — bounded failure-reason and execution-conflict posture
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` — current rollout UI boundary that Phase 50 should not let own decision truth
- `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex` — current mounted audit/timeline surface

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Guardrails.SignalFact` already gives Phase 50 a bounded normalized fact contract with explicit `status` and `reason` atoms.
- `Rulestead.Store.Command.GovernanceSupport.normalize_guardrail_metadata/1` already gives the phase a safe bounded evidence shape for durable metadata.
- `Rulestead.AuditEvent.metadata/1` already accepts normalized guardrail evidence and correlation/governance metadata, making it the natural durable truth channel for automatic interventions.
- The existing governed mutation and scheduling contracts already provide actor, correlation, execution-stage, and replay/idempotency patterns that Phase 50 should reuse rather than replace.
- The compare contract already enforces the authored-state boundary that this phase must preserve.

### Established Patterns
- The repo prefers authored desired state plus derived operational truth, not mixed mutable config.
- The repo prefers exact reviewed or recorded artifacts over recomputing “latest truth” at execution time.
- The repo prefers append-only audit and explicit provenance over magical automation.
- The repo prefers fail-closed behavior when prerequisites or upstream truth are weak or missing.
- Mounted admin consumes and explains core semantics; it does not invent a second workflow model.

### Integration Points
- Phase 50 should add a core decision reducer on top of the Phase 49 normalized signal contract.
- Automatic hold and rollback should plug into the existing command/store/audit envelope rather than a UI-specific or scheduler-specific path.
- Stable rollback should integrate with the repo’s existing exact-artifact posture by referencing a recorded stable stage snapshot, not ad hoc inverse reconstruction.
- Future mounted rollout-status work in Phase 51 should consume the explicit operational history and any derived read model from this phase rather than querying authored rollout config for mutable health.

</code_context>

<deferred>
## Deferred Ideas

- Automatic stage advancement based on healthy guardrails
- Vendor-style statistical engines or broad experiment-analysis surfaces
- Rulestead-owned metrics ingestion, storage, or dashboards
- Reusing `scheduled_executions` as the primary semantic model for reactive guardrail automation
- Polluting authored rollout config with mutable monitoring or intervention state

</deferred>

---

*Phase: 50-guarded-decision-engine-audit*
*Context gathered: 2026-05-26*
