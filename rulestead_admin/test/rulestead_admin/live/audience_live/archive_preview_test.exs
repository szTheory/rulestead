defmodule RulesteadAdmin.Live.AudienceLive.ArchivePreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  describe "governance in prod" do
    setup do
      Rulestead.Fake.Control.reset!()
      seed_prod_audience_flags!()
      :ok
    end

    test "archive with references shows governed callout and submit CTA", %{conn: conn} do
      conn = init_prod_session(conn)

      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=prod")

      assert html =~ "Change request required"
      assert html =~ "Governance required"
      assert html =~ "Continue to submit"
      refute html =~ "Continue to archive confirm"
    end
  end

  defp seed_prod_audience_flags! do
    alias Rulestead.Fake.Control

    Control.put_environment!(%{key: "prod", name: "Production"})
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
      environment_keys: ["prod"]
    })

    publish_ruleset!("checkout", "prod", %{
      salt: "checkout:prod",
      rules: [%{key: "vip-rule", strategy: :segment_match, audience_key: "vip-users", conditions: []}]
    })

    Control.rebuild_audience_reference_projection!()
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
