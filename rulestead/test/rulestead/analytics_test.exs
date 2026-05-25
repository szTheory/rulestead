# credo:disable-for-this-file
defmodule Rulestead.AnalyticsTest do
  use ExUnit.Case, async: false

  alias Rulestead.Context
  alias Rulestead.Analytics.Batcher

  setup do
    if Process.whereis(Batcher) do
      :ets.delete_all_objects(Batcher.table_name())
    else
      start_supervised!({Batcher, [flush_interval: false]})
    end

    :ok
  end

  describe "track/3" do
    test "buffers an event into the batcher using a string actor_id" do
      assert :ok = Rulestead.track("user_123", "signup", %{"source" => "web"})

      objects = :ets.tab2list(Batcher.table_name())
      assert length(objects) == 1

      {_key, event} = hd(objects)
      assert event.kind == "custom"
      assert event.actor_id == "user_123"
      assert event.event_name == "signup"
      assert event.metadata == %{"source" => "web"}
    end

    test "buffers an event into the batcher using a Context map" do
      context = %{actor: %{key: "user_456"}}
      assert :ok = Rulestead.track(context, "purchase", %{"amount" => 100})

      objects = :ets.tab2list(Batcher.table_name())
      assert length(objects) == 1

      {_key, event} = hd(objects)
      assert event.actor_id == "user_456"
      assert event.event_name == "purchase"
    end

    test "buffers an event using a Context struct" do
      context = Context.new(actor: "user_789")
      assert :ok = Rulestead.track(context, "login")

      objects = :ets.tab2list(Batcher.table_name())
      assert length(objects) == 1

      {_key, event} = hd(objects)
      assert event.actor_id == "user_789"
      assert event.event_name == "login"
      assert event.metadata == %{}
    end
  end
end
