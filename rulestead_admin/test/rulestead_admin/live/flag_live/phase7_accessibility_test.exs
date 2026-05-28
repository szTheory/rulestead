defmodule RulesteadAdmin.Live.FlagLive.Phase7AccessibilityTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command
  alias RulesteadAdmin.TestSupport.AxeAudit

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    now = ~U[2026-04-23 16:00:00Z]

    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
    seed_flag!()
    publish_ruleset!("checkout-redesign", "prod")

    assert {:ok, _} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "incident"
             )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin", "auditor"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "kill, per-flag timeline, and global audit screens stay accessible", %{conn: conn} do
    {:ok, _kill_view, kill_html} = live(conn, "/admin/flags/checkout-redesign/kill?env=prod")
    AxeAudit.assert_accessible!(kill_html)

    {:ok, timeline_view, timeline_html} =
      live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    AxeAudit.assert_accessible!(timeline_html)

    rollback_html =
      timeline_view
      |> element("button[phx-click='rollback']")
      |> render_click()

    AxeAudit.assert_accessible!(rollback_html)

    {:ok, audit_view, audit_html} = live(conn, "/admin/flags/audit?env_filter=all")
    AxeAudit.assert_accessible!(audit_html)

    filtered_html =
      audit_view
      |> form("form[aria-label='Audit filters']", %{
        "filters" => %{
          "actor" => "Priya",
          "env_filter" => "prod",
          "mutation" => "",
          "from" => "",
          "to" => ""
        }
      })
      |> render_change()

    AxeAudit.assert_accessible!(filtered_html)
  end

  defp seed_flag! do
    assert %{flag: %{key: "checkout-redesign"}} =
             Control.put_flag!(%{
               key: "checkout-redesign",
               owner: "growth",
               tags: ["checkout", "release"],
               description: "Checkout experiment for the new payment flow",
               expected_expiration: ~D[2026-05-01],
               permanent: false,
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               environment_keys: ["prod"]
             })
  end

  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
             )
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end
