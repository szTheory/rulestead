# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Adopter do
  @moduledoc """
  Integrator-facing verification entrypoint for the v1.11 integration spine band.

  Delegates to `mix verify.phase76` (flat post-GA proof union; no duplicate implementation).
  """

  use Mix.Task

  @shortdoc "Runs the v1.11 adopter verification suite (alias for verify.phase76)"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("verify.phase76", args)
  end
end
