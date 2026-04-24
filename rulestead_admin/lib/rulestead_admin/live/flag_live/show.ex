defmodule RulesteadAdmin.Live.FlagLive.Show do
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
          current_path: assigns.current_path || "/admin/flags/#{assigns.flag_key}",
          page_title: assigns.flag_key || "Flag detail",
          page_kicker: "Flag detail",
          page_summary: "Compile-safe placeholder for the calm read surface."
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
        <h2>Flag detail placeholder</h2>
        <p>Flag key: <code><%= @flag_key %></code></p>
        <p>
          The detail route and environment shell are mounted now so Phase 06-04 can
          fill in summary, lifecycle, and environment status without changing the mount contract.
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
