defmodule RulesteadAdmin.Live.FlagLive.Simulate do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page, nil)}
  end

  @impl true
  def handle_params(%{"key" => key}, _uri, socket) do
    page =
      socket.assigns
      |> Session.placeholder_assigns(
        current_path: "/admin/flags/#{key}/simulate",
        page_title: "#{key} simulation",
        page_kicker: "Simulation",
        page_summary: "Route-backed explain workspace reserved for one actor context at a time."
      )
      |> Map.put(:flag_key, key)

    {:noreply, assign(socket, :page, page)}
  end

  @impl true
  def render(%{page: page} = assigns) when is_map(page) do
    assigns = assign(assigns, :page, page)

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
        title="Explain inputs stay explicit"
        body="Phase 7 reserves a dedicated screen for single-context simulation, test-fixture export, and bounded trace detail."
        tone="accent"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <OperatorComponents.summary_grid
        items={[
          %{title: "Route", value: @page.current_path, tone: "neutral"},
          %{title: "Environment", value: @page.current_environment.name, tone: "neutral"},
          %{title: "Screen state", value: "Placeholder only", tone: "warning"}
        ]}
      />

      <FlagComponents.section_card title="Empty state">
        <p>No simulation request has been submitted yet.</p>
        <p>This page will keep the result summary, trace detail, and copy-as-test-fixture flow on one route-backed screen.</p>
      </FlagComponents.section_card>

      <OperatorComponents.trace_panel
        title="Trace shell"
        summary="Matched rule, bucket result, cache age, and fixture output will render here once Phase 7 feature logic lands."
        rows={[
          %{label: "Targeting key", value: "pending"},
          %{label: "Matched rule", value: "pending"},
          %{label: "Fixture export", value: "%Rulestead.Context{...}"}
        ]}
      />
    </Shell.page>
    """
  end
end
