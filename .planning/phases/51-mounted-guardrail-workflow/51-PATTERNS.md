# Phase 51: Mounted Guardrail Workflow - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` | LiveView controller | request-response + CRUD | `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | component | request-response + transform | `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` | component | request-response + transform | `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` | LiveView controller | request-response + audit event projection | `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` | test | request-response + CRUD verification | `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` | exact |
| `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` | test | request-response + event-driven audit verification | `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` | exact |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` (LiveView controller, request-response + CRUD)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`

**Imports pattern** (lines 5-10):
```elixir
use Phoenix.LiveView

alias Rulestead.Context
alias Rulestead.Store.Command
alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, RolloutComponents, Shell}
alias RulesteadAdmin.Live.Session
```

**Mount assigns pattern** (lines 15-35):
```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:flag_key, nil)
   |> assign(:current_path, nil)
   |> assign(:sample_size, @sample_size)
   |> assign(:ladder_steps, @ladder_steps)
   |> assign(:detail, nil)
   |> assign(:published_percentage, 0)
   |> assign(:rollout_rule_key, nil)
   |> assign(:rollout_rule_index, nil)
   |> assign(:source_ruleset, nil)
   |> assign(:percentage, nil)
   |> assign(:preview, nil)
   |> assign(:confirm_reason, "")
   |> assign(:confirmation_required?, false)
   |> assign(:editable?, false)
   |> assign(:status_message, nil)
   |> assign(:error_message, nil)
   |> assign(:env_links, %{})}
end
```

Copy this assign style for `:guardrail_status`, `:guardrail_status_error`, `:guardrail_definitions`, and optional `:guardrail_interventions`. Initialize absent status explicitly instead of omitting the panel.

**Route/load pattern** (lines 38-50):
```elixir
def handle_params(%{"key" => flag_key}, uri, socket) do
  env = query_params(uri)["env"] || socket.assigns.current_environment.key
  base_path = build_base_path(socket, flag_key)

  socket =
    socket
    |> assign(:flag_key, flag_key)
    |> assign(:current_path, Session.current_path(socket, base_path))
    |> assign(:env_links, Session.env_links(socket, base_path))
    |> load_page(flag_key, env)

  {:noreply, socket}
end
```

**Core page load pattern** (lines 280-303):
```elixir
defp load_page(socket, flag_key, env) do
  case Rulestead.fetch_flag(flag_key, env) do
    {:ok, detail} ->
      ruleset = source_ruleset(detail)
      {rollout_rule, rollout_rule_index} = find_rollout_rule(ruleset)

      socket
      |> assign(:detail, detail)
      |> assign(:published_percentage, active_rollout_percentage(detail))
      |> assign(:source_ruleset, ruleset)
      |> assign(:rollout_rule_key, field(rollout_rule, :key))
      |> assign(:rollout_rule_index, rollout_rule_index)
      |> assign(:percentage, current_percentage(rollout_rule))
      |> assign(:preview, nil)
      |> assign(:confirm_reason, "")
      |> assign(:confirmation_required?, false)
      |> assign(:editable?, is_nil(detail.flag.archived_at) and not is_nil(rollout_rule))
      |> assign(
        :error_message,
        if(is_nil(rollout_rule),
          do: "No rollout rule is available for this environment.",
          else: nil
        )
      )
```

Extend this load path after `rollout_rule` is found. Use `Rulestead.fetch_guardrail_status/3` with `rule_key: field(rollout_rule, :key), actor: socket.assigns.current_actor`; treat `{:error, _}` as a missing prerequisite assign, not as healthy.

**Status/error response pattern** (lines 242-266):
```elixir
with {:ok, _draft} <-
       Rulestead.save_draft_ruleset(
         Command.SaveDraftRuleset.new(detail.flag.key, detail.environment.key, ruleset,
           actor: socket.assigns.current_actor,
           metadata: command_metadata(socket, "rollouts.save_draft", rollout_reason(socket, mode))
         )
       ),
     {:ok, _published} <- maybe_publish(mode, detail.flag.key, detail.environment.key, socket) do
  {:noreply,
   socket
   |> assign(:confirmation_required?, false)
   |> assign(:confirm_reason, "")
   |> assign(:status_message, message)
   |> assign(:preview, nil)
   |> load_page(detail.flag.key, detail.environment.key)}
else
  {:error, error} ->
    {:noreply, assign(socket, :error_message, error.message)}
end
```

Reuse this fail-closed style for guardrail status load errors: assign an explicit copy string such as `Guardrail status could not be loaded...`; do not crash or hide the status panel.

**Serialization pattern to modify** (lines 464-507):
```elixir
defp serialize_rule(rule) do
  %{
    key: field(rule, :key),
    name: field(rule, :name),
    description: field(rule, :description),
    strategy: normalize_strategy(field(rule, :strategy)),
    value: serialize_plain_map(field(rule, :value, %{})),
    audience_id: field(rule, :audience_id),
    audience_key: field(rule, :audience_key),
    conditions: Enum.map(field(rule, :conditions, []), &serialize_condition/1),
    variants: Enum.map(field(rule, :variants, []), &serialize_variant/1),
    rollout: serialize_rollout(field(rule, :rollout))
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Enum.into(%{})
end

defp serialize_rollout(rollout) do
  %{
    bucket_by: normalize_strategy(field(rollout, :bucket_by)),
    percentage: field(rollout, :percentage, 0),
    salt: field(rollout, :salt)
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Enum.into(%{})
end
```

Add `guardrails: Enum.map(field(rollout, :guardrails, []), &serialize_guardrail/1)` and a helper that preserves `signal_key`, `threshold_operator`, `threshold_value`, `freshness_window_seconds`, `min_sample_size`, `environment_scope`, and `tenant_scope`.

---

### `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` (component, request-response + transform)

**Analog:** `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex`

**Imports/component declaration pattern** (lines 1-5):
```elixir
defmodule RulesteadAdmin.Components.RolloutComponents do
  @moduledoc false

  use Phoenix.Component
```

**Function component attr pattern** (lines 58-83):
```elixir
attr(:preview, :map, default: nil)
attr(:percentage, :integer, default: 0)
attr(:sample_size, :integer, default: 0)

def preview_panel(assigns) do
  ~H"""
  <section class="rs-card" aria-label="Sample preview">
    <h2>Sample preview</h2>
    <p>Preview only. This panel compares intended exposure to a bounded deterministic sample before publish.</p>
    <div :if={is_nil(@preview)}>
      <p>Run preview to compare <%= @percentage %>% intended exposure against <%= @sample_size %> deterministic sample keys.</p>
    </div>
    <div :if={@preview}>
      <p><%= @preview.sample_size %> deterministic sample keys</p>
      <p>Intended exposure: <strong><%= @preview.intended_percentage %>%</strong></p>
      <p>Observed assignments: <strong><%= @preview.observed_percentage %>%</strong> hit the rollout rule.</p>
```

Create `guardrail_status/1` in this style. Use `attr/3`, one `rs-card` section with `aria-label="Guardrail status"`, text state labels, no nested cards, and no JS/chart dependency.

**Compact support component pattern** (lines 41-55):
```elixir
attr(:variants, :list, default: [])

def variant_weights(assigns) do
  ~H"""
  <section class="rs-rollout-variants" aria-label="Variant weights">
    <h2>Variant weights stay locked on this page</h2>
    <p>Use the dedicated rules workspace if composition itself needs to change.</p>
    <ul>
      <li :for={variant <- @variants}>
        <code><%= variant.key %></code>
        <span><%= variant.weight %>%</span>
      </li>
    </ul>
  </section>
  """
end
```

Use this list shape for authored guardrail definitions: signal key in `<code>`, threshold operator/value, freshness window, and min sample size.

---

### `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` (component, request-response + transform)

**Analog:** `rulestead_admin/lib/rulestead_admin/components/audit_components.ex`

**Timeline row pattern** (lines 88-125):
```elixir
attr :entry, :map, required: true
attr :show_flag, :boolean, default: false
attr :show_rollback, :boolean, default: false

def timeline_row(assigns) do
  ~H"""
  <article class="rs-card rs-audit-row" data-result={@entry.result}>
    <header>
      <h3>{@entry.title}</h3>
      <p>{@entry.meta}</p>
    </header>

    <p>{@entry.summary}</p>
    <p :if={@show_flag} class="rs-audit-row__flag">Flag: <code>{@entry.resource_key}</code></p>
    <p :if={@entry.reason} class="rs-audit-row__reason">Reason: {@entry.reason}</p>
    <p :if={@entry.rollback_of_event_id} class="rs-audit-row__link">
      Rollback of audit event <code>{@entry.rollback_of_event_id}</code>
    </p>

    <details aria-label={"Raw detail for #{@entry.title}"}>
      <summary>Show raw detail</summary>
      <pre>{inspect(@entry.raw, pretty: true)}</pre>
    </details>
  </article>
  """
end
```

If automatic labels are added here, keep raw metadata behind `<details>` and render readable operator copy first. Add an `:automatic?` or `:source_label` field to prepared entries rather than branching over raw provider payloads in the component.

**Diff disclosure pattern** (lines 127-157):
```elixir
attr :entry, :map, required: true
attr :source_label, :string, default: "Before"
attr :current_target_label, :string, default: nil
attr :proposed_target_label, :string, default: "After"
attr :structured_label, :string, default: "Readable diff"

def diff_card(assigns) do
  ~H"""
  <details aria-label={@structured_label}>
    <summary>{@structured_label}</summary>
    <section class="rs-diff-card" aria-label={"Diff for #{@entry.title}"}>
```

Use the same disclosure-first pattern for rollback target snapshots or normalized decision evidence if the planner chooses to expose more than the compact evidence row.

---

### `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` (LiveView controller, request-response + audit event projection)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`

**Imports pattern** (lines 5-9):
```elixir
use Phoenix.LiveView

alias Rulestead.Admin.Redaction
alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, OperatorComponents, Shell}
alias RulesteadAdmin.Live.Session
```

**Audit read pattern** (lines 100-118):
```elixir
defp load_page(socket, key, env) do
  with {:ok, detail} <- Rulestead.fetch_flag(key, env),
       {:ok, page} <-
         Rulestead.list_audit_events(
           flag_key: key,
           environment_key: env,
           actor: socket.assigns.current_actor
         ) do
    socket
    |> assign(:detail, detail)
    |> assign(:entries, build_entries(page.entries))
    |> assign(:error_message, nil)
  else
    {:error, error} ->
      socket
      |> assign(:detail, nil)
      |> assign(:entries, [])
      |> assign(:error_message, error.message)
  end
end
```

Reuse this for the rollout-page intervention excerpt. Filter prepared entries to guardrail event types and nearby rollout/ruleset manual actions after calling the core API; do not add a new storage/query path.

**Entry projection pattern** (lines 121-148):
```elixir
defp build_entries(entries) do
  entries
  |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
  |> Enum.map(&entry_view/1)
end

defp entry_view(event) do
  metadata = redacted_metadata(event.metadata)
  before_state = metadata["before"] || %{}
  after_state = metadata["after"] || %{}
  rollback_of_event_id = metadata["rollback_of_event_id"]
  diff_state = metadata["diff"] || %{}

  %{
    id: event.id,
    title: title_for(event),
    meta: meta_for(event),
    summary: summary_for(event, before_state, after_state, diff_state),
    reason: event.reason,
    raw: %{event: Map.take(event, [:event_type, :result, :resource_key, :environment_key, :actor_display, :occurred_at]), metadata: metadata},
    result: event.result,
    rollback_of_event_id: rollback_of_event_id,
    rollback_allowed?: rollback_allowed?(event),
    show_diff?: map_size(before_state) > 0 or map_size(after_state) > 0
  }
end
```

Add explicit `title_for/1` and `summary_for/4` clauses for `rollout.guardrail_held`, `rollout.guardrail_rollback`, and `rollout.guardrail_evaluated` before the generic fallback.

**Redaction allowlist pattern** (lines 151-167):
```elixir
defp redacted_metadata(metadata) do
  metadata
  |> Redaction.redact_metadata(
    allow: [
      "before.status",
      "before.kill_switch_variant_key",
      "before.rules",
      "after.status",
      "after.kill_switch_variant_key",
      "after.rules",
      "diff.rules",
      "rollback_of_event_id",
      "links.inverse_event_type"
    ]
  )
  |> Map.fetch!(:audit)
end
```

Extend the allowlist only for bounded normalized guardrail metadata needed for automatic/source/remediation wording. Do not expose raw provider payloads.

**Title/summary pattern to extend** (lines 169-197):
```elixir
defp title_for(%{event_type: "kill_switch.engage", result: :ok}), do: "Kill switch engaged"
defp title_for(%{event_type: "kill_switch.release", result: :ok}), do: "Kill switch released"
defp title_for(%{event_type: "audit.rollback"}), do: "Rollback applied"
defp title_for(%{event_type: event_type, result: :denied}), do: "#{humanize_event(event_type)} denied"
defp title_for(%{event_type: event_type}), do: humanize_event(event_type)

defp summary_for(%{event_type: "ruleset.publish"}, _before_state, _after_state, diff_state) do
  "Ruleset publish updated ordered rule positions: #{Enum.join(diff_lines("ruleset.publish", diff_state), "; ")}."
end
```

---

### `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` (test, request-response + CRUD verification)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`

**Setup pattern** (lines 1-31):
```elixir
defmodule RulesteadAdmin.Live.FlagLive.RolloutsTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)
```

**LiveView interaction/assertion pattern** (lines 78-119):
```elixir
{:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

assert html =~ "Rollout controls"
assert html =~ "Rule 2 of 3"
assert html =~ "Variant weights stay locked on this page"

changed_html =
  view
  |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
  |> render_change()

assert changed_html =~ "50%"

saved_html =
  view
  |> element("button[phx-click='save_draft']")
  |> render_click()

assert saved_html =~ "Draft saved for Production"

detail = Rulestead.fetch_flag!("checkout-redesign", "prod")
[draft | _rest] = detail.draft_rulesets
rollout_rule = Enum.at(draft.rules, 1)

assert rollout_rule.rollout.percentage == 50
assert Enum.map(rollout_rule.variants, & &1.weight) == [80, 20]
```

Add regression assertions here that `rollout_rule.rollout.guardrails` survives draft save and publish.

**Seed ruleset pattern to extend** (lines 253-298):
```elixir
defp publish_ruleset!(flag_key, environment_key) do
  ruleset = %{
    salt: "#{flag_key}:#{environment_key}:v1",
    rules: [
      %{
        key: "checkout-canary",
        name: "Checkout canary",
        strategy: :variant_split,
        conditions: [],
        rollout: %{bucket_by: :subject, percentage: 25, salt: "checkout-canary"},
        variants: [
          %{key: "control", value: %{value: false}, weight: 80},
          %{key: "treatment", value: %{value: true}, weight: 20}
        ]
      }
    ]
  }

  assert {:ok, _draft} =
           Rulestead.save_draft_ruleset(
             Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
           )

  assert {:ok, _published} =
           Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
end
```

Extend the rollout map with `guardrails: [%{signal_key: ..., threshold_operator: ..., threshold_value: ..., freshness_window_seconds: ..., min_sample_size: ..., environment_scope: ..., tenant_scope: ...}]`.

---

### `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` (test, request-response + event-driven audit verification)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs`

**Setup/audit seed pattern** (lines 23-68):
```elixir
setup %{conn: conn} do
  previous_policy = Application.get_env(:rulestead, :admin_policy)
  Application.put_env(:rulestead, :store, Rulestead.Fake)
  Application.put_env(:rulestead, :admin_policy, AllowPolicy)

  now = ~U[2026-04-23 16:00:00Z]
  Control.reset!(now: now)
  Control.set_now!(now)
  ensure_environment!("prod", "Production")
  seed_flag!()
  publish_ruleset!("checkout-redesign", "prod")

  assert {:ok, _} =
           Rulestead.engage_kill_switch("checkout-redesign", "prod", %{id: "op-1", display: "Priya", roles: [:admin]},
             reason: "incident"
           )
```

Use `Rulestead.evaluate_guarded_rollout/4` or Fake control support if exposed by planning to seed automatic guardrail audit rows. Keep the store as `Rulestead.Fake`.

**Timeline assertion pattern** (lines 71-88):
```elixir
test "per-flag timeline shows reverse-chronological redacted rows and appends rollback as a linked event", %{conn: conn} do
  {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

  assert html =~ "Kill switch engage denied"
  assert html =~ "Kill switch engaged"
  assert html =~ "Denied action remains visible in the audit ledger."
  refute html =~ "viewer@example.com"
  assert html =~ "Show raw detail"

  rollback_html =
    view
    |> element("button[phx-click='rollback']")
    |> render_click()

  assert rollback_html =~ "Rollback appended as audit event"
  assert rollback_html =~ "Rollback applied"
  assert rollback_html =~ "Rollback of audit event"
end
```

Add assertions for `Automatic guardrail hold`, `Automatic guardrail rollback`, `Automatic`, remediation reason, and absence of raw provider details.

## Shared Patterns

### Core Status Boundary
**Source:** `rulestead/lib/rulestead.ex` lines 960-977  
**Apply to:** `rollouts.ex`
```elixir
@doc """
Fetches the latest derived guardrail status for one rollout rule or stage.
"""
@spec fetch_guardrail_status(Command.FetchGuardrailStatus.t()) :: Store.result(map())
def fetch_guardrail_status(%Command.FetchGuardrailStatus{} = command) do
  admin_read(:fetch_guardrail_status, command)
end

def fetch_guardrail_status(flag_key, environment_key, opts \\ []) do
  flag_key
  |> Command.FetchGuardrailStatus.new(environment_key, opts)
  |> fetch_guardrail_status()
end
```

### Guardrail Status Command Shape
**Source:** `rulestead/lib/rulestead/store/command.ex` lines 1486-1511  
**Apply to:** `rollouts.ex`, tests
```elixir
defmodule FetchGuardrailStatus do
  @moduledoc false

  alias Rulestead.Store.Command.GovernanceSupport

  @enforce_keys [:flag_key, :environment_key]
  defstruct [:flag_key, :environment_key, :rule_key, :stage, actor: nil]

  def new(flag_key, environment_key, opts \\ []) do
    %__MODULE__{
      flag_key: GovernanceSupport.normalize_string(flag_key),
      environment_key: GovernanceSupport.normalize_string(environment_key),
      rule_key: Keyword.get(opts, :rule_key) |> GovernanceSupport.normalize_string(),
      stage: Keyword.get(opts, :stage) |> GovernanceSupport.normalize_string(),
      actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
    }
  end
end
```

### Missing Status Is Explicit Error
**Source:** `rulestead/lib/rulestead/fake.ex` lines 866-887  
**Apply to:** `rollouts.ex`, `rollouts_test.exs`
```elixir
case decision do
  nil ->
    {:reply, {:error, StoreError.invalid_command("guardrail status was not found")}, state}

  decision ->
    active_ruleset_version =
      state.flags[to_string(command.flag_key)].environments[to_string(command.environment_key)].active_ruleset_version

    {:reply, {:ok, guardrail_status_payload_in_state(decision, active_ruleset_version)}, state}
end
```

The UI must render missing prerequisite copy on this error path.

### Normalized Evidence Vocabulary
**Source:** `rulestead/lib/rulestead/store/command.ex` lines 181-221  
**Apply to:** `rollout_components.ex`, `rollouts.ex`
```elixir
evidence =
  %{}
  |> maybe_put("status", normalize_enum(Map.get(value, "status"), @guardrail_statuses))
  |> maybe_put("reason", normalize_enum(Map.get(value, "reason"), @guardrail_reasons))
  |> maybe_put("threshold_operator", normalize_enum(Map.get(value, "threshold_operator"), @guardrail_threshold_operators))
  |> maybe_put("threshold_value", normalize_numeric(Map.get(value, "threshold_value")))
  |> maybe_put("observed_value", normalize_numeric(Map.get(value, "observed_value")))
  |> maybe_put("freshness_window_seconds", normalize_non_negative_integer(Map.get(value, "freshness_window_seconds")))
  |> maybe_put("sample_size", normalize_non_negative_integer(Map.get(value, "sample_size")))
  |> maybe_put("min_sample_size", normalize_non_negative_integer(Map.get(value, "min_sample_size")))

%{}
|> maybe_put("signal_key", normalize_string(Map.get(value, "signal_key")))
|> maybe_put("environment_key", normalize_string(Map.get(value, "environment_key")))
|> maybe_put("tenant_key", tenant_key)
|> maybe_put("environment_scope", normalize_enum(Map.get(value, "environment_scope"), @guardrail_environment_scopes))
|> maybe_put("tenant_scope", normalize_enum(Map.get(value, "tenant_scope"), @guardrail_tenant_scopes))
|> maybe_put("evidence", if(map_size(evidence) == 0, do: nil, else: evidence))
```

### Authored Guardrail Embed Fields
**Source:** `rulestead/lib/rulestead/ruleset/guardrail.ex` lines 16-24 and `rulestead/lib/rulestead/ruleset/rollout.ex` lines 14-19  
**Apply to:** `rollouts.ex`, `rollouts_test.exs`, `rollout_components.ex`
```elixir
embedded_schema do
  field(:signal_key, :string)
  field(:threshold_operator, Ecto.Enum, values: @threshold_operators)
  field(:threshold_value, :float)
  field(:freshness_window_seconds, :integer)
  field(:min_sample_size, :integer)
  field(:environment_scope, Ecto.Enum, values: @environment_scopes, default: :environment)
  field(:tenant_scope, Ecto.Enum, values: @tenant_scopes, default: :not_applicable)
end

embedded_schema do
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
  field(:percentage, :integer)
  field(:salt, :string)
  embeds_many(:guardrails, Guardrail, on_replace: :delete)
end
```

### Guardrail Decision Payload Fields
**Source:** `rulestead/lib/rulestead/guardrail_decision.ex` lines 95-120  
**Apply to:** `rollout_components.ex`, `rollouts.ex`
```elixir
%{
  id: decision.id,
  flag_key: decision.flag_key,
  environment_key: decision.environment_key,
  rule_key: decision.rule_key,
  stage: decision.stage,
  tenant_key: decision.tenant_key,
  decision_state: decision.decision_state,
  action_type: decision.action_type,
  decision_reason: decision.decision_reason,
  effective_percentage: decision.effective_percentage,
  rollout_salt: decision.rollout_salt,
  variant_fingerprint: decision.variant_fingerprint,
  monitoring_window_started_at: decision.monitoring_window_started_at,
  monitoring_window_ends_at: decision.monitoring_window_ends_at,
  occurred_at: decision.occurred_at,
  signal_facts: normalize_signal_facts(decision.signal_facts || []),
  guardrail_evidence: normalize_map(decision.guardrail_evidence),
  authored_snapshot: normalize_map(decision.authored_snapshot),
  rollback_target_snapshot: normalize_map(decision.rollback_target_snapshot),
  correlation_id: decision.correlation_id,
  metadata: Command.GovernanceSupport.normalize_metadata(decision.metadata)
}
```

### Audit Read Boundary
**Source:** `rulestead/lib/rulestead.ex` lines 342-356  
**Apply to:** `rollouts.ex`, `timeline.ex`
```elixir
@doc """
Lists redacted audit events for one flag or all flags.
"""
@spec list_audit_events(Command.ListAuditEvents.t() | keyword()) ::
        Store.result(Command.Page.t(map()))
def list_audit_events(command_or_opts \\ Command.ListAuditEvents.new())

def list_audit_events(%Command.ListAuditEvents{} = command) do
  admin_read(:list_audit_events, command)
end

def list_audit_events(opts) when is_list(opts) do
  opts
  |> Command.ListAuditEvents.new()
  |> list_audit_events()
end
```

### Accessibility and Status Messaging
**Source:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` lines 158-170 and `timeline.ex` lines 57-60  
**Apply to:** all new rendered status/error states
```elixir
<p :if={@error_message} role="alert"><%= @error_message %></p>
<p :if={@status_message} role="status"><%= @status_message %></p>

<p :if={@error_message} role="alert">{@error_message}</p>
<p :if={@notice} role="status">{@notice}</p>
```

## No Analog Found

None. Every planned Phase 51 file has an exact same-file or same-role analog in the current mounted admin codebase.

## Metadata

**Analog search scope:** `rulestead_admin/lib`, `rulestead_admin/test`, `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/fake.ex`, `rulestead/lib/rulestead/ruleset/*`, `rulestead/lib/rulestead/guardrail_decision.ex`  
**Files scanned:** 14 planning/code files plus targeted core API ranges  
**Pattern extraction date:** 2026-05-27
