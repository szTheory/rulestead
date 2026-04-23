defmodule Rulestead.Fake.Control do
  @moduledoc """
  Test-only controls for `Rulestead.Fake`.

  These helpers are intentionally separate from the shared `Rulestead.Store`
  behaviour so production callers cannot rely on fake-only affordances.
  """

  alias Rulestead.Fake

  @spec ensure_started() :: :ok
  def ensure_started do
    case Process.whereis(Fake) do
      nil ->
        case Fake.start_link() do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> raise "failed to start Rulestead.Fake: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end

  @spec reset!(keyword()) :: :ok
  def reset!(opts \\ []) do
    ensure_started()

    case Fake.reset(opts) do
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  @spec put_environment!(map()) :: map()
  def put_environment!(attrs) do
    ensure_started()

    case Fake.put_environment(attrs) do
      {:ok, environment} -> environment
      {:error, error} -> raise error
    end
  end

  @spec put_flag!(map()) :: map()
  def put_flag!(attrs) do
    ensure_started()

    case Fake.put_flag(attrs) do
      {:ok, flag} -> flag
      {:error, error} -> raise error
    end
  end

  @spec put_flag(map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def put_flag(attrs) do
    ensure_started()
    Fake.put_flag(attrs)
  end

  @spec snapshot!() :: map()
  def snapshot! do
    ensure_started()

    case Fake.snapshot() do
      {:ok, state} -> state
      {:error, error} -> raise error
    end
  end

  @spec now!() :: DateTime.t()
  def now! do
    ensure_started()

    case Fake.now() do
      {:ok, now} -> now
      {:error, error} -> raise error
    end
  end

  @spec set_now!(DateTime.t()) :: DateTime.t()
  def set_now!(%DateTime{} = now) do
    ensure_started()

    case Fake.set_now(now) do
      {:ok, updated_now} -> updated_now
      {:error, error} -> raise error
    end
  end

  @spec advance_time!(integer()) :: DateTime.t()
  def advance_time!(seconds) when is_integer(seconds) do
    ensure_started()

    case Fake.advance_time(seconds) do
      {:ok, updated_now} -> updated_now
      {:error, error} -> raise error
    end
  end

  @spec latest_snapshot!(String.t() | atom()) :: map()
  def latest_snapshot!(environment_key) do
    ensure_started()

    case GenServer.call(Fake, {:control, :latest_snapshot, environment_key}) do
      {:ok, snapshot} -> snapshot
      {:error, error} -> raise error
    end
  end

  @spec disconnect!() :: :ok
  def disconnect! do
    ensure_started()
    GenServer.call(Fake, {:control, :disconnect})
  end

  @spec reconnect!() :: :ok
  def reconnect! do
    ensure_started()
    GenServer.call(Fake, {:control, :reconnect})
  end

  @spec publish!(module() | atom(), String.t() | atom(), pos_integer()) :: :ok
  def publish!(pubsub, environment_key, snapshot_version) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.broadcast(
        pubsub,
        Rulestead.Runtime.Config.snapshot()[:pubsub_topic],
        {:rulestead_runtime_refresh,
         %{environment_key: to_string(environment_key), snapshot_version: snapshot_version}}
      )

      :ok
    else
      raise "Phoenix.PubSub is not available"
    end
  end
end
