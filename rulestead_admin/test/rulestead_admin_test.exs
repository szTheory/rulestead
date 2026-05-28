defmodule RulesteadAdminTest do
  use ExUnit.Case, async: true

  test "the admin package skeleton loads" do
    assert RulesteadAdmin.version() == to_string(Application.spec(:rulestead_admin)[:vsn])
    assert Code.ensure_loaded?(RulesteadAdmin.Router)
  end
end
