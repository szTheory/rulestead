defmodule Rulestead.Guardrails.Decision do
  @moduledoc false

  alias Rulestead.Guardrails.SignalFact

  @recoverable_reasons [:stale, :insufficient_sample]
  @terminal_reasons [
    :provider_missing,
    :unsupported_signal,
    :unsupported_scope,
    :invalid_provider_response
  ]

  @enforce_keys [:state, :reason, :evaluated_at]
  defstruct [:state, :reason, :evaluated_at, :monitoring_window_closed?, signal_facts: []]

  @type t :: %__MODULE__{
          state: :healthy | :pending_data | :held | :rollback_triggered,
          reason: String.t(),
          evaluated_at: DateTime.t(),
          monitoring_window_closed?: boolean(),
          signal_facts: [SignalFact.t()]
        }

  @spec evaluate([SignalFact.t() | map()], keyword()) :: t()
  def evaluate(signal_facts, opts \\ []) do
    facts = Enum.map(signal_facts, &SignalFact.new/1)

    evaluated_at =
      Keyword.get(opts, :evaluated_at, DateTime.utc_now()) |> DateTime.truncate(:second)

    monitoring_window_closed? =
      monitoring_window_closed?(evaluated_at, Keyword.get(opts, :monitoring_window_ends_at))

    {state, reason} = classify_facts(facts, monitoring_window_closed?)

    %__MODULE__{
      state: state,
      reason: reason,
      evaluated_at: evaluated_at,
      monitoring_window_closed?: monitoring_window_closed?,
      signal_facts: facts
    }
  end

  defp classify_facts([], true), do: {:held, "monitoring_window_expired"}
  defp classify_facts([], false), do: {:pending_data, "monitoring_window_active"}

  defp classify_facts(facts, monitoring_window_closed?) do
    cond do
      fact = Enum.find(facts, &(&1.reason in @terminal_reasons)) ->
        {:held, Atom.to_string(fact.reason)}

      fact = Enum.find(facts, &(&1.reason == :breached)) ->
        {:rollback_triggered, Atom.to_string(fact.reason)}

      fact = Enum.find(facts, &(&1.reason in @recoverable_reasons)) ->
        recoverable_state(fact, monitoring_window_closed?)

      Enum.all?(facts, &(&1.reason == :healthy)) ->
        {:healthy, "healthy"}

      true ->
        default_window_state(monitoring_window_closed?)
    end
  end

  defp recoverable_state(fact, true), do: {:held, Atom.to_string(fact.reason)}
  defp recoverable_state(fact, false), do: {:pending_data, Atom.to_string(fact.reason)}

  defp default_window_state(true), do: {:held, "monitoring_window_expired"}
  defp default_window_state(false), do: {:pending_data, "monitoring_window_active"}

  defp monitoring_window_closed?(evaluated_at, %DateTime{} = ends_at),
    do: DateTime.compare(evaluated_at, ends_at) in [:gt, :eq]

  defp monitoring_window_closed?(_evaluated_at, _ends_at), do: false
end
