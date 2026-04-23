defmodule RulesteadAdmin do
  @moduledoc false

  @version Mix.Project.config()[:version] || "0.1.0"

  @spec version() :: String.t()
  def version, do: @version
end
