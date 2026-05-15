defmodule Rulestead.Telemetry.CacheTest do
  use ExUnit.Case, async: false

  alias Rulestead.Telemetry.Cache

  describe "initialization" do
    test "initializes an ETS table on startup" do
      # Should be started by the test, or we start it manually if it's a GenServer
      assert {:ok, _pid} = Cache.start_link([])
      assert :ets.info(Cache.table_name()) != :undefined
    end
  end

  describe "record_evaluation/3" do
    setup do
      {:ok, _pid} = Cache.start_link([])
      :ok
    end

    test "bumps evaluation count and updates last_evaluated_at for a given flag_key" do
      flag_key = "my_flag"
      variant = "on"
      timestamp = DateTime.utc_now()

      Cache.record_evaluation(flag_key, variant, timestamp)
      
      snapshot = Cache.snapshot()
      assert %{
        "my_flag" => %{
          last_evaluated_at: ^timestamp,
          variants_served: %{"on" => 1}
        }
      } = snapshot

      # Bump again with a different variant
      Cache.record_evaluation(flag_key, "off", timestamp)
      
      snapshot_after = Cache.snapshot()
      assert %{
        "my_flag" => %{
          last_evaluated_at: ^timestamp,
          variants_served: %{"on" => 1, "off" => 1}
        }
      } = snapshot_after
    end
  end

  describe "snapshot/0 and clear/0" do
    setup do
      {:ok, _pid} = Cache.start_link([])
      :ok
    end

    test "returns a snapshot of the cache and can clear it for flushing" do
      timestamp = DateTime.utc_now()
      Cache.record_evaluation("f1", "on", timestamp)
      Cache.record_evaluation("f2", "off", timestamp)

      snapshot = Cache.snapshot()
      assert Map.has_key?(snapshot, "f1")
      assert Map.has_key?(snapshot, "f2")

      Cache.clear()
      
      assert Cache.snapshot() == %{}
    end
  end
end
