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
end
