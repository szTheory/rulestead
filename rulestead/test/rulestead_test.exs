defmodule RulesteadTest do
  use ExUnit.Case, async: true

  test "the package root module loads" do
    assert Rulestead.version() == "0.1.0"
  end
end
