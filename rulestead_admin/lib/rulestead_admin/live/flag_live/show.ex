defmodule RulesteadAdmin.Live.FlagLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:detail, nil)
     |> assign(:change_request_preview, [])
     |> assign(:scheduled_execution_preview, [])
     |> assign(:error_message, nil)
     |> assign(:missing_environment, nil)
     |> assign(:environment_state_cards, [])
     |> assign(:env_options, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    query = query_params(uri)
    key = params["key"]
    env = query["env"] || socket.assigns.current_environment.key
    base_path = detail_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(
        :return_to,
        Session.canonical_return_to(
          socket,
          query["return_to"],
          socket.assigns.rulestead_admin_mount_path <> "/flags"
        )
      )
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(
        :env_links,
        Session.env_links(socket, base_path, %{"return_to" => query["return_to"]})
      )
      |> load_detail(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker="Flag detail"
      page_summary="Operator hub for current behavior, evidence, ownership, and the next safest action."
      base_path={@rulestead_admin_mount_path}
      current_section={:flags}
      breadcrumbs={[%{label: "Back to flags", path: @return_to}]}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      env_options={@env_options}
      env_context_help="Shows this flag key's state in the selected environment. Promotion uses Compare."
      policy_state={@rulestead_admin_policy_state}
      flash={@flash}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <OperatorComponents.empty_state
        :if={@missing_environment}
        variant="hero"
        title={"#{@flag_key} is not configured in #{@current_environment.name}"}
        body={"You are viewing the #{@current_environment.name} environment scope. This switch changes the state you inspect; it does not promote or copy a flag between environments."}
      >
        <:actions>
          <a
            :if={@missing_environment.primary_environment}
            href={@missing_environment.primary_path}
            class="rs-button rs-button--primary"
          >
            View <%= @missing_environment.primary_environment.name %> state
          </a>
          <a href={Session.current_path(assigns, fetch_mount_path(assigns) <> "/flags", %{"view" => "all"})} class="rs-button">
            Open flags in <%= @current_environment.name %>
          </a>
          <a
            :if={@missing_environment.compare_path}
            href={@missing_environment.compare_path}
            class="rs-button"
          >
            Compare environments
          </a>
        </:actions>
      </OperatorComponents.empty_state>

      <div :if={@detail} class="rs-detail">
        <AuditComponents.kill_switch_banner
          :if={kill_switch_active?(@detail)}
          active?={true}
          flag_key={@detail.flag.key}
          environment_name={@detail.environment.name}
          reason={latest_reason(@detail, @current_actor)}
          kill_path={path_for(assigns, "/#{@detail.flag.key}/kill")}
          timeline_path={path_for(assigns, "/#{@detail.flag.key}/timeline")}
          show_release_button={@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?}
        />

        <section class="rs-hub-hero" aria-label="Flag overview">
          <div class="rs-hub-hero__identity">
            <p class="rs-eyebrow">Flag</p>
            <h2><code><%= @detail.flag.key %></code></h2>
            <p class="rs-hub-hero__description"><%= @detail.flag.description %></p>
            <div class="rs-inline-badges">
              <FlagComponents.environment_status status={@detail.flag_environment.status} />
              <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
              <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
            </div>
            <FlagComponents.tag_list tags={@detail.flag.tags} />
          </div>
          <div class="rs-hub-hero__signals" aria-label="Current flag signals">
            <OperatorComponents.signal label="Scope" value={"Viewing #{@detail.environment.name} state"} />
            <OperatorComponents.signal label="Type" value={humanize(@detail.flag.flag_type)} />
            <OperatorComponents.signal label="Default" value={inspect(default_flag_value(@detail.flag.default_value))} />
            <OperatorComponents.signal label="Owner" value={owner_label(@detail)} />
          </div>
        </section>

        <section class="rs-env-states" aria-label="Environment states">
          <header class="rs-section-header">
            <div>
              <p class="rs-eyebrow">Environment states</p>
              <h2>Where this flag exists</h2>
              <p>
                The flag key is global, but rules, status, kill switch, and publish history are stored per environment.
              </p>
            </div>
            <a href={compare_path(assigns, @detail.flag.key)}>Compare environments</a>
          </header>
          <div class="rs-env-state-grid">
            <%= for card <- @environment_state_cards do %>
              <a
                :if={card.available?}
                href={card.href}
                class="rs-env-state"
                data-current={to_string(card.current?)}
                data-available="true"
              >
                <span class="rs-env-state__name"><%= card.environment.name %></span>
                <span :if={card.current?} class="rs-env-state__badge">Viewing</span>
                <FlagComponents.environment_status status={card.status} />
                <span><%= card.ruleset_label %></span>
                <span><%= card.lifecycle_label %></span>
              </a>
              <div
                :if={!card.available?}
                class="rs-env-state"
                data-current={to_string(card.current?)}
                data-available="false"
                aria-disabled="true"
              >
                <span class="rs-env-state__name"><%= card.environment.name %></span>
                <span class="rs-env-state__badge">Not configured</span>
                <span>No environment state exists for this flag.</span>
              </div>
            <% end %>
          </div>
        </section>

        <section class="rs-hub-priority" aria-label="Current behavior and next action">
          <div class="rs-hub-priority__main">
            <p class="rs-eyebrow">Current behavior</p>
            <h2><%= behavior_headline(@detail) %></h2>
            <p><%= behavior_summary(@detail) %></p>
          </div>
          <div class="rs-hub-priority__side">
            <p class="rs-eyebrow">Recommended next action</p>
            <p class="rs-hub-priority__recommendation">
              <%= primary_action_label(archive_readiness(@detail)) %>
            </p>
            <div class="rs-inline-badges">
              <FlagComponents.readiness_badge readiness={archive_readiness(@detail).readiness} />
              <FlagComponents.evidence_quality_badge quality={archive_readiness(@detail).evidence_quality} />
            </div>
            <p :if={guidance_limited?(archive_readiness(@detail))}>
              Guidance is limited by missing evidence. Review this flag manually before choosing a cleanup path.
            </p>
          </div>
        </section>

        <nav class="rs-task-board" aria-label="Flag task launcher">
          <section class="rs-task-group" aria-label="Operate">
            <h2>Operate</h2>
            <OperatorComponents.task_link
              title="Open rules workspace"
              summary="Review active and draft behavior before publishing."
              href={path_for(assigns, "/#{@detail.flag.key}/rules")}
              primary?={true}
            />
            <OperatorComponents.task_link
              title="Rollouts"
              summary="Advance, hold, or inspect rollout stages."
              href={path_for(assigns, "/#{@detail.flag.key}/rollouts")}
            />
          </section>
          <section class="rs-task-group" aria-label="Debug">
            <h2>Debug</h2>
            <OperatorComponents.task_link
              title="Simulate"
              summary="Run this flag against a controlled context."
              href={path_for(assigns, "/#{@detail.flag.key}/simulate")}
            />
            <OperatorComponents.task_link
              title="Explain"
              summary="Answer why an actor received a decision."
              href={path_for(assigns, "/#{@detail.flag.key}/explain")}
            />
            <OperatorComponents.task_link
              title="Open audit timeline"
              summary="Read append-only history for this flag."
              href={path_for(assigns, "/#{@detail.flag.key}/timeline")}
            />
          </section>
          <section class="rs-task-group" aria-label="Govern">
            <h2>Govern</h2>
            <OperatorComponents.task_link
              :if={@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?}
              title="Edit metadata"
              summary="Update ownership, tags, and lifecycle posture."
              href={path_for(assigns, "/#{@detail.flag.key}/edit")}
            />
            <OperatorComponents.task_link
              title="Review cleanup"
              summary="Check evidence before archiving."
              href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}
            />
            <OperatorComponents.task_link
              title="Compare environments"
              summary="Preview source and target state before any governed promotion."
              href={compare_path(assigns, @detail.flag.key)}
            />
            <OperatorComponents.task_link
              :if={@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?}
              title="Open kill switch"
              summary="Emergency override route."
              href={path_for(assigns, "/#{@detail.flag.key}/kill")}
              tone="critical"
            />
          </section>
        </nav>

        <section class="rs-hub-section" aria-label="Runtime state">
          <header class="rs-section-header">
            <div>
              <p class="rs-eyebrow">Runtime state</p>
              <h2>How this flag is positioned now</h2>
            </div>
          </header>
          <OperatorComponents.detail_grid rows={[
            %{label: "Lifecycle posture", value: humanize(@detail.lifecycle.mode)},
            %{label: "Review by", value: @detail.lifecycle.review_by || "Not scheduled"},
            %{label: "Archive readiness", value: humanize(archive_readiness(@detail).readiness)},
            %{label: "Evidence quality", value: humanize(archive_readiness(@detail).evidence_quality)},
            %{label: "Code references", value: humanize(freshness(@detail).code_references)}
          ]} />

          <div class="rs-inline-badges">
            <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
            <%= if @detail.lifecycle.state in [:stale, :potentially_stale] do %>
              <a href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}>
                <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
              </a>
            <% else %>
              <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
            <% end %>
          </div>
        </section>

        <div class="rs-hub-grid">
          <section class="rs-hub-section" aria-label="Rules status">
            <header class="rs-section-header">
              <div>
                <p class="rs-eyebrow">Rules</p>
                <h2>Rules status</h2>
              </div>
              <a href={path_for(assigns, "/#{@detail.flag.key}/rules")}>Open rules workspace</a>
            </header>
            <OperatorComponents.detail_grid rows={[
              %{label: "Active ruleset", value: active_ruleset_label(@detail)},
              %{label: "Draft ruleset", value: draft_ruleset_label(@detail)},
              %{label: "Value type", value: humanize(@detail.flag.value_type)}
            ]} />
          </section>

          <section class="rs-hub-section" aria-label="Governance queue">
            <header class="rs-section-header">
              <div>
                <p class="rs-eyebrow">Governance</p>
                <h2>Queued work</h2>
              </div>
            </header>
            <div class="rs-queue-preview">
              <h3>Open change requests</h3>
              <p :if={@change_request_preview == []}>No open change requests for this flag in <%= @current_environment.name %>.</p>
              <ul :if={@change_request_preview != []}>
                <li :for={entry <- @change_request_preview}>
                  <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
                </li>
              </ul>
              <h3>Scheduled changes</h3>
              <p :if={@scheduled_execution_preview == []}>No scheduled changes for this flag in <%= @current_environment.name %>.</p>
              <ul :if={@scheduled_execution_preview != []}>
                <li :for={entry <- @scheduled_execution_preview}>
                  <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
                </li>
              </ul>
            </div>
          </section>
        </div>

        <details class="rs-progressive-detail">
          <summary>Evidence, ownership, and environments</summary>
          <div class="rs-progressive-detail__grid">
            <section class="rs-hub-section" aria-label="Evidence">
              <h2>Evidence</h2>
              <OperatorComponents.detail_grid rows={[
                %{label: "Reasons", value: joined_labels(archive_readiness(@detail).reasons, &reason_label/1, "No archive-positive signals yet.")},
                %{label: "Unknowns", value: joined_labels(archive_readiness(@detail).unknowns, &unknown_label/1, "No known evidence gaps.")},
                %{label: "Blockers", value: joined_labels(archive_readiness(@detail).blockers, &blocker_label/1, "No blockers identified.")},
                %{label: "Evaluation evidence", value: freshness(@detail).evaluation |> humanize()},
                %{label: "Latest scan receipt", value: scan_label(freshness(@detail).code_refs_scan)}
              ]} />
            </section>

            <section class="rs-hub-section" aria-label="Ownership and metadata">
              <h2>Ownership and metadata</h2>
              <OperatorComponents.detail_grid rows={[
                %{label: "Owner reference", value: @detail.lifecycle.owner_ref || "Not set"},
                %{label: "Owner kind", value: humanize(@detail.lifecycle.owner_kind)},
                %{label: "Display snapshot", value: @detail.lifecycle.owner_display || "Not set"}
              ]} />
            </section>

            <section class="rs-hub-section" aria-label="Environment model">
              <h2>Environment model</h2>
              <p>
                Switching the environment changes which environment-scoped state you are inspecting. Use Compare for promotion review.
              </p>
            </section>
          </div>
        </details>
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("release_kill_switch", _params, socket) do
    case Rulestead.release_kill_switch(
           socket.assigns.flag_key,
           socket.assigns.current_environment.key,
           socket.assigns.current_actor,
           reason: "Released from flag detail banner"
         ) do
      {:ok, _payload} ->
        {:noreply,
         socket
         |> assign(:error_message, nil)
         |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}

      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        assign(socket, :detail, detail)
        |> assign(:change_request_preview, load_change_request_preview(key, env))
        |> assign(:scheduled_execution_preview, load_scheduled_execution_preview(key, env))
        |> assign(:missing_environment, nil)
        |> assign(:environment_state_cards, environment_state_cards(socket, detail, key, env))
        |> assign(:env_options, flag_env_options(socket, detail.environment_cards, key, env))
        |> assign(:error_message, nil)

      {:error, error} ->
        missing_environment = missing_environment_context(socket, key, env)

        socket
        |> assign(:detail, nil)
        |> assign(:change_request_preview, [])
        |> assign(:scheduled_execution_preview, [])
        |> assign(:missing_environment, missing_environment)
        |> assign(:environment_state_cards, [])
        |> assign(
          :env_options,
          missing_environment_options(socket, missing_environment, key, env)
        )
        |> assign(:error_message, if(missing_environment, do: nil, else: error.message))
    end
  end

  defp load_change_request_preview(flag_key, env) do
    case Rulestead.list_change_requests(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.filter(&(&1.state in [:submitted, :approved]))
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: get_in(entry.command, ["diff", "title"]) || humanize(entry.action),
            path: "/admin/flags/change-requests/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
  end

  defp default_flag_value(%{value: value}), do: value
  defp default_flag_value(%{"value" => value}), do: value
  defp default_flag_value(value), do: value

  defp load_scheduled_execution_preview(flag_key, env) do
    case Rulestead.list_scheduled_executions(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: "#{humanize(entry.action)} at #{format_schedule(entry.scheduled_for)}",
            path: "/admin/flags/schedule/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
  end

  defp environment_state_cards(socket, detail, key, env) do
    cards_by_env = Map.new(detail.environment_cards, &{&1.environment.key, &1})

    Enum.map(socket.assigns.available_environments, fn environment ->
      card = Map.get(cards_by_env, environment.key)

      if card do
        %{
          environment: environment,
          available?: true,
          current?: environment.key == env,
          href: env_path(socket, key, environment.key),
          status: card.flag_environment.status,
          ruleset_label: environment_ruleset_label(card),
          lifecycle_label: humanize(card.lifecycle.state)
        }
      else
        %{
          environment: environment,
          available?: false,
          current?: environment.key == env
        }
      end
    end)
  end

  defp flag_env_options(socket, environment_cards, key, env) do
    configured = MapSet.new(Enum.map(environment_cards, & &1.environment.key))

    Enum.map(socket.assigns.available_environments, fn environment ->
      available? = MapSet.member?(configured, environment.key)

      %{
        environment: environment,
        href: env_path(socket, key, environment.key),
        current?: environment.key == env,
        available?: available?,
        title: env_option_title(environment, available?)
      }
    end)
  end

  defp missing_environment_options(_socket, nil, _key, _env), do: nil

  defp missing_environment_options(socket, missing_environment, key, env) do
    configured =
      missing_environment.environment_cards
      |> Enum.map(& &1.environment.key)
      |> MapSet.new()

    Enum.map(socket.assigns.available_environments, fn environment ->
      available? = MapSet.member?(configured, environment.key)

      %{
        environment: environment,
        href: env_path(socket, key, environment.key),
        current?: environment.key == env,
        available?: available?,
        title: env_option_title(environment, available?)
      }
    end)
  end

  defp missing_environment_context(socket, key, env) do
    case Rulestead.list_flags(query: key, include_archived?: true, limit: 100) do
      {:ok, page} ->
        cards =
          page.entries
          |> Enum.filter(&(&1.flag.key == key))
          |> Enum.sort_by(& &1.environment.key)

        case cards do
          [] ->
            nil

          cards ->
            primary = Enum.find(cards, &(&1.environment.key != env)) || List.first(cards)

            %{
              environment_cards: cards,
              primary_environment: primary && primary.environment,
              primary_path: primary && env_path(socket, key, primary.environment.key),
              compare_path: compare_path(socket, key)
            }
        end

      _other ->
        nil
    end
  end

  defp environment_ruleset_label(%{
         active_ruleset: %{version: version},
         has_draft_ruleset?: true
       }),
       do: "Active v#{version}; draft waiting"

  defp environment_ruleset_label(%{active_ruleset: %{version: version}}), do: "Active v#{version}"

  defp environment_ruleset_label(%{has_draft_ruleset?: true, draft_rulesets: [ruleset | _]}),
    do: "Draft v#{ruleset.version} waiting"

  defp environment_ruleset_label(_card), do: "Default value only"

  defp env_option_title(environment, true), do: "View #{environment.name} state"

  defp env_option_title(environment, false),
    do: "#{environment.name} is not configured for this flag"

  defp env_path(socket, key, environment_key) do
    Session.path_with_return_to(
      %{
        current_environment: %{socket.assigns.current_environment | key: environment_key},
        current_tenant: socket.assigns.current_tenant
      },
      admin_base_path(socket, "/#{key}"),
      fetch_return_to(socket)
    )
  end

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

  defp page_title(%{flag_key: flag_key}) when is_binary(flag_key), do: flag_key
  defp page_title(_assigns), do: "Flag detail"

  defp kill_switch_active?(detail), do: detail.flag_environment.status == :killswitched
  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness
  defp freshness(detail), do: detail.lifecycle.freshness

  defp owner_label(detail),
    do: detail.flag.ownership.owner_display || detail.flag.ownership.owner_ref || "Not set"

  defp behavior_headline(detail) do
    cond do
      kill_switch_active?(detail) ->
        "Kill switch is forcing the default value"

      detail.active_ruleset ->
        "Serving active ruleset v#{detail.active_ruleset.version}"

      true ->
        "Serving the default value"
    end
  end

  defp behavior_summary(detail) do
    cond do
      kill_switch_active?(detail) ->
        "Authored rules stay intact, but #{detail.environment.name} is currently overridden until an operator releases the kill switch."

      detail.has_draft_ruleset? ->
        "The published ruleset is live in #{detail.environment.name}. Draft changes exist and should be simulated before publish."

      detail.active_ruleset ->
        "The published ruleset is live in #{detail.environment.name}. No draft ruleset is waiting for this environment."

      true ->
        "No published ruleset exists for #{detail.environment.name}; evaluations fall back to the configured default."
    end
  end

  defp active_ruleset_label(%{active_ruleset: nil}), do: "No published ruleset yet"
  defp active_ruleset_label(%{active_ruleset: ruleset}), do: "Version #{ruleset.version}"

  defp draft_ruleset_label(%{has_draft_ruleset?: true, draft_rulesets: [ruleset | _]}),
    do: "Version #{ruleset.version} waiting for review"

  defp draft_ruleset_label(%{environment: environment}),
    do: "No draft ruleset for #{environment.name}"

  defp latest_reason(detail, actor) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: actor
           ),
         event when is_map(event) <-
           Enum.find(
             page.entries,
             &(&1.event_type in ["kill_switch.engage", "kill_switch.release"])
           ) do
      event.reason
    else
      _ -> nil
    end
  end

  defp detail_base_path(socket, key), do: admin_base_path(socket, "/#{key}")

  defp path_for(socket, suffix) do
    Session.path_with_return_to(
      socket,
      admin_base_path(socket, suffix),
      fetch_return_to(socket)
    )
  end

  defp compare_path(%Phoenix.LiveView.Socket{} = socket, flag_key) do
    params =
      socket.assigns.available_environments
      |> compare_params(socket.assigns.current_environment.key)

    Session.current_path(socket, admin_base_path(socket, "/compare/#{flag_key}"), params)
  end

  defp compare_path(assigns, flag_key) do
    params =
      assigns.available_environments
      |> compare_params(assigns.current_environment.key)

    Session.current_path(assigns, admin_base_path(assigns, "/compare/#{flag_key}"), params)
  end

  defp compare_params(environments, current_key) do
    target =
      environments
      |> Enum.map(& &1.key)
      |> Enum.find(&(&1 != current_key))

    %{}
    |> Map.put("source_env", current_key)
    |> maybe_put_param("target_env", target)
  end

  defp maybe_put_param(params, _key, nil), do: params
  defp maybe_put_param(params, key, value), do: Map.put(params, key, value)

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp fetch_return_to(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns.return_to
  defp fetch_return_to(%{return_to: return_to}), do: return_to

  defp format_schedule(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_schedule(_datetime), do: "pending"

  defp primary_action_label(%{recommended_next_action: nil}),
    do: "No primary recommendation yet."

  defp primary_action_label(%{recommended_next_action: action}),
    do: action_label(action)

  defp guidance_limited?(%{evidence_quality: :weak}), do: true
  defp guidance_limited?(%{recommended_next_action: nil}), do: true
  defp guidance_limited?(_archive_readiness), do: false

  defp joined_labels([], _mapper, fallback), do: fallback

  defp joined_labels(values, mapper, _fallback) do
    values
    |> Enum.map_join(", ", mapper)
  end

  defp reason_label(:expiring_posture), do: "Expiring posture authored"
  defp reason_label(:review_horizon_passed), do: "Review horizon passed"
  defp reason_label(:stale_evaluation), do: "Evaluation has not run recently"
  defp reason_label(:never_evaluated), do: "Evaluation has never run"
  defp reason_label(:no_code_refs), do: "Fresh scan found no code references"
  defp reason_label(:already_archived), do: "Already archived"
  defp reason_label(reason), do: humanize(reason)

  defp unknown_label(:code_refs_scan_missing), do: "Code-reference scan receipt is missing"
  defp unknown_label(:code_refs_scan_stale), do: "Code-reference scan receipt is stale"
  defp unknown_label(:evaluation_missing), do: "Evaluation evidence is missing"
  defp unknown_label(reason), do: humanize(reason)

  defp blocker_label(:protected_flag_type), do: "Protected flag type resists archival"
  defp blocker_label(:permanent_posture), do: "Permanent posture keeps this flag active"

  defp blocker_label(:remote_config_requires_review),
    do: "Remote config flags require stronger review"

  defp blocker_label(:code_refs_present), do: "Code references are still present"
  defp blocker_label(:already_archived), do: "Already archived"
  defp blocker_label(reason), do: humanize(reason)

  defp action_label(:archive_ready), do: "Archive when the review is complete"
  defp action_label(:keep_active), do: "Keep active"
  defp action_label(:review_manually), do: "Review manually"
  defp action_label(:refresh_code_refs), do: "Refresh code references"
  defp action_label(:collect_eval_evidence), do: "Collect evaluation evidence"
  defp action_label(:remove_code_refs), do: "Remove code references"
  defp action_label(:mark_permanent), do: "Mark permanent"
  defp action_label(action), do: humanize(action)

  defp scan_label(nil), do: "No code-reference scan receipt yet."

  defp scan_label(%{received_at: %DateTime{} = received_at, reference_count: reference_count}) do
    "Received #{DateTime.to_iso8601(received_at)} with #{reference_count} references."
  end

  defp scan_label(_scan), do: "Scan receipt unavailable."
end
