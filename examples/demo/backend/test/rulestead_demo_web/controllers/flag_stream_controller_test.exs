defmodule RulesteadDemoWeb.FlagStreamControllerTest do
  use RulesteadDemoWeb.ConnCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Runtime.Refresh

  setup do
    demo_actor = %{id: "seed", roles: ["admin"]}
    flag_key = "enable-new-dashboard"

    case Rulestead.fetch_flag(flag_key, "staging", include_ruleset?: false) do
      {:ok, _flag} ->
        :ok

      {:error, _error} ->
        {:ok, _flag} =
          Rulestead.create_flag(
            %{
              key: flag_key,
              description: "Turns the demo frontend's new dashboard experience on.",
              flag_type: :release,
              value_type: :boolean,
              default_value: %{value: false},
              owner: "demo-platform",
              permanent: true,
              tags: ["demo", "ga"],
              environment_keys: ["staging", "production"]
            },
            actor: demo_actor
          )
    end

    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Command.SaveDraftRuleset.new(flag_key, "staging", %{
          salt: "enable-new-dashboard:stream:v1",
          rules: [%{key: "always-on", strategy: :forced_value, value: %{value: true}, conditions: []}]
        }, actor: demo_actor)
      )

    {:ok, _published} =
      Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, "staging", actor: demo_actor))

    if Process.whereis(RulesteadDemo.RuntimeRefresh.Staging) do
      :ok = Refresh.refresh_now(RulesteadDemo.RuntimeRefresh.Staging)
    end

    :ok
  end

  test "GET /api/flags/stream emits a bounded configuration-changed event" do
    conn = build_conn() |> get("/api/flags/stream?env=staging")

    assert conn.status == 200
    assert {"content-type", "text/event-stream; charset=utf-8"} in conn.resp_headers
    assert conn.resp_body =~ "event: configuration-changed"
    assert conn.resp_body =~ "\"environmentKey\":\"staging\""
    assert conn.resp_body =~ "\"snapshotVersion\":"
  end
end
