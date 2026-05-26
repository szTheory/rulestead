defmodule Rulestead.Guardrails.Provider do
  @moduledoc false

  alias Rulestead.Guardrails.{Query, SignalFact}

  @type result ::
          SignalFact.t()
          | map()
          | keyword()
          | {:ok, SignalFact.t() | map() | keyword()}
          | {:error, atom() | String.t()}

  @callback fetch_signal(Query.t()) :: result()
end
