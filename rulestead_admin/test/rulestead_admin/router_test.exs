defmodule RulesteadAdmin.RouterTest do
  use ExUnit.Case, async: true

  require RulesteadAdmin.Router

  test "use imports the mount macro without raising" do
    using_ast =
      quote do
        use RulesteadAdmin.Router
      end
      |> Macro.expand(__ENV__)

    assert Macro.to_string(using_ast) =~ "RulesteadAdmin.Router.__using__([])"
    refute Macro.to_string(using_ast) =~ "raise"
  end

  test "rulestead_admin expands to a mounted route set with a policy-aware live session" do
    mount_ast =
      quote do
        RulesteadAdmin.Router.rulestead_admin("/flags", policy: RulesteadAdmin.TestPolicy)
      end
      |> Macro.expand(__ENV__)

    rendered = Macro.to_string(mount_ast)

    assert rendered =~ "scope(path, as: :rulestead_admin)"
    assert rendered =~ "live_session"
    assert rendered =~ "RulesteadAdmin.Live.Session"
    assert rendered =~ "RulesteadAdmin.TestPolicy"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Index"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Show"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Rules"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Simulate"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Rollouts"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Kill"
    assert rendered =~ "RulesteadAdmin.Live.FlagLive.Timeline"
    assert rendered =~ "RulesteadAdmin.Live.AuditLive.Index"
    assert rendered =~ "RulesteadAdmin.Live.ChangeRequestLive.Index"
    assert rendered =~ "RulesteadAdmin.Live.ChangeRequestLive.Show"
    assert rendered =~ "RulesteadAdmin.Live.ScheduleLive.Index"
    assert rendered =~ "RulesteadAdmin.Live.ScheduleLive.Show"
    assert rendered =~ "/:key/simulate"
    assert rendered =~ "/:key/rollouts"
    assert rendered =~ "/:key/kill"
    assert rendered =~ "/:key/timeline"
    assert rendered =~ "/change-requests"
    assert rendered =~ "/change-requests/:id"
    assert rendered =~ "/schedule"
    assert rendered =~ "/schedule/:scheduled_execution_id"
    assert rendered =~ "/audit"
    assert :binary.match(rendered, "\"/audit\"") < :binary.match(rendered, "\"/:key\"")
    assert :binary.match(rendered, "\"/change-requests\"") < :binary.match(rendered, "\"/:key\"")
    assert :binary.match(rendered, "\"/schedule\"") < :binary.match(rendered, "\"/:key\"")
  end
end
