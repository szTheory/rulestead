defmodule RulesteadAdmin.Live.FlagLive.Simulate do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Context
  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell, SimulateComponents}
  alias RulesteadAdmin.Live.Session

  @archetypes [
    %{
      id: "support_case",
      label: "Support case",
      summary: "Known customer context with redaction-sensitive traits.",
      form: %{
        "targeting_key" => "support-user-42",
        "tenant_key" => "acme",
        "session_id" => "sess-support-42",
        "request_id" => "req-support-42",
        "traits" => "plan=enterprise\nemail=sam@example.com\nip=203.0.113.8"
      }
    },
    %{
      id: "anonymous_checkout",
      label: "Anonymous checkout",
      summary: "Session-only context to check fallthrough behavior.",
      form: %{
        "targeting_key" => "anon-session-19",
        "tenant_key" => "",
        "session_id" => "anon-session-19",
        "request_id" => "req-anon-19",
        "traits" => "plan=free\ncountry=US"
      }
    }
  ]

  @empty_form %{
    "targeting_key" => "",
    "tenant_key" => "",
    "session_id" => "",
    "request_id" => "",
    "traits" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:form, @empty_form)
     |> assign(:selected_archetype, nil)
     |> assign(:simulation_result, nil)
     |> assign(:redacted_context, nil)
     |> assign(:fixture_export, fixture_export(@empty_form, nil))
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_params(%{"key" => key}, _uri, socket) do
    page =
      socket.assigns
      |> Session.placeholder_assigns(
        current_path: "/admin/flags/#{key}/simulate",
        page_title: "#{key} simulation",
        page_kicker: "Simulation",
        page_summary: "Run one actor context at a time, inspect the summary first, then open trace detail only when needed."
      )
      |> Map.put(:flag_key, key)
      |> Map.put(:archetypes, @archetypes)

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:fixture_export, fixture_export(socket.assigns.form, page.current_environment.key))}
  end

  @impl true
  def handle_event("validate", %{"simulation" => params}, socket) do
    form = normalize_form(params)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:fixture_export, fixture_export(form, socket.assigns.page.current_environment.key))}
  end

  def handle_event("run_simulation", %{"simulation" => params}, socket) do
    form = normalize_form(params)
    context = build_context(form, socket.assigns.page.current_environment.key)

    case Rulestead.simulate_flag(
           socket.assigns.page.flag_key,
           socket.assigns.page.current_environment.key,
           context,
           actor: socket.assigns.current_actor
         ) do
      {:ok, %{result: result, redacted_context: redacted_context}} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:simulation_result, result)
         |> assign(:redacted_context, redacted_context)
         |> assign(:fixture_export, fixture_export(form, socket.assigns.page.current_environment.key))
         |> assign(:error_message, nil)}

      {:error, error} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:simulation_result, nil)
         |> assign(:redacted_context, nil)
         |> assign(:fixture_export, fixture_export(form, socket.assigns.page.current_environment.key))
         |> assign(:error_message, error.message)}
    end
  end

  def handle_event("apply_archetype", %{"id" => id}, socket) do
    archetype = Enum.find(@archetypes, &(&1.id == id))
    form = if archetype, do: archetype.form, else: @empty_form

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:selected_archetype, archetype)
     |> assign(:simulation_result, nil)
     |> assign(:redacted_context, nil)
     |> assign(:fixture_export, fixture_export(form, socket.assigns.page.current_environment.key))
     |> assign(:error_message, nil)}
  end

  def handle_event("reset_archetype", _params, socket) do
    {:noreply,
     socket
     |> assign(:form, @empty_form)
     |> assign(:selected_archetype, nil)
     |> assign(:simulation_result, nil)
     |> assign(:redacted_context, nil)
     |> assign(:fixture_export, fixture_export(@empty_form, socket.assigns.page.current_environment.key))
     |> assign(:error_message, nil)}
  end

  def handle_event("export_fixture", _params, socket) do
    {:noreply, assign(socket, :fixture_export, fixture_export(socket.assigns.form, socket.assigns.page.current_environment.key))}
  end

  @impl true
  def render(%{page: page} = assigns) when is_map(page) do
    assigns =
      assigns
      |> assign(:page, page)
      |> assign(:summary_items, summary_items(assigns.simulation_result))
      |> assign(:visible_traits, visible_traits(assigns.redacted_context))

    ~H"""
    <Shell.page
      page_title={@page.page_title}
      page_kicker={@page.page_kicker}
      page_summary={@page.page_summary}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
    >
      <:header_actions>
        <a href={"/admin/flags/#{@page.flag_key}?env=#{@page.current_environment.key}"}>Back to detail</a>
      </:header_actions>

      <OperatorComponents.banner
        title="Single-context simulation"
        body="Use one targeting key and one trait payload, read the decision summary first, then expand trace detail only if the summary does not answer the question."
        tone="accent"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <FlagComponents.section_card title="Simulation inputs">
        <form aria-label="Simulation form" phx-change="validate" phx-submit="run_simulation">
          <div class="rs-simulate-form">
            <div>
              <label for="simulation-targeting-key">Targeting key</label>
              <input id="simulation-targeting-key" name="simulation[targeting_key]" value={@form["targeting_key"]} />
            </div>

            <div>
              <label for="simulation-tenant-key">Tenant key</label>
              <input id="simulation-tenant-key" name="simulation[tenant_key]" value={@form["tenant_key"]} />
            </div>

            <div>
              <label for="simulation-session-id">Session ID</label>
              <input id="simulation-session-id" name="simulation[session_id]" value={@form["session_id"]} />
            </div>

            <div>
              <label for="simulation-request-id">Request ID</label>
              <input id="simulation-request-id" name="simulation[request_id]" value={@form["request_id"]} />
            </div>

            <div>
              <label for="simulation-traits">Traits</label>
              <textarea id="simulation-traits" name="simulation[traits]" rows="6"><%= @form["traits"] %></textarea>
              <p>One <code>key=value</code> pair per line. Visible metadata stays redacted by default.</p>
            </div>

            <div class="rs-simulate-form__actions">
              <button type="submit">Run simulation</button>
              <button type="button" phx-click="export_fixture">Copy as test fixture</button>
            </div>
          </div>
        </form>
      </FlagComponents.section_card>

      <SimulateComponents.archetype_chips
        title="Saved archetypes"
        archetypes={@page.archetypes}
        selected_archetype={@selected_archetype}
      />

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <FlagComponents.section_card title="Simulation summary">
        <p :if={is_nil(@simulation_result)}>Run simulation to load the matched rule, bucket result, and reproducible fixture export for this environment.</p>
        <OperatorComponents.summary_grid :if={@simulation_result} items={@summary_items} />
      </FlagComponents.section_card>

      <FlagComponents.section_card title="Visible metadata">
        <p>Non-fixture UI metadata uses the admin redaction helper before it is displayed.</p>
        <dl>
          <div>
            <dt>Environment</dt>
            <dd><code><%= @page.current_environment.key %></code></dd>
          </div>
          <div>
            <dt>Targeting key</dt>
            <dd><code><%= blank(@form["targeting_key"]) %></code></dd>
          </div>
          <div>
            <dt>Traits</dt>
            <dd><code><%= @visible_traits %></code></dd>
          </div>
        </dl>
      </FlagComponents.section_card>

      <SimulateComponents.fixture_export
        fixture_export={@fixture_export}
        environment_key={@page.current_environment.key}
      />

      <SimulateComponents.trace_disclosure trace={trace_payload(@simulation_result)} />
    </Shell.page>
    """
  end

  defp normalize_form(params) do
    @empty_form
    |> Map.merge(params)
    |> Enum.into(%{}, fn {key, value} -> {key, normalize_string(value)} end)
  end

  defp build_context(form, environment_key) do
    Context.new(%{
      targeting_key: form["targeting_key"],
      tenant_key: form["tenant_key"],
      environment: environment_key,
      request_id: form["request_id"],
      session_id: form["session_id"],
      attributes: parse_traits(form["traits"])
    })
  end

  defp parse_traits(traits) do
    traits
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, "=", parts: 2) do
        [key, value] ->
          Map.put(acc, String.trim(key), coerce_scalar(String.trim(value)))

        _other ->
          acc
      end
    end)
  end

  defp coerce_scalar("true"), do: true
  defp coerce_scalar("false"), do: false

  defp coerce_scalar(value) do
    cond do
      value == "" ->
        ""

      Regex.match?(~r/^-?\d+$/, value) ->
        String.to_integer(value)

      Regex.match?(~r/^-?\d+\.\d+$/, value) ->
        String.to_float(value)

      true ->
        value
    end
  end

  defp summary_items(nil), do: []

  defp summary_items(result) do
    rollout = result.debug_trace[:rollout] || %{}

    [
      %{title: "Matched rule", value: result.matched_rule || "Default path", tone: matched_rule_tone(result)},
      %{title: "Returned value", value: inspect(result.value), tone: "neutral"},
      %{title: "Variant", value: result.variant || "None", tone: "neutral"},
      %{title: "Reason", value: humanize(result.reason), tone: "neutral"},
      %{title: "Bucket result", value: bucket_summary(rollout), tone: "neutral"},
      %{title: "Snapshot version", value: result.flag_version || "Unknown", tone: "neutral"},
      %{title: "Cache age", value: cache_age(result.cache_age_ms), tone: "neutral"}
    ]
  end

  defp matched_rule_tone(%{matched_rule: nil}), do: "warning"
  defp matched_rule_tone(_result), do: "positive"

  defp bucket_summary(%{bucket: bucket, variant: variant}) when is_integer(bucket),
    do: "#{bucket} -> #{variant || "matched"}"

  defp bucket_summary(%{bucket: bucket}) when is_integer(bucket), do: Integer.to_string(bucket)
  defp bucket_summary(_rollout), do: "No rollout bucket"

  defp cache_age(nil), do: "Unknown"
  defp cache_age(cache_age_ms), do: "#{cache_age_ms}ms"

  defp trace_payload(nil), do: nil
  defp trace_payload(result), do: result.debug_trace || %{}

  defp visible_traits(nil), do: "No traits submitted"

  defp visible_traits(redacted_context) do
    redacted_context
    |> get_in([:audit, :traits])
    |> case do
      nil -> "No traits submitted"
      traits -> inspect(traits, sort_maps: true)
    end
  end

  defp fixture_export(form, environment_key) do
    context =
      Context.new(%{
        targeting_key: form["targeting_key"],
        tenant_key: form["tenant_key"],
        environment: environment_key,
        request_id: form["request_id"],
        session_id: form["session_id"],
        attributes: parse_traits(form["traits"])
      })

    """
    %Rulestead.Context{
      actor: #{literal(context.actor)},
      targeting_key: #{literal(context.targeting_key)},
      tenant_key: #{literal(context.tenant_key)},
      environment: #{literal(context.environment)},
      attributes: #{literal(context.attributes)},
      request_id: #{literal(context.request_id)},
      session_id: #{literal(context.session_id)},
      strict?: #{literal(context.strict?)}
    }
    """
    |> String.trim()
  end

  defp literal(value) when is_map(value), do: inspect(value, pretty: true, sort_maps: true)
  defp literal(value), do: inspect(value)

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
  defp humanize(value), do: inspect(value)

  defp normalize_string(nil), do: ""
  defp normalize_string(value) when is_binary(value), do: value
  defp normalize_string(value), do: to_string(value)

  defp blank(""), do: "Not provided"
  defp blank(nil), do: "Not provided"
  defp blank(value), do: value
end
