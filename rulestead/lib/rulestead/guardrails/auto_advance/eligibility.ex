defmodule Rulestead.Guardrails.AutoAdvance.Eligibility do
  @moduledoc false

  @enforce_keys [:status, :reasons]
  defstruct [
    :status,
    :reasons,
    :policy_snapshot,
    :decision_summary,
    :monitoring_window_closed?
  ]

  @type t :: %__MODULE__{
          status: :eligible | :blocked,
          reasons: [String.t()],
          policy_snapshot: map() | nil,
          decision_summary: map() | nil,
          monitoring_window_closed?: boolean() | nil
        }
end
