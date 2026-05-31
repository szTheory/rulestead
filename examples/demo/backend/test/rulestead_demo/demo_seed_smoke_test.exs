defmodule RulesteadDemo.DemoSeedSmokeTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Rulestead.{Audience, Flag, Repo}
  alias RulesteadDemo.Fixtures

  @adoption_lab_flags [
    "enable-new-dashboard",
    "fleet-map-v2",
    "dispatch-ops-copy",
    "ops-banner-config",
    "dispatch-guarded-rollout",
    "ops-audience-preview"
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
    {:ok, _view, html} = live(recycled_conn, "/admin/flags?env=staging&view=all")

    assert html =~ "Feature flags"
    assert html =~ "enable-new-dashboard"
    assert html =~ "fleet-map-v2"
    assert html =~ "urgent-route prioritization"
    assert html =~ "Staging"
  end

  test "seed script refreshes existing FleetDesk descriptions" do
    {1, nil} =
      Repo.update_all(
        from(flag in Flag, where: flag.key == "dispatch-ops-copy"),
        set: [description: "Dispatch queue headline copy experiment."]
      )

    audience = Repo.get_by!(Audience, key: "fleet-ops-dispatchers")

    audience
    |> Audience.changeset(%{
      description: "Pro-plan dispatch operators for audience preview journeys."
    })
    |> Repo.update!()

    Code.eval_file(Path.expand("../../priv/repo/seeds.exs", __DIR__))

    assert %Flag{description: description} = Repo.get_by!(Flag, key: "dispatch-ops-copy")
    assert description =~ "urgent-route prioritization"
    assert description =~ "faster first action"

    assert %Flag{lifecycle: %{mode: :expiring, review_by: ~D[2026-07-31]}} =
             Repo.get_by!(Flag, key: "dispatch-ops-copy")

    assert %Audience{description: audience_description} =
             Repo.get_by!(Audience, key: "fleet-ops-dispatchers")

    assert audience_description =~ "validate audience previews"
  end

  test "personas API exposes adoption-lab fixture set", %{conn: conn} do
    conn = get(conn, "/api/demo/personas")

    payload = json_response(conn, 200)
    assert payload["product"] == "FleetDesk"
    assert length(payload["personas"]) == length(Fixtures.personas())
    assert length(payload["flags"]) == 6
  end

  test "preview evidence resolver returns support-safe audience preview", %{conn: _conn} do
    actor = Fixtures.demo_actor()

    assert {:ok, preview} =
             Rulestead.preview_audience_impact(
               "fleet-ops-dispatchers",
               :update,
               environment_key: "staging",
               tenant_key: "acme-logistics",
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]
               },
               actor: actor,
               reason: "adoption lab audience preview smoke"
             )

    assert preview.preview_basis == "authored_state_with_host_evidence"
    assert preview.uncertainty.authoritative_population_count? == false
    assert [%{actor_key: "fleetdesk-fleet-ops-dispatchers"}] = preview.sample_evidence
    assert preview.impression_evidence[:window_label] == "last_24h"
  end

  test "guarded rollout flag is visible on admin mount", %{conn: conn} do
    sign_in_conn = get(conn, ~p"/demo/sign-in")
    recycled_conn = Phoenix.ConnTest.recycle(sign_in_conn)

    {:ok, _view, html} =
      live(recycled_conn, "/admin/flags/dispatch-guarded-rollout/rollouts?env=staging")

    assert html =~ "Rollout controls"
    assert html =~ "dispatch_error_rate"
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
