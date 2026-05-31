defmodule RulesteadAdmin.Components.FlagComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:state, :any, required: true)

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

  attr(:state, :any, required: true)
  attr(:last_evaluated_at, :any, default: nil)

  def stale_badge(assigns) do
    state = normalize_state(assigns.state)

    assigns =
      assign(assigns,
        label: if(state == :fresh, do: "Fresh", else: humanize_state(state)),
        title: stale_title(state, assigns.last_evaluated_at)
      )

    ~H"""
    <span class="rs-badge rs-badge--stale" data-tone={state_tone(normalize_state(@state))} title={@title}>
      <%= @label %>
    </span>
    """
  end

  attr(:status, :any, required: true)

  def environment_status(assigns) do
    status = normalize_state(assigns.status)
    assigns = assign(assigns, label: humanize_state(status), tone: state_tone(status))

    ~H"""
    <span class="rs-status-indicator" title={"Environment is " <> @label} style="display: inline-flex; align-items: center; gap: 0.375rem; font-size: 0.875rem; font-weight: 500; color: var(--rs-color-text-muted, #4b5563);">
      <span class="rs-status-dot" style={"width: 0.5rem; height: 0.5rem; border-radius: 9999px; " <> dot_color(@tone)}></span>
      <%= @label %>
    </span>
    """
  end

  defp dot_color("positive"), do: "background-color: var(--rs-color-positive-600, #16a34a);"
  defp dot_color("warning"), do: "background-color: var(--rs-color-warning-500, #f59e0b);"
  defp dot_color("critical"), do: "background-color: var(--rs-color-critical-600, #dc2626);"
  defp dot_color(_), do: "background-color: var(--rs-color-neutral-400, #9ca3af);"

  attr(:readiness, :any, required: true)

  def readiness_badge(assigns) do
    readiness = normalize_readiness(assigns.readiness)

    assigns =
      assign(assigns,
        label: humanize_state(readiness),
        tone: readiness_tone(readiness)
      )

    ~H"""
    <span class="rs-badge rs-badge--readiness" data-tone={@tone}>
      <%= @label %>
    </span>
    """
  end

  attr(:quality, :any, required: true)

  def evidence_quality_badge(assigns) do
    quality = normalize_quality(assigns.quality)

    assigns =
      assign(assigns,
        label: humanize_state(quality),
        tone: quality_tone(quality)
      )

    ~H"""
    <span class="rs-badge rs-badge--evidence" data-tone={@tone}>
      <%= @label %>
    </span>
    """
  end

  attr(:tags, :list, default: [])

  def tag_list(assigns) do
    ~H"""
    <ul class="rs-tag-list" aria-label="Tags">
      <%= for tag <- @tags do %>
        <li><span class="rs-tag"><%= tag %></span></li>
      <% end %>
    </ul>
    """
  end

  attr(:page, :map, required: true)
  attr(:base_path, :string, required: true)
  attr(:params, :map, default: %{})

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(
        :next_path,
        pagination_path(assigns.base_path, assigns.params, :next, assigns.page)
      )
      |> assign(
        :prev_path,
        pagination_path(assigns.base_path, assigns.params, :prev, assigns.page)
      )

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

  attr(:title, :string, required: true)
  attr(:value, :any, required: true)
  attr(:tone, :string, default: "neutral")

  def stat(assigns) do
    ~H"""
    <article class="rs-stat" data-tone={@tone}>
      <p class="rs-stat__title"><%= @title %></p>
      <p class="rs-stat__value"><%= @value %></p>
    </article>
    """
  end

  attr(:title, :string, required: true)
  slot(:inner_block, required: true)

  def section_card(assigns) do
    ~H"""
    <section class="rs-card">
      <h2><%= @title %></h2>
      <div><%= render_slot(@inner_block) %></div>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:tone, :string, default: "neutral")
  slot(:inner_block, required: true)

  def callout(assigns) do
    ~H"""
    <section class="rs-card rs-callout" data-tone={@tone}>
      <h2><%= @title %></h2>
      <div><%= render_slot(@inner_block) %></div>
    </section>
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

  @known_readiness %{
    "keep_active" => :keep_active,
    "needs_review" => :needs_review,
    "archive_candidate" => :archive_candidate
  }

  @known_quality %{
    "strong" => :strong,
    "partial" => :partial,
    "weak" => :weak
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

  defp readiness_tone(:keep_active), do: "positive"
  defp readiness_tone(:needs_review), do: "warning"
  defp readiness_tone(:archive_candidate), do: "critical"
  defp readiness_tone(_readiness), do: "neutral"

  defp quality_tone(:strong), do: "positive"
  defp quality_tone(:partial), do: "warning"
  defp quality_tone(:weak), do: "neutral"
  defp quality_tone(_quality), do: "neutral"

  defp humanize_state(state) do
    state
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp stale_title(state, nil), do: humanize_state(state)

  defp stale_title(state, %DateTime{} = last_evaluated_at),
    do: "#{humanize_state(state)}. Last evaluated #{DateTime.to_iso8601(last_evaluated_at)}"

  defp stale_title(state, _value), do: humanize_state(state)

  defp normalize_readiness(%{readiness: readiness}), do: normalize_readiness(readiness)
  defp normalize_readiness(nil), do: :unknown

  defp normalize_readiness(readiness) when is_binary(readiness),
    do: Map.get(@known_readiness, readiness, :unknown)

  defp normalize_readiness(readiness) when is_atom(readiness), do: readiness
  defp normalize_readiness(_readiness), do: :unknown

  defp normalize_quality(nil), do: :unknown

  defp normalize_quality(quality) when is_binary(quality),
    do: Map.get(@known_quality, quality, :unknown)

  defp normalize_quality(quality) when is_atom(quality), do: quality
  defp normalize_quality(_quality), do: :unknown
end
