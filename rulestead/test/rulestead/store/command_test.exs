defmodule Rulestead.Store.CommandTest do
  use ExUnit.Case, async: true

  alias Rulestead.Store
  alias Rulestead.Store.Command

  test "exposes an environment-keyed snapshot fetch callback" do
    assert {:fetch_snapshot, 1} in Store.behaviour_info(:callbacks)
  end

  test "builds a snapshot fetch command with an optional version selector" do
    assert %Command.FetchSnapshot{environment_key: "production", version: nil} =
             Command.FetchSnapshot.new("production")

    assert %Command.FetchSnapshot{environment_key: "production", version: 7} =
             Command.FetchSnapshot.new("production", version: 7)
  end

  describe "StopExperiment" do
    test "builds a StopExperiment command" do
      assert %Command.StopExperiment{
               flag_key: "my_experiment",
               environment_key: "production",
               rule_id: "rule_123",
               winning_variant_id: "v_1"
             } = Command.StopExperiment.new("my_experiment", "production", "rule_123", "v_1")
    end

    test "normalizes inputs" do
      assert %Command.StopExperiment{
               flag_key: "my_experiment",
               environment_key: "production",
               rule_id: "rule_123",
               winning_variant_id: "v_1",
               actor: %{"id" => "user_1"},
               reason: "test reason",
               metadata: %{"test" => true}
             } = Command.StopExperiment.new(:my_experiment, :production, "  rule_123  ", "  v_1  ", actor: %{id: "user_1"}, reason: "test reason", metadata: %{test: true})
    end
  end
end
