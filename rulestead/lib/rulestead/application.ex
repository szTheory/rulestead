defmodule Rulestead.Application do
  @moduledoc false

  use Application

  alias Rulestead.Admin.StaleTracker
  alias Rulestead.Runtime.Config
  alias Rulestead.Runtime.Supervisor, as: RuntimeSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      StaleTracker,
      {RuntimeSupervisor, Config.runtime_options()}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    Elixir.Supervisor.start_link(children, opts)
  end
end
