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
    children =
      opts
      |> Config.environment_keys()
      |> Enum.map(fn environment_key ->
        Supervisor.child_spec(
          {Refresh,
           Keyword.merge(
             opts,
             environment_key: environment_key,
             store: Config.store(opts),
             pubsub: Keyword.get(opts, :pubsub)
           )},
          id: {Refresh, environment_key}
        )
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
