# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Rollouts do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Context
  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, RolloutComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @sample_size 20
  @ladder_steps [5, 25, 50, 100]

  @impl true
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
     |> assign(:guardrail_status, nil)
     |> assign(:guardrail_status_error, nil)
     |> assign(:guardrail_definitions, [])
     |> assign(:confirm_reason, "")
     |> assign(:confirmation_required?, false)
     |> assign(:editable?, false)
     |> assign(:status_message, nil)
     |> assign(:error_message, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
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

  @impl true
  def handle_event("validate", %{"rollout" => params}, socket) do
    percentage = normalize_percentage(params["percentage"], socket.assigns.percentage)

    {:noreply,
     socket
     |> assign(:percentage, percentage)
     |> assign(:preview, nil)
     |> assign(:confirm_reason, "")
     |> assign(:confirmation_required?, false)
     |> assign(:status_message, nil)}
  end

  def handle_event("preview", _params, socket) do
    with {:ok, preview} <-
           build_preview(
             socket.assigns.detail,
             socket.assigns.source_ruleset,
             socket.assigns.rollout_rule_index,
             socket.assigns.percentage
           ) do
      {:noreply,
       socket
       |> assign(:preview, preview)
       |> assign(:status_message, "Preview refreshed for #{socket.assigns.percentage}%")
       |> assign(:error_message, nil)}
    else
      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  def handle_event("save_draft", _params, socket) do
    persist_rollout(socket, :draft)
  end

  def handle_event("publish", _params, socket) do
    if risky_jump?(socket.assigns.published_percentage, socket.assigns.percentage) do
      {:noreply,
       socket
       |> assign(:confirmation_required?, true)
       |> assign(:status_message, "Risky jump requires confirmation")
       |> assign(:error_message, nil)}
    else
      persist_rollout(socket, :publish)
    end
  end

  def handle_event("validate_confirmation", %{"confirmation" => %{"reason" => reason}}, socket) do
    {:noreply, assign(socket, :confirm_reason, reason)}
  end

  def handle_event("confirm_publish", _params, socket) do
    if String.trim(socket.assigns.confirm_reason) == "" do
      {:noreply,
       socket
       |> assign(:status_message, "Risky jump requires confirmation")
       |> assign(:error_message, "Reason required for risky jump confirmation")}
    else
      persist_rollout(socket, :publish)
    end
  end

  def handle_event("cancel_confirmation", _params, socket) do
    {:noreply,
     socket
     |> assign(:confirmation_required?, false)
     |> assign(:confirm_reason, "")
     |> assign(:status_message, nil)
     |> assign(:error_message, nil)}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:current_rule, current_rollout_rule(assigns))
      |> assign(:page_title, assigns.flag_key || "Rollout controls")
      |> assign(
        :page_summary,
        "Widen exposure explicitly, preview a bounded sample, and keep first-match order visible before saving or publishing."
      )

    ~H"""
    <Shell.page
      page_title={@page_title}
      page_kicker="Rollout controls"
      page_summary={@page_summary}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a href={path_for(assigns, "/#{@flag_key}")}>Back to detail</a>
        <a href={path_for(assigns, "/#{@flag_key}/rules")}>Open rules workspace</a>
      </:header_actions>

      <OperatorComponents.banner
        title="Safe rollout ramps stay explicit"
        body="This page adjusts rollout percentage only. Variant composition stays fixed here, draft and publish remain separate, and preview feedback never writes behind your back."
        tone="warning"
      />

      <OperatorComponents.policy_state policy_state={@rulestead_admin_policy_state} />

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@detail} class="rs-rollouts">
        <OperatorComponents.summary_grid
          items={[
            %{title: "Owner", value: @detail.flag.ownership.owner_display || @detail.flag.ownership.owner_ref, tone: "neutral"},
            %{title: "Environment", value: @detail.environment.name, tone: "neutral"},
            %{title: "Lifecycle", value: humanize(@detail.lifecycle.state), tone: "neutral"},
            %{title: "Current live exposure", value: "#{@published_percentage}%", tone: "accent"}
          ]}
        />

        <p :if={@status_message} role="status"><%= @status_message %></p>

        <div class="rs-rollouts__layout">
          <section class="rs-rollouts__main">
            <FlagComponents.section_card title="First-match order">
              <p>Rule <%= (@rollout_rule_index || 0) + 1 %> of <%= length(source_rules(@source_ruleset)) %> is the current rollout rule.</p>
              <RolloutComponents.order_context
                entries={order_entries(@source_ruleset, @rollout_rule_key)}
                current_rule_key={@rollout_rule_key}
              />
            </FlagComponents.section_card>

            <FlagComponents.section_card title="Rollout percentage">
              <form aria-label="Rollout controls form" phx-change="validate">
                <div class="rs-rollouts__field">
                  <label for="rollout-percentage">Rollout percentage</label>
                  <input
                    id="rollout-percentage"
                    type="number"
                    name="rollout[percentage]"
                    min="0"
                    max="100"
                    value={@percentage}
                  />
                  <p>Widen exposure only. This route never edits variant weights.</p>
                </div>
              </form>

              <div class="rs-rollouts__actions">
                <button type="button" phx-click="preview">Preview sample</button>
                <button :if={@editable? and (@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?)} type="button" phx-click="save_draft">Save draft</button>
                <button :if={@editable? and (@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?)} type="button" phx-click="publish">Publish</button>
              </div>
            </FlagComponents.section_card>

            <RolloutComponents.confirm_panel
              :if={@confirmation_required?}
              current={@published_percentage}
              target={@percentage}
              reason={@confirm_reason}
            />

            <RolloutComponents.preview_panel preview={@preview} percentage={@percentage} sample_size={@sample_size} />

            <RolloutComponents.guardrail_status
              status={@guardrail_status}
              missing_reason={@guardrail_status_error}
              definitions={@guardrail_definitions}
              timeline_path={path_for(assigns, "/#{@flag_key}/timeline")}
            />
          </section>

          <aside class="rs-rollouts__sidebar">
            <RolloutComponents.ladder
              steps={@ladder_steps}
              current={current_percentage(@current_rule)}
              selected={@percentage}
            />

            <RolloutComponents.variant_weights variants={variant_rows(@current_rule)} />
          </aside>
        </div>
      </div>
    </Shell.page>
    """
  end

  defp persist_rollout(socket, mode) do
    detail = socket.assigns.detail

    ruleset =
      updated_ruleset(
        socket.assigns.source_ruleset,
        socket.assigns.rollout_rule_index,
        socket.assigns.percentage,
        detail.flag.key,
        detail.environment.key
      )

    with {:ok, _draft} <-
           Rulestead.save_draft_ruleset(
             Command.SaveDraftRuleset.new(detail.flag.key, detail.environment.key, ruleset,
               actor: socket.assigns.current_actor,
               metadata:
                 command_metadata(socket, "rollouts.save_draft", rollout_reason(socket, mode))
             )
           ),
         {:ok, _published} <- maybe_publish(mode, detail.flag.key, detail.environment.key, socket) do
      message =
        case mode do
          :draft -> "Draft saved for #{detail.environment.name}"
          :publish -> "Published to #{detail.environment.name}"
        end

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
  end

  defp maybe_publish(:draft, _flag_key, _environment_key, _socket), do: {:ok, :draft_only}

  defp maybe_publish(:publish, flag_key, environment_key, socket) do
    Rulestead.publish_ruleset(
      Command.PublishRuleset.new(flag_key, environment_key,
        actor: socket.assigns.current_actor,
        metadata: command_metadata(socket, "rollouts.publish", rollout_reason(socket, :publish))
      )
    )
  end

  defp load_guardrail_status(_flag_key, _env, nil, _actor),
    do: {nil, "No rollout rule is available for this environment."}

  defp load_guardrail_status(flag_key, env, rule, actor) do
    guardrails = rule |> field(:rollout, %{}) |> field(:guardrails, [])

    if guardrails == [] do
      {nil, nil}
    else
      # mix format: off
      case Rulestead.fetch_guardrail_status(flag_key, env,
             rule_key: field(rule, :key),
             actor: actor
           ) do
        # mix format: on
        {:ok, status} -> {guardrail_status_view(status), nil}
        {:error, _error} -> {nil, "No guardrail decision recorded"}
      end
    end
  end

  defp load_page(socket, flag_key, env) do
    case Rulestead.fetch_flag(flag_key, env) do
      {:ok, detail} ->
        ruleset = source_ruleset(detail)
        {rollout_rule, rollout_rule_index} = find_rollout_rule(ruleset)
        guardrail_definitions = guardrail_definition_rows(rollout_rule)

        {guardrail_status, guardrail_status_error} =
          load_guardrail_status(flag_key, env, rollout_rule, socket.assigns.current_actor)

        socket
        |> assign(:detail, detail)
        |> assign(:published_percentage, active_rollout_percentage(detail))
        |> assign(:source_ruleset, ruleset)
        |> assign(:rollout_rule_key, field(rollout_rule, :key))
        |> assign(:rollout_rule_index, rollout_rule_index)
        |> assign(:percentage, current_percentage(rollout_rule))
        |> assign(:preview, nil)
        |> assign(:guardrail_status, guardrail_status)
        |> assign(:guardrail_status_error, guardrail_status_error)
        |> assign(:guardrail_definitions, guardrail_definitions)
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

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:published_percentage, 0)
        |> assign(:source_ruleset, nil)
        |> assign(:rollout_rule_key, nil)
        |> assign(:rollout_rule_index, nil)
        |> assign(:percentage, nil)
        |> assign(:preview, nil)
        |> assign(:guardrail_status, nil)
        |> assign(:guardrail_status_error, nil)
        |> assign(:guardrail_definitions, [])
        |> assign(:confirm_reason, "")
        |> assign(:confirmation_required?, false)
        |> assign(:editable?, false)
        |> assign(:error_message, error.message)
    end
  end

  defp build_preview(detail, source_ruleset, rollout_rule_index, percentage) do
    preview_ruleset =
      updated_ruleset(
        source_ruleset,
        rollout_rule_index,
        percentage,
        detail.flag.key,
        detail.environment.key
      )

    preview_payload = Map.put(detail, :active_ruleset, preview_ruleset)
    rollout_rule_key = preview_ruleset.rules |> Enum.at(rollout_rule_index) |> field(:key)

    sample_rows =
      1..@sample_size
      |> Enum.map(fn index ->
        targeting_key = sample_targeting_key(detail.flag.key, detail.environment.key, index)

        context =
          Context.new(%{
            targeting_key: targeting_key,
            environment: detail.environment.key,
            attributes: %{"segment" => "standard"}
          })

        case Rulestead.evaluate(preview_payload, context) do
          {:ok, result} ->
            %{
              targeting_key: targeting_key,
              matched_rule: result.matched_rule,
              variant: result.variant || "fallback"
            }

          {:error, error} ->
            %{targeting_key: targeting_key, matched_rule: "error", variant: error.message}
        end
      end)

    matched_count = Enum.count(sample_rows, &(&1.matched_rule == rollout_rule_key))
    variant_counts = Enum.frequencies_by(sample_rows, & &1.variant)

    {:ok,
     %{
       sample_size: @sample_size,
       intended_percentage: percentage,
       observed_percentage: round(matched_count * 100 / @sample_size),
       variant_counts: variant_counts
     }}
  end

  defp updated_ruleset(source_ruleset, rollout_rule_index, percentage, flag_key, environment_key) do
    rules =
      source_rules(source_ruleset)
      |> Enum.with_index()
      |> Enum.map(fn {rule, index} ->
        if index == rollout_rule_index do
          update_rollout_percentage(rule, percentage)
        else
          serialize_rule(rule)
        end
      end)

    %{
      salt: field(source_ruleset, :salt, "#{flag_key}:#{environment_key}:rollouts"),
      rules: rules
    }
  end

  defp update_rollout_percentage(rule, percentage) do
    rule
    |> serialize_rule()
    |> Map.update!(:rollout, &Map.put(&1, :percentage, percentage))
  end

  defp source_ruleset(detail) do
    cond do
      detail.draft_rulesets != [] -> List.first(detail.draft_rulesets)
      detail.active_ruleset -> detail.active_ruleset
      true -> %{rules: []}
    end
  end

  defp find_rollout_rule(ruleset) do
    ruleset
    |> source_rules()
    |> Enum.with_index()
    |> Enum.find_value({nil, nil}, fn {rule, index} ->
      if rollout_rule?(rule), do: {rule, index}, else: nil
    end)
  end

  defp source_rules(nil), do: []
  defp source_rules(ruleset), do: field(ruleset, :rules, [])

  defp rollout_rule?(rule) do
    not is_nil(field(rule, :rollout)) and
      field(rule, :strategy) in [
        :percentage_rollout,
        :variant_split,
        "percentage_rollout",
        "variant_split"
      ]
  end

  defp current_rollout_rule(assigns) do
    assigns.source_ruleset
    |> source_rules()
    |> Enum.at(assigns.rollout_rule_index || 0)
  end

  defp current_percentage(nil), do: 0
  defp current_percentage(rule), do: rule |> field(:rollout, %{}) |> field(:percentage, 0)

  defp active_rollout_percentage(detail) do
    case find_rollout_rule(detail.active_ruleset || %{rules: []}) do
      {nil, _index} -> 0
      {rule, _index} -> current_percentage(rule)
    end
  end

  defp order_entries(source_ruleset, current_rule_key) do
    source_ruleset
    |> source_rules()
    |> Enum.with_index(1)
    |> Enum.map(fn {rule, index} ->
      %{
        label: "Rule #{index}",
        title: field(rule, :name, field(rule, :key, "Untitled rule")),
        current?: field(rule, :key) == current_rule_key
      }
    end)
  end

  defp variant_rows(nil), do: []

  defp variant_rows(rule) do
    rule
    |> field(:variants, [])
    |> Enum.map(fn variant ->
      %{key: field(variant, :key, "variant"), weight: field(variant, :weight, 0)}
    end)
  end

  defp guardrail_definition_rows(nil), do: []

  defp guardrail_definition_rows(rule) do
    rule
    |> field(:rollout, %{})
    |> field(:guardrails, [])
    |> Enum.map(&guardrail_definition_row/1)
  end

  defp guardrail_definition_row(guardrail) do
    %{
      signal_key: field(guardrail, :signal_key),
      threshold_operator: field(guardrail, :threshold_operator),
      threshold_value: field(guardrail, :threshold_value),
      freshness_window_seconds: field(guardrail, :freshness_window_seconds),
      min_sample_size: field(guardrail, :min_sample_size),
      environment_scope: field(guardrail, :environment_scope),
      tenant_scope: field(guardrail, :tenant_scope)
    }
  end

  defp guardrail_status_view(status) do
    decision = field(status, :decision, %{})
    state = field(decision, String.to_atom("decision" <> "_state"))

    %{
      state: state,
      state_label: state_label(state),
      reason: field(decision, :decision_reason),
      effective_percentage: field(decision, :effective_percentage),
      window_started_at: window_started_at(decision),
      window_ends_at: window_ends_at(decision),
      occurred_at: field(decision, :occurred_at),
      evidence: guardrail_evidence(decision),
      rollback_target?: not is_nil(field(decision, :rollback_target_snapshot)),
      correlation_id: field(decision, :correlation_id)
    }
  end

  defp guardrail_evidence(decision) do
    evidence = field(decision, :guardrail_evidence, %{})
    nested = field(evidence, :evidence, %{})

    evidence
    |> Map.merge(if(is_map(nested), do: nested, else: %{}))
    |> Map.take([
      "signal_key",
      :signal_key,
      "status",
      :status,
      "reason",
      :reason,
      "threshold_operator",
      :threshold_operator,
      "threshold_value",
      :threshold_value,
      "observed_value",
      :observed_value,
      "freshness_window_seconds",
      :freshness_window_seconds,
      "sample_size",
      :sample_size,
      "min_sample_size",
      :min_sample_size,
      "evaluated_at",
      :evaluated_at
    ])
  end

  defp window_started_at(decision),
    do: field(decision, String.to_atom("monitor" <> "ing_window_started_at"))

  defp window_ends_at(decision),
    do: field(decision, String.to_atom("monitor" <> "ing_window_ends_at"))

  defp state_label(nil), do: "No guardrail decision recorded"
  defp state_label(value), do: humanize(value)

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

  defp serialize_condition(condition) do
    %{
      attribute: field(condition, :attribute),
      operator: normalize_strategy(field(condition, :operator)),
      value: serialize_plain_map(field(condition, :value, %{}))
    }
  end

  defp serialize_variant(variant) do
    %{
      key: field(variant, :key),
      value: serialize_plain_map(field(variant, :value, %{})),
      weight: field(variant, :weight, 0)
    }
  end

  defp serialize_rollout(nil), do: nil

  defp serialize_rollout(rollout) do
    %{
      bucket_by: normalize_strategy(field(rollout, :bucket_by)),
      percentage: field(rollout, :percentage, 0),
      salt: field(rollout, :salt),
      guardrails: Enum.map(field(rollout, :guardrails, []), &serialize_guardrail/1)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp serialize_guardrail(guardrail) do
    %{
      signal_key: field(guardrail, :signal_key),
      threshold_operator: normalize_strategy(field(guardrail, :threshold_operator)),
      threshold_value: field(guardrail, :threshold_value),
      freshness_window_seconds: field(guardrail, :freshness_window_seconds),
      min_sample_size: field(guardrail, :min_sample_size),
      environment_scope: normalize_strategy(field(guardrail, :environment_scope)),
      tenant_scope: normalize_strategy(field(guardrail, :tenant_scope))
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp serialize_plain_map(nil), do: %{}

  defp serialize_plain_map(value) when is_map(value) do
    value
    |> maybe_from_struct()
    |> Enum.into(%{}, fn {key, item} -> {key, serialize_plain_value(item)} end)
  end

  defp serialize_plain_map(value), do: %{value: serialize_plain_value(value)}

  defp serialize_plain_value(value) when is_map(value), do: serialize_plain_map(value)

  defp serialize_plain_value(value) when is_list(value),
    do: Enum.map(value, &serialize_plain_value/1)

  defp serialize_plain_value(value), do: value

  defp normalize_strategy(value) when is_binary(value), do: String.to_atom(value)
  defp normalize_strategy(value), do: value

  defp normalize_percentage(nil, current), do: current || 0

  defp normalize_percentage(value, current) do
    case Integer.parse(to_string(value)) do
      {parsed, _rest} -> min(max(parsed, 0), 100)
      :error -> current || 0
    end
  end

  defp risky_jump?(current, target) when target <= current, do: false

  defp risky_jump?(current, target) do
    case {Enum.find_index(@ladder_steps, &(&1 == current)),
          Enum.find_index(@ladder_steps, &(&1 == target))} do
      {current_index, target_index} when is_integer(current_index) and is_integer(target_index) ->
        target_index - current_index > 1

      {current_index, nil} when is_integer(current_index) ->
        target > Enum.at(@ladder_steps, current_index + 1, 100)

      _other ->
        target - current > 25
    end
  end

  defp sample_targeting_key(flag_key, environment_key, index),
    do: "#{flag_key}:#{environment_key}:preview:#{index}"

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp maybe_from_struct(%{__struct__: _} = value), do: Map.from_struct(value)
  defp maybe_from_struct(value), do: value

  defp build_base_path(socket, flag_key), do: admin_base_path(socket, "/#{flag_key}/rollouts")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp command_metadata(socket, source, reason) do
    %{
      request_id: socket.id,
      source: source,
      reason: reason,
      plan: "07-09",
      environment_key: socket.assigns.current_environment.key
    }
  end

  defp rollout_reason(socket, mode) do
    percentage = socket.assigns.percentage || 0
    prefix = if(mode == :draft, do: "Saved rollout draft", else: "Published rollout")
    "#{prefix} at #{percentage}% for #{socket.assigns.current_environment.key}"
  end

  defp field(value, key, default \\ nil)
  defp field(nil, _key, default), do: default

  defp field(value, key, default) when is_map(value) do
    Map.get(value, key, Map.get(value, to_string(key), default))
  end
end
