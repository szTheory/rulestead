defmodule RulesteadAdmin.Components.AudienceTraceComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:rule_traces, :list, default: [])

  def audience_trace_steps(assigns) do
    ~H"""
    <section :if={@rule_traces != []} class="rs-card" aria-label="Audience trace steps">
      <h3>Audience targeting</h3>
      <ul>
        <li :for={trace <- @rule_traces}>
          <strong><%= trace.rule_key %></strong>
          <span :if={audience_trace = Map.get(trace, :audience_trace)}>
            — audience <code><%= audience_trace.audience_key %></code>:
            <%= audience_status(audience_trace) %>
          </span>
          <span :if={is_nil(Map.get(trace, :audience_trace))}> — no reusable audience on this rule</span>
        </li>
      </ul>
    </section>
    """
  end

  defp audience_status(%{matched?: true, reason: :matched}), do: "matched"
  defp audience_status(%{matched?: false, reason: :missed}), do: "missed"
  defp audience_status(%{reason: :missing}), do: "missing from snapshot"
  defp audience_status(%{reason: :archived}), do: "archived"
  defp audience_status(_), do: "unknown"
end
