defmodule RulesteadAdmin.Live.FlagLive.RolloutsTest do
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

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
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

  test "page shows rollout rule context, keeps variant weights locked, and saves draft percentage edits only", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "Rollout controls"
    assert html =~ "Owner"
    assert html =~ "growth"
    assert html =~ "Production"
    assert html =~ "Rule 2 of 3"
    assert html =~ "VIP allowlist"
    assert html =~ "Checkout canary"
    assert html =~ "Fallback disabled"
    assert html =~ "Variant weights stay locked on this page"
    assert html =~ "control"
    assert html =~ "80%"
    assert html =~ "treatment"
    assert html =~ "20%"

    changed_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()

    assert changed_html =~ "50%"
    refute changed_html =~ "Draft saved for Production"

    saved_html =
      view
      |> element("button[phx-click='save_draft']")
      |> render_click()

    assert saved_html =~ "Draft saved for Production"

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")
    [draft | _rest] = detail.draft_rulesets
    rollout_rule = Enum.at(draft.rules, 1)

    assert rollout_rule.rollout.percentage == 50
    assert Enum.map(rollout_rule.variants, & &1.weight) == [80, 20]
    assert detail.active_ruleset.version == 1
    assert Enum.at(detail.active_ruleset.rules, 1).rollout.percentage == 25
  end

  test "preview samples a bounded deterministic set without persisting hidden changes", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    preview_html =
      view
      |> form("form[aria-label='Rollout controls form']", %{"rollout" => %{"percentage" => "50"}})
      |> render_change()
      |> then(fn _html ->
        view
        |> element("button[phx-click='preview']")
        |> render_click()
      end)

    assert preview_html =~ "Sample preview"
    assert preview_html =~ "20 deterministic sample keys"
    assert preview_html =~ "Intended exposure"
    assert preview_html =~ "50%"
    assert preview_html =~ "Observed assignments"
    assert preview_html =~ "Preview only"

    detail = Rulestead.fetch_flag!("checkout-redesign", "prod")

    assert detail.draft_rulesets == []
    assert Enum.at(detail.active_ruleset.rules, 1).rollout.percentage == 25
  end

  test "ordered first-match context stays visible around the rollout rule", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert html =~ "First-match order"
    assert html =~ "Rule 1"
    assert html =~ "Rule 2"
    assert html =~ "Rule 3"
    assert html =~ "Current rollout rule"
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

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
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
