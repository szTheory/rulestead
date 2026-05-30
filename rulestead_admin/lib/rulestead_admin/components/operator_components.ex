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

  attr(:policy_state, :map, required: true)

  def policy_state(assigns) do
    ~H"""
    <aside class="rs-policy-state" data-tone={@policy_state.tone}>
      <div class="rs-policy-state__badge" title={"You have #{highest_capability(Map.get(@policy_state, :capabilities))} access in this environment. " <> capability_summary(Map.get(@policy_state, :capabilities))}>
        <span aria-hidden="true">🛡️</span> Your access: <%= highest_capability(Map.get(@policy_state, :capabilities)) %>
      </div>
    </aside>
    """
  end

  defp highest_capability(%{admin?: true}), do: "Admin"
  defp highest_capability(%{execute?: true}), do: "Execute"
  defp highest_capability(%{propose?: true}), do: "Propose"
  defp highest_capability(%{read?: true}), do: "Read-Only"
  defp highest_capability(_), do: "None"

  defp capability_summary(nil), do: "No capabilities defined"

  defp capability_summary(caps) do
    "Permissions - Read: #{caps.read?}, Execute: #{caps.execute?}, Propose: #{caps.propose?}, Admin: #{caps.admin?}"
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
