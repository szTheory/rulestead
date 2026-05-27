defmodule Mix.Tasks.Rebuild.AudienceReferenceProjection do
  @moduledoc """
  Rebuilds dependency projection rows from existing authored rulesets.

  Run with:

      mix rebuild.audience_reference_projection
  """
  use Mix.Task

  @shortdoc "Rebuilds the audience dependency projection table"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    case Rulestead.Store.Ecto.rebuild_audience_reference_projection() do
      {:ok, result} ->
        Mix.shell().info(
          "Rebuilt audience_reference_projection (deleted=#{result.deleted_rows}, inserted=#{result.inserted_rows})"
        )

      {:error, error} ->
        Mix.raise("Failed to rebuild audience_reference_projection: #{Exception.message(error)}")
    end
  end
end
