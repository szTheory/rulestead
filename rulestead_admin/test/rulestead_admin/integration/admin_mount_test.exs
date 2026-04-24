defmodule RulesteadAdmin.Integration.AdminMountTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
    ensure_environment!("staging", "Staging")

    assert {:ok, _payload} =
             Rulestead.create_flag(%{
               key: "checkout-redesign",
               description: "Checkout experiment",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               owner: "growth",
               permanent: false,
               expected_expiration: ~D[2026-05-01],
               environment_keys: ["prod", "staging"],
               tags: ["checkout", "release"]
             })

    ruleset = %{
      salt: "checkout-redesign:prod:v1",
      rules: [
        %{
          key: "baseline-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new("checkout-redesign", "prod", ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "prod"))

    snapshot = Control.snapshot!()

    audience = %{
      id: "aud-vip",
      key: "vip-customers",
      description: "VIP customers",
      definition: %{},
      archived_at: nil,
      inserted_at: now,
      updated_at: now
    }

    assert :ok = Control.restore!(Map.put(snapshot, :audiences, %{"vip-customers" => audience}))

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 9, email: "host-admin@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "host-style mount reaches list, detail, and rules screens through the router macro", %{conn: conn} do
    {:ok, _list_view, list_html} = live(conn, "/admin/flags?env=prod")
    assert list_html =~ "Flag inventory"
    assert list_html =~ "Environment"

    detail_conn = Phoenix.ConnTest.recycle(conn)
    {:ok, _detail_view, detail_html} = live(detail_conn, "/admin/flags/checkout-redesign?env=prod")
    assert detail_html =~ "Open rules workspace"
    assert detail_html =~ "Production"

    rules_conn = Phoenix.ConnTest.recycle(conn)
    {:ok, _rules_view, rules_html} = live(rules_conn, "/admin/flags/checkout-redesign/rules?env=prod")
    assert rules_html =~ "Rules workspace"
    assert rules_html =~ "Reusable audience"
    assert rules_html =~ "Save draft"
    refute rules_html =~ "simulate"
    refute rules_html =~ "kill switch"
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
