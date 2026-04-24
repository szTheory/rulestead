defmodule RulesteadAdmin.Components.RolloutComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:steps, :list, default: [])
  attr(:current, :integer, default: 0)
  attr(:selected, :integer, default: 0)

  def ladder(assigns) do
    ~H"""
    <section class="rs-rollout-ladder" aria-label="Suggested rollout ladder">
      <h2>Suggested rollout ladder</h2>
      <p>Recommendations stay advisory. Operators still choose when to preview, save, and publish.</p>
      <ol>
        <li :for={step <- @steps} data-current={to_string(step == @current)} data-selected={to_string(step == @selected)}>
          <strong><%= step %>%</strong>
          <span :if={step == @current}>Current</span>
          <span :if={step == @selected and step != @current}>Selected</span>
        </li>
      </ol>
    </section>
    """
  end

  attr(:entries, :list, default: [])
  attr(:current_rule_key, :string, default: nil)

  def order_context(assigns) do
    ~H"""
    <ol class="rs-rollout-order" aria-label="Rule order">
      <li :for={entry <- @entries} data-current={to_string(entry.current?)}>
        <strong><%= entry.label %></strong>
        <span><%= entry.title %></span>
        <span :if={entry.current?}>Current rollout rule</span>
      </li>
    </ol>
    """
  end

  attr(:variants, :list, default: [])

  def variant_weights(assigns) do
    ~H"""
    <section class="rs-rollout-variants" aria-label="Variant weights">
      <h2>Variant weights stay locked on this page</h2>
      <p>Use the dedicated rules workspace if composition itself needs to change.</p>
      <ul>
        <li :for={variant <- @variants}>
          <code><%= variant.key %></code>
          <span><%= variant.weight %>%</span>
        </li>
      </ul>
    </section>
    """
  end

  attr(:preview, :map, default: nil)
  attr(:percentage, :integer, default: 0)
  attr(:sample_size, :integer, default: 0)

  def preview_panel(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Sample preview">
      <h2>Sample preview</h2>
      <p>Preview only. This panel compares intended exposure to a bounded deterministic sample before publish.</p>
      <div :if={is_nil(@preview)}>
        <p>Run preview to compare <%= @percentage %>% intended exposure against <%= @sample_size %> deterministic sample keys.</p>
      </div>
      <div :if={@preview}>
        <p><%= @preview.sample_size %> deterministic sample keys</p>
        <p>Intended exposure: <strong><%= @preview.intended_percentage %>%</strong></p>
        <p>Observed assignments: <strong><%= @preview.observed_percentage %>%</strong> hit the rollout rule.</p>
        <ul aria-label="Observed assignments">
          <li :for={{variant, count} <- Enum.sort(@preview.variant_counts)}>
            <code><%= variant %></code>
            <span><%= count %>/<%= @preview.sample_size %></span>
          </li>
        </ul>
      </div>
    </section>
    """
  end
end
