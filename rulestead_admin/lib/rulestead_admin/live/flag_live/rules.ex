defmodule RulesteadAdmin.Live.FlagLive.Rules do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :flag_key, nil)}
  end

  @impl true
  def handle_params(%{"key" => flag_key}, uri, socket) do
    socket =
      socket
      |> assign(:flag_key, flag_key)
      |> assign(:current_path, path_from_uri(uri))

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      Map.merge(
        assigns,
        Session.placeholder_assigns(assigns,
          current_path: assigns.current_path || "/admin/flags/#{assigns.flag_key}/rules",
          page_title: "Rules workspace",
          page_kicker: "Rules editor",
          page_summary: "Dedicated placeholder workspace for draft-first rule authoring."
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
        <h2>Rules workspace placeholder</h2>
        <p>Flag key: <code><%= @flag_key %></code></p>
        <p>
          This route exists now so the editor work can land on a stable, policy-aware
          session seam in Phase 06-05.
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
