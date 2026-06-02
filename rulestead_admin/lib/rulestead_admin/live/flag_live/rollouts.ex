# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Rollouts do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Context
  alias Rulestead.Admin.Authorizer
  alias Rulestead.Admin.Redaction
  alias Rulestead.Governance.RolloutAutoAdvance
  alias Rulestead.Promotion.Compare
  alias Rulestead.Store.Command

  alias RulesteadAdmin.Components.{
    AuditComponents,
    FlagComponents,
    OperatorComponents,
    RolloutComponents,
    Shell
  }

  alias RulesteadAdmin.Live.Session

  @sample_size 20
  @ladder_steps [5, 25, 50, 100]
  @strategy_atoms %{
    "forced_value" => :forced_value,
    "percentage_rollout" => :percentage_rollout,
    "variant_split" => :variant_split,
    "equals" => :equals,
    "in" => :in,
    "not_in" => :not_in,
    "gt" => :gt,
    "lt" => :lt,
    "gte" => :gte,
    "lte" => :lte,
    "subject" => :subject,
    "environment" => :environment,
    "required" => :required
  }

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
     |> assign(:guardrail_interventions, [])
     |> assign(:auto_advance_policy, nil)
     |> assign(:auto_advance_scheduled_tick, nil)
     |> assign(:auto_advance_mode, :unavailable)
     |> assign(:auto_advance_protected_callout?, false)
     |> assign(:auto_advance_approval_requirement, nil)
     |> assign(:auto_advance_can_save?, false)
     |> assign(:auto_advance_capability_denied_reason, nil)
     |> assign(:auto_advance_form_error, nil)
     |> assign(:confirm_reason, "")
     |> assign(:confirmation_required?, false)
     |> assign(:editable?, false)
     |> assign(:status_message, nil)
     |> assign(:error_message, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"key" => flag_key}, _uri, socket) do
    env = socket.assigns.current_environment.key
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

  def handle_event("preview", _params, %{assigns: %{editable?: false}} = socket) do
    {:noreply,
     assign(socket, :error_message, "No rollout rule is available for this environment.")}
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

  def handle_event("validate_auto_advance", %{"auto_advance" => params}, socket) do
    attrs = parse_auto_advance_params(params)

    error =
      case validate_auto_advance_policy(attrs) do
        :ok -> nil
        {:error, msg} -> msg
      end

    {:noreply, assign(socket, :auto_advance_form_error, error)}
  end

  def handle_event("save_auto_advance_policy", %{"auto_advance" => params}, socket) do
    attrs =
      params
      |> parse_auto_advance_params()
      |> ensure_auto_advance_rule_key(socket.assigns.rollout_rule_key)

    flag_key = socket.assigns.flag_key
    env = socket.assigns.current_environment.key

    with :ok <- authorize_advance_rollout(socket),
         :ok <- validate_auto_advance_policy(attrs),
         {:ok, _} <-
           Rulestead.upsert_rollout_auto_advance_policy(flag_key, env, attrs,
             actor: socket.assigns.current_actor,
             reason: params["reason"] || "Auto-advance policy updated from rollouts page",
             metadata:
               command_metadata(socket, "rollouts.save_auto_advance_policy", %{
                 enabled: attrs.enabled,
                 observation_window_seconds: attrs.observation_window_seconds,
                 next_stage: attrs.next_stage,
                 next_percentage: attrs.next_percentage
               })
           ) do
      {:noreply,
       socket
       |> assign(:status_message, "Auto-advance policy saved.")
       |> assign(:auto_advance_form_error, nil)
       |> assign(:error_message, nil)
       |> load_page(flag_key, env)}
    else
      {:error, :unauthorized} ->
        {:noreply,
         assign(socket, :error_message, "Advance permission required to configure auto-advance.")}

      {:error, %Rulestead.Error{} = error} ->
        {:noreply, assign(socket, :error_message, error.message)}

      {:error, message} when is_binary(message) ->
        {:noreply, assign(socket, :auto_advance_form_error, message)}
    end
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
      base_path={@rulestead_admin_mount_path}
      current_section={:flags}
      breadcrumbs={[
        %{label: "Flags", path: @rulestead_admin_mount_path <> "/flags?env=" <> @current_environment.key},
        %{label: @flag_key, path: @rulestead_admin_mount_path <> "/" <> @flag_key <> "?env=" <> @current_environment.key},
        %{label: "Rollouts", path: @rulestead_admin_mount_path <> "/" <> @flag_key <> "/rollouts?env=" <> @current_environment.key}
      ]}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      env_context_help="Shows this flag key's rollout state in the selected environment. Promotion uses Compare."
      policy_state={@rulestead_admin_policy_state}
    >
      <:header_actions>
        <a href={path_for(assigns, "/#{@flag_key}")}>Back to flag</a>
        <a href={path_for(assigns, "/#{@flag_key}/rules")}>Open rules workspace</a>
      </:header_actions>

      <OperatorComponents.banner
        title="Safe rollout ramps stay explicit"
        body="This page adjusts rollout percentage only. Variant composition stays fixed here, draft and publish remain separate, and preview feedback never writes behind your back."
        tone="warning"
      />

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
                <button :if={@editable?} type="button" phx-click="preview">Preview sample</button>
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
              form_error={@auto_advance_form_error}
              rollout_rule_key={@rollout_rule_key}
              ladder_steps={@ladder_steps}
            />

            <section class="rs-card" aria-label="Guardrail interventions">
              <h2>Guardrail interventions</h2>
              <p :if={@guardrail_interventions == []}>
                No guardrail intervention events are available for this rollout stage yet.
              </p>
              <div :for={entry <- @guardrail_interventions}>
                <AuditComponents.timeline_row entry={entry} />
              </div>
              <a href={path_for(assigns, "/#{@flag_key}/timeline")}>Open full timeline</a>
            </section>
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

        guardrail_interventions =
          load_guardrail_interventions(flag_key, env, socket.assigns.current_actor)

        socket =
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
          |> assign(:guardrail_interventions, guardrail_interventions)
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
          |> assign_auto_advance_load(
            flag_key,
            env,
            field(rollout_rule, :key),
            guardrail_definitions,
            guardrail_status
          )

        socket

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
        |> assign(:guardrail_interventions, [])
        |> assign_auto_advance_defaults()
        |> assign(:confirm_reason, "")
        |> assign(:confirmation_required?, false)
        |> assign(:editable?, false)
        |> assign(:error_message, error.message)
    end
  end

  defp assign_auto_advance_defaults(socket) do
    socket
    |> assign(:auto_advance_policy, nil)
    |> assign(:auto_advance_scheduled_tick, nil)
    |> assign(:auto_advance_mode, :unavailable)
    |> assign(:auto_advance_protected_callout?, false)
    |> assign(:auto_advance_approval_requirement, nil)
    |> assign(:auto_advance_can_save?, false)
    |> assign(:auto_advance_capability_denied_reason, nil)
    |> assign(:auto_advance_form_error, nil)
  end

  defp assign_auto_advance_load(
         socket,
         flag_key,
         env,
         rollout_rule_key,
         definitions,
         guardrail_status
       ) do
    if is_nil(rollout_rule_key) do
      assign_auto_advance_defaults(socket)
    else
      actor = socket.assigns.current_actor
      resource = %{resource_type: "flag", resource_key: flag_key}
      policy = fetch_auto_advance_policy(flag_key, env, rollout_rule_key)
      scheduled_tick = fetch_auto_advance_scheduled_tick(flag_key, env, rollout_rule_key)
      now = auto_advance_now()

      approval_requirement =
        Authorizer.approval_requirement(actor, :advance_rollout, resource, env)

      protected_callout? =
        Compare.protected_target?(env) or approval_requirement.change_request_required?

      {auth_ok?, capability_denied_reason} =
        case Authorizer.authorize(actor, :advance_rollout, resource, env) do
          :ok -> {true, nil}
          {:error, error, _} -> {false, format_capability_denied_reason(error)}
        end

      mode =
        derive_auto_advance_mode(definitions, guardrail_status, policy, scheduled_tick, now)

      can_save? = auth_ok? and mode not in [:unavailable, :blocked_health]

      socket
      |> assign(:auto_advance_policy, policy)
      |> assign(:auto_advance_scheduled_tick, scheduled_tick)
      |> assign(:auto_advance_mode, mode)
      |> assign(:auto_advance_protected_callout?, protected_callout?)
      |> assign(:auto_advance_approval_requirement, approval_requirement)
      |> assign(:auto_advance_can_save?, can_save?)
      |> assign(:auto_advance_capability_denied_reason, capability_denied_reason)
    end
  end

  defp fetch_auto_advance_policy(flag_key, env, rollout_rule_key) do
    case Rulestead.fetch_rollout_auto_advance_policy(flag_key, env, rollout_rule_key) do
      {:ok, %{policy: policy}} -> policy
      {:ok, policy} when is_map(policy) -> policy
      {:error, error} -> if auto_advance_policy_not_found?(error), do: nil, else: nil
    end
  end

  defp auto_advance_policy_not_found?(%{message: "rollout_auto_advance_policy_not_found"}),
    do: true

  defp auto_advance_policy_not_found?(_), do: false

  defp fetch_auto_advance_scheduled_tick(flag_key, env, rollout_rule_key) do
    case Rulestead.list_scheduled_executions(
           resource_key: flag_key,
           environment_key: env,
           action: :advance_rollout,
           state: "scheduled",
           limit: 10
         ) do
      {:ok, page} ->
        page.entries
        |> Enum.filter(fn tick ->
          RolloutAutoAdvance.automation_tick?(Map.get(tick, :metadata) || %{})
        end)
        |> Enum.find(fn tick ->
          get_in(tick.command_snapshot, ["rollout", "rule_key"]) == rollout_rule_key or
            get_in(tick.command_snapshot, [:rollout, :rule_key]) == rollout_rule_key
        end)

      _ ->
        nil
    end
  end

  defp derive_auto_advance_mode(definitions, guardrail_status, policy, scheduled_tick, now) do
    cond do
      definitions == [] ->
        :unavailable

      guardrail_status &&
          guardrail_status.state in [:held, :pending_data, :rollback_triggered] ->
        :blocked_health

      policy_enabled?(policy) && policy_incomplete?(policy) ->
        :config_incomplete

      not is_nil(scheduled_tick) ->
        :scheduled

      policy_enabled?(policy) && window_open?(guardrail_status, now) ->
        :pending_observation

      true ->
        :ready
    end
  end

  defp policy_enabled?(nil), do: false

  defp policy_enabled?(policy) do
    field(policy, :enabled) == true
  end

  defp policy_incomplete?(policy) do
    policy_enabled?(policy) and
      (blank_policy_field?(policy, :observation_window_seconds) or
         blank_policy_field?(policy, :next_stage) or
         blank_policy_field?(policy, :next_percentage))
  end

  defp blank_policy_field?(policy, key) do
    case field(policy, key) do
      nil -> true
      "" -> true
      0 when key in [:observation_window_seconds, :next_percentage] -> true
      _ -> false
    end
  end

  defp window_open?(%{window_ends_at: %DateTime{} = window_ends_at}, %DateTime{} = now) do
    DateTime.compare(window_ends_at, now) == :gt
  end

  defp window_open?(_, _), do: false

  defp auto_advance_now do
    case Application.get_env(:rulestead, :admin_lifecycle) do
      %{now: %DateTime{} = now} ->
        now

      _ ->
        case Application.get_env(:rulestead, :store) do
          Rulestead.Fake -> Rulestead.Fake.Control.now!()
          _ -> DateTime.utc_now()
        end
    end
  end

  defp format_capability_denied_reason(error) do
    case error do
      %{message: message} when is_binary(message) -> message
      _ -> "Advance rollout is not permitted for this actor in this environment."
    end
  end

  defp parse_auto_advance_params(params) do
    enabled = params["enabled"] in ["true", true, "on"]

    %{
      rule_key: params["rule_key"],
      enabled: enabled,
      observation_window_seconds: parse_int(params["observation_window_seconds"]),
      next_stage: blank_to_nil(params["next_stage"]),
      next_percentage: parse_int(params["next_percentage"])
    }
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, _} -> parsed
      :error -> nil
    end
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(_), do: nil

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp blank_to_nil(value), do: value

  defp authorize_advance_rollout(socket) do
    actor = socket.assigns.current_actor
    env = socket.assigns.current_environment.key
    resource = %{resource_type: "flag", resource_key: socket.assigns.flag_key}

    case Authorizer.authorize(actor, :advance_rollout, resource, env) do
      :ok -> :ok
      {:error, _, _} -> {:error, :unauthorized}
    end
  end

  defp ensure_auto_advance_rule_key(attrs, rollout_rule_key) do
    if blank?(attrs.rule_key) and is_binary(rollout_rule_key) and rollout_rule_key != "" do
      Map.put(attrs, :rule_key, rollout_rule_key)
    else
      attrs
    end
  end

  defp validate_auto_advance_policy(%{enabled: false}), do: :ok
  defp validate_auto_advance_policy(%{enabled: nil}), do: :ok

  defp validate_auto_advance_policy(attrs) do
    cond do
      not positive_int?(attrs.observation_window_seconds) ->
        {:error, "Observation window must be greater than zero when auto-advance is enabled."}

      blank?(attrs.next_stage) ->
        {:error, "Next stage is required when auto-advance is enabled."}

      not percentage_in_range?(attrs.next_percentage) ->
        {:error, "Next percentage must be between 0 and 100 when auto-advance is enabled."}

      true ->
        :ok
    end
  end

  defp positive_int?(value) when is_integer(value) and value > 0, do: true
  defp positive_int?(_), do: false

  defp percentage_in_range?(value) when is_integer(value) and value >= 0 and value <= 100,
    do: true

  defp percentage_in_range?(_), do: false

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_), do: false

  defp load_guardrail_interventions(flag_key, env, actor) do
    case Rulestead.list_audit_events(flag_key: flag_key, environment_key: env, actor: actor) do
      {:ok, page} ->
        page.entries
        |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
        |> Enum.filter(&intervention_event?/1)
        |> Enum.map(&intervention_entry_view/1)
        |> Enum.take(5)

      {:error, _error} ->
        []
    end
  end

  defp intervention_event?(%{event_type: event_type}) do
    event_type in [
      "rollout.guardrail_held",
      "rollout.guardrail_rollback",
      "rollout.guardrail_evaluated",
      "rollout.advance",
      "ruleset.publish"
    ]
  end

  defp intervention_entry_view(event) do
    metadata = intervention_redacted_metadata(event.metadata)
    before_state = metadata["before"] || %{}
    after_state = metadata["after"] || %{}
    diff_state = metadata["diff"] || %{}

    %{
      id: event.id,
      title: intervention_title_for(event),
      meta: intervention_meta_for(event),
      summary: intervention_summary_for(event, metadata, before_state, after_state, diff_state),
      reason: event.reason,
      automatic?: guardrail_automation_event?(event),
      source_label: source_label(metadata),
      raw: %{
        event:
          Map.take(event, [
            :event_type,
            :result,
            :resource_key,
            :environment_key,
            :actor_display,
            :occurred_at
          ]),
        metadata: metadata
      },
      result: event.result,
      rollback_of_event_id: metadata["rollback_of_event_id"],
      rollback_allowed?: false,
      show_diff?: false
    }
  end

  defp intervention_redacted_metadata(metadata) do
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
        "guardrail.signal_key",
        "guardrail.environment_key",
        "guardrail.tenant_key",
        "guardrail.status",
        "guardrail.reason",
        "guardrail.threshold_operator",
        "guardrail.threshold_value",
        "guardrail.observed_value",
        "guardrail.freshness_window_seconds",
        "guardrail.sample_size",
        "guardrail.min_sample_size",
        "guardrail.evaluated_at",
        "links.guardrail_decision_id",
        "links.stable_guardrail_decision_id",
        "rollback_of_event_id",
        "links.inverse_event_type",
        "source",
        "request_id",
        "context.source",
        "context.eligibility",
        "context.scheduled_execution_id",
        "context.observation_window_started_at",
        "context.observation_window_ends_at",
        "context.observation_window_seconds",
        "context.eligibility.policy_snapshot",
        "context.eligibility.policy_snapshot.next_stage",
        "context.eligibility.policy_snapshot.next_percentage",
        "context.eligibility.policy_snapshot.observation_window_seconds",
        "links.scheduled_execution_id",
        "links.change_request_id"
      ]
    )
    |> Map.fetch!(:audit)
  end

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

  defp source_label(metadata), do: metadata["source"]

  defp intervention_title_for(%{event_type: "rollout.guardrail_held"}),
    do: "Automatic guardrail hold"

  defp intervention_title_for(%{event_type: "rollout.guardrail_rollback"}),
    do: "Automatic guardrail rollback"

  defp intervention_title_for(%{event_type: "rollout.guardrail_evaluated"}),
    do: "Guardrail evaluated"

  defp intervention_title_for(%{event_type: "rollout.advance"} = event) do
    if guardrail_automation_event?(event),
      do: "Automatic rollout advance",
      else: humanize_event("rollout.advance")
  end

  defp intervention_title_for(%{event_type: event_type}), do: humanize_event(event_type)

  defp intervention_meta_for(event) do
    actor = event.actor_display || event.actor_id || "Unknown actor"
    result = event.result |> to_string() |> String.upcase()

    time =
      if(event.occurred_at,
        do: Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S UTC"),
        else: "Unknown time"
      )

    "#{actor} • #{event.environment_key} • #{result} • #{time}"
  end

  defp intervention_summary_for(
         %{event_type: "rollout.guardrail_held"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state
       ) do
    append_reason(
      "Guardrail automation held this rollout fail-closed. Review the missing or stale signal before advancing.",
      event
    )
  end

  defp intervention_summary_for(
         %{event_type: "rollout.guardrail_rollback"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state
       ) do
    append_reason(
      "A confirmed threshold breach triggered rollback to the last stable rollout snapshot.",
      event
    )
  end

  defp intervention_summary_for(
         %{event_type: "rollout.guardrail_evaluated"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state
       ) do
    append_reason(
      "Automation is waiting for valid guardrail evidence and will not assume the stage is healthy.",
      event
    )
  end

  defp intervention_summary_for(
         %{event_type: "ruleset.publish"},
         _metadata,
         _before_state,
         _after_state,
         diff_state
       ) do
    "Ruleset publish updated ordered rule positions: #{Enum.join(diff_lines("ruleset.publish", diff_state), "; ")}."
  end

  defp intervention_summary_for(
         %{event_type: "rollout.advance"} = event,
         metadata,
         before_state,
         after_state,
         _diff_state
       ) do
    if guardrail_automation_event?(event) do
      automatic_rollout_advance_summary(metadata, before_state, after_state)
    else
      "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
    end
  end

  defp intervention_summary_for(event, _metadata, before_state, after_state, _diff_state) do
    "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
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
    state = field(decision, :decision_state)

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

  defp window_started_at(decision), do: field(decision, :monitoring_window_started_at)

  defp window_ends_at(decision), do: field(decision, :monitoring_window_ends_at)

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

  defp normalize_strategy(value) when is_binary(value), do: Map.get(@strategy_atoms, value, value)
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

  defp diff_lines("ruleset.publish", %{"rules" => rules}) when is_list(rules) do
    Enum.map(rules, fn rule ->
      "#{rule["key"]} from #{inspect(rule["from"])} to #{inspect(rule["to"])}"
    end)
  end

  defp diff_lines(_event_type, _diff_state), do: []

  defp state_summary(state) when map_size(state) == 0, do: "no recorded state"

  defp state_summary(state) do
    rules = Map.get(state, "rules") || Map.get(state, :rules)

    if is_list(rules) and rules != [] do
      rules
      |> Enum.map_join(", ", fn rule ->
        "#{rule["key"] || rule[:key]} @ #{rule["position"] || rule[:position]}"
      end)
    else
      status = state["status"] || state[:status] || "unknown"
      variant = state["kill_switch_variant_key"] || state[:kill_switch_variant_key] || "none"
      "status #{status}, kill variant #{variant}"
    end
  end

  defp humanize_event(event_type) do
    event_type
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp automatic_rollout_advance_summary(metadata, before_state, after_state) do
    context = metadata["context"] || metadata[:context] || %{}
    eligibility = context["eligibility"] || context[:eligibility] || %{}
    snapshot = eligibility["policy_snapshot"] || eligibility[:policy_snapshot] || %{}

    stage = snapshot["next_stage"] || snapshot[:next_stage]
    percentage = snapshot["next_percentage"] || snapshot[:next_percentage]

    {stage, percentage} =
      if present?(stage) do
        {stage, percentage}
      else
        advance_target_from_rules(after_state) || advance_target_from_rules(before_state) ||
          {nil, nil}
      end

    window_ends =
      context["observation_window_ends_at"] || context[:observation_window_ends_at]

    base =
      cond do
        present?(stage) and present?(percentage) ->
          "Advanced to #{stage} at #{percentage}%"

        present?(stage) ->
          "Advanced to #{stage}"

        true ->
          "Automatic rollout advanced"
      end

    if present?(window_ends) do
      "#{base} after observation window closed at #{format_observation_timestamp(window_ends)}."
    else
      "#{base} after observation window closed."
    end
  end

  defp advance_target_from_rules(state) do
    rules = Map.get(state, "rules") || Map.get(state, :rules) || []

    case List.first(rules) do
      %{} = rule ->
        rollout = Map.get(rule, "rollout") || Map.get(rule, :rollout) || %{}
        stage = Map.get(rollout, "stage") || Map.get(rollout, :stage)
        percentage = Map.get(rollout, "percentage") || Map.get(rollout, :percentage)
        if present?(stage), do: {stage, percentage}, else: nil

      _ ->
        nil
    end
  end

  defp format_observation_timestamp(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")

  defp format_observation_timestamp(value) when is_binary(value), do: value
  defp format_observation_timestamp(_), do: "closed"

  defp present?(value), do: not is_nil(value) and value != ""

  defp append_reason(summary, %{reason: reason}) when is_binary(reason) and reason != "",
    do: "#{summary} Reason: #{reason}"

  defp append_reason(summary, _event), do: summary

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
