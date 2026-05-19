defmodule Rulestead.TestHelpers do
  @moduledoc false
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
  @spec __assert_flag_evaluated__(String.t() | atom(), (() -> term())) :: term()
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
