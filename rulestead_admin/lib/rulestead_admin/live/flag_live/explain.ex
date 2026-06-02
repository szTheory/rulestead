# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Explain do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{
    AudienceTraceComponents,
    FlagComponents,
    OperatorComponents,
    Shell,
    SimulateComponents
  }

  alias RulesteadAdmin.Live.Session

  @empty_form %{
    "targeting_key" => "",
    "tenant_key" => "",
    "session_id" => "",
    "request_id" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:form, @empty_form)
     |> assign(:simulation_result, nil)
     |> assign(:explanation, nil)
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    key = params["key"]

    form =
      @empty_form
      |> Map.put("targeting_key", params["targeting_key"] || "")
      |> Map.put(
        "tenant_key",
        params["tenant_key"] ||
          (socket.assigns.current_tenant && socket.assigns.current_tenant.key) || ""
      )
      |> Map.put("session_id", params["session_id"] || "")
      |> Map.put("request_id", params["request_id"] || "")

    page =
      socket.assigns
      |> Session.placeholder_assigns(
        current_path: "#{socket.assigns.rulestead_admin_mount_path}/#{key}/explain",
        page_title: "#{key} explain",
        page_kicker: "Decision explainer",
        page_summary:
          "Support-safe permalink for why a flag evaluated the way it did, including reusable audience steps."
      )
      |> Map.put(:flag_key, key)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:form, form)
     |> maybe_run_explain(form, page)}
  end

  @impl true
  def handle_event("validate", %{"explain" => params}, socket) do
    {:noreply, assign(socket, :form, normalize_form(params))}
  end

  def handle_event("run_explain", %{"explain" => params}, socket) do
    form = normalize_form(params)
    page = socket.assigns.page

    {:noreply,
     socket
     |> assign(:form, form)
     |> push_patch(to: explain_path(socket, page.flag_key, form))
     |> maybe_run_explain(form, page)}
  end

  @impl true
  def render(%{page: page} = assigns) when is_map(page) do
    trace = assigns.simulation_result && assigns.simulation_result.debug_trace

    assigns =
      assigns
      |> assign(:page, page)
      |> assign(:trace, trace)
      |> assign(:summary_items, summary_items(assigns.simulation_result))

    ~H"""
    <Shell.page
      page_title={@page.page_title}
      page_kicker={@page.page_kicker}
      page_summary={@page.page_summary}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
      env_context_help="Shows this flag key's explanation context in the selected environment. Promotion uses Compare."
      policy_state={@page.policy_state}
    >
      <:header_actions>
        <a href={flag_detail_path(assigns)}>Back to flag</a>
        <a href={simulate_path(assigns)}>Open simulate</a>
      </:header_actions>

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <FlagComponents.section_card title="Explain context">
        <p>Permalink fields stay in the query string. Traits are never stored in URLs.</p>
        <form class="rs-form" phx-change="validate" phx-submit="run_explain" aria-label="Explain lookup form">
          <div class="rs-form-grid rs-form-grid--two">
            <div class="rs-form-field">
              <label for="explain-targeting-key">Targeting key</label>
              <input id="explain-targeting-key" type="text" name="explain[targeting_key]" value={@form["targeting_key"]} />
              <p class="rs-field-help">Required. This is the actor key used to reproduce the decision.</p>
            </div>
            <div class="rs-form-field">
              <label for="explain-tenant-key">Tenant key</label>
              <input id="explain-tenant-key" type="text" name="explain[tenant_key]" value={@form["tenant_key"]} />
              <p class="rs-field-help">Optional boundary when rules depend on account or workspace context.</p>
            </div>
            <div class="rs-form-field">
              <label for="explain-session-id">Session ID</label>
              <input id="explain-session-id" type="text" name="explain[session_id]" value={@form["session_id"]} />
              <p class="rs-field-help">Optional session context for anonymous or session-scoped checks.</p>
            </div>
            <div class="rs-form-field">
              <label for="explain-request-id">Request ID</label>
              <input id="explain-request-id" type="text" name="explain[request_id]" value={@form["request_id"]} />
              <p class="rs-field-help">Optional support trace handle.</p>
            </div>
            <div class="rs-form-actions rs-form-field--wide">
              <button class="rs-button rs-button--primary" type="submit">Explain decision</button>
            </div>
          </div>
        </form>
      </FlagComponents.section_card>

      <OperatorComponents.summary_grid
        :if={@summary_items != []}
        items={@summary_items}
        aria_label="Explain summary"
      />

      <FlagComponents.callout :if={@explanation} title="Decision explanation" tone="accent">
        <p><%= @explanation %></p>
      </FlagComponents.callout>

      <OperatorComponents.empty_state
        :if={@summary_items == [] and is_nil(@error_message)}
        title="Enter a targeting key to explain a decision"
        body="The explanation will show the returned value, matched rule, and audience trace without putting trait payloads in the URL."
        icon="?"
        variant="compact"
      />

      <AudienceTraceComponents.audience_trace_steps :if={@trace} rule_traces={Map.get(@trace, :rule_traces, [])} />

      <SimulateComponents.trace_disclosure trace={@trace} />
    </Shell.page>
    """
  end

  defp maybe_run_explain(socket, form, page) do
    if blank_to_nil(form["targeting_key"]) do
      context = build_context(form, page.current_environment.key)

      case Rulestead.simulate_flag(page.flag_key, page.current_environment.key, context,
             actor: socket.assigns.current_actor
           ) do
        {:ok, %{result: result}} ->
          explanation =
            case Rulestead.explain_flag(page.flag_key, page.current_environment.key, context,
                   actor: socket.assigns.current_actor
                 ) do
              {:ok, %{explanation: text}} -> text
              _ -> nil
            end

          socket
          |> assign(:simulation_result, result)
          |> assign(:explanation, explanation)
          |> assign(:error_message, nil)

        {:error, error} ->
          socket
          |> assign(:simulation_result, nil)
          |> assign(:explanation, nil)
          |> assign(:error_message, error.message)
      end
    else
      assign(socket, simulation_result: nil, explanation: nil, error_message: nil)
    end
  end

  defp summary_items(nil), do: []

  defp summary_items(result) do
    [
      %{title: "Matched rule", value: result.matched_rule || "Default path", tone: "neutral"},
      %{title: "Returned value", value: inspect(result.value), tone: "neutral"},
      %{title: "Reason", value: humanize_reason(result.reason), tone: "neutral"}
    ]
  end

  defp humanize_reason(reason) when is_atom(reason),
    do: reason |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp humanize_reason(reason), do: to_string(reason)

  defp build_context(form, environment_key) do
    %{
      targeting_key: form["targeting_key"],
      tenant_key: blank_to_nil(form["tenant_key"]),
      session_id: blank_to_nil(form["session_id"]),
      request_id: blank_to_nil(form["request_id"]),
      environment_key: environment_key
    }
  end

  defp explain_path(socket, flag_key, form) do
    params =
      %{"env" => socket.assigns.current_environment.key}
      |> maybe_put("tenant", blank_to_nil(form["tenant_key"]))
      |> maybe_put("targeting_key", blank_to_nil(form["targeting_key"]))
      |> maybe_put("session_id", blank_to_nil(form["session_id"]))
      |> maybe_put("request_id", blank_to_nil(form["request_id"]))

    "#{socket.assigns.rulestead_admin_mount_path}/#{flag_key}/explain?#{URI.encode_query(params)}"
  end

  defp flag_detail_path(assigns) do
    Session.current_path(
      assigns,
      "#{assigns.rulestead_admin_mount_path}/#{assigns.page.flag_key}"
    )
  end

  defp simulate_path(assigns) do
    Session.current_path(
      assigns,
      "#{assigns.rulestead_admin_mount_path}/#{assigns.page.flag_key}/simulate"
    )
  end

  defp normalize_form(params) do
    %{
      "targeting_key" => Map.get(params, "targeting_key", ""),
      "tenant_key" => Map.get(params, "tenant_key", ""),
      "session_id" => Map.get(params, "session_id", ""),
      "request_id" => Map.get(params, "request_id", "")
    }
  end

  defp maybe_put(params, _key, nil), do: params
  defp maybe_put(params, key, value), do: Map.put(params, key, value)

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
