# Phase 63: Mounted Auto-Advance Workflows - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Mounted admin (`rulestead_admin`) exposes auto-advance configuration, pending-observation state, and automation-vs-manual distinction on existing rollout surfaces — without observability dashboards, fleet claims, or core orchestration changes.

**In scope:** Auto-advance panel on `FlagLive.Rollouts`, policy form (toggle + authored plan), pending-observation UI composed from guardrail window + scheduled tick, prerequisite/health remediation copy, timeline/intervention automation labeling for `rollout.advance` with `guardrail_automation` source, LiveView + integration tests for ADM-04 and AUD-04.

**Out of scope:** Core policy contract changes (Phase 61), tick scheduling/execute orchestration (Phase 62), `mix verify.phase64` / release-contract / host seam docs (Phase 64), new LiveView routes, fleet dashboards, metrics surfaces, auto-approval in protected environments, changes to hold/rollback decision paths.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Surface placement: extend rollouts page, no new route
- **D-01:** Add an **Auto-advance** section on the existing `FlagLive.Rollouts` page, positioned between `RolloutComponents.guardrail_status/1` and the guardrail interventions excerpt.
- **Do not** add a new LiveView route, standalone admin screen, or global `/admin/rollouts` auto-advance dashboard.

### D-02 — Policy editing: inline authored form, direct save
- **D-02:** Inline form on the rollouts page with fields: `enabled` toggle, `observation_window_seconds`, `next_stage`, `next_percentage`.
- Save via `Rulestead.upsert_rollout_auto_advance_policy/4` on form submit — **not** the ruleset preview→confirm→publish chain.
- Ladder `[5, 25, 50, 100]` remains advisory UI only; policy `next_stage` / `next_percentage` are operator-authored (Phase 61 D-01).
- Require `:advance_rollout` capability (or admin) to save; policy denied → `OperatorComponents.capability_explanation/1`.

### D-03 — Prerequisites gate: disable with bounded remediation, never imply healthy
- **D-03:** Derive `@auto_advance_mode` on page load:
  - `:unavailable` — no guardrail definitions on rollout rule → panel explains wiring guardrails first; toggle disabled
  - `:blocked_health` — guardrail status `:held`, `:pending_data`, or `:rollback_triggered` → reuse fail-closed guardrail copy; do **not** imply automation will advance
  - `:config_incomplete` — save blocked until window + next stage + percentage are authored when enabling
  - `:ready` — policy enabled, prerequisites met, window not yet closed or no pending tick
  - `:pending_observation` — policy enabled, monitoring window open (`window_ends_at` in future)
  - `:scheduled` — pending auto-advance scheduled execution exists for this flag/env/rule
- Never show fleet-health language or Rulestead-owned metrics; remediation stays bounded to this rollout stage.

### D-04 — Pending observation state: compose guardrail window + scheduled tick
- **D-04:** Pending UI composes:
  1. `guardrail_status` window bounds (`window_started_at`, `window_ends_at`) from existing `fetch_guardrail_status`
  2. `Rulestead.list_scheduled_executions/1` filtered to: `resource_key` = flag, `environment_key` = env, `action: :advance_rollout`, `state: "scheduled"`, `metadata.source == "guardrail_automation"`, matching current rollout `rule_key` in command snapshot
- Calm operator copy examples:
  - Window open: *"Observation window open until {time}. Auto-advance evaluates at window close."*
  - Tick scheduled: *"Advance scheduled for {scheduled_for} if guardrails remain healthy."*
- If manual advance superseded tick (Phase 62 idempotency), refresh on `load_page` — do not show stale scheduled state.

### D-05 — Protected environment callout: set expectations, allow policy save
- **D-05:** When environment is protected and `Authorizer.change_request_required?(:advance_rollout)`, show informational callout on auto-advance panel:
  - *"When eligible, advancement submits a change request for approval — it will not auto-apply in this environment."*
- Policy may still be saved/enabled; execution routing is Phase 62's submit-at-tick behavior (no auto-approve).
- Optionally show approval count / self-approval posture using existing `ApprovalRequirement` seams (planner discretion).

### D-06 — Timeline distinction (AUD-04): extend automation labeling to `rollout.advance`
- **D-06:** Extend `guardrail_automation_event?/1` in `rollouts.ex` and `timeline.ex`:
  - Existing automatic events: `rollout.guardrail_held`, `rollout.guardrail_rollback`, `rollout.guardrail_evaluated`
  - **Add:** `rollout.advance` when `metadata["source"] == "guardrail_automation"` (or atom `:guardrail_automation`)
- Titles and summaries:
  - Automatic: **"Automatic rollout advance"** with observation window bounds + next stage from audit metadata
  - Manual: retain existing **"Manual rollout action"** label in `AuditComponents.timeline_row`
- Extend redaction allow-list for: `auto_advance.*`, `observation_window_started_at`, `observation_window_ends_at`, `observation_window_seconds`, `links.scheduled_execution_id`, `links.change_request_id`
- Include auto-advance `rollout.advance` events in rollouts page intervention excerpt filter.

### D-07 — Component shape and four-plan execution
- **D-07:** Add `RolloutComponents.auto_advance_panel/1` (sibling to `guardrail_status/1`), following Phase 59 `GovernanceComponents.blast_radius_panel/1` extraction pattern.
- Four plans (mirror Phases 59/61/62):
  - **63-01** — Panel component + load assigns (policy fetch, scheduled tick, `@auto_advance_mode` derivation)
  - **63-02** — Policy form events + capability/prerequisite gates (ADM-04)
  - **63-03** — Timeline/intervention automation labeling + redaction (AUD-04)
  - **63-04** — LiveView contract tests: toggle save, pending state, blocked prerequisites, automation vs manual excerpts

### Claude's Discretion
- Exact panel markup/CSS (`rs-card`, `OperatorComponents.banner` tone variants)
- Whether protected below-threshold env shows subtle "direct advance when eligible" note vs CR-only callout
- Collapsible scheduled-tick detail vs always-visible pending strip
- Optional approval-requirement display on protected-env callout

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/REQUIREMENTS.md` — ADM-04, AUD-04 acceptance criteria and mounted UX rubric
- `.planning/ROADMAP.md` — Phase 63 goal, success criteria, phase boundary vs 64
- `.planning/STATE.md` — v1.8.0 mounted-workflows next action

### Prior phases (contracts this phase presents)
- `.planning/phases/61-auto-advance-authored-contract/61-CONTEXT.md` — policy persistence, authored next-stage plan, ladder advisory-only
- `.planning/phases/62-orchestration-and-governed-execution/62-CONTEXT.md` — scheduled tick, `guardrail_automation` audit, protected-env CR routing
- `.planning/milestones/v1.7.0-phases/59-mounted-governance-workflows/59-CONTEXT.md` — mounted pattern: reuse routes, extracted panel component, calm operator copy, capability_explanation

### Product and UX anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — preview→confirm→audit for ruleset mutations; mounted posture; AI/governance suggestive not autopilot
- `prompts/rulestead-domain-language-field-guide.md` — rollout, guardrail, observation window vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned Policy, fail-closed, redaction
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit correlation, no PII in meta

### Core store and orchestration (read-only for admin)
- `rulestead/lib/rulestead.ex` — `upsert_rollout_auto_advance_policy/4`, `fetch_rollout_auto_advance_policy/3`, `list_scheduled_executions/1`
- `rulestead/lib/rulestead/governance/rollout_auto_advance/schedule.ex` — tick metadata shape (`source`, `automation_phase`)
- `rulestead/lib/rulestead/governance/rollout_auto_advance.ex` — `automation_tick?/1`, `automation_audit_metadata/1`
- `rulestead/lib/rulestead/admin/authorizer.ex` — `change_request_required?` for protected environments

### Admin integration points
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` — primary mount point for panel + form events
- `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` — full timeline automation labeling
- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` — `guardrail_status/1` pattern to extend
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` — `timeline_row/1` Automatic vs Manual labels
- `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` — existing guardrail intervention test patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.fetch_rollout_auto_advance_policy/3` + `upsert_rollout_auto_advance_policy/4` — policy CRUD for form load/save
- `Rulestead.list_scheduled_executions/1` — pending auto-advance tick lookup
- `Rulestead.fetch_guardrail_status/3` — window bounds + health state for pending observation
- `RolloutComponents.guardrail_status/1` — fail-closed prerequisite copy and window display
- `AuditComponents.timeline_row/1` — `automatic?` + `source_label` rendering (Automatic vs Manual rollout action)
- `OperatorComponents.capability_explanation/1` — policy-denied actions
- `Rulestead.Admin.Redaction.redact_metadata/2` — extend allow-list for auto-advance audit keys

### Established Patterns
- Rollouts page loads guardrail status + 5-row intervention excerpt from `list_audit_events`
- `guardrail_automation_event?/1` currently covers held/rollback/evaluated only — Phase 63 extends for `rollout.advance`
- Mounted governance (Phase 59): extracted panel component, no new routes, informational callouts for protected env
- LiveView tests seed audit events with `metadata: %{source: :guardrail_automation}` and assert HTML labels

### Integration Points
- `load_page/3` in `rollouts.ex`: add policy fetch + scheduled tick query + `@auto_advance_mode` assign
- New `handle_event("save_auto_advance_policy", ...)` → upsert + reload page
- `intervention_event?/1` filter: include `rollout.advance` when automation source
- `timeline.ex` `entry_view/1`: same `guardrail_automation_event?` extension + title/summary for auto advance

</code_context>

<specifics>
## Specific Ideas

- GitHub PR / LaunchDarkly mental model: automation events labeled distinctly from manual operator actions — not silent publish
- Phase 59 governed CR callout pattern applies to protected-env auto-advance expectations
- Observation window copy should match Phase 61 semantics: duration in policy, concrete bounds from guardrail status per stage

</specifics>

<deferred>
## Deferred Ideas

- Global `/admin/rollouts` fleet auto-advance dashboard — out of scope (ROADMAP SC #4)
- Metrics graphs or signal trend charts — observability product widening; host-owned
- Auto-approve change requests for protected-env auto-advance — Phase 62 explicitly deferred
- `mix verify.phase64`, release-contract auto-advance claims, host seam subsection — Phase 64 (VER-01–03)
- Pre-approved CR at policy-enable time — deferred in Phase 62

</deferred>

---

*Phase: 63-mounted-auto-advance-workflows*
*Context gathered: 2026-05-27*
