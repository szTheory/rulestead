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
        "/admin/flags/compare/checkout-redesign?env=prod&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    assert html =~ "checkout-redesign"
    assert html =~ "Source"
    assert html =~ "Current target"
    assert html =~ "Proposed target after apply"
  end

  test "renders typed findings and stale preview warnings behind disclosure", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare/checkout-redesign?env=prod&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    assert html =~ "Staleness conflict"
    assert html =~ "missing dependency"
    assert html =~ "Show structured diff for checkout-redesign"
    assert html =~ "Show raw compare payload for checkout-redesign"
    assert html =~ "Compare token"
  end

  test "stays read-only on drill-in route", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare/checkout-redesign?env=prod&source_env=staging&target_env=prod&compare_token=stale-preview"
      )

    refute html =~ ">Apply<"
    refute html =~ ">Schedule<"
    refute html =~ "Submit change request"
    refute html =~ ">Publish<"
  end

  defp seed_compare_fixture! do
    Control.reset!()
    Control.put_environment!(%{key: "prod", name: "Production"})

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
end
