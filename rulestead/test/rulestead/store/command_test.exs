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
end
