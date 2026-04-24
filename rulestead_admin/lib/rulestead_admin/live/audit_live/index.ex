defmodule RulesteadAdmin.Live.AuditLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page, nil)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    page =
      Session.placeholder_assigns(
        socket.assigns,
        current_path: "/admin/audit",
        page_title: "Audit timeline",
        page_kicker: "Audit",
        page_summary: "Global audit route reserved for actor, environment, and mutation filters across every flag."
      )

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
      <OperatorComponents.banner
        title="Global audit is cross-flag by design"
        body="This route holds the SRE and support investigation surface without collapsing per-flag history into the detail page."
        tone="neutral"
      />

      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <OperatorComponents.summary_grid
        items={[
          %{title: "Route", value: @page.current_path, tone: "neutral"},
          %{title: "Filter scope", value: @page.current_environment.name, tone: "neutral"},
          %{title: "Ledger mode", value: "Append-only", tone: "positive"}
        ]}
      />

      <FlagComponents.section_card title="Empty state">
        <p>No global audit filters have been applied yet.</p>
        <p>Phase 7 will add actor, environment, mutation, and date range filtering while keeping redaction and denied actions visible.</p>
      </FlagComponents.section_card>

      <OperatorComponents.audit_timeline
        title="Global timeline shell"
        entries={[
          %{title: "Flag publish", meta: "Pending actor • #{@page.current_environment.name}", summary: "Cross-flag investigation rows will render here."},
          %{title: "Kill switch denied", meta: "Pending actor • #{@page.current_environment.name}", summary: "Denied actions remain part of the audit story."}
        ]}
      />
    </Shell.page>
    """
  end
end
