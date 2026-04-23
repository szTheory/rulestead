defmodule RulesteadAdminTest do
  use ExUnit.Case, async: true

  test "the admin package skeleton loads" do
    assert RulesteadAdmin.version() == "0.1.0"
    assert Code.ensure_loaded?(RulesteadAdmin.Router)
  end
end
