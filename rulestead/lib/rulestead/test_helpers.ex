defmodule Rulestead.TestHelpers do
  @moduledoc """
  Fake-backed test helpers for host-app tests.

  `Rulestead.TestHelpers` is a **Supported adopter facade** in the 1.x contract
  (`api_stability.md` — "Supported adopter facades"). It provides a stable,
  in-memory-backed API your host application's ExUnit tests can use to control
  flag state without touching a real store or database.

  ## Quickstart

      # In your test_helper.exs or a shared test support module:
      import Rulestead.TestHelpers

      # Seed a flag for the duration of a block:
      with_flag("my_feature", true) do
        assert MyApp.feature_enabled?()
      end

      # Or seed for the remainder of a test:
      put_flag("my_feature", true)

  ## Public API (closed catalog)

  - `with_flag/3` — scope a flag value to a block; restores prior state after
  - `put_flag/3` — seed a fake-backed flag for the rest of the current test
  - `clear_flags/0` — reset all fake state for test isolation
  - `seed_bucket/3` — pin a variant assignment for one targeting key
  - `assert_flag_evaluated/2` — assert a matching eval telemetry event was emitted

  The backing store (`Rulestead.Fake`) and its control module are internal and
  not part of the 1.x public contract.
  """
  # Public fake-backed test helpers for host app tests.

  import ExUnit.Assertions

  alias Rulestead.{Fake.Control, Telemetry}

  @eval_events [[:rulestead, :eval, :decide, :stop]]
  @assert_timeout 1_000

  @doc """
  Seeds a flag value for the duration of the block and restores prior fake state.
  """
  defmacro with_flag(flag_key, value, do: block) do
    quote do
      snapshot = Control.snapshot!()

      try do
        Rulestead.TestHelpers.put_flag(unquote(flag_key), unquote(value))
        unquote(block)
      after
        Control.restore!(snapshot)
      end
    end
  end

  @doc """
  Seeds a fake-backed flag for the remainder of the current test.
  """
  @spec put_flag(String.t() | atom(), term(), keyword()) :: map()
  def put_flag(flag_key, value, opts \\ []) do
    Control.put_test_flag!(flag_key, value, opts)
  end

  @doc """
  Clears fake state for test isolation.
  """
  @spec clear_flags() :: :ok
  def clear_flags do
    Control.reset!()
  end

  @doc """
  Pins a variant assignment for one targeting key through the fake-backed contract.
  """
  @spec seed_bucket(String.t() | atom(), String.t() | atom(), String.t() | atom()) :: map()
  def seed_bucket(flag_key, targeting_key, variant) do
    Control.seed_bucket!(flag_key, targeting_key, variant)
  end

  @doc """
  Asserts that the enclosed code emits a matching eval stop event.
  """
  defmacro assert_flag_evaluated(flag_key, do: block) do
    quote do
      Rulestead.TestHelpers.__assert_flag_evaluated__(unquote(flag_key), fn -> unquote(block) end)
    end
  end

  @doc false
  @spec __assert_flag_evaluated__(String.t() | atom(), (-> term())) :: term()
  def __assert_flag_evaluated__(flag_key, fun) when is_function(fun, 0) do
    test_pid = self()
    handler_id = "rulestead-test-helper-#{System.unique_integer([:positive])}"
    expected_flag_key = to_string(flag_key)

    :ok =
      Telemetry.attach_many(
        handler_id,
        @eval_events,
        fn event, _measurements, metadata, _config ->
          send(test_pid, {:rulestead_eval_event, event, metadata})
        end,
        nil
      )

    try do
      result = fun.()

      assert_receive {:rulestead_eval_event, [:rulestead, :eval, :decide, :stop], metadata},
                     @assert_timeout

      assert metadata.flag_key == expected_flag_key
      assert Map.has_key?(metadata, :reason)
      refute Map.has_key?(metadata, :attributes)
      refute Map.has_key?(metadata, :value)

      result
    after
      Telemetry.detach(handler_id)
    end
  end
end
