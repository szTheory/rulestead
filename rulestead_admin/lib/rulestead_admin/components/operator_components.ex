defmodule RulesteadAdmin.Components.OperatorComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:name, :string, required: true)

  def action_icon(assigns) do
    ~H"""
    <span class="rs-action-icon" data-icon={@name} aria-hidden="true">
      <svg :if={@name == "archive"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M4.25 6.5h11.5M6 6.5v8.25h8V6.5M7.25 4.25h5.5l1 2.25h-7.5l1-2.25ZM8 10h4" />
      </svg>
      <svg :if={@name == "back"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M11.75 5.25 7 10l4.75 4.75M7.5 10h8" />
      </svg>
      <svg :if={@name == "compare"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M6.5 4.5 3.5 7.5l3 3M3.75 7.5h12M13.5 9.5l3 3-3 3M4.25 12.5h12" />
      </svg>
      <svg :if={@name == "create"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M10 4.25v11.5M4.25 10h11.5" />
      </svg>
      <svg :if={@name == "diagnostics"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M3.75 10h3l1.5-4.5 3.25 9 1.5-4.5h3.25" />
      </svg>
      <svg :if={@name == "edit"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M5 14.75h3.25L15 8l-3.25-3.25L5 11.5v3.25ZM10.75 5.75 14 9" />
      </svg>
      <svg :if={@name == "execute"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M8.25 4.75 14 10l-5.75 5.25V4.75Z" />
      </svg>
      <svg :if={@name == "explain"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M10 15.5v.05M8.25 8a2 2 0 1 1 3.35 1.48c-.95.86-1.6 1.35-1.6 2.52" />
        <circle cx="10" cy="10" r="7" />
      </svg>
      <svg :if={@name == "kill"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M7 3.75h6L16.25 7v6L13 16.25H7L3.75 13V7L7 3.75Z" />
        <path d="M7.5 7.5 12.5 12.5M12.5 7.5 7.5 12.5" />
      </svg>
      <svg :if={@name == "preview"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M2.75 10s2.5-4.75 7.25-4.75S17.25 10 17.25 10 14.75 14.75 10 14.75 2.75 10 2.75 10Z" />
        <circle cx="10" cy="10" r="2.25" />
      </svg>
      <svg :if={@name == "publish"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M10 14.75V4.5M6.25 8.25 10 4.5l3.75 3.75M4.5 15.5h11" />
      </svg>
      <svg :if={@name == "reject"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M5.5 5.5 14.5 14.5M14.5 5.5 5.5 14.5" />
      </svg>
      <svg :if={@name == "rules"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M5 5.5h10M5 10h10M5 14.5h6M3.25 5.5h.05M3.25 10h.05M3.25 14.5h.05" />
      </svg>
      <svg :if={@name == "save"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M5 4.5h8l2 2v9H5v-11ZM7 4.5v4h5v-4M7.5 15.5v-4h5v4" />
      </svg>
      <svg :if={@name == "schedule"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M6.25 3.75v2.5M13.75 3.75v2.5M4.5 7.5h11M5 5.25h10v10.5H5V5.25ZM10 10v2.75l2 1.25" />
      </svg>
      <svg :if={@name == "simulate"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M7.25 5.25 14 10l-6.75 4.75V5.25Z" />
      </svg>
      <svg :if={@name == "timeline"} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M10 5.75V10l2.75 1.75" />
        <circle cx="10" cy="10" r="6.75" />
      </svg>
      <svg :if={@name not in ~w(archive back compare create diagnostics edit execute explain kill preview publish reject rules save schedule simulate timeline)} viewBox="0 0 20 20" fill="none" focusable="false">
        <path d="M10 4.25v11.5M4.25 10h11.5" />
      </svg>
    </span>
    """
  end

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:tone, :string, default: "neutral")
  attr(:aria_label, :string, default: nil)
  slot(:actions)

  def banner(assigns) do
    ~H"""
    <section class="rs-banner" data-tone={@tone} aria-label={@aria_label}>
      <h2><%= @title %></h2>
      <p><%= @body %></p>
      <div :if={@actions != []} class="rs-banner__actions">
        <%= render_slot(@actions) %>
      </div>
    </section>
    """
  end

  attr(:aria_label, :string, default: "Page actions")
  slot(:inner_block, required: true)

  def action_bar(assigns) do
    ~H"""
    <div class="rs-action-bar" role="group" aria-label={@aria_label}>
      <%= render_slot(@inner_block) %>
    </div>
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
          <h3 class="rs-record-row__title"><.link navigate={@href}><%= @title %></.link></h3>
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

  attr(:title, :string, required: true)
  attr(:summary, :string, default: nil)
  attr(:href, :string, required: true)
  attr(:tone, :string, default: "neutral")
  attr(:primary?, :boolean, default: false)
  attr(:icon, :string, default: nil)

  def task_link(assigns) do
    ~H"""
    <.link
      class={["rs-task-link", @primary? && "rs-task-link--primary"]}
      data-tone={@tone}
      navigate={@href}
    >
      <span class="rs-task-link__label">
        <.action_icon :if={@icon} name={@icon} />
        <strong><%= @title %></strong>
      </span>
      <span :if={@summary} class="rs-task-link__summary"><%= @summary %></span>
    </.link>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :any, required: true)
  attr(:tone, :string, default: "neutral")

  def signal(assigns) do
    ~H"""
    <div class="rs-signal" data-tone={@tone}>
      <span><%= @label %></span>
      <strong><%= @value %></strong>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:icon, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:variant, :string, default: "default")
  slot(:actions)

  def empty_state(assigns) do
    ~H"""
    <section id={@id} class="rs-empty-state" data-variant={@variant} aria-label={@title}>
      <div :if={@icon} class="rs-empty-state__icon" aria-hidden="true"><%= @icon %></div>
      <h2 class="rs-empty-state__title"><%= @title %></h2>
      <p class="rs-empty-state__text"><%= @body %></p>
      <div :if={@actions != []} class="rs-empty-state__actions">
        <%= render_slot(@actions) %>
      </div>
    </section>
    """
  end

  attr(:links, :list, default: [])

  def related_links(assigns) do
    ~H"""
    <nav class="rs-related-links" aria-label="Related routes">
      <.link :for={link <- @links} navigate={link.path}><%= link.label %></.link>
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
end
