# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Rules do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.{OperatorComponents, RuleEditorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:detail, nil)
     |> assign(:audiences, [])
     |> assign(:rules, [])
     |> assign(:editable?, true)
     |> assign(:status_message, nil)
     |> assign(:error_messages, [])
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
      |> load_workspace(flag_key, env)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"ruleset" => params}, socket) do
    rules = parse_ruleset_params(params, socket.assigns.rules)
    {:noreply, assign_workspace(socket, socket.assigns.detail, rules, audiences: socket.assigns.audiences)}
  end

  def handle_event("save_draft", params, socket) do
    rules = event_rules(params, socket)
    save_rules(socket, rules, :draft)
  end

  def handle_event("publish", params, socket) do
    rules = event_rules(params, socket)
    save_rules(socket, rules, :publish)
  end

  def handle_event("move_rule", %{"key" => key, "direction" => direction}, socket) do
    rules = move_rule(socket.assigns.rules, key, direction)

    socket =
      socket
      |> assign_workspace(socket.assigns.detail, rules, audiences: socket.assigns.audiences)
      |> assign(:status_message, "Rule order updated")

    {:noreply, socket}
  end

  def handle_event("add_rule", _params, socket) do
    rules = socket.assigns.rules ++ [blank_rule(next_rule_index(socket.assigns.rules))]

    {:noreply,
     socket
     |> assign_workspace(socket.assigns.detail, rules, audiences: socket.assigns.audiences)
     |> assign(:status_message, "Added a new draft rule")}
  end

  def handle_event("archive_flag", _params, socket) do
    case Rulestead.archive_flag(
           Command.ArchiveFlag.new(socket.assigns.flag_key,
             actor: socket.assigns.current_actor,
             reason: "Archived from rules workspace",
             metadata: command_metadata(socket, "rules.archive", "Archived flag from rules workspace")
           )
         ) do
      {:ok, _payload} ->
        env = socket.assigns.detail.environment.key

        {:noreply,
         socket
         |> assign(:status_message, "Flag archived")
         |> load_workspace(socket.assigns.flag_key, env)}

      {:error, error} ->
        {:noreply, assign(socket, :error_messages, [error.message])}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={@flag_key || "Rules workspace"}
      page_kicker="Rules workspace"
      page_summary="Dedicated environment-scoped rule authoring with explicit draft and publish actions."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <OperatorComponents.policy_state policy_state={@rulestead_admin_policy_state} />

      <div :if={@detail} class="rs-rules-workspace">
        <div class="rs-rules-workspace__header">
          <div>
            <h2>Rules workspace</h2>
            <p>
              Editing <code><%= @detail.flag.key %></code> for <strong><%= @detail.environment.name %></strong>.
            </p>
          </div>
          <div class="rs-rules-workspace__links">
            <a href={path_for(assigns, "/#{@detail.flag.key}")}>Back to detail</a>
          </div>
        </div>

        <RuleEditorComponents.lifecycle_banner
          detail={@detail}
          editable?={@editable?}
          status_message={@status_message}
        />

        <RuleEditorComponents.validation_notices
          error_messages={@error_messages}
          editable?={@editable?}
        />

        <form aria-label="Rules workspace form" phx-change="validate" phx-submit="save_draft">
          <div class="rs-rules-workspace__layout">
            <section class="rs-rules-workspace__editor">
              <div class="rs-rules-workspace__toolbar">
                <div>
                  <h3>Ordered rules</h3>
                  <p>Use the dedicated workspace to edit, reorder, and save one environment-scoped draft.</p>
                </div>
                <button :if={@editable?} type="button" phx-click="add_rule">Add rule</button>
              </div>

              <RuleEditorComponents.rule_card
                :for={{rule, index} <- Enum.with_index(@rules)}
                index={index}
                rule={rule}
                audiences={@audiences}
                mount_path={@rulestead_admin_mount_path}
                editable?={@editable?}
              />
            </section>

            <aside class="rs-rules-workspace__sidebar">
              <RuleEditorComponents.action_bar
                detail={@detail}
                editable?={@editable?}
                error_messages={@error_messages}
              />

              <RuleEditorComponents.audience_library audiences={@audiences} mount_path={@rulestead_admin_mount_path} />
            </aside>
          </div>
        </form>
      </div>
    </Shell.page>
    """
  end

  defp save_rules(socket, rules, mode) do
    detail = socket.assigns.detail
    audiences = socket.assigns.audiences
    errors = validate_rules(rules, audiences, editable?: socket.assigns.editable?)

    if errors != [] do
      {:noreply,
       socket
       |> assign(:error_messages, errors)
       |> assign(:status_message, nil)}
    else
      socket = assign_workspace(socket, detail, rules, audiences: audiences)

      ruleset = %{
        salt: build_salt(detail.flag.key, detail.environment.key),
        rules: Enum.map(rules, &rule_to_payload/1)
      }

      with {:ok, _draft} <-
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(detail.flag.key, detail.environment.key, ruleset,
                 actor: socket.assigns.current_actor,
                 metadata: command_metadata(socket, "rules.save_draft", rules_reason(detail, mode))
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
         |> assign(:status_message, message)
         |> load_workspace(detail.flag.key, detail.environment.key)}
      else
        {:error, error} ->
          {:noreply, assign(socket, :error_messages, normalize_store_errors(error))}
      end
    end
  end

  defp maybe_publish(:draft, _flag_key, _environment_key, _socket), do: {:ok, :draft_only}

  defp maybe_publish(:publish, flag_key, environment_key, socket) do
    Rulestead.publish_ruleset(
      Command.PublishRuleset.new(flag_key, environment_key,
        actor: socket.assigns.current_actor,
        metadata: command_metadata(socket, "rules.publish", "Published ruleset from rules workspace")
      )
    )
  end

  defp assign_workspace(socket, detail, rules, opts) do
    audiences = Keyword.fetch!(opts, :audiences)

    capability_editable? =
      socket.assigns.rulestead_admin_policy_state.capabilities.edit? or
        socket.assigns.rulestead_admin_policy_state.capabilities.admin? or
        socket.assigns.rulestead_admin_policy_state.capabilities.propose?

    editable? = capability_editable? && detail && is_nil(detail.flag.archived_at)
    errors = validate_rules(rules, audiences, editable?: editable?)

    socket
    |> assign(:detail, detail)
    |> assign(:rules, rules)
    |> assign(:audiences, audiences)
    |> assign(:editable?, editable?)
    |> assign(:error_messages, errors)
  end

  defp load_workspace(socket, flag_key, env) do
    detail_result = Rulestead.fetch_flag(flag_key, env)
    audiences_result = Rulestead.list_audiences()

    case {detail_result, audiences_result} do
      {{:ok, detail}, {:ok, audiences}} ->
        assign_workspace(socket, detail, rules_from_detail(detail), audiences: audiences)

      {{:error, error}, _} ->
        socket
        |> assign(:detail, nil)
        |> assign(:rules, [])
        |> assign(:audiences, [])
        |> assign(:editable?, false)
        |> assign(:error_messages, [error.message])

      {_, {:error, error}} ->
        socket
        |> assign(:detail, nil)
        |> assign(:rules, [])
        |> assign(:audiences, [])
        |> assign(:editable?, false)
        |> assign(:error_messages, [error.message])
    end
  end

  defp event_rules(%{"ruleset" => params}, socket) do
    parse_ruleset_params(params, socket.assigns.rules)
  end

  defp event_rules(_params, socket), do: socket.assigns.rules

  defp rules_from_detail(detail) do
    source_rules =
      cond do
        detail.draft_rulesets != [] -> List.first(detail.draft_rulesets).rules
        detail.active_ruleset -> detail.active_ruleset.rules
        true -> []
      end

    source_rules
    |> Enum.with_index()
    |> Enum.map(fn {rule, index} -> normalize_rule(rule, index) end)
    |> case do
      [] -> [blank_rule(0)]
      rules -> rules
    end
  end

  defp normalize_rule(rule, index) do
    %{
      "index" => index,
      "key" => present(rule[:key] || rule["key"]) || "rule-#{index + 1}",
      "name" => rule[:name] || rule["name"] || "",
      "strategy" => normalize_strategy(rule[:strategy] || rule["strategy"]),
      "audience_key" => rule[:audience_key] || rule["audience_key"] || "",
      "value" => normalize_value(rule[:value] || rule["value"]),
      "conditions" => normalize_conditions(rule[:conditions] || rule["conditions"] || []),
      "variants" => normalize_variants(rule[:variants] || rule["variants"] || []),
      "rollout" => rule[:rollout] || rule["rollout"]
    }
  end

  defp blank_rule(index) do
    %{
      "index" => index,
      "key" => "rule-#{index + 1}",
      "name" => "",
      "strategy" => "forced_value",
      "audience_key" => "",
      "value" => "true",
      "conditions" => [],
      "variants" => [],
      "rollout" => nil
    }
  end

  defp normalize_conditions(conditions) when is_list(conditions), do: conditions
  defp normalize_conditions(_conditions), do: []

  defp normalize_variants(variants) when is_list(variants) do
    variants
    |> Enum.with_index()
    |> Enum.map(fn {variant, index} ->
      %{
        "index" => index,
        "key" => variant[:key] || variant["key"] || "variant-#{index + 1}",
        "value" => normalize_value(variant[:value] || variant["value"]),
        "weight" => to_string(variant[:weight] || variant["weight"] || 0)
      }
    end)
  end

  defp normalize_variants(_variants), do: []

  defp parse_ruleset_params(params, existing_rules) do
    params
    |> Map.get("rules", %{})
    |> Enum.sort_by(fn {index, _rule} -> String.to_integer(index) end)
    |> Enum.map(fn {index, rule_params} ->
      existing_rule = Enum.at(existing_rules, String.to_integer(index), %{})
      strategy = normalize_strategy(rule_params["strategy"] || existing_rule["strategy"])

      %{
        "index" => String.to_integer(index),
        "key" => present(rule_params["key"]) || existing_rule["key"] || "rule-#{String.to_integer(index) + 1}",
        "name" => rule_params["name"] || "",
        "strategy" => strategy,
        "audience_key" => rule_params["audience_key"] || "",
        "value" => normalize_value(rule_params["value"] || existing_rule["value"]),
        "conditions" => existing_rule["conditions"] || [],
        "variants" => parse_variants(rule_params["variants"] || %{}, existing_rule["variants"] || []),
        "rollout" => normalize_rollout(strategy, existing_rule["rollout"])
      }
    end)
  end

  defp parse_variants(variants, existing_variants) when is_map(variants) do
    variants
    |> Enum.sort_by(fn {index, _variant} -> String.to_integer(index) end)
    |> Enum.map(fn {index, variant_params} ->
      existing_variant = Enum.at(existing_variants, String.to_integer(index), %{})

      %{
        "index" => String.to_integer(index),
        "key" => variant_params["key"] || existing_variant["key"] || "variant-#{String.to_integer(index) + 1}",
        "value" => normalize_value(variant_params["value"] || existing_variant["value"]),
        "weight" => variant_params["weight"] || existing_variant["weight"] || "0"
      }
    end)
  end

  defp parse_variants(_variants, existing_variants), do: existing_variants

  defp normalize_rollout("variant_split", nil), do: %{"bucket_by" => :subject, "percentage" => 100}
  defp normalize_rollout("variant_split", rollout) when is_map(rollout), do: rollout
  defp normalize_rollout(_strategy, _rollout), do: nil

  defp rule_to_payload(rule) do
    payload = %{
      key: rule["key"],
      name: blank_to_nil(rule["name"]),
      strategy: String.to_existing_atom(rule["strategy"]),
      value: %{value: truthy_value(rule["value"])},
      conditions: [],
      variants: Enum.map(rule["variants"], &variant_to_payload/1)
    }

    payload
    |> maybe_put_audience(rule)
    |> maybe_put_rollout(rule)
  end

  defp variant_to_payload(variant) do
    %{
      key: variant["key"],
      value: %{value: truthy_value(variant["value"])},
      weight: parse_integer(variant["weight"])
    }
  end

  defp maybe_put_audience(payload, %{"strategy" => "segment_match", "audience_key" => audience_key}) do
    Map.put(payload, :audience_key, blank_to_nil(audience_key))
  end

  defp maybe_put_audience(payload, _rule), do: payload

  defp maybe_put_rollout(payload, %{"strategy" => "variant_split", "rollout" => rollout}) do
    Map.put(payload, :rollout, %{bucket_by: rollout["bucket_by"] || :subject, percentage: rollout["percentage"] || 100})
  end

  defp maybe_put_rollout(payload, _rule), do: payload

  defp validate_rules(rules, audiences, opts) do
    editable? = Keyword.fetch!(opts, :editable?)
    audience_keys = MapSet.new(Enum.map(audiences, & &1.key))

    cond do
      not editable? ->
        ["This flag is archived. Rules are read-only."]

      Enum.any?(rules, &invalid_variant_total?/1) ->
        ["Variant weights must total 100", "Save draft disabled until variant weights total 100"]

      Enum.any?(rules, &missing_audience?(&1, audience_keys)) ->
        ["Choose a reusable audience for segment match rules"]

      true ->
        []
    end
  end

  defp invalid_variant_total?(%{"strategy" => "variant_split", "variants" => variants}) do
    variants != [] and Enum.sum(Enum.map(variants, &parse_integer(&1["weight"]))) != 100
  end

  defp invalid_variant_total?(_rule), do: false

  defp missing_audience?(%{"strategy" => "segment_match", "audience_key" => audience_key}, audience_keys) do
    audience = blank_to_nil(audience_key)
    is_nil(audience) or not MapSet.member?(audience_keys, audience)
  end

  defp missing_audience?(_rule, _audience_keys), do: false

  defp move_rule(rules, key, "down") do
    swap_rule(rules, key, 1)
  end

  defp move_rule(rules, key, "up") do
    swap_rule(rules, key, -1)
  end

  defp move_rule(rules, _key, _direction), do: rules

  defp swap_rule(rules, key, offset) do
    index = Enum.find_index(rules, &(&1["key"] == key))

    cond do
      is_nil(index) -> rules
      index + offset < 0 -> rules
      index + offset >= length(rules) -> rules
      true -> List.replace_at(List.replace_at(rules, index, Enum.at(rules, index + offset)), index + offset, Enum.at(rules, index))
    end
  end

  defp normalize_store_errors(%{details: details}) when is_list(details) and details != [] do
    Enum.map(details, fn detail -> detail[:message] || detail["message"] || "Validation failed" end)
  end

  defp normalize_store_errors(error), do: [error.message]

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  defp build_salt(flag_key, environment_key) do
    "#{flag_key}:#{environment_key}:draft:#{System.unique_integer([:positive])}"
  end

  defp build_base_path(socket, flag_key), do: admin_base_path(socket, "/#{flag_key}/rules")

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

  defp rules_reason(detail, :draft), do: "Saved draft ruleset for #{detail.environment.key}"
  defp rules_reason(detail, :publish), do: "Published ruleset for #{detail.environment.key}"

  defp normalize_strategy(strategy) when is_atom(strategy), do: Atom.to_string(strategy)
  defp normalize_strategy(strategy) when is_binary(strategy), do: strategy
  defp normalize_strategy(_strategy), do: "forced_value"

  defp normalize_value(%{value: value}), do: normalize_value(value)
  defp normalize_value(%{"value" => value}), do: normalize_value(value)
  defp normalize_value(value) when is_map(value) and map_size(value) == 0, do: "false"
  defp normalize_value(true), do: "true"
  defp normalize_value(false), do: "false"
  defp normalize_value(nil), do: "false"
  defp normalize_value(value) when is_binary(value), do: value
  defp normalize_value(value), do: to_string(value)

  defp truthy_value("true"), do: true
  defp truthy_value("false"), do: false
  defp truthy_value(value), do: value

  defp next_rule_index(rules), do: length(rules)

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(value) when is_binary(value), do: String.to_integer(value)
  defp parse_integer(_value), do: 0

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: String.trim(value))
  defp blank_to_nil(value), do: value

  defp present(value), do: blank_to_nil(value)
end
