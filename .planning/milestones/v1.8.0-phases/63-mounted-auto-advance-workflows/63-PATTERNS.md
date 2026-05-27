# Phase 63 — Pattern Map

**Mapped:** 2026-05-27  
**Sources:** 63-CONTEXT.md, 63-RESEARCH.md, Phase 59/61/62 shipped code  
**Requirements:** ADM-04 (mounted auto-advance panel), AUD-04 (automation vs manual labeling)

---

## File inventory

| File | Role | Plan | Closest analog |
|------|------|------|----------------|
| `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | **Create** — `auto_advance_panel/1` + mode copy helpers | 63-01 | `guardrail_status/1` (same module); extraction shape from `GovernanceComponents.blast_radius_panel/1` |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` | **Modify** — load assigns, render panel, form events, intervention/timeline helpers, redaction | 63-01, 63-02, 63-03 | Existing `load_page/3`, `guardrail_status` render slot, `intervention_entry_view/1` |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` | **Modify** — extend automation detection, titles/summaries, redaction allow-list | 63-03 | Parallel helpers already duplicated from `rollouts.ex` |
| `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` | **Read-only** — `timeline_row/1` already renders `automatic?` / Manual rollout action | — | No change expected; entry map drives labels |
| `rulestead_admin/lib/rulestead_admin/components/governance_components.ex` | **Read-only analog** — panel extraction + callout pattern | — | `blast_radius_panel/1` (Phase 59) |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | **Read-only** — `capability_explanation/1`, `banner/1` | 63-02 | `change_request_live/show.ex`, `audience_live/edit_confirm.ex` |
| `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` | **Modify** — ADM-04 contract tests | 63-04 | `seed_guardrail_hold!/0`, intervention excerpt test |
| `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` | **Modify** — AUD-04 auto-advance row + redaction | 63-04 | `"timeline distinguishes automatic guardrail events..."` |
| `rulestead/` core packages | **No changes** | — | Phase boundary; read-only via `Rulestead.fetch_*`, `upsert_*`, `list_scheduled_executions/1` |

---

## 63-01 — Panel component + load assigns

### Surface placement (D-01)

**Analog:** Current rollouts render order — `guardrail_status` immediately before interventions excerpt.

```246:262:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
            <RolloutComponents.guardrail_status
              status={@guardrail_status}
              missing_reason={@guardrail_status_error}
              definitions={@guardrail_definitions}
              timeline_path={path_for(assigns, "/#{@flag_key}/timeline")}
            />

            <section class="rs-card" aria-label="Guardrail interventions">
              <h2>Guardrail interventions</h2>
              ...
            </section>
```

**Phase 63 insertion:**

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

Between `guardrail_status` and the interventions `<section>`.

### Panel extraction shape (D-07)

**Analog:** `GovernanceComponents.blast_radius_panel/1` — attrs-driven, verdict callout, bounded lists, no business logic in HEEx.

```19:70:rulestead_admin/lib/rulestead_admin/components/governance_components.ex
  def blast_radius_panel(assigns) do
    reasons = breach_reasons(assigns.assessment)

    assigns =
      assigns
      |> assign(:verdict, verdict(assigns.assessment))
      |> assign(:breach_reasons, reasons)
      ...

    ~H"""
    <section class="rs-card" aria-label="Blast radius governance">
      <FlagComponents.callout title={verdict_title(@verdict)} tone={verdict_tone(@verdict)}>
        ...
      </FlagComponents.callout>
      ...
    </section>
    """
  end
```

**Analog (same module, rollout tone):** `RolloutComponents.guardrail_status/1` — `rs-card`, fail-closed `state_body/1` copy, window bounds display.

```90:153:rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
  def guardrail_status(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Guardrail status">
      <h2>Guardrail status</h2>
      ...
      <p><%= state_body(@status.state) %></p>
      ...
      <dt>Window</dt>
      <dd><%= @status.window_started_at %> to <%= @status.window_ends_at %></dd>
      ...
    </section>
    """
  end
```

**Phase 63 `auto_advance_panel/1` pattern:**

- `attr` declarations for all assigns from RESEARCH §3.7
- `section.rs-card` with `aria-label="Auto-advance"`
- Mode-specific callouts via private helpers (`mode_body/1`, `blocked_health_body/1`) — reuse guardrail `state_body/1` strings for `:blocked_health`, never fleet-health language
- Inline form stub (fields only in 63-02): `enabled`, `observation_window_seconds`, `next_stage`, `next_percentage`
- Advisory ladder reference via existing `ladder/1` copy tone ("Recommendations stay advisory")
- `OperatorComponents.banner` or `FlagComponents.callout` for protected-env informational callout (D-05)

### `load_page/3` extension

**Analog:** Existing guardrail + intervention load in same function.

```352:406:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp load_page(socket, flag_key, env) do
    case Rulestead.fetch_flag(flag_key, env) do
      {:ok, detail} ->
        ...
        {guardrail_status, guardrail_status_error} =
          load_guardrail_status(flag_key, env, rollout_rule, socket.assigns.current_actor)

        guardrail_interventions =
          load_guardrail_interventions(flag_key, env, socket.assigns.current_actor)

        socket
        |> assign(:detail, detail)
        ...
        |> assign(:guardrail_interventions, guardrail_interventions)
```

**Add after guardrail load (when `rollout_rule_key` present):**

1. **Policy fetch** — treat not-found as nil:

```elixir
policy =
  case Rulestead.fetch_rollout_auto_advance_policy(flag_key, env, rollout_rule_key,
         actor: socket.assigns.current_actor
       ) do
    {:ok, %{policy: policy}} -> policy
    {:error, %{type: :invalid_command, message: "rollout_auto_advance_policy_not_found"}} -> nil
    {:error, _} -> nil
  end
```

**Core API (read-only):**

```1067:1086:rulestead/lib/rulestead.ex
  @spec fetch_rollout_auto_advance_policy(
          String.t() | atom(),
          String.t() | atom(),
          String.t() | atom(),
          keyword()
        ) :: Store.result(map())
  def fetch_rollout_auto_advance_policy(flag_key, environment_key, rule_key, _opts \\ []) do
    flag_key
    |> Command.FetchRolloutAutoAdvancePolicy.new(environment_key, rule_key)
    |> fetch_rollout_auto_advance_policy()
  end
```

2. **Scheduled tick query** — analog: `ScheduleLive.Index.list_scheduled_executions/2`:

```190:201:rulestead_admin/lib/rulestead_admin/live/schedule_live/index.ex
  defp list_scheduled_executions(socket, filters) do
    command =
      Command.ListScheduledExecutions.new(
        environment_key: socket.assigns.current_environment.key,
        state: filters["state"],
        limit: @default_limit
      )

    case Rulestead.list_scheduled_executions(command) do
      {:ok, %Command.Page{entries: entries}} -> entries
      _ -> []
    end
  end
```

**Phase 63 bounded filter + post-filter:**

```elixir
alias Rulestead.Governance.RolloutAutoAdvance

scheduled_tick =
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

**Tick metadata filter (core, read-only):**

```11:18:rulestead/lib/rulestead/governance/rollout_auto_advance.ex
  @spec automation_tick?(map()) :: boolean()
  def automation_tick?(metadata) when is_map(metadata) do
    source = Map.get(metadata, "source") || Map.get(metadata, :source)
    source == "guardrail_automation" or source == :guardrail_automation
  end
```

3. **`@auto_advance_mode` derivation (D-03)** — pure function in `rollouts.ex` or small `FlagLive.AutoAdvance` module:

```
derive_mode(definitions, guardrail_status, policy, scheduled_tick, now)

[] definitions                          → :unavailable
state in [:held, :pending_data, :rollback_triggered] → :blocked_health
policy.enabled && incomplete fields     → :config_incomplete
scheduled_tick != nil                   → :scheduled
policy.enabled && window_ends_at > now  → :pending_observation
else                                    → :ready
```

Window bounds from existing `guardrail_status_view/1`:

```746:762:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp guardrail_status_view(status) do
    ...
    %{
      state: state,
      ...
      window_started_at: window_started_at(decision),
      window_ends_at: window_ends_at(decision),
      ...
    }
  end
```

4. **Protected-env callout flags (D-05)** — analog: `AudienceLive.Governance.governance_mode/3`:

```51:71:rulestead_admin/lib/rulestead_admin/live/audience_live/governance.ex
  def governance_mode(environment_key, assessment, visibility_tier) do
    cond do
      not Compare.protected_target?(normalize_environment_key(environment_key)) ->
        :unrestricted
      ...
      assessment_verdict(assessment) == :above_threshold ->
        :change_request
```

**Phase 63 (simpler):**

```elixir
alias Rulestead.Admin.Authorizer
alias Rulestead.Promotion.Compare

resource = %{resource_type: "flag", resource_key: flag_key}
approval_requirement = Authorizer.approval_requirement(actor, :advance_rollout, resource, env)

protected_callout? =
  Compare.protected_target?(env) or approval_requirement.change_request_required?
```

---

## 63-02 — Policy form events + capability gates (ADM-04)

### Direct save, not ruleset publish chain (D-02)

**Do not follow:** `persist_rollout/2` draft→publish path. Auto-advance policy lives in `rollout_auto_advance_policies`, not ruleset draft.

**Follow:** Direct command upsert + `load_page/3` reload (like kill-switch engage, not like ruleset preview→confirm).

```elixir
def handle_event("save_auto_advance_policy", %{"auto_advance" => params}, socket) do
  # parse enabled, observation_window_seconds, next_stage, next_percentage
  # validate completeness when enabled
  with :ok <- authorize_advance_rollout(socket),
       {:ok, _} <- Rulestead.upsert_rollout_auto_advance_policy(
         socket.assigns.flag_key,
         socket.assigns.current_environment.key,
         %{rule_key: socket.assigns.rollout_rule_key, ...},
         actor: socket.assigns.current_actor,
         metadata: command_metadata(socket, "rollouts.save_auto_advance_policy", reason)
       ) do
    {:noreply, load_page(socket, ...) |> assign(:status_message, "...")}
  else
    {:error, %Rulestead.Error{}} = err -> {:noreply, assign(socket, :error_message, err.message)}
    {:error, :unauthorized} -> ...
  end
end
```

**Core upsert (maps to `:advance_rollout`):**

```1048:1062:rulestead/lib/rulestead.ex
  def upsert_rollout_auto_advance_policy(flag_key, environment_key, attrs, opts \\ [])
      when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)
    rule_key = Map.fetch!(attrs, :rule_key)
    flag_key
    |> Command.UpsertRolloutAutoAdvancePolicy.new(environment_key, rule_key, attrs, opts)
    |> upsert_rollout_auto_advance_policy()
  end
```

Optional: `handle_event("validate_auto_advance", ...)` for live field hints when enabling.

### Capability gate — `:advance_rollout`, not `execute?` (D-02)

**Anti-pattern:** Publish button uses `capabilities.execute?` (maps to `:publish_ruleset`).

```232:233:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
                <button :if={@editable? and (@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?)} type="button" phx-click="publish">Publish</button>
```

**Correct gate:**

```elixir
alias Rulestead.Admin.Authorizer

defp authorize_advance_rollout(socket) do
  actor = socket.assigns.current_actor
  env = socket.assigns.current_environment.key
  resource = %{resource_type: "flag", resource_key: socket.assigns.flag_key}

  case Authorizer.authorize(actor, :advance_rollout, resource, env) do
    :ok -> :ok
    {:error, reason} -> {:error, reason}
  end
end
```

**Denied UI analog:**

```55:61:rulestead_admin/lib/rulestead_admin/components/operator_components.ex
  def capability_explanation(assigns) do
    ~H"""
    <div class="rs-capability-explanation" data-tone={@tone}>
      <strong><%= @title %></strong>
      <span><%= @reason %></span>
    </div>
    """
  end
```

Render in panel when denied:

```heex
<OperatorComponents.capability_explanation
  :if={!@can_save? && @capability_denied_reason}
  title="Auto-advance configuration requires advance permission"
  reason={@capability_denied_reason}
/>
```

**Test analog:** `DenyWritesPolicy` in rollouts_test — extend or add variant denying `:advance_rollout` only.

### Prerequisite gates (D-03)

| Mode | Toggle | Save | Copy source |
|------|--------|------|-------------|
| `:unavailable` | disabled | blocked | "Wire guardrails on this rollout rule before enabling auto-advance." |
| `:blocked_health` | disabled | blocked | Reuse `state_body/1` from `RolloutComponents` — do not promise automation |
| `:config_incomplete` | enabled | blocked until fields | Inline field hints |
| `:ready` | enabled | allowed | Neutral ready copy |
| `:pending_observation` | enabled (read-only state) | allowed | D-04 window copy |
| `:scheduled` | enabled (read-only state) | allowed | D-04 tick copy |

**Fail-closed guardrail copy to reuse:**

```187:206:rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
  defp state_body(:pending_data),
    do: "Automation is waiting for valid guardrail evidence and will not assume the stage is healthy."

  defp state_body(:held),
    do: "Guardrail automation held this rollout fail-closed. Review the missing or stale signal before advancing."

  defp state_body(:rollback_triggered),
    do: "A confirmed threshold breach triggered rollback to the last stable rollout snapshot."
```

### Protected-env callout (D-05)

**Copy (informational, policy save still allowed):**

> When eligible, advancement submits a change request for approval — it will not auto-apply in this environment.

**Optional analog for approval count:** `edit_confirm.ex` lines 84–90 (`required_approvals`, `self_approval_allowed?`).

### Pending observation copy (D-04)

- Window open: *"Observation window open until {time}. Auto-advance evaluates at window close."*
- Tick scheduled: *"Advance scheduled for {scheduled_for} if guardrails remain healthy."*

Compose from `@guardrail_status.window_ends_at` + `@scheduled_tick.scheduled_for`. Reload on save/advance clears stale ticks (Phase 62 supersede).

---

## 63-03 — Timeline + intervention automation labeling (AUD-04)

### Extend `guardrail_automation_event?/1` (both files)

**Current (incomplete for AUD-04):**

```499:505:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp guardrail_automation_event?(%{event_type: event_type}) do
    event_type in [
      "rollout.guardrail_held",
      "rollout.guardrail_rollback",
      "rollout.guardrail_evaluated"
    ]
  end
```

**Phase 63 extension (apply identically in `timeline.ex`):**

```elixir
defp guardrail_automation_event?(%{event_type: "rollout.advance"} = event) do
  metadata = event.metadata || %{}
  source = metadata["source"] || metadata[:source]
  source in ["guardrail_automation", :guardrail_automation]
end

defp guardrail_automation_event?(%{event_type: event_type}) do
  event_type in [
    "rollout.guardrail_held",
    "rollout.guardrail_rollback",
    "rollout.guardrail_evaluated"
  ]
end
```

**Intervention filter:** `intervention_event?/1` already includes `"rollout.advance"` — no filter change; labeling via `automatic?: guardrail_automation_event?(event)`.

```422:430:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp intervention_event?(%{event_type: event_type}) do
    event_type in [
      "rollout.guardrail_held",
      "rollout.guardrail_rollback",
      "rollout.guardrail_evaluated",
      "rollout.advance",
      "ruleset.publish"
    ]
  end
```

### Titles and summaries

**Add to `intervention_title_for/1` and `title_for/1`:**

```elixir
defp intervention_title_for(%{event_type: "rollout.advance"} = event) do
  if guardrail_automation_event?(event),
    do: "Automatic rollout advance",
    else: humanize_event("rollout.advance")
end
```

**Auto-advance summary:** pull next stage/%, observation window from redacted metadata `context.eligibility.policy_snapshot` or `before`/`after`/`diff` percentage transition.

**Manual advance:** existing fallback + `AuditComponents.timeline_row` Manual label:

```104:112:rulestead_admin/lib/rulestead_admin/components/audit_components.ex
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

No component change — extend entry map `automatic?: true` and `title`.

### Redaction allow-list extension (explicit paths only)

**Analog:** Existing intervention redaction — prefix path matching, no wildcards.

```465:496:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp intervention_redacted_metadata(metadata) do
    metadata
    |> Redaction.redact_metadata(
      allow: [
        "before.status",
        ...
        "source",
        "request_id"
      ]
    )
    |> Map.fetch!(:audit)
  end
```

**Add to both `intervention_redacted_metadata/1` (rollouts) and `redacted_metadata/1` (timeline):**

```elixir
"context.source",
"context.eligibility",
"context.scheduled_execution_id",
"context.observation_window_started_at",
"context.observation_window_ends_at",
"context.observation_window_seconds",
"context.eligibility.policy_snapshot",
"links.scheduled_execution_id",
"links.change_request_id"
```

**Redaction engine constraint:**

```45:48:rulestead/lib/rulestead/admin/redaction.ex
  defp allowed_path?(allow, path) do
    Enum.any?(allow, fn allowed ->
      direct_match?(path, allowed) || direct_match?(tl_or_empty(path), allowed)
    end)
  end
```

Do **not** use `auto_advance.*` — list nested keys explicitly.

---

## 63-04 — LiveView contract tests

### Rollouts test patterns

**Analog:** Guardrail intervention excerpt with automatic labels.

```246:255:rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs
  test "rollout page shows guardrail intervention excerpt with automatic labels", %{conn: conn} do
    seed_guardrail_hold!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Guardrail interventions"
    assert html =~ "Automatic guardrail hold"
    assert html =~ "Automatic"
    assert html =~ "Open full timeline"
  end
```

**New seed helpers (recommended private functions):**

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
```

**Required scenarios (from RESEARCH §5):**

| # | Intent | Key assertions |
|---|--------|----------------|
| 1 | `:unavailable` — no guardrails | disabled toggle; wiring copy |
| 2 | Policy save enables authored plan | form submit; `fetch_rollout_auto_advance_policy` returns enabled |
| 3 | `:blocked_health` | reuse `seed_guardrail_hold!/0`; fail-closed copy; toggle disabled |
| 4 | `:pending_observation` | `Control.set_now!/1`; future `window_ends_at`; observation copy |
| 5 | `:scheduled` | advance + policy → tick in `list_scheduled_executions`; scheduled copy |
| 6 | Protected env CR callout | policy with `change_request_required?` → true; callout; save succeeds |
| 7 | Denied `:advance_rollout` | `capability_explanation`; no save |
| 8 | Auto `rollout.advance` in excerpt | `"Automatic rollout advance"`, `"Automatic"` |

**Clock control analog:**

```57:59:rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs
    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
```

### Timeline test patterns

**Analog:** Manual vs automatic distinction test.

```109:125:rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs
  test "timeline distinguishes automatic guardrail events from manual rollout actions", %{
    conn: conn
  } do
    seed_guardrail_interventions!()

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Automatic guardrail hold"
    ...
    assert html =~ "Manual rollout action"
    assert html =~ "[REDACTED]"
    refute html =~ "provider-secret-timeline"
  end
```

**Extend `seed_guardrail_interventions!/0`:** add automation `rollout.advance` audit (`metadata: %{source: :guardrail_automation}`) alongside existing manual advances (`source: :admin_ui`).

**Redaction test:** assert allowed auto-advance keys visible; raw provider payload `[REDACTED]`.

### Regression commands (63-04 verify)

```bash
cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs
cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/timeline_test.exs
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
mix compile --warnings-as-errors
```

---

## Cross-cutting constraints

| Constraint | Pattern |
|------------|---------|
| No new routes | Extend `FlagLive.Rollouts` only (D-01) |
| No core changes | Call existing APIs; Phase 61/62 contracts unchanged |
| Ladder advisory-only | `@ladder_steps [5, 25, 50, 100]` reference only; do not auto-fill policy fields |
| No fleet/metrics UI | Window bounds + scheduled tick only |
| Duplicate helper drift | Extend `guardrail_automation_event?/1` in rollouts + timeline atomically (63-03) |
| Stale tick hygiene | Filter `state: "scheduled"`; reload after save |

---

## Plan dependency order

```
63-01 (panel + load) → 63-02 (form + gates) → 63-03 (timeline/redaction) → 63-04 (tests)
```

63-03 may parallel 63-02 after 63-01 if panel assigns are stable.

---

## PATTERN MAPPING COMPLETE
