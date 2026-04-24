defmodule RulesteadAdmin.Live.FlagLive.Timeline do
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
        current_path: "/admin/flags/#{key}/timeline",
        page_title: "#{key} audit timeline",
        page_kicker: "Timeline",
        page_summary: "Per-flag audit route reserved for append-only history, readable diffs, and linked rollback context."
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
        <a href={"/admin/audit?env=#{@page.current_environment.key}"}>Open global audit</a>
      </:header_actions>

      <OperatorComponents.banner
        title="Audit stays append-only"
        body="This per-flag timeline will surface successful and denied writes, environment scope, and linked rollback events."
        tone="neutral"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <FlagComponents.section_card title="Empty state">
        <p>No audit entries are rendered yet.</p>
        <p>The final screen will prioritize readable event summaries first and only expand into raw structure when needed.</p>
      </FlagComponents.section_card>

      <OperatorComponents.audit_timeline
        title="Per-flag timeline shell"
        entries={[
          %{title: "Draft saved", meta: "Pending actor • #{@page.current_environment.name}", summary: "Structured audit rows will appear here."},
          %{title: "Publish", meta: "Pending actor • #{@page.current_environment.name}", summary: "Rollback links and denied writes will share this timeline."}
        ]}
      />

      <OperatorComponents.diff_card
        title="Diff shell"
        summary="Readable before/after diffs will live beside each event without making raw JSON the default."
        before_value="%{state: :before}"
        after_value="%{state: :after}"
      />
    </Shell.page>
    """
  end
end
