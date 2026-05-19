defmodule Rulestead.KillSwitchError do
  @moduledoc false
  # Constructors for kill-switch-domain `Rulestead.Error` values.


  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :kill_switch,
          type: type,
          message: message
        ],
        opts
      )
    )
  end

  @spec active(keyword()) :: Error.t()
  def active(opts \\ []) do
    new(:kill_switch_active, "flag is disabled by an active kill switch", opts)
  end
end
