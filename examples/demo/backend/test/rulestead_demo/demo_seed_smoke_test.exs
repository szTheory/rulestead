defmodule RulesteadDemo.DemoSeedSmokeTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias RulesteadDemo.Fixtures

  @adoption_lab_flags [
    "enable-new-dashboard",
    "fleet-map-v2",
    "dispatch-ops-copy",
    "ops-banner-config"
  ]

  setup do
    Code.eval_file(Path.expand("../../priv/repo/seeds.exs", __DIR__))
    :ok
  end

  test "seed script creates FleetDesk adoption-lab authored state", %{conn: conn} do
    for flag_key <- @adoption_lab_flags do
      assert {:ok, flag} = Rulestead.fetch_flag(flag_key, "staging")
      assert flag.flag.key == flag_key
    end

    context =
      Rulestead.Context.new(
        targeting_key: "fleet-manager-acme",
        environment: "staging",
        attributes: %{"plan" => "enterprise", "tenant_key" => "acme-logistics"}
      )

    assert {:ok, map_result} = Rulestead.Runtime.evaluate("staging", "fleet-map-v2", context)
    assert map_result.enabled?

    sign_in_conn = get(conn, ~p"/demo/sign-in")
    assert redirected_to(sign_in_conn) == "/admin/flags?env=staging"

    recycled_conn = Phoenix.ConnTest.recycle(sign_in_conn)
    {:ok, _view, html} = live(recycled_conn, "/admin/flags?env=staging")

    assert html =~ "Flag inventory"
    assert html =~ "enable-new-dashboard"
    assert html =~ "fleet-map-v2"
    assert html =~ "Staging"
  end

  test "personas API exposes adoption-lab fixture set", %{conn: conn} do
    conn = get(conn, "/api/demo/personas")

    payload = json_response(conn, 200)
    assert payload["product"] == "FleetDesk"
    assert length(payload["personas"]) == length(Fixtures.personas())
    assert length(payload["flags"]) == 4
  end

  test "explain API returns support-safe trace for primary flag", %{conn: conn} do
    conn =
      get(
        conn,
        "/api/flags/explain?env=staging&flag_key=enable-new-dashboard&targeting_key=demo-user&plan=pro&tenant_key=acme-logistics"
      )

    payload = json_response(conn, 200)
    assert payload["flagKey"] == "enable-new-dashboard"
    assert is_binary(payload["explanation"])
    assert payload["explanation"] =~ "Matched rule"
  end
end
