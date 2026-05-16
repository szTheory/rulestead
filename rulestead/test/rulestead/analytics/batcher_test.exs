defmodule Rulestead.Analytics.BatcherTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Analytics.Batcher
  alias Rulestead.Analytics.Event
  alias Rulestead.Repo

  setup do
    # Clear the table before each test in case it's lingering
    try do
      :ets.delete(:rulestead_analytics_batcher)
    rescue
      ArgumentError -> :ok
    end

    start_supervised!({Batcher, flush_interval: 0, batch_size: 10, max_size: 100})
    :ok
  end

  describe "insert/1" do
    test "inserts events into ETS table non-blockingly" do
      event = %{kind: "custom", event_name: "test_event"}
      assert :ok = Batcher.insert(event)

      size = :ets.info(:rulestead_analytics_batcher, :size)
      assert size == 1
    end

    test "drops events if ETS table size exceeds max_size" do
      # We override the max size to something very small for this test
      try do
        :ets.delete(:rulestead_analytics_batcher)
      rescue
        ArgumentError -> :ok
      end
      
      stop_supervised(Batcher)
      start_supervised!({Batcher, flush_interval: 0, max_size: 2})

      assert :ok = Batcher.insert(%{kind: "custom", event_name: "event_1"})
      assert :ok = Batcher.insert(%{kind: "custom", event_name: "event_2"})
      
      # The 3rd insert should be dropped because size >= 2
      assert :ok = Batcher.insert(%{kind: "custom", event_name: "event_3"})

      size = :ets.info(:rulestead_analytics_batcher, :size)
      assert size == 2
    end
  end

  describe "flush_now/1" do
    test "drains ETS table and writes to DB via Repo.insert_all" do
      event1 = %{kind: "custom", event_name: "event_1"}
      event2 = %{kind: "custom", event_name: "event_2"}

      Batcher.insert(event1)
      Batcher.insert(event2)

      assert :ets.info(:rulestead_analytics_batcher, :size) == 2

      # Manually trigger flush
      Batcher.flush_now(10)

      # ETS should be empty
      assert :ets.info(:rulestead_analytics_batcher, :size) == 0

      # DB should have 2 events
      events = Repo.all(Event)
      assert length(events) == 2
      
      event_names = Enum.map(events, & &1.event_name) |> Enum.sort()
      assert event_names == ["event_1", "event_2"]
    end
    
    test "only flushes up to batch_size" do
      event1 = %{kind: "custom", event_name: "event_1"}
      event2 = %{kind: "custom", event_name: "event_2"}
      event3 = %{kind: "custom", event_name: "event_3"}

      Batcher.insert(event1)
      Batcher.insert(event2)
      Batcher.insert(event3)

      assert :ets.info(:rulestead_analytics_batcher, :size) == 3

      # Manually trigger flush with batch_size 2
      Batcher.flush_now(2)

      # ETS should have 1 item left
      assert :ets.info(:rulestead_analytics_batcher, :size) == 1

      # DB should have 2 events
      events = Repo.all(Event)
      assert length(events) == 2
    end
  end
end
