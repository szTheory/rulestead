defmodule Rulestead do
  @moduledoc """
  Root public module for the `rulestead` package.

  Phase 1 intentionally keeps the public API minimal while the package
  boundary, release tooling, and documentation surface settle.
  """

  @version Mix.Project.config()[:version] || "0.1.0"

  @doc """
  Returns the package version.
  """
  @spec version() :: String.t()
  def version, do: @version
end
