defmodule RulesteadDemoWeb.FlagControllerTest do
  use RulesteadDemoWeb.ConnCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Runtime.Refresh

  setup do
    seed_demo_flag!()
    :ok
  end

  test "GET /api/flags returns normalized runtime-backed JSON", %{conn: conn} do
    conn = get(conn, ~p"/api/flags?env=staging&flag_key=enable-new-dashboard")

    assert %{
             "flagKey" => "enable-new-dashboard",
             "environmentKey" => "staging",
             "enabled" => true,
             "value" => true,
             "reason" => "rule_match"
           } = json_response(conn, 200)
  end

  test "GET /api/flags fails closed for missing inputs", %{conn: conn} do
    conn = get(conn, ~p"/api/flags?env=staging")

    assert %{"error" => %{"code" => "invalid_command", "message" => "flag_key is required"}} =
             json_response(conn, 422)
  end

  test "GET /api/flags fails closed for invalid environments", %{conn: conn} do
    conn = get(conn, ~p"/api/flags?env=qa&flag_key=enable-new-dashboard")

    assert %{
             "error" => %{
               "code" => "environment_not_found",
               "message" => "env must be one of the configured demo environments"
             }
           } = json_response(conn, 422)
  end

  test "OPTIONS /api/flags responds with browser bridge CORS headers", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://localhost:3000")
      |> put_req_header("access-control-request-method", "GET")
      |> options(~p"/api/flags")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
    assert get_resp_header(conn, "access-control-allow-methods") == ["GET, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
  end

  test "GET /api/flags includes allow-origin for approved demo frontend", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://localhost:3000")
      |> get(~p"/api/flags?env=staging&flag_key=enable-new-dashboard")

    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
    assert %{"flagKey" => "enable-new-dashboard"} = json_response(conn, 200)
  end

  defp seed_demo_flag! do
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

    ruleset = %{
      salt: "enable-new-dashboard:test:v1",
      rules: [
        %{
          key: "always-on-demo-dashboard",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    for environment_key <- ["staging", "production"] do
      {:ok, _draft} =
        Rulestead.save_draft_ruleset(
          Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset, actor: demo_actor)
        )

      {:ok, _published} =
        Rulestead.publish_ruleset(
          Command.PublishRuleset.new(flag_key, environment_key, actor: demo_actor)
        )
    end

    refresh_runtime!()
  end

  defp refresh_runtime! do
    for refresh_name <- [
          RulesteadDemo.RuntimeRefresh.Staging,
          RulesteadDemo.RuntimeRefresh.Production
        ] do
      if Process.whereis(refresh_name) do
        :ok = Refresh.refresh_now(refresh_name)
      end
    end
  end
end
