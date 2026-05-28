defmodule RulesteadAdmin.Live.EnvironmentCompareLive.ShowTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    seed_compare_fixture!()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_tenants" => [
          %{"key" => "acme", "name" => "Acme"},
          %{"key" => "globex", "name" => "Globex"}
        ],
        "rulestead_admin_default_tenant" => "acme",
        "rulestead_admin_last_tenant" => "acme",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "renders source current target and proposed target sections for one flag", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare/checkout-redesign?env=prod&tenant=acme&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    assert html =~ "checkout-redesign"
    assert html =~ "Source"
    assert html =~ "Current target"
    assert html =~ "Proposed target after apply"
    assert html =~ "Tenant scope"
    assert html =~ "tenant"
  end

  test "renders reviewed preview drill-in state from the summary-carried compare token", %{
    conn: conn
  } do
    {:ok, _summary_view, summary_html} =
      live(
        conn,
        "/admin/flags/compare?env=prod&tenant=acme&source_env=staging&target_env=prod"
      )

    summary_path = drill_in_path(summary_html, "checkout-redesign")
    query = query_from_path(summary_path)

    {:ok, _view, html} = live(conn, summary_path)

    refute html =~ "Staleness conflict"
    assert html =~ "compare token metadata"
    assert html =~ query["compare_token"]
    assert query["env"] == "prod"
    assert query["tenant"] == "acme"
    assert query["source_env"] == "staging"
    assert query["target_env"] == "prod"
  end

  test "renders typed findings and stale preview warnings behind disclosure", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare/checkout-redesign?env=prod&tenant=acme&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    assert html =~ "Staleness conflict"
    assert html =~ "Audience dependencies for this flag"
    assert html =~ "vip-users"
    assert html =~ "Show structured diff for checkout-redesign"
    assert html =~ "Show raw compare payload for checkout-redesign"
    assert html =~ "Compare token"
    assert html =~ "acme"
  end

  test "stays read-only on drill-in route", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare/checkout-redesign?env=prod&tenant=acme&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    refute html =~ ">Apply<"
    refute html =~ ">Schedule<"
    refute html =~ "Submit change request"
    refute html =~ ">Publish<"
  end

  defp seed_compare_fixture! do
    Control.reset!()
    Control.put_environment!(%{key: "prod", name: "Production"})

    Control.put_audience!(%{
      key: "vip-users",
      description: "VIP reusable audience",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
    })

    Control.put_flag!(%{
      key: "checkout-redesign",
      description: "Release the new checkout flow",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      tags: ["checkout", "release"],
      environment_keys: ["staging", "prod"]
    })

    publish_ruleset!("checkout-redesign", "staging", checkout_source_ruleset())
    publish_ruleset!("checkout-redesign", "prod", checkout_target_ruleset())

    Rulestead.save_draft_ruleset!(
      Command.SaveDraftRuleset.new(
        "checkout-redesign",
        "staging",
        Map.put(checkout_source_ruleset(), :salt, "checkout-redesign:stale")
      )
    )

    {:ok, _kill_switch} =
      Rulestead.engage_kill_switch(
        "checkout-redesign",
        "prod",
        %{id: "operator-1", type: "user", display: "Operator"},
        reason: "simulate override"
      )
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    %{version: version} =
      Rulestead.save_draft_ruleset!(
        Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
      )

    Rulestead.publish_ruleset!(
      Command.PublishRuleset.new(flag_key, environment_key, version: version)
    )
  end

  defp checkout_source_ruleset do
    %{
      salt: "checkout-redesign:staging",
      metadata: %{source: "test"},
      rules: [
        %{
          key: "vip-audience",
          name: "VIP audience",
          strategy: :segment_match,
          audience_key: "vip-users",
          conditions: []
        },
        %{
          key: "force-enabled",
          name: "Force enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }
  end

  defp checkout_target_ruleset do
    %{
      salt: "checkout-redesign:prod",
      metadata: %{source: "test"},
      rules: [
        %{
          key: "force-disabled",
          name: "Force disabled",
          strategy: :forced_value,
          value: %{value: false},
          conditions: []
        }
      ]
    }
  end

  defp drill_in_path(html, flag_key) do
    Regex.run(~r/href="([^"]*\/compare\/#{flag_key}\?[^"]+)"/, html, capture: :all_but_first)
    |> List.first()
    |> String.replace("&amp;", "&")
  end

  defp query_from_path(path) do
    path
    |> URI.parse()
    |> Map.fetch!(:query)
    |> URI.decode_query()
  end
end
