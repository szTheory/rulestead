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
    <span class="rs-status-indicator" title={"Environment is " <> @label}>
      <span class="rs-status-dot" data-tone={@tone}></span>
      <%= @label %>
    </span>
    """
  end

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
  attr(:id, :string, default: nil)
  slot(:inner_block, required: true)

  def section_card(assigns) do
    ~H"""
    <section id={@id} class="rs-card">
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

  @flag_subnav_tabs [
    {:overview, "Overview", ""},
    {:rules, "Rules", "/rules"},
    {:simulate, "Simulate", "/simulate"},
    {:explain, "Explain", "/explain"},
    {:rollouts, "Rollouts", "/rollouts"},
    {:timeline, "Timeline", "/timeline"}
  ]

  @doc """
  Persistent sub-navigation for a single flag, threading its lifecycle views
  (Overview · Rules · Simulate · Explain · Rollouts · Timeline) together. The
  destructive Kill switch is rendered as a fenced, right-aligned critical action
  rather than a peer tab, so it stays one click away (and bookmarkable) without
  sitting in the path of routine browsing. Cleanup/Edit are governed flows, not
  views, and intentionally stay off the strip.
  """
  attr(:flag_key, :string, required: true)
  attr(:base_path, :string, required: true)
  attr(:env_key, :string, required: true)
  attr(:current, :atom, default: :overview)
  attr(:show_kill?, :boolean, default: false)

  def flag_sub_nav(assigns) do
    assigns = assign(assigns, :tabs, @flag_subnav_tabs)

    ~H"""
    <nav class="rs-flag-subnav" aria-label="Flag views">
      <div class="rs-flag-subnav__tabs">
        <a
          :for={{key, label, suffix} <- @tabs}
          href={"#{@base_path}/#{@flag_key}#{suffix}?env=#{@env_key}"}
          class="rs-flag-subnav__tab"
          data-current={to_string(key == @current)}
          aria-current={if(key == @current, do: "page", else: nil)}
        >
          {label}
        </a>
      </div>
      <a
        :if={@show_kill?}
        href={"#{@base_path}/#{@flag_key}/kill?env=#{@env_key}"}
        class="rs-flag-subnav__kill"
        data-tone="critical"
      >
        Kill switch
      </a>
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

  defp state_tone(state), do: RulesteadAdmin.StatusTone.tone(:flag_lifecycle, state)
  defp readiness_tone(state), do: RulesteadAdmin.StatusTone.tone(:flag_readiness, state)

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
