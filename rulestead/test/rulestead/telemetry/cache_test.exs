defmodule Rulestead.Telemetry.CacheTest do
  use ExUnit.Case, async: true
  alias Rulestead.Telemetry.Cache

  describe "ETS initialization" do
    test "initializes an ETS table on startup" do
      assert {:ok, _pid} = Cache.start_link([])
      assert :ets.info(Cache.table_name()) != :undefined
    end
  end

  describe "cache operations" do
    setup do
      start_supervised!(Cache)
      Cache.clear()
      :ok
    end

    test "bumps evaluation count and updates last_evaluated_at for a given flag_key" do
      flag_key = "some_flag_key"
      env_key = "test"
      variant = "variant_a"
      timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

      Cache.record_evaluation(flag_key, env_key, variant, timestamp)

      snapshot = Cache.snapshot()
      assert snapshot[{flag_key, env_key}] != nil
      assert snapshot[{flag_key, env_key}].variants_served[variant] == 1
      assert snapshot[{flag_key, env_key}].last_evaluated_at == timestamp

      Cache.clear()
      assert Cache.snapshot() == %{}
    end

    test "can return a snapshot of the cache and clear it for flushing" do
      ts = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      Cache.record_evaluation("flag_1", "test", "on", ts)
      Cache.record_evaluation("flag_1", "test", "on", ts)
      Cache.record_evaluation("flag_1", "test", "off", ts)
      Cache.record_evaluation("flag_2", "test", "active", ts)

      snapshot = Cache.snapshot()

      assert snapshot[{"flag_1", "test"}].variants_served["on"] == 2
      assert snapshot[{"flag_1", "test"}].variants_served["off"] == 1

      assert snapshot[{"flag_2", "test"}].variants_served["active"] == 1

      Cache.clear()
      assert Cache.snapshot() == %{}
    end
  end
end
