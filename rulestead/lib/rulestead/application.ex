# credo:disable-for-this-file
defmodule Rulestead.Application do
  @moduledoc false

  use Application

  alias Rulestead.Admin.StaleTracker
  alias Rulestead.Redis
  alias Rulestead.Runtime.Config
  alias Rulestead.Runtime.Supervisor, as: RuntimeSupervisor

  @impl true
  def start(_type, _args) do
    children =
      redis_children() ++
        [
          StaleTracker,
          Rulestead.Analytics.Batcher,
          {RuntimeSupervisor, Config.runtime_options()}
        ]

    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]

    case Elixir.Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Rulestead.Analytics.TelemetryHandler.attach()
        {:ok, pid}

      error ->
        error
    end
  end

  defp redis_children do
    if Redis.enabled?() do
      [
        Supervisor.child_spec({Redix, Redis.connection_spec()}, id: Redis.name()),
        Rulestead.Redis.Publisher
      ]
    else
      []
    end
  end
end
