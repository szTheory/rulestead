defmodule Rulestead.Runtime.Supervisor do
  @moduledoc false

  use Supervisor

  alias Rulestead.Runtime.{Config, Refresh}

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
    environment_keys = Config.environment_keys(opts)

    children =
      environment_keys
      |> Enum.map(fn environment_key ->
        refresh_name =
          refresh_name_for(opts, environment_keys, environment_key)

        Supervisor.child_spec(
          {Refresh,
           Keyword.merge(
             opts,
             environment_key: environment_key,
             store: Config.store(opts),
             pubsub: Keyword.get(opts, :pubsub),
             name: refresh_name
           )},
          id: {Refresh, environment_key}
        )
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp refresh_name_for(opts, environment_keys, environment_key) do
    case Keyword.get(opts, :refresh_name) do
      nil -> nil
      name when is_map(name) -> Map.get(name, environment_key)
      name when length(environment_keys) == 1 -> name
      _other -> nil
    end
  end
end
