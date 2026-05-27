defmodule RulesteadAdmin.Live.AudienceLive.EditPreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Rulestead.Fake.Control.reset!()
    seed_audience_flag!()
    :ok
  end

  test "edit preview shows impact fingerprint and confirm link", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

    assert html =~ "audprev_"
    assert html =~ "Continue to confirm"
    assert html =~ "Authored state"
  end

  test "edit preview surfaces drift copy when preview is stale", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test&drifted=true")

    assert html =~ "Preview refreshed"
    assert html =~ "Authored state changed since preview"
  end

  describe "governance in prod" do
    setup do
      Rulestead.Fake.Control.reset!()
      seed_prod_audience_flags!()
      :ok
    end

    test "above-threshold update shows governed callout and submit CTA", %{conn: conn} do
      conn = init_prod_session(conn)

      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=prod")

      assert html =~ "Change request required"
      assert html =~ "Governance required"
      assert html =~ "Continue to submit"
      refute html =~ "Continue to confirm"
    end
  end

  test "edit confirm requires preview fingerprint in query", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/confirm?env=test")

    assert html =~ "Run impact preview before confirming"
  end

  defp seed_audience_flag! do
    alias Rulestead.Fake.Control

    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    Control.put_flag!(%{
      key: "checkout",
      description: "Checkout",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      environment_keys: ["test"]
    })

    publish_ruleset!("checkout", "test", %{
      salt: "checkout:test",
      rules: [%{key: "vip-rule", strategy: :segment_match, audience_key: "vip-users", conditions: []}]
    })
  end

  defp seed_prod_audience_flags! do
    alias Rulestead.Fake.Control

    Control.put_environment!(%{key: "prod", name: "Production"})
    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    for {flag_key, rule_key} <- [
          {"checkout", "vip-rule"},
          {"checkout-b", "vip-rule-b"},
          {"checkout-c", "vip-rule-c"}
        ] do
      Control.put_flag!(%{
        key: flag_key,
        description: "Checkout #{flag_key}",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "growth",
        permanent: true,
        expected_expiration: nil,
        environment_keys: ["prod"]
      })

      publish_ruleset!(flag_key, "prod", %{
        salt: "#{flag_key}:prod",
        rules: [%{key: rule_key, strategy: :segment_match, audience_key: "vip-users", conditions: []}]
      })
    end

    Control.rebuild_audience_reference_projection!()
  end

  defp init_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
      "rulestead_admin_last_env" => "test"
    })
  end

  defp init_prod_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}],
      "rulestead_admin_last_env" => "prod"
    })
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    alias Rulestead.Store.Command

    %{version: version} =
      Rulestead.save_draft_ruleset!(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))

    Rulestead.publish_ruleset!(Command.PublishRuleset.new(flag_key, environment_key, version: version))
  end
end
