defmodule RulesteadAdmin.Live.FlagLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :screen_action, :index)}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, :current_path, path_from_uri(uri))}
  end

  @impl true
  def render(assigns) do
    assigns =
      Map.merge(
        assigns,
        Session.placeholder_assigns(assigns,
          current_path: assigns.current_path || "/admin/flags",
          page_title: "Flags",
          page_kicker: "Flag inventory",
          page_summary: "Scanning-first placeholder for the Phase 6 flag list."
        )
      )

    ~H"""
    <Shell.page
      page_title={@page_title}
      page_kicker={@page_kicker}
      page_summary={@page_summary}
      current_environment={@current_environment}
      environments={@environments}
      env_links={@env_links}
    >
      <section>
        <h2>Flag list placeholder</h2>
        <p>
          The mounted admin package is wired. This screen stays compile-safe until
          Phase 06-04 fills in list search, filters, and pagination.
        </p>
      </section>
    </Shell.page>
    """
  end

  defp path_from_uri(uri) when is_binary(uri) do
    uri
    |> URI.parse()
    |> Map.get(:path)
  end

  defp path_from_uri(_uri), do: "/admin/flags"
end
