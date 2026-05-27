# Phase 51: Mounted Guardrail Workflow - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Surface guardrail health, thresholds, freshness, and automatic intervention reasons inside the existing mounted rollout experience. Phase 51 is a `rulestead_admin` mounted-workflow presentation phase over the Phase 49/50 core guardrail contract; it must not create a standalone guardrail dashboard, metrics provider UI, fleet observability surface, or new decision engine.

</domain>

<decisions>
## Implementation Decisions

### Status source and package boundary
- **D-01:** Phase 51 must read guardrail health from the core-owned `Rulestead.fetch_guardrail_status/3` read path, scoped by the mounted environment and current rollout rule.
- **D-02:** `rulestead_admin` must not recompute guardrail decisions, query `guardrail_decisions` storage directly, or infer health from authored rollout configuration.
- **D-03:** Status reads should treat a not-found or unavailable guardrail decision as explicit missing prerequisite copy, never as healthy state.

### Mounted workflow scope
- **D-04:** Guardrail health belongs on the existing per-flag rollout workflow, primarily `RulesteadAdmin.Live.FlagLive.Rollouts`, with bounded supporting copy/components in existing rollout and audit component modules.
- **D-05:** Timeline distinction should stay inside existing per-flag timeline surfaces and, if useful, a small rollout-page excerpt. Phase 51 should not add a new `/guardrails` dashboard or broaden global audit filters unless the planner finds it strictly necessary for `ADM-01`.
- **D-06:** The mounted UI remains a companion explanation surface. It consumes core operational truth and must not imply standalone-admin support or Rulestead-owned observability data.

### Display semantics
- **D-07:** The rollout screen should show authored guardrail definitions alongside latest operational status: signal identity, threshold operator/value, freshness window, minimum sample size, decision state, decision reason, and bounded normalized evidence.
- **D-08:** Missing, stale, insufficient-sample, provider-missing, unsupported-signal, and unsupported-scope outcomes should render as fail-closed or pending prerequisite explanations, not empty panels or reassuring "no issues" language.
- **D-09:** Raw provider payloads and provider-specific dashboards are out of scope. Display copy must use the normalized guardrail metadata and decision payloads produced by core.

### Preservation and timeline distinction
- **D-10:** Percentage edits from the rollout page must preserve authored `rollout.guardrails`; Phase 51 should add a regression test because current `serialize_rollout/1` omits guardrails while core rollout serialization preserves them.
- **D-11:** Automatic guardrail events such as `rollout.guardrail_held`, `rollout.guardrail_rollback`, and `rollout.guardrail_evaluated` should be labeled distinctly from manual publish, rollout, and audit rollback actions.
- **D-12:** Timeline wording should make system provenance clear with bounded copy such as automatic hold, automatic rollback, evaluated, source, and remediation reason, while continuing to redact raw metadata behind existing audit components.

### the agent's Discretion
- Exact component boundaries between `RolloutComponents`, `AuditComponents`, and LiveView helper functions.
- Exact visual treatment and copy, provided status/missing-data semantics remain explicit and compact.
- Whether the rollout page shows a short timeline excerpt or only links to the per-flag timeline, provided operators can distinguish manual actions from automatic interventions in the existing workflow.
- Exact test fixture helpers for seeded guardrail decisions and audit rows.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` - Phase 51 goal, dependency, and success criteria.
- `.planning/REQUIREMENTS.md` - `ADM-01`, support truth gate, proof posture gate, and guarded rollout out-of-scope list.
- `.planning/PROJECT.md` - v1.5.0 milestone framing, host-owned observability boundary, and linked-version sibling-package posture.
- `.planning/STATE.md` - Phase 49/50 completion state and Phase 51 readiness.

### Prior locked decisions
- `.planning/phases/49-guardrail-signal-contract/49-CONTEXT.md` - Host-owned signal seam, authored guardrail definitions, normalized fail-closed reasons, explicit scope, and no observability-product expansion.
- `.planning/phases/50-guarded-decision-engine-audit/50-CONTEXT.md` - Core-owned decision states, durable operational truth, governed/audited automatic interventions, and the rule that LiveView does not own decision truth.
- `.planning/phases/51-mounted-guardrail-workflow/51-RESEARCH.md` - Phase 51 implementation research, code paths, pitfalls, and verification recommendations.
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` - Existing rollout workflow, sticky exposure, audit, and operator semantics.
- `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` - Support-truth and mounted companion discipline.
- `.planning/phases/46-mounted-proof-bar-restoration/46-CONTEXT.md` - Mounted companion proof posture and bounded admin surface.

### Prompt anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` - Mounted admin information architecture and calm operator workflow principles.
- `prompts/rulestead-telemetry-observability-and-audit.md` - Audit versus telemetry separation, redaction, and bounded evidence expectations.
- `prompts/rulestead-security-privacy-and-threat-model.md` - Fail-closed and host-owned trust boundaries.
- `prompts/rulestead-host-app-integration-seam.md` - Host-owned integration seam posture.
- `prompts/rulestead-domain-language-field-guide.md` - Canonical rollout, guardrail, hold, rollback, and operator vocabulary.

### Existing code and contracts
- `rulestead/lib/rulestead.ex` - `fetch_guardrail_status/3`, `list_audit_events/1`, and admin read boundary.
- `rulestead/lib/rulestead/store/command.ex` - `FetchGuardrailStatus`, `ListAuditEvents`, and normalized guardrail metadata helpers.
- `rulestead/lib/rulestead/guardrail_decision.ex` - Durable decision fields, decision states, action types, monitoring timestamps, evidence, and serialization.
- `rulestead/lib/rulestead/ruleset/guardrail.ex` - Authored guardrail definition fields.
- `rulestead/lib/rulestead/ruleset/rollout.ex` - Rollout embed shape, including `guardrails`.
- `rulestead/lib/rulestead/store/ecto.ex` - Ecto-backed status payloads and automatic guardrail audit event types.
- `rulestead/lib/rulestead/fake.ex` - Fake-backed status payloads, audit events, and admin test support.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` - Primary mounted rollout workflow and current serialization gap.
- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` - Existing rollout component patterns.
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` - Existing audit row and raw-detail disclosure patterns.
- `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` - Per-flag timeline titles, summaries, redaction, and rollback behavior.
- `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` - Existing rollout LiveView coverage and place for guardrail status/preservation tests.
- `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` - Existing per-flag timeline coverage and place for automatic guardrail event wording tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.fetch_guardrail_status/3` is the package-boundary-safe read API for latest guardrail status by flag, environment, rule key, and optional stage.
- `Rulestead.list_audit_events/1` already backs mounted audit timelines and can supply automatic guardrail events without a new admin product surface.
- `Rulestead.GuardrailDecision.serialize/1` exposes the latest decision state, action type, reason, monitoring window, normalized evidence, snapshots, and correlation id.
- `Rulestead.Store.Command.GovernanceSupport.normalize_guardrail_metadata/1` gives mounted UI a bounded evidence vocabulary.
- `RulesteadAdmin.Components.RolloutComponents` and `AuditComponents` already use Phoenix function components suitable for compact status and timeline displays.
- `Rulestead.Fake` already supports guardrail status reads and audit rows, making it the right primary test adapter for Phase 51 mounted tests.

### Established Patterns
- Mounted admin reads and explains core semantics; it does not duplicate core decision logic.
- The repo favors explicit missing-prerequisite and fail-closed copy over silent empty states or inferred success.
- Audit rows stay append-only, redacted, and readable first, with raw detail behind disclosure.
- Rollout edits are intentionally narrow: percentage can change on the rollout page, while variant composition and broader ruleset editing stay elsewhere.
- Linked sibling-package design means `rulestead_admin` can consume new core APIs but should not prepare a standalone package or release shape.

### Integration Points
- Extend `FlagLive.Rollouts.load_page/3` to load guardrail status for the current rollout rule via `Rulestead.fetch_guardrail_status/3`.
- Add or extend rollout components to render authored guardrail definitions, latest decision state, normalized evidence, and missing-data fallback copy.
- Extend rollout serialization helpers so draft/publish percentage edits carry `rollout.guardrails` forward.
- Extend `FlagLive.Timeline` and/or `AuditComponents` to title and summarize guardrail automation events distinctly from manual actions.
- Extend `rollouts_test.exs` and `timeline_test.exs` with Fake-backed guardrail decisions and audit rows.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 51 as an explanation layer over already-recorded operational truth.
- The operator-facing rule remains: bad data pauses; proven regression rolls back; missing status is never healthy by default.
- Preferred implementation shape: one read-only status panel in the rollout page, compact guardrail definition/status rows, explicit fallback copy for no decision yet, and per-flag timeline wording for automatic hold/rollback/evaluation.
- The highest-risk regression is silent loss of authored `rollout.guardrails` during percentage saves.

</specifics>

<deferred>
## Deferred Ideas

- Rulestead-owned metrics ingestion, storage, dashboards, anomaly detection, or provider adapters.
- Automatic stage advancement based on healthy guardrails.
- Fleet-wide observability or standalone guardrail admin screens.
- Provider-specific charting, baselines, cohorts, or statistics engines.
- Global audit filter expansion unless a later phase explicitly needs it.

</deferred>

---

*Phase: 51-mounted-guardrail-workflow*
*Context gathered: 2026-05-27*
