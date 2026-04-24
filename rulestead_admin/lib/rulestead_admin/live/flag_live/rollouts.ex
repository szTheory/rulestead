defmodule RulesteadAdmin.Live.FlagLive.Rollouts do
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
        current_path: "/admin/flags/#{key}/rollouts",
        page_title: "#{key} rollout controls",
        page_kicker: "Rollouts",
        page_summary: "Draft-aware rollout screen reserved for explicit ramps, previews, and publish confirmations."
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
        <a href={"/admin/flags/#{@page.flag_key}/rules?env=#{@page.current_environment.key}"}>Open rules workspace</a>
      </:header_actions>

      <OperatorComponents.banner
        title="Rollouts stay monotonic and explicit"
        body="This screen will layer preview-rich percentage ramps on top of the existing draft and publish boundary."
        tone="warning"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <OperatorComponents.summary_grid
        items={[
          %{title: "Route", value: @page.current_path, tone: "neutral"},
          %{title: "Current scope", value: @page.current_environment.name, tone: "neutral"},
          %{title: "Persistence", value: "No hidden saves", tone: "warning"}
        ]}
      />

      <FlagComponents.section_card title="Empty state">
        <p>No rollout plan has been drafted for this environment yet.</p>
        <p>The final implementation will keep preview feedback responsive while preserving explicit save and publish actions.</p>
      </FlagComponents.section_card>

      <OperatorComponents.rollout_ladder steps={["5%", "25%", "50%", "100%"]} current="25%" />
    </Shell.page>
    """
  end
end
