# Phase 63 — Research: Mounted Auto-Advance Workflows

**Researched:** 2026-05-27  
**Source:** `63-CONTEXT.md` (user decisions), Phase 61/62 shipped code, mounted rollout/timeline LiveViews, Phase 59 governance panel pattern  
**Requirements:** ADM-04, AUD-04

---

## 1. Executive Summary

Phase 63 is a **presentation-only** milestone: mount auto-advance configuration, pending-observation state, and automation-vs-manual audit labeling on the existing `FlagLive.Rollouts` page and per-flag timeline — without changing core policy contracts (Phase 61), orchestration (Phase 62), or introducing fleet/metrics surfaces.

**Planner-critical constraints:**

| Constraint | Why it matters |
|------------|----------------|
| No new LiveView routes | D-01; ROADMAP SC #4 — mounted posture only |
| Direct policy save, not ruleset publish chain | D-02; auto-advance lives in `rollout_auto_advance_policies`, not ruleset draft/publish |
| `:advance_rollout` authorization for saves | `upsert_rollout_auto_advance_policy` maps to `:advance_rollout` in `Rulestead.command_action/2` |
| Fail-closed `@auto_advance_mode` | ADM-04; never imply healthy fleet or Rulestead-owned metrics |
| Compose pending state from guardrail window + scheduled tick | D-04; no new core read APIs required |
| Extend `guardrail_automation_event?/1` for `rollout.advance` | AUD-04; reuse `AuditComponents.timeline_row` Automatic vs Manual labels |
| Redaction uses prefix paths, not wildcards | `Redaction.allowed_path?/2` has no `*` — list explicit nested keys |
| Core orchestration is read-only | Phase boundary; call existing `fetch_*`, `upsert_*`, `list_scheduled_executions/1` only |

Phase 63 delivers four plans (63-01…63-04) mirroring Phases 59/61/62: panel + load assigns, policy form + gates, timeline/redaction labeling, LiveView contract tests.

---

## 2. Codebase Findings

### 2.1 Phase 61/62 assets ready to present (no core changes)

| Asset | Location | Phase 63 use |
|-------|----------|--------------|
| Policy CRUD | `Rulestead.fetch_rollout_auto_advance_policy/3`, `upsert_rollout_auto_advance_policy/4` | Form load/save |
| Policy fields | `Command.UpsertRolloutAutoAdvancePolicy`: `enabled`, `observation_window_seconds`, `next_stage`, `next_percentage` | Inline form fields |
| Not-found semantics | `rollout_auto_advance_policy_not_found` error on fetch | Treat as nil policy (disabled, empty fields) |
| Scheduled ticks | `Rulestead.list_scheduled_executions/1` + Phase 62 schedule metadata | Pending tick strip |
| Tick shape | `Schedule.schedule_metadata/0` → `source: guardrail_automation`, `automation_phase: evaluate_and_advance` | Client-side filter |
| Snapshot rule match | `command_snapshot["rollout"]["rule_key"]` | Filter ticks to current rollout rule |
| Guardrail window | `fetch_guardrail_status/3` → `monitoring_window_started_at/ends_at`, `decision_state` | Pending observation copy |
| Protected-env routing | `Authorizer.approval_requirement/4` for `:advance_rollout` | Informational callout (D-05) |
| Automation audit | `rollout.advance` with `metadata.source: guardrail_automation` + `context.eligibility` | Timeline/intervention labeling |

**Phase 62 audit envelope for successful auto-advance** (via `audit_event_changeset/5`):

- Top-level `source` from command metadata (`guardrail_automation`)
- `context` merges full advance command metadata (`eligibility`, `scheduled_execution_id`, `request_id`)
- `before` / `after` / `diff` carry ruleset percentage transition
- `links.guardrail_decision_id` links to new decision row

### 2.2 Mounted rollout page — current integration points

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`

| Concern | Current state | Phase 63 gap |
|---------|---------------|--------------|
| Page layout | `guardrail_status` → interventions excerpt | Insert `auto_advance_panel` between them (D-01) |
| `load_page/3` | Fetches flag, guardrail status, 5-row intervention excerpt | Add policy fetch, scheduled tick query, `@auto_advance_mode` |
| Form events | Rollout percentage only | Add `save_auto_advance_policy`, optional `validate_auto_advance` |
| `guardrail_automation_event?/1` | held / rollback / evaluated only | Extend for `rollout.advance` + source check (D-06) |
| `intervention_event?/1` | Already includes `"rollout.advance"` | No filter change; labeling distinguishes auto vs manual |
| Capability gating | Publish uses `execute?` or `admin?` | Policy save must gate on `:advance_rollout` via `Authorizer` (D-02) |

**Established intervention test pattern** (`rollouts_test.exs`):

- `seed_guardrail_hold!/0` seeds manual advance + automation hold audit
- Asserts `"Automatic guardrail hold"`, `"Automatic"`, `"source guardrail_automation"`
- Denies audit reads → interventions hidden but guardrail status remains

### 2.3 Component patterns to reuse

**`RolloutComponents.guardrail_status/1`** — `rs-card` section with fail-closed copy per `decision_state` (`:held`, `:pending_data`, `:rollback_triggered`). Auto-advance panel should **reuse tone/copy** for `:blocked_health` rather than invent new fleet language.

**`GovernanceComponents.blast_radius_panel/1`** (Phase 59) — extracted panel with verdict callout, bounded breach list, optional nested slot. **`RolloutComponents.auto_advance_panel/1`** should follow same extraction shape: attrs-driven, mode-specific callouts, no business logic in HEEx.

**`AuditComponents.timeline_row/1`** — already renders:

```101:112:rulestead_admin/lib/rulestead_admin/components/audit_components.ex
      <p :if={Map.get(@entry, :automatic?, false)} class="rs-audit-row__source">
        Automatic<span :if={Map.get(@entry, :source_label)}> source {@entry.source_label}</span>
      </p>
      <p
        :if={
          !Map.get(@entry, :automatic?, false) and
            String.starts_with?(to_string(@entry.raw.event.event_type), "rollout.")
        }
        class="rs-audit-row__source"
      >
        Manual rollout action
      </p>
```

Extending `automatic?` on the entry map is sufficient for AUD-04 — **no component change required**.

**`OperatorComponents.capability_explanation/1`** — use when `:advance_rollout` denied (title e.g. "Auto-advance configuration requires advance permission").

**Protected-env callout pattern** — mirror Phase 59 preview copy (`AudienceLive.Governance`): informational banner when `change_request_required?`, not a new route or auto-approve path.

### 2.4 Timeline page — parallel labeling gap

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`

- Duplicates `guardrail_automation_event?/1`, `redacted_metadata/1`, title/summary helpers — **same extension needed in both files** (or extract shared helper in 63-03; CONTEXT allows either).
- Existing test `"timeline distinguishes automatic guardrail events from manual rollout actions"` seeds manual `rollout.advance` (`source: :admin_ui`) alongside automation events — **extend with automation `rollout.advance` row**.

### 2.5 Scheduled execution listing — admin seam note

`Rulestead.list_scheduled_executions/1` calls `run_store/3` **without** `admin_read/authorize` (unlike `list_audit_events`). Schedule LiveView uses the same path. Phase 63 should:

- Query with bounded filters: `resource_key`, `environment_key`, `action: :advance_rollout`, `state: "scheduled"`
- Post-filter: `RolloutAutoAdvance.automation_tick?/1` on metadata + `command_snapshot.rollout.rule_key == @rollout_rule_key`
- Acceptable for mounted rollout context; do **not** widen into a fleet schedule dashboard (ROADMAP SC #4)

**`ListScheduledExecutions` filters available today:**

`environment_key`, `state`, `action`, `resource_type`, `resource_key`, `limit` — **no metadata filter at store layer**; rule_key match is LiveView-side.

### 2.6 Redaction allow-list gap

Current rollout/timeline allow lists cover guardrail evidence and `source`, but **not** auto-advance audit keys. `Redaction` uses prefix path matching (`Enum.take(path, length(allowed)) == allowed`) — **`auto_advance.*` is not supported**.

Planner must add explicit paths, e.g.:

- `context.source`, `context.eligibility`, `context.scheduled_execution_id`
- `context.observation_window_started_at`, `context.observation_window_ends_at` (present on protected-env CR submit metadata)
- `links.scheduled_execution_id`, `links.change_request_id`
- Nested eligibility: `context.eligibility.policy_snapshot` fields if surfaced in summary

PII rule unchanged: no raw provider payloads in allow list (existing tests assert `[REDACTED]`).

### 2.7 Ladder advisory-only

`@ladder_steps [5, 25, 50, 100]` and `RolloutComponents.ladder/1` already state advisory copy. Auto-advance form **`next_stage` / `next_percentage` are operator-authored** — show ladder as reference only, do not auto-fill from ladder selection (Phase 61 D-01).

---

## 3. Implementation Approach

Aligned with `63-CONTEXT.md` D-01 through D-07.

### 3.1 Surface placement (D-01)

In `rollouts.ex` render, between `RolloutComponents.guardrail_status/1` and guardrail interventions section:

```heex
<RolloutComponents.auto_advance_panel
  mode={@auto_advance_mode}
  policy={@auto_advance_policy}
  guardrail_status={@guardrail_status}
  guardrail_definitions={@guardrail_definitions}
  scheduled_tick={@auto_advance_scheduled_tick}
  protected_callout?={@auto_advance_protected_callout?}
  approval_requirement={@auto_advance_approval_requirement}
  can_save?={@auto_advance_can_save?}
  capability_denied_reason={@auto_advance_capability_denied_reason}
  ladder_steps={@ladder_steps}
/>
```

No new routes, no schedule index changes, no metrics charts.

### 3.2 Policy form (D-02)

**Load:** In `load_page/3`, when rollout rule exists:

```elixir
policy =
  case Rulestead.fetch_rollout_auto_advance_policy(flag_key, env, rule_key,
         actor: socket.assigns.current_actor
       ) do
    {:ok, %{policy: policy}} -> policy
    {:error, %{type: :invalid_command, message: "rollout_auto_advance_policy_not_found"}} -> nil
    {:error, _} -> nil
  end
```

**Save event:** `handle_event("save_auto_advance_policy", %{"auto_advance" => params}, socket)`

- Parse: `enabled` (checkbox), `observation_window_seconds`, `next_stage`, `next_percentage`
- Validate completeness when `enabled == true` (client + server)
- Call `Rulestead.upsert_rollout_auto_advance_policy/4` with `rule_key`, `actor`, `reason`, `metadata`
- On success: `load_page/3` refresh (picks up pending tick if advance already scheduled)
- On `{:error, %Rulestead.Error{}}`: assign `:error_message`

**Authorization:**

```elixir
Authorizer.authorize(actor, :advance_rollout, %{resource_type: "flag", resource_key: flag_key}, env)
```

When denied → disable form, render `capability_explanation/1`. Do not rely solely on `capabilities.execute?` (maps to `:publish_ruleset`, not `:advance_rollout`).

### 3.3 `@auto_advance_mode` derivation (D-03)

Recommended pure function (LiveView-private or small `FlagLive.AutoAdvance` module):

```
derive_mode(guardrail_definitions, guardrail_status, policy, scheduled_tick, now)

1. guardrail_definitions == []           → :unavailable
2. decision_state in [:held, :pending_data, :rollback_triggered]
                                         → :blocked_health
3. policy.enabled and incomplete fields  → :config_incomplete
4. scheduled_tick != nil                 → :scheduled
5. policy.enabled and window_ends_at > now → :pending_observation
6. else                                  → :ready
```

**`:blocked_health`** — reuse `RolloutComponents` state_body strings; panel toggle disabled; copy must **not** promise automation will run.

**`:unavailable`** — "Wire guardrails on this rollout rule before enabling auto-advance." Toggle disabled.

**`:config_incomplete`** — block save when enabling without window + next stage + percentage; show inline field hints.

**`:pending_observation`** — calm copy from D-04 using `guardrail_status.window_ends_at`.

**`:scheduled`** — show `scheduled_tick.scheduled_for` + policy next stage/% from tick `command_snapshot.auto_advance` or loaded policy.

**Never use:** "fleet healthy", "all signals green globally", trend graphs, or host-metrics ownership claims.

### 3.4 Pending observation composition (D-04)

**Window bounds** — from existing `@guardrail_status` assign (`window_started_at`, `window_ends_at`).

**Scheduled tick query** — in `load_page/3`:

```elixir
case Rulestead.list_scheduled_executions(
       resource_key: flag_key,
       environment_key: env,
       action: :advance_rollout,
       state: "scheduled",
       limit: 10
     ) do
  {:ok, page} ->
    page.entries
    |> Enum.filter(&RolloutAutoAdvance.automation_tick?/1)
    |> Enum.find(fn tick ->
      get_in(tick.command_snapshot, ["rollout", "rule_key"]) == rollout_rule_key
    end)

  _ -> nil
end
```

Copy templates (operator-facing):

- Window open: *"Observation window open until {time}. Auto-advance evaluates at window close."*
- Tick scheduled: *"Advance scheduled for {scheduled_for} if guardrails remain healthy."*

**Stale tick hygiene:** Phase 62 cancels superseded ticks on manual advance; filtering `state: "scheduled"` + reload on save/advance is sufficient. Do not show completed/cancelled ticks.

### 3.5 Protected environment callout (D-05)

On panel load, when `Compare.protected_target?(env)` **or** `Authorizer.approval_requirement(actor, :advance_rollout, resource, env).change_request_required?`:

> *"When eligible, advancement submits a change request for approval — it will not auto-apply in this environment."*

Policy save remains allowed. Optional: show `required_approvals` / self-approval from `ApprovalRequirement` (Phase 59 D-05 pattern — planner discretion).

### 3.6 Timeline distinction (D-06)

**Extend detection** (both `rollouts.ex` and `timeline.ex`):

```elixir
defp guardrail_automation_event?(%{event_type: "rollout.advance"} = event) do
  metadata = event.metadata || %{}
  source = metadata["source"] || metadata[:source]
  source in ["guardrail_automation", :guardrail_automation]
end

defp guardrail_automation_event?(%{event_type: event_type}) do
  event_type in ["rollout.guardrail_held", "rollout.guardrail_rollback", "rollout.guardrail_evaluated"]
end
```

**Titles / summaries:**

| Event | Title | Summary intent |
|-------|-------|----------------|
| Auto `rollout.advance` | **Automatic rollout advance** | Next stage/%, observation window from `context.eligibility.policy_snapshot` or before/after diff |
| Manual `rollout.advance` | (existing humanize) | **Manual rollout action** label via `AuditComponents` |

**Redaction** — extend both `redacted_metadata/1` and `intervention_redacted_metadata/1` allow lists with explicit paths (see §2.6).

**Intervention excerpt** — already includes `rollout.advance`; auto rows gain `automatic?: true` after extension.

### 3.7 Component shape (D-07)

**`RolloutComponents.auto_advance_panel/1`** attrs:

| Attr | Purpose |
|------|---------|
| `mode` | `:unavailable` \| `:blocked_health` \| `:config_incomplete` \| `:ready` \| `:pending_observation` \| `:scheduled` |
| `policy` | Loaded policy map or nil |
| `guardrail_status` | Existing status view |
| `guardrail_definitions` | Prerequisite check |
| `scheduled_tick` | Filtered tick or nil |
| `protected_callout?` | Show D-05 banner |
| `approval_requirement` | Optional approval copy |
| `can_save?` | Authorization + mode gates |
| `capability_denied_reason` | For `capability_explanation` |
| `ladder_steps` | Advisory reference |

Form: `phx-submit="save_auto_advance_policy"`, `phx-change="validate_auto_advance"` (optional live validation).

---

## 4. Four-Plan Breakdown Recommendation

| Plan | Scope | Primary files | Requirements |
|------|-------|---------------|--------------|
| **63-01** | Panel component + `load_page` assigns: policy fetch, scheduled tick, `@auto_advance_mode`, protected callout flags | `rollout_components.ex`, `rollouts.ex` | ADM-04 (read path) |
| **63-02** | Form events, `:advance_rollout` capability gate, prerequisite/disabled states, upsert + reload | `rollouts.ex`, `operator_components.ex` (if needed) | ADM-04 (write path) |
| **63-03** | Timeline + intervention automation labeling, redaction allow-list, auto-advance titles/summaries | `rollouts.ex`, `timeline.ex` | AUD-04 |
| **63-04** | LiveView contract tests: toggle save, pending/scheduled states, blocked prerequisites, protected callout, auto vs manual excerpts | `rollouts_test.exs`, `timeline_test.exs` | ADM-04, AUD-04 |

**Dependency order:** 63-01 → 63-02 → 63-03 → 63-04 (63-03 can parallel 63-02 after 63-01 if needed).

### File-by-file change map

| File | Plan | Change |
|------|------|--------|
| `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | 63-01 | Add `auto_advance_panel/1` + private copy helpers |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` | 63-01, 63-02, 63-03 | Load assigns, render panel, form events, extend intervention helpers + redaction |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` | 63-03 | Extend `guardrail_automation_event?/1`, title/summary, redaction |
| `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` | 63-04 | ADM-04 scenarios |
| `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` | 63-04 | AUD-04 auto-advance row |
| `rulestead/` core packages | — | **No changes** (phase boundary) |

---

## 5. Testing Strategy

**Pattern:** Extend existing `RulesteadAdmin.Live.FlagLive.RolloutsTest` / `TimelineTest` — `Rulestead.Fake` store, `Control.set_now!/1` for window/tick timing, custom `Policy` modules for capability denial.

### Required test cases

| # | Test intent | File | Key assertions |
|---|-------------|------|----------------|
| 1 | Auto-advance panel renders with disabled toggle when no guardrails | `rollouts_test` | `:unavailable` copy; no save form or toggle disabled |
| 2 | Policy save enables auto-advance with authored plan | `rollouts_test` | Upsert via form; `fetch_rollout_auto_advance_policy` returns enabled policy |
| 3 | `:blocked_health` when guardrail held | `rollouts_test` | Reuse `seed_guardrail_hold!/0`; fail-closed copy; toggle disabled |
| 4 | `:pending_observation` shows window copy | `rollouts_test` | Seed healthy decision with future `window_ends_at`; assert observation copy |
| 5 | `:scheduled` shows tick time | `rollouts_test` | `advance_rollout` + enabled policy → `list_scheduled_executions` tick; assert scheduled copy |
| 6 | Protected env shows CR callout, still saves policy | `rollouts_test` | Policy module `change_request_required?` → true; callout text; save succeeds |
| 7 | Denied `:advance_rollout` shows capability_explanation | `rollouts_test` | DenyWritesPolicy variant denying advance; no save |
| 8 | Intervention excerpt labels auto `rollout.advance` | `rollouts_test` | Seed automation advance audit; `"Automatic rollout advance"`, `"Automatic"` |
| 9 | Timeline distinguishes auto vs manual advance | `timeline_test` | Extend `seed_guardrail_interventions!/0` with automation advance; `"Automatic rollout advance"` + `"Manual rollout action"` |
| 10 | Redaction preserves allowed auto-advance keys | `timeline_test` | `[REDACTED]` for raw provider; allowed fields visible |

### Test seed helpers (recommended private functions)

```elixir
defp seed_auto_advance_policy!(enabled \\ true, overrides \\ []) do
  Rulestead.upsert_rollout_auto_advance_policy(
    "checkout-redesign", "prod",
    Map.merge(%{
      rule_key: "checkout-canary",
      enabled: enabled,
      observation_window_seconds: 300,
      next_stage: "canary-50",
      next_percentage: 50
    }, Map.new(overrides))
  )
end

defp seed_auto_advance_tick!(...) do
  # advance_rollout with monitoring_window_* + enabled policy
  # returns tick from list_scheduled_executions
end

defp seed_automation_advance_audit!(...) do
  # execute auto-advance tick via StoreFixtures pattern OR
  # advance_rollout with metadata source guardrail_automation for UI-only test
end
```

**Regression commands (63-04 verify task):**

```bash
cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs
cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/timeline_test.exs
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs  # Phase 62 unchanged
mix compile --warnings-as-errors
```

---

## 6. Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Implying healthy fleet when guardrails blocked** | High | `:blocked_health` disables toggle; reuse fail-closed guardrail copy; no green "ready to advance" language |
| **Redaction wildcard `auto_advance.*` silently redacts everything** | High | Use explicit allow paths; extend timeline test `[REDACTED]` assertions |
| **Wrong capability gate (`execute?` vs `:advance_rollout`)** | Medium | Call `Authorizer.authorize/4` for `:advance_rollout` explicitly |
| **`list_scheduled_executions` unauthenticated** | Low | Bounded query scoped to current flag/env; same as schedule surfaces; no new exposure |
| **Stale scheduled tick shown after manual advance** | Medium | Filter `state: "scheduled"` only; reload after save; trust Phase 62 supersede |
| **Policy not found crashes load** | Medium | Treat not-found as nil policy; default form to disabled |
| **Duplicate `guardrail_automation_event?/1` drift** | Medium | Extend both files in 63-03 atomically; optional extract to shared module |
| **Clock flake in pending_observation tests** | Medium | Use `Control.set_now!/1` with fixed `window_ends_at` relative to fake now |
| **Over-scoping into Phase 64** | Medium | No `mix verify.phase64`, docs, or release-contract edits |
| **Observability UI creep** | Medium | No charts, signal trends, or fleet dashboards — window + tick only |

---

## 7. Validation Architecture (Nyquist)

### Requirement → acceptance mapping

| Requirement | Acceptance criterion | Validating test(s) |
|-------------|---------------------|-------------------|
| **ADM-04** | Rollout detail exposes auto-advance toggle | #2, #7 |
| **ADM-04** | Observation-window duration visible | #2, panel renders `observation_window_seconds` |
| **ADM-04** | Pending-observation state with calm copy | #4, #5 |
| **ADM-04** | Bounded remediation when prerequisites/health block | #1, #3 |
| **ADM-04** | No fleet/metrics/dashboard claims | Manual copy review + refute banned phrases in tests |
| **AUD-04** | Distinguish automation from manual in timeline | #9 |
| **AUD-04** | Distinguish in audit/intervention excerpts | #8 |
| **AUD-04** | Remediation guidance preserved | #3, #9 (existing hold/rollback copy unchanged) |
| **AUD-04** | Policy-aware redaction | #10 |

### Test dimensions

| Layer | Command | Validates | When |
|-------|---------|-----------|------|
| LiveView integration | `mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | ADM-04 mounted panel + form | After 63-02, 63-04 |
| LiveView integration | `mix test test/rulestead_admin/live/flag_live/timeline_test.exs` | AUD-04 labeling + redaction | After 63-03, 63-04 |
| Component (optional) | `mix test test/rulestead_admin/components/rollout_components_test.exs` | Panel mode copy snapshots | 63-01 if extracted |
| Core regression | `mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` | Phase 62 untouched | Every plan |
| Compile | `mix compile --warnings-as-errors` | No warnings | Every plan |

### Contract test matrix

| Scenario | Rollouts LV | Timeline LV | ADM-04 | AUD-04 |
|----------|-------------|-------------|--------|--------|
| Panel unavailable (no guardrails) | ✓ | — | ✓ | — |
| Policy save enabled/disabled | ✓ | — | ✓ | — |
| Blocked health | ✓ | — | ✓ | partial |
| Pending observation copy | ✓ | — | ✓ | — |
| Scheduled tick copy | ✓ | — | ✓ | — |
| Protected-env callout | ✓ | — | ✓ | — |
| Capability denied | ✓ | — | ✓ | — |
| Auto advance audit row | ✓ | ✓ | — | ✓ |
| Manual advance row | ✓ | ✓ | — | ✓ |
| Redaction allow-list | — | ✓ | — | ✓ |

**Nyquist quick run:** `rollouts_test.exs` + `timeline_test.exs` auto-advance tests only.  
**Nyquist full:** all rows + Phase 62 orchestration contract + compile both packages.

### Observability hooks (read-only verification)

Phase 63 does not add telemetry. Planners may manually confirm during UAT:

| Signal | Where | Phase 63 relevance |
|--------|-------|-------------------|
| Policy upsert audit | Store mutation telemetry | Form save triggers existing admin mutation span |
| Scheduled tick visible | `list_scheduled_executions` | Pending strip matches Phase 62 tick |
| `rollout.advance` audit | Timeline/intervention | `source: guardrail_automation` renders Automatic |

---

## 8. Open Questions

CONTEXT is detailed; remaining planner discretion only:

1. **Shared helper extraction** — Keep duplicated `guardrail_automation_event?/1` in rollouts + timeline vs extract `RulesteadAdmin.AuditRolloutLabels` (minimal diff favors duplicate extend).
2. **Pending strip UX** — Always-visible observation + tick lines vs collapsible tick detail when both present.
3. **Protected-env approval display** — Show `required_approvals` count on callout or copy-only sentence.
4. **Non-protected direct-advance note** — Optional subtle "eligible advances apply directly" when `change_request_required?` is false (D-05 discretion).

---

## RESEARCH COMPLETE
