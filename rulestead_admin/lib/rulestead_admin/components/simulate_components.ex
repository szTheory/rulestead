defmodule RulesteadAdmin.Components.SimulateComponents do
  @moduledoc false

  use Phoenix.Component

  attr :title, :string, required: true
  attr :archetypes, :list, default: []
  attr :selected_archetype, :map, default: nil

  def archetype_chips(assigns) do
    ~H"""
    <section class="rs-card" aria-label={@title}>
      <h2><%= @title %></h2>
      <p :if={@selected_archetype}>
        <strong><%= @selected_archetype.label %></strong>
        <span><%= @selected_archetype.summary %></span>
      </p>
      <p :if={is_nil(@selected_archetype)}>No saved archetype applied</p>

      <div class="rs-archetype-chips">
        <button
          :for={archetype <- @archetypes}
          type="button"
          phx-click="apply_archetype"
          phx-value-id={archetype.id}
          aria-label={"Apply #{archetype.label} archetype"}
        >
          <%= archetype.label %>
        </button>

        <button type="button" phx-click="reset_archetype">Reset archetype</button>
      </div>
    </section>
    """
  end

  attr :fixture_export, :string, required: true
  attr :environment_key, :string, required: true

  def fixture_export(assigns) do
    ~H"""
    <section class="rs-card" aria-label="Fixture export">
      <h2>Fixture export</h2>
      <p>Copy as test fixture returns the canonical context literal for <code><%= @environment_key %></code>.</p>
      <textarea aria-label="ExUnit fixture export" readonly rows="12"><%= @fixture_export %></textarea>
    </section>
    """
  end

  attr :trace, :map, default: nil

  def trace_disclosure(assigns) do
    ~H"""
    <section class="rs-card">
      <h2>Trace detail</h2>
      <p>Show rule-by-rule detail only when the summary is not enough.</p>
      <details aria-label="Trace detail">
        <summary>Show rule-by-rule detail</summary>

        <div :if={is_nil(@trace)}>
          <p>No trace yet. Run simulation first.</p>
        </div>

        <div :if={@trace}>
          <h3>Condition checks</h3>
          <ul>
            <li :for={rule_trace <- Map.get(@trace, :rule_traces, [])}>
              <strong><%= rule_trace.rule_key %></strong>
              <span><%= if rule_trace.matched?, do: "matched", else: "skipped" %></span>

              <ul>
                <li :for={condition <- Map.get(rule_trace, :conditions, [])}>
                  <code><%= condition.attribute %></code>
                  <span><%= humanize(condition.reason) %></span>
                  <span>actual=<%= inspect(condition.actual) %></span>
                </li>
              </ul>
            </li>
          </ul>

          <h3>Bucket math</h3>
          <dl>
            <div>
              <dt>Outcome</dt>
              <dd><code><%= humanize(Map.get(@trace, :outcome)) %></code></dd>
            </div>
            <div :for={rule_trace <- Map.get(@trace, :rule_traces, [])}>
              <dt><%= rule_trace.rule_key %></dt>
              <dd><code><%= bucket_row(rule_trace.rollout) %></code></dd>
            </div>
          </dl>
        </div>
      </details>
    </section>
    """
  end

  defp bucket_row(%{bucket: bucket, variant_bucket: variant_bucket, percentage: percentage, bucket_by: bucket_by}) do
    "#{bucket_by} bucket=#{bucket}, variant_bucket=#{variant_bucket}, percentage=#{percentage}"
  end

  defp bucket_row(%{bucket: bucket, bucket_by: bucket_by}) when is_integer(bucket) do
    "#{bucket_by} bucket=#{bucket}"
  end

  defp bucket_row(_rollout), do: "No rollout bucket"

  defp humanize(nil), do: "unknown"
  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
end
