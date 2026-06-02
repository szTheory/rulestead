# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.ExperimentLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:detail, nil)
     |> assign(:results, [])
     |> assign(:guardrail_warning, nil)
     |> assign(:error_message, nil)
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
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_detail(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker="Experiment detail"
      page_summary="Calm read surface for experiment results, metrics, and lifecycle."
      base_path={@rulestead_admin_mount_path}
      current_section={:experiments}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      tenant_links={Session.tenant_links(assigns, detail_base_path(assigns, @flag_key || ""))}
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@detail} class="rs-detail">
        <div class="rs-detail__actions">
          <a href={path_for(assigns, "/#{@detail.flag.key}/edit")}>Edit metadata</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/rules")}>Open rules workspace</a>
        </div>

        <OperatorComponents.banner
          :if={@guardrail_warning}
          title="Guardrail Warning"
          body={@guardrail_warning}
          tone="warning"
        />

        <div class="rs-detail__hero">
          <div>
            <h2><code><%= @detail.flag.key %></code></h2>
            <p><%= @detail.flag.description %></p>
            <FlagComponents.tag_list tags={@detail.flag.tags} />
          </div>
          <div class="rs-detail__stats">
            <FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} tone="neutral" />
            <FlagComponents.stat title="Owner" value={@detail.flag.ownership.owner_display || @detail.flag.ownership.owner_ref} tone="neutral" />
            <FlagComponents.stat title="Environment status" value={humanize(@detail.flag_environment.status)} tone="neutral" />
          </div>
        </div>

        <FlagComponents.section_card title="Experiment Results">
          <p :if={Enum.empty?(@results)}>No significant data collected yet for this experiment.</p>

          <div :for={result <- @results} class="rs-experiment-result">
            <h3>Variant: <code><%= result.variation %></code> vs Control</h3>
            <OperatorComponents.summary_grid items={[
              %{title: "Lift", value: format_percent(result.stats.lift), tone: tone_for_lift(result.stats.lift)},
              %{title: "P-Value", value: Float.round(result.stats.p_value, 4) |> to_string(), tone: tone_for_pvalue(result.stats.p_value)},
              %{title: "Significant", value: if(result.stats.significant, do: "Yes", else: "No"), tone: if(result.stats.significant, do: "positive", else: "neutral")}
            ]} />
            <OperatorComponents.detail_grid rows={experiment_result_rows(result)} />
          </div>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Lifecycle">
          <p>
            <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
            <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
            <span>Owner: <%= @detail.flag.ownership.owner_display || @detail.flag.ownership.owner_ref %></span>
          </p>
        </FlagComponents.section_card>

      </div>
    </Shell.page>
    """
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:detail, detail)
        |> assign(:error_message, nil)
        |> load_experiment_data(key, env, detail)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:results, [])
        |> assign(:guardrail_warning, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp load_experiment_data(socket, key, env, detail) do
    # Target conversion event
    conversion_metrics = fetch_metrics(key, "conversion", env)

    # Target error event for guardrail
    error_metrics = fetch_metrics(key, "error", env)

    control_val = detail.flag.default_value |> default_flag_value() |> to_string()

    control_metric =
      Enum.find(conversion_metrics, &(&1.variation == control_val)) ||
        %{exposures: 0, conversions: 0}

    variants = Enum.reject(conversion_metrics, &(&1.variation == control_val))

    results =
      Enum.map(variants, fn variant ->
        stats = Rulestead.Analytics.Stats.evaluate(control_metric, variant)

        %{
          variation: variant.variation,
          stats: stats,
          control_exposures: control_metric.exposures,
          control_conversions: control_metric.conversions,
          variant_exposures: variant.exposures,
          variant_conversions: variant.conversions
        }
      end)

    total_errors = Enum.reduce(error_metrics, 0, fn metric, acc -> metric.conversions + acc end)

    guardrail_warning =
      if total_errors > 50 do
        "Elevated error rates detected (#{total_errors} errors). Consider pausing the experiment."
      else
        nil
      end

    socket
    |> assign(:results, results)
    |> assign(:guardrail_warning, guardrail_warning)
  end

  defp fetch_metrics(key, event, env) do
    if mock = Process.get({:mock_metrics, key, event}) do
      mock
    else
      Rulestead.Analytics.Query.experiment_metrics(key, event, env)
    end
  end

  defp format_percent(val) do
    (val * 100.0) |> Float.round(2) |> to_string() |> Kernel.<>("%")
  end

  defp tone_for_lift(lift) when lift > 0.0, do: "positive"
  defp tone_for_lift(lift) when lift < 0.0, do: "critical"
  defp tone_for_lift(_), do: "neutral"

  defp tone_for_pvalue(p) when p < 0.05, do: "positive"
  defp tone_for_pvalue(_), do: "neutral"

  defp experiment_result_rows(result) do
    [
      %{label: "Control exposures", value: to_string(result.control_exposures)},
      %{label: "Control conversions", value: to_string(result.control_conversions)},
      %{label: "Variant exposures", value: to_string(result.variant_exposures)},
      %{label: "Variant conversions", value: to_string(result.variant_conversions)}
    ]
  end

  defp default_flag_value(%{value: value}), do: value
  defp default_flag_value(%{"value" => value}), do: value
  defp default_flag_value(value), do: value

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
  defp page_title(_assigns), do: "Experiment detail"

  defp detail_base_path(socket, key), do: admin_base_path(socket, "/#{key}")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
end
