defmodule RulesteadAdmin.Live.FlagLive.RolloutsAccessibilityTest do
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

    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod"]
    )

    publish_ruleset!("checkout-redesign", "prod")

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

  test "rollout page stays accessible before preview, after preview, and when risky confirmation is present",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")
    AxeAudit.assert_accessible!(html)

    preview_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='preview']")
        |> render_click()
      end)

    AxeAudit.assert_accessible!(preview_html)
    assert preview_html =~ "Sample preview"
    assert preview_html =~ "Observed assignments"

    risky_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "100"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='publish']")
        |> render_click()
      end)

    AxeAudit.assert_accessible!(risky_html)
    assert risky_html =~ "Risky jump requires confirmation"
    assert risky_html =~ "Reason for risky jump"
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
  end

  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "vip-allowlist",
          name: "VIP allowlist",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{
              attribute: "attributes.segment",
              operator: :equals,
              value: %{equals: "vip"}
            }
          ]
        },
        %{
          key: "checkout-canary",
          name: "Checkout canary",
          strategy: :variant_split,
          conditions: [],
          rollout: %{bucket_by: :subject, percentage: 25, salt: "checkout-canary"},
          variants: [
            %{key: "control", value: %{value: false}, weight: 80},
            %{key: "treatment", value: %{value: true}, weight: 20}
          ]
        },
        %{
          key: "fallback-disabled",
          name: "Fallback disabled",
          strategy: :forced_value,
          value: %{value: false},
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
