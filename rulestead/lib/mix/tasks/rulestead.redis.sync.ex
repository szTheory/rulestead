defmodule Mix.Tasks.Rulestead.Redis.Sync do
  @moduledoc false

  use Mix.Task

  import Ecto.Query

  alias Rulestead.{Environment, Redis, Repo}
  alias Rulestead.Store.Command

  @shortdoc "Seeds Redis with the latest runtime snapshots from Ecto"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    shell = Mix.shell()
    environments = Repo.all(from(environment in Environment, order_by: environment.key))

    {synced, skipped} =
      Enum.reduce(environments, {0, 0}, fn environment, {synced, skipped} ->
        case Rulestead.Store.Ecto.fetch_snapshot(Command.FetchSnapshot.new(environment.key)) do
          {:ok, snapshot} ->
            case Redis.client().command(
                   Redis.name(),
                   ["SET", Redis.snapshot_key(environment.key), :erlang.term_to_binary(snapshot)]
                 ) do
              {:ok, _response} ->
                shell.info("Synced #{environment.key} to Redis")
                {synced + 1, skipped}

              {:error, reason} ->
                Mix.raise("Failed to sync #{environment.key} to Redis: #{inspect(reason)}")
            end

          {:error, %Rulestead.Error{type: :snapshot_not_found}} ->
            shell.info("Skipping #{environment.key}: no published snapshot")
            {synced, skipped + 1}

          {:error, error} ->
            Mix.raise("Failed to fetch snapshot for #{environment.key}: #{inspect(error)}")
        end
      end)

    shell.info("Redis sync complete: #{synced} synced, #{skipped} skipped")
  end
end
