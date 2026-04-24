defmodule RulesteadAdmin.Live.FlagLive.Kill do
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
        current_path: "/admin/flags/#{key}/kill",
        page_title: "#{key} kill switch",
        page_kicker: "Kill switch",
        page_summary: "Bookmarkable emergency override route reserved for explicit kill and restore flows."
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
        title="Emergency control stays separate from authored rules"
        body="This placeholder reserves a dedicated environment-scoped kill surface so restore behavior stays explicit and auditable."
        tone="critical"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <OperatorComponents.summary_grid
        items={[
          %{title: "Route", value: @page.current_path, tone: "neutral"},
          %{title: "Override state", value: "No active override", tone: "positive"},
          %{title: "Confirmation", value: confirmation_hint(@page.policy_state), tone: @page.policy_state.tone}
        ]}
      />

      <FlagComponents.section_card title="Empty state">
        <p>No kill-switch override is active for this environment.</p>
        <p>Phase 7 will place the engage and restore flow here without mutating the underlying authored ruleset.</p>
      </FlagComponents.section_card>

      <OperatorComponents.confirm_modal_shell
        title="Kill-switch confirmation shell"
        summary="The real implementation will require explicit confirmation before forcing the flag back to its default value."
        confirmation_hint={confirmation_hint(@page.policy_state)}
        action_label="Engage kill switch"
      />
    </Shell.page>
    """
  end

  defp confirmation_hint(%{production?: true}), do: "Typed key confirmation required for production."
  defp confirmation_hint(_policy_state), do: "Standard confirmation required for non-production environments."
end
