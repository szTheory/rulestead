defmodule RulesteadAdmin.Components.OperatorComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:tone, :string, default: "neutral")
  attr(:aria_label, :string, default: nil)

  def banner(assigns) do
    ~H"""
    <section class="rs-banner" data-tone={@tone} aria-label={@aria_label}>
      <h2><%= @title %></h2>
      <p><%= @body %></p>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:summary, :string, default: nil)
  slot(:inner_block)

  def page_section(assigns) do
    ~H"""
    <section class="rs-page-section">
      <h2><%= @title %></h2>
      <p :if={@summary}><%= @summary %></p>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:href, :string, required: true)
  attr(:meta, :string, default: nil)
  attr(:tone, :string, default: "neutral")
  slot(:inner_block)
  slot(:actions)

  def record_row(assigns) do
    ~H"""
    <article class="rs-record-row" data-tone={@tone}>
      <header class="rs-record-row__header">
        <div>
          <h3 class="rs-record-row__title"><a href={@href}><%= @title %></a></h3>
          <p :if={@meta} class="rs-record-row__meta"><%= @meta %></p>
        </div>
        <div :if={@actions != []} class="rs-record-row__actions">
          <%= render_slot(@actions) %>
        </div>
      </header>
      <div :if={@inner_block != []} class="rs-record-row__body">
        <%= render_slot(@inner_block) %>
      </div>
    </article>
    """
  end

  attr(:rows, :list, default: [])

  def detail_grid(assigns) do
    ~H"""
    <dl class="rs-kv-grid">
      <div :for={row <- @rows}>
        <dt><%= row.label %></dt>
        <dd><%= row.value %></dd>
      </div>
    </dl>
    """
  end

  attr(:links, :list, default: [])

  def related_links(assigns) do
    ~H"""
    <nav class="rs-related-links" aria-label="Related routes">
      <a :for={link <- @links} href={link.path}><%= link.label %></a>
    </nav>
    """
  end

  attr(:items, :list, default: [])
  attr(:aria_label, :string, default: "Summary")

  def summary_grid(assigns) do
    ~H"""
    <section class="rs-summary-grid" aria-label={@aria_label}>
      <article :for={item <- @items} class="rs-stat" data-tone={Map.get(item, :tone, "neutral")}>
        <p class="rs-stat__title"><%= item.title %></p>
        <p class="rs-stat__value"><%= item.value %></p>
      </article>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:reason, :string, required: true)
  attr(:tone, :string, default: "warning")

  def capability_explanation(assigns) do
    ~H"""
    <div class="rs-capability-explanation" data-tone={@tone}>
      <strong><%= @title %></strong>
      <span><%= @reason %></span>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:rows, :list, default: [])

  def trace_panel(assigns) do
    ~H"""
    <section class="rs-trace-panel">
      <h2><%= @title %></h2>
      <p><%= @summary %></p>
      <dl>
        <div :for={row <- @rows}>
          <dt><%= row.label %></dt>
          <dd><code><%= row.value %></code></dd>
        </div>
      </dl>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:entries, :list, default: [])

  def status_list(assigns) do
    ~H"""
    <section class="rs-status-list" aria-label={@title}>
      <h2><%= @title %></h2>
      <dl>
        <div :for={entry <- @entries} class="rs-status-list__row" data-tone={Map.get(entry, :tone, "neutral")}>
          <dt><%= entry.label %></dt>
          <dd>
            <strong><%= entry.value %></strong>
            <span :if={Map.get(entry, :summary)}><%= entry.summary %></span>
          </dd>
        </div>
      </dl>
    </section>
    """
  end

  attr(:steps, :list, default: [])
  attr(:current, :string, default: nil)

  def rollout_ladder(assigns) do
    ~H"""
    <section class="rs-rollout-ladder" aria-label="Suggested rollout ladder">
      <ol>
        <li :for={step <- @steps} data-current={to_string(step == @current)}>
          <strong><%= step %></strong>
          <span :if={step == @current}>Current recommendation</span>
        </li>
      </ol>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:confirmation_hint, :string, required: true)
  attr(:action_label, :string, required: true)

  def confirm_modal_shell(assigns) do
    ~H"""
    <section class="rs-confirm-modal" aria-label={@title}>
      <h2><%= @title %></h2>
      <p><%= @summary %></p>
      <p><strong>Confirmation:</strong> <%= @confirmation_hint %></p>
      <button type="button" disabled><%= @action_label %></button>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:entries, :list, default: [])

  def audit_timeline(assigns) do
    ~H"""
    <section class="rs-audit-timeline" aria-label={@title}>
      <h2><%= @title %></h2>
      <ul>
        <li :for={entry <- @entries}>
          <strong><%= entry.title %></strong>
          <span><%= entry.meta %></span>
          <p><%= entry.summary %></p>
        </li>
      </ul>
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:summary, :string, required: true)
  attr(:before_value, :string, required: true)
  attr(:after_value, :string, required: true)

  def diff_card(assigns) do
    ~H"""
    <section class="rs-diff-card" aria-label={@title}>
      <h2><%= @title %></h2>
      <p><%= @summary %></p>
      <div class="rs-diff-card__values">
        <div>
          <p>Before</p>
          <code><%= @before_value %></code>
        </div>
        <div>
          <p>After</p>
          <code><%= @after_value %></code>
        </div>
      </div>
    </section>
    """
  end
end
