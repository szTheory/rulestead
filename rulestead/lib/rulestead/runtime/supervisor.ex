defmodule Rulestead.Runtime.Supervisor do
  @moduledoc false

  use Supervisor

  alias Rulestead.Runtime.{Cache, Config, Snapshot}
  alias Rulestead.Store.Command

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    opts = Config.runtime_options(opts)

    case Keyword.get(opts, :name, __MODULE__) do
      nil -> Supervisor.start_link(__MODULE__, opts)
      name -> Supervisor.start_link(__MODULE__, opts, name: name)
    end
  end

  @impl true
  def init(opts) do
    Cache.ensure_tables()

    opts
    |> Config.environment_keys()
    |> Enum.each(&boot_environment(&1, opts))

    Supervisor.init([], strategy: :one_for_one)
  end

  defp boot_environment(environment_key, opts) do
    Cache.register_environment(environment_key)

    case fetch_snapshot(environment_key, opts) do
      {:ok, snapshot} ->
        with {:ok, compiled} <- Snapshot.compile(snapshot),
             {:ok, _applied} <- Cache.apply(compiled) do
          :ok
        else
          {:error, error} -> Cache.mark_refresh_failed(environment_key, error)
        end

      {:error, error} ->
        Cache.mark_refresh_failed(environment_key, error)
    end
  end

  defp fetch_snapshot(environment_key, opts) do
    case Config.store(opts) do
      adapter when is_atom(adapter) ->
        if Code.ensure_loaded?(adapter) and function_exported?(adapter, :fetch_snapshot, 1) do
          adapter.fetch_snapshot(Command.FetchSnapshot.new(environment_key))
        else
          {:error, :store_unavailable}
        end

      _other ->
        {:error, :store_unavailable}
    end
  end
end
