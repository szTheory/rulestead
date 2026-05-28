# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Adopter do
  @moduledoc """
  Integrator-facing verification entrypoint for the v1.10.1 support-truth band.

  Delegates to `mix verify.phase73` (flat post-GA proof union; no duplicate implementation).
  """

  use Mix.Task

  @shortdoc "Runs the v1.10.1 adopter verification suite (alias for verify.phase73)"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("verify.phase73", args)
  end
end
