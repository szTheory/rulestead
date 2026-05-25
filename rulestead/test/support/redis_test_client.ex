defmodule Rulestead.Test.RedisClient do
  @moduledoc false

  use Agent

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Agent.start_link(fn -> %{data: %{}, failures: %{}} end, name: name)
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec command(GenServer.server(), [String.t() | binary()]) ::
          {:ok, binary() | nil} | {:error, term()}
  def command(server, ["GET", key]) do
    Agent.get(server, fn state ->
      case state.failures[:get] do
        nil -> {:ok, Map.get(state.data, key)}
        reason -> {:error, reason}
      end
    end)
  end

  def command(server, ["SET", key, value]) when is_binary(key) do
    Agent.get_and_update(server, fn state ->
      case state.failures[:set] do
        nil -> {{:ok, "OK"}, put_in(state, [:data, key], value)}
        reason -> {{:error, reason}, state}
      end
    end)
  end

  def command(_server, command), do: {:error, {:unsupported_command, command}}

  @spec get(GenServer.server(), String.t()) :: binary() | nil
  def get(server, key) do
    Agent.get(server, fn state -> Map.get(state.data, key) end)
  end

  @spec fail_command(GenServer.server(), :get | :set, term()) :: :ok
  def fail_command(server, operation, reason) do
    Agent.update(server, fn state -> put_in(state, [:failures, operation], reason) end)
  end

  @spec clear_failures(GenServer.server()) :: :ok
  def clear_failures(server) do
    Agent.update(server, fn state -> %{state | failures: %{}} end)
  end
end
