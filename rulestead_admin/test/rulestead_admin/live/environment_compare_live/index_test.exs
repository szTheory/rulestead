defmodule RulesteadAdmin.Live.EnvironmentCompareLive.IndexTest do
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

  test "renders mounted compare summary with explicit url-backed environment state", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare?env=prod&tenant=acme&source_env=staging&target_env=prod"
      )

    assert html =~ "Environment compare"
    assert html =~ "source"
    assert html =~ "current target"
    assert html =~ "proposed target after apply"
    assert html =~ "source_env=staging"
    assert html =~ "tenant=acme"
    assert html =~ "target_env=prod"
    assert html =~ "Tenant scope"
  end

  test "renders findings buckets from compare payload without apply controls", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare?env=prod&tenant=acme&source_env=staging&target_env=prod"
      )

    assert html =~ "Blockers"
    assert html =~ "Warnings"
    assert html =~ "Info"
    assert html =~ "compare token"
    assert html =~ "tenant"
    assert html =~ "unpublished work"
    assert html =~ "operational override"
    refute html =~ ">Apply<"
    refute html =~ ">Schedule<"
    refute html =~ "Submit change request"
    refute html =~ ">Publish<"
  end

  test "preserves mounted admin production emphasis and flag drill-in navigation", %{conn: conn} do
    {:ok, _view, html} =
      live(
        conn,
        "/admin/flags/compare?env=prod&tenant=acme&source_env=staging&target_env=prod"
      )

    query = drill_in_query(html, "checkout-redesign")

    assert html =~ "Production target"
    assert html =~ "Review blockers and governed-apply requirements before continuing."
    assert query["env"] == "prod"
    assert query["tenant"] == "acme"
    assert query["source_env"] == "staging"
    assert query["target_env"] == "prod"
    assert is_binary(query["compare_token"])
    refute query["compare_token"] == ""
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

    Control.put_flag!(%{
      key: "beta-banner",
      description: "Roll out the beta banner",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      tags: ["beta"],
      environment_keys: ["staging"]
    })

    publish_ruleset!("checkout-redesign", "staging", checkout_source_ruleset())
    publish_ruleset!("checkout-redesign", "prod", checkout_target_ruleset())
    publish_ruleset!("beta-banner", "staging", beta_banner_ruleset())

    Rulestead.save_draft_ruleset!(
      Command.SaveDraftRuleset.new(
        "checkout-redesign",
        "staging",
        Map.put(checkout_source_ruleset(), :salt, "checkout-redesign:draft")
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

  defp beta_banner_ruleset do
    %{
      salt: "beta-banner:staging",
      metadata: %{source: "test"},
      rules: [
        %{
          key: "beta-enabled",
          name: "Beta enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }
  end

  defp drill_in_query(html, flag_key) do
    href =
      Regex.run(~r/href="([^"]*\/compare\/#{flag_key}\?[^"]+)"/, html, capture: :all_but_first)
      |> List.first()
      |> String.replace("&amp;", "&")

    href
    |> URI.parse()
    |> Map.fetch!(:query)
    |> URI.decode_query()
  end
end
