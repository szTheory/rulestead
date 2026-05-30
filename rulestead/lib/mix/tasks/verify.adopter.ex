# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Adopter do
  @moduledoc """
  Integrator-facing verification entrypoint for the v1.12 adoption-lab band.

  Delegates to `mix verify.phase82` (flat post-GA proof union; no duplicate implementation).
  """

  use Mix.Task

  @shortdoc "Runs the v1.12 adopter verification suite (alias for verify.phase82)"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("verify.phase82", args)
  end
end
