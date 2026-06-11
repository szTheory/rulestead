defmodule RulesteadAdmin.Components.RolloutComponents do
  @moduledoc false

  use Phoenix.Component

  alias RulesteadAdmin.Components.OperatorComponents

  attr(:steps, :list, default: [])
  attr(:current, :integer, default: 0)
  attr(:selected, :integer, default: 0)

  def ladder(assigns) do
    ~H"""
    <section class="rs-rollout-ladder" aria-label="Suggested rollout ladder">
      <h2>Suggested rollout ladder</h2>
      <p>Recommendations stay advisory. Operators still choose when to preview, save, and publish.</p>
      <ol>
        <li :for={step <- @steps} data-current={to_string(step == @current)} data-selected={to_string(step == @selected)}>
          <strong><%= step %>%</strong>
          <span :if={step == @current}>Current</span>
          <span :if={step == @selected and step != @current}>Selected</span>
        </li>
      </ol>
    </section>
    """
  end

  attr(:entries, :list, default: [])
  attr(:current_rule_key, :string, default: nil)

  def order_context(assigns) do
    ~H"""
    <ol class="rs-rollout-order" aria-label="Rule order">
      <li :for={entry <- @entries} data-current={to_string(entry.current?)}>
        <strong><%= entry.label %></strong>
        <span><%= entry.title %></span>
        <span :if={entry.current?}>Current rollout rule</span>
      </li>
    </ol>
    """
  end

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
        <ul aria-label="Observed assignments">
          <li :for={{variant, count} <- Enum.sort(@preview.variant_counts)}>
            <code><%= variant %></code>
            <span><%= count %>/<%= @preview.sample_size %></span>
          </li>
        </ul>
      </div>
    </section>
    """
  end

  attr(:status, :map, default: nil)
  attr(:missing_reason, :string, default: nil)
  attr(:definitions, :list, default: [])
  attr(:timeline_path, :string, required: true)

  def guardrail_status(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Guardrail status">
      <h2>Guardrail status</h2>

      <div :if={@definitions != []}>
        <p>Authored guardrail definitions for this rollout stage.</p>
        <ul>
          <li :for={definition <- @definitions}>
            <code><%= definition.signal_key %></code>
            <span><%= definition.threshold_operator %> <%= definition.threshold_value %></span>
            <span>Freshness: <%= definition.freshness_window_seconds %>s</span>
            <span>Sample: <%= definition.min_sample_size %> minimum</span>
            <span><%= definition.environment_scope %> / <%= definition.tenant_scope %></span>
          </li>
        </ul>
      </div>

      <div :if={@definitions == []}>
        <p>No guardrail definitions are authored for this rollout stage.</p>
      </div>

      <div :if={@status}>
        <p role="status"><strong><%= @status.state_label %></strong></p>
        <p><%= state_body(@status.state) %></p>
        <p :if={@status.reason}>Reason: <code><%= @status.reason %></code></p>
        <p :if={@status.effective_percentage}>Effective exposure: <strong><%= @status.effective_percentage %>%</strong></p>

        <h3>Thresholds and evidence</h3>
        <dl>
          <dt>Signal</dt>
          <dd><code><%= evidence_value(@status.evidence, :signal_key) %></code></dd>
          <dt>Threshold</dt>
          <dd><%= evidence_value(@status.evidence, :threshold_operator) %> <%= evidence_value(@status.evidence, :threshold_value) %></dd>
          <dt>Observed</dt>
          <dd><%= evidence_value(@status.evidence, :observed_value) %></dd>
          <dt>Freshness</dt>
          <dd><%= evidence_value(@status.evidence, :freshness_window_seconds) %>s</dd>
          <dt>Sample</dt>
          <dd><%= evidence_value(@status.evidence, :sample_size) %> / <%= evidence_value(@status.evidence, :min_sample_size) %></dd>
          <dt>Evidence reason</dt>
          <dd><code><%= evidence_value(@status.evidence, :reason) %></code></dd>
          <dt>Evaluated at</dt>
          <dd><%= evidence_value(@status.evidence, :evaluated_at) %></dd>
          <dt>Window</dt>
          <dd><%= @status.window_started_at %> to <%= @status.window_ends_at %></dd>
          <dt>Recorded at</dt>
          <dd><%= @status.occurred_at %></dd>
          <dt :if={@status.correlation_id}>Correlation</dt>
          <dd :if={@status.correlation_id}><code><%= @status.correlation_id %></code></dd>
        </dl>
      </div>

      <div :if={is_nil(@status) and @definitions != []}>
        <h3>No guardrail decision recorded</h3>
        <p role="alert">
          <%= missing_status_body(@missing_reason) %>
        </p>
      </div>

      <.link navigate={@timeline_path}>Open full timeline</.link>
    </section>
    """
  end

  attr(:current, :integer, required: true)
  attr(:target, :integer, required: true)
  attr(:reason, :string, default: "")

  def confirm_panel(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Risky jump confirmation">
      <h2>Risky jump requires confirmation</h2>
      <p>Publish risky jump from <strong><%= @current %>%</strong> to <strong><%= @target %>%</strong> only after reviewing the preview and recording why the ladder recommendation is being skipped.</p>

      <form aria-label="Risky jump confirmation form" phx-change="validate_confirmation">
        <label for="rollout-confirm-reason">Reason for risky jump</label>
        <textarea
          id="rollout-confirm-reason"
          name="confirmation[reason]"
          rows="4"
        ><%= @reason %></textarea>
      </form>

      <div class="rs-rollout-confirm__actions">
        <button type="button" phx-click="confirm_publish">Publish risky jump</button>
        <button type="button" phx-click="cancel_confirmation">Cancel</button>
      </div>
    </section>
    """
  end

  defp state_body(:healthy),
    do: "Valid guardrail evidence is inside threshold for this rollout stage."

  defp state_body("healthy"), do: state_body(:healthy)

  defp state_body(:pending_data),
    do:
      "Automation is waiting for valid guardrail evidence and will not assume the stage is healthy."

  defp state_body("pending_data"), do: state_body(:pending_data)

  defp state_body(:held),
    do:
      "Guardrail automation held this rollout fail-closed. Review the missing or stale signal before advancing."

  defp state_body("held"), do: state_body(:held)

  defp state_body(:rollback_triggered),
    do: "A confirmed threshold breach triggered rollback to the last stable rollout snapshot."

  defp state_body("rollback_triggered"), do: state_body(:rollback_triggered)

  defp state_body(_state),
    do:
      "Guardrail status could not be loaded. Keep the rollout unchanged, then retry from this mounted page or review the per-flag audit timeline."

  defp evidence_value(evidence, key) when is_map(evidence) do
    Map.get(evidence, key, Map.get(evidence, to_string(key), "n/a"))
  end

  defp evidence_value(_evidence, _key), do: "n/a"

  defp missing_status_body(_reason) do
    "This rollout stage has guardrail definitions, but no evaluated decision has been recorded for this environment yet. Wire the host signal provider or run the guarded evaluation before treating the stage as healthy."
  end

  attr(:mode, :atom,
    required: true,
    values: [
      :unavailable,
      :blocked_health,
      :config_incomplete,
      :ready,
      :pending_observation,
      :scheduled
    ]
  )

  attr(:policy, :map, default: nil)
  attr(:guardrail_status, :map, default: nil)
  attr(:guardrail_definitions, :list, default: [])
  attr(:scheduled_tick, :map, default: nil)
  attr(:protected_callout?, :boolean, default: false)
  attr(:approval_requirement, :map, default: nil)
  attr(:can_save?, :boolean, default: false)
  attr(:capability_denied_reason, :string, default: nil)
  attr(:form_error, :string, default: nil)
  attr(:rollout_rule_key, :string, default: nil)
  attr(:ladder_steps, :list, default: [])

  def auto_advance_panel(assigns) do
    assigns = assign(assigns, :policy_enabled, policy_enabled?(assigns.policy))

    ~H"""
    <section class="rs-card" aria-label="Auto-advance">
      <h2>Auto-advance</h2>

      <p role="status"><%= mode_body(@mode, @guardrail_status, @scheduled_tick) %></p>

      <div :if={@protected_callout?} class="rs-auto-advance-protected-callout">
        <p>
          When eligible, advancement submits a change request for approval — it will not auto-apply in this environment.
        </p>
      </div>

      <OperatorComponents.capability_explanation
        :if={!@can_save? && @capability_denied_reason}
        title="Auto-advance configuration requires advance permission"
        reason={@capability_denied_reason}
        tone="warning"
      />

      <form
        :if={@can_save? and @mode not in [:unavailable, :blocked_health]}
        id="auto-advance-form"
        aria-label="Auto-advance policy form"
        phx-submit="save_auto_advance_policy"
        phx-change="validate_auto_advance"
      >
        <input
          type="hidden"
          name="auto_advance[rule_key]"
          value={auto_advance_rule_key(@policy, @rollout_rule_key)}
        />
        <label>
          <input
            type="checkbox"
            name="auto_advance[enabled]"
            value="true"
            checked={@policy_enabled}
          />
          Enable auto-advance
        </label>

        <label>
          Observation window (seconds)
          <input
            type="number"
            name="auto_advance[observation_window_seconds]"
            min="1"
            value={policy_field(@policy, :observation_window_seconds)}
          />
        </label>

        <label>
          Next stage
          <input
            type="text"
            name="auto_advance[next_stage]"
            value={policy_field(@policy, :next_stage)}
          />
        </label>

        <label>
          Next percentage
          <input
            type="number"
            name="auto_advance[next_percentage]"
            min="0"
            max="100"
            value={policy_field(@policy, :next_percentage)}
          />
        </label>

        <p :if={@form_error} role="alert"><%= @form_error %></p>

        <button type="submit" disabled={@mode == :config_incomplete}>
          Save auto-advance policy
        </button>
      </form>

      <div :if={@mode in [:unavailable, :blocked_health]} class="rs-auto-advance-readonly-fields">
        <label>
          <input type="checkbox" disabled checked={@policy_enabled} />
          Enable auto-advance
        </label>
        <p>
          Observation window (seconds):
          <span><%= policy_field(@policy, :observation_window_seconds) %></span>
        </p>
        <p>
          Next stage: <span><%= policy_field(@policy, :next_stage) %></span>
        </p>
        <p>
          Next percentage: <span><%= policy_field(@policy, :next_percentage) %></span>
        </p>
      </div>

      <p :if={@ladder_steps != []}>
        Recommendations stay advisory; next stage and percentage are operator-authored.
        Suggested ladder: <%= Enum.join(@ladder_steps, ", ") %>%.
      </p>
    </section>
    """
  end

  defp policy_enabled?(nil), do: false

  defp policy_enabled?(policy) do
    Map.get(policy, :enabled) == true or Map.get(policy, "enabled") == true
  end

  defp auto_advance_rule_key(policy, rollout_rule_key) do
    case policy_field(policy, :rule_key) do
      "" -> rollout_rule_key || ""
      value -> value
    end
  end

  defp policy_field(nil, _key), do: ""

  defp policy_field(policy, key) do
    case Map.get(policy, key) || Map.get(policy, to_string(key)) do
      nil -> ""
      value -> to_string(value)
    end
  end

  defp mode_body(:unavailable, _status, _tick) do
    "Wire guardrails on this rollout rule before enabling auto-advance."
  end

  defp mode_body(:blocked_health, %{state: state}, _tick) when not is_nil(state) do
    state_body(state)
  end

  defp mode_body(:blocked_health, _status, _tick) do
    state_body(:held)
  end

  defp mode_body(:config_incomplete, _status, _tick) do
    "Enabling auto-advance requires an observation window, next stage, and next percentage."
  end

  defp mode_body(:ready, _status, _tick) do
    "Auto-advance is configured. Advancement runs when guardrail evidence is valid at window close."
  end

  defp mode_body(:pending_observation, %{window_ends_at: window_ends_at}, _tick)
       when not is_nil(window_ends_at) do
    "Observation window open until #{window_ends_at}. Auto-advance evaluates at window close."
  end

  defp mode_body(:pending_observation, _status, _tick) do
    "Observation window is open. Auto-advance evaluates at window close."
  end

  defp mode_body(:scheduled, _status, %{scheduled_for: scheduled_for})
       when not is_nil(scheduled_for) do
    "Advance scheduled for #{scheduled_for} if guardrails remain healthy."
  end

  defp mode_body(:scheduled, _status, _tick) do
    "Advance is scheduled if guardrails remain healthy."
  end

  defp mode_body(_mode, _status, _tick) do
    "Auto-advance status is unavailable for this rollout stage."
  end
end
