defmodule RulesteadAdmin.Components.FlagComponents do
  @moduledoc false

  use Phoenix.Component

  attr :state, :any, required: true

  def lifecycle_badge(assigns) do
    assigns =
      assign(assigns,
        label:
          assigns.state
          |> normalize_state()
          |> humanize_state(),
        tone:
          assigns.state
          |> normalize_state()
          |> state_tone()
      )

    ~H"""
    <span class="rs-badge rs-badge--lifecycle" data-tone={@tone}>
      <%= @label %>
    </span>
    """
  end

  attr :state, :any, required: true
  attr :last_evaluated_at, :any, default: nil

  def stale_badge(assigns) do
    state = normalize_state(assigns.state)

    assigns =
      assign(assigns,
        label:
          if(state == :fresh, do: "Fresh", else: humanize_state(state)),
        title: stale_title(state, assigns.last_evaluated_at)
      )

    ~H"""
    <span class="rs-badge rs-badge--stale" data-tone={state_tone(normalize_state(@state))} title={@title}>
      <%= @label %>
    </span>
    """
  end

  attr :status, :any, required: true

  def environment_status(assigns) do
    status = normalize_state(assigns.status)
    assigns = assign(assigns, label: humanize_state(status))

    ~H"""
    <span class="rs-badge rs-badge--environment" data-tone={state_tone(normalize_state(@status))}>
      <%= @label %>
    </span>
    """
  end

  attr :tags, :list, default: []

  def tag_list(assigns) do
    ~H"""
    <ul class="rs-tag-list" aria-label="Tags">
      <%= for tag <- @tags do %>
        <li><span class="rs-tag"><%= tag %></span></li>
      <% end %>
    </ul>
    """
  end

  attr :page, :map, required: true
  attr :base_path, :string, required: true
  attr :params, :map, default: %{}

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:next_path, pagination_path(assigns.base_path, assigns.params, :next, assigns.page))
      |> assign(:prev_path, pagination_path(assigns.base_path, assigns.params, :prev, assigns.page))

    ~H"""
    <nav class="rs-pagination" aria-label="Flag inventory pagination">
      <.link :if={@page.has_previous_page?} patch={@prev_path} rel="prev">
        Previous page
      </.link>
      <span class="rs-pagination__meta">
        Showing up to <%= @page.limit %> flags
      </span>
      <.link :if={@page.has_next_page?} patch={@next_path} rel="next">
        Next page
      </.link>
    </nav>
    """
  end

  defp pagination_path(base_path, params, :next, %{next_cursor: cursor}) when is_binary(cursor) do
    build_path(base_path, Map.merge(params, %{"after" => cursor, "before" => nil}))
  end

  defp pagination_path(base_path, params, :prev, %{prev_cursor: cursor}) when is_binary(cursor) do
    build_path(base_path, Map.merge(params, %{"before" => cursor, "after" => nil}))
  end

  defp pagination_path(_base_path, _params, _direction, _page), do: nil

  defp build_path(base_path, params) do
    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value in ["", false, "false"] end)
      |> Enum.into([])
      |> URI.encode_query()

    if query == "", do: base_path, else: base_path <> "?" <> query
  end

  @known_states %{
    "active" => :active,
    "fresh" => :fresh,
    "potentially_stale" => :potentially_stale,
    "stale" => :stale,
    "archived" => :archived,
    "draft" => :draft
  }

  defp normalize_state(%{state: state}), do: normalize_state(state)
  defp normalize_state(nil), do: :unknown
  defp normalize_state(state) when is_binary(state), do: Map.get(@known_states, state, :unknown)
  defp normalize_state(state) when is_atom(state), do: state
  defp normalize_state(_state), do: :unknown

  defp state_tone(:active), do: "positive"
  defp state_tone(:fresh), do: "positive"
  defp state_tone(:potentially_stale), do: "warning"
  defp state_tone(:stale), do: "critical"
  defp state_tone(:archived), do: "muted"
  defp state_tone(:draft), do: "accent"
  defp state_tone(_state), do: "neutral"

  defp humanize_state(state) do
    state
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp stale_title(state, nil), do: humanize_state(state)
  defp stale_title(state, %DateTime{} = last_evaluated_at), do: "#{humanize_state(state)}. Last evaluated #{DateTime.to_iso8601(last_evaluated_at)}"
  defp stale_title(state, _value), do: humanize_state(state)
end
