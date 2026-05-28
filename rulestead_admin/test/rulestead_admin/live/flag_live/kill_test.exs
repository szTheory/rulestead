defmodule RulesteadAdmin.Live.FlagLive.KillTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  defmodule AuditRestrictedPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, :list_audit_events, _resource, _environment_key), do: false
    def can?(_actor, :access_admin, _resource, _environment_key), do: true
    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)
    now = ~U[2026-04-23 16:00:00Z]

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

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
    publish_ruleset!("checkout-redesign", "staging")

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

  test "engaging the kill switch uses lighter confirmation outside prod and typed-key confirmation in prod",
       %{
         conn: conn
       } do
    {:ok, staging_view, staging_html} =
      live(conn, "/admin/flags/checkout-redesign/kill?env=staging")

    assert staging_html =~ "Standard confirmation required for non-production environments."

    staging_result =
      staging_view
      |> form("form[aria-label='Kill switch engage form']", %{"reason" => "staging incident"})
      |> render_submit()

    assert staging_result =~ "Kill switch engaged for Staging."

    assert Rulestead.fetch_flag!("checkout-redesign", "staging").flag_environment.status ==
             :killswitched

    prod_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin", "auditor"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, prod_view, prod_html} = live(prod_conn, "/admin/flags/checkout-redesign/kill?env=prod")

    assert prod_html =~ "Typed key confirmation required for production."

    invalid_html =
      prod_view
      |> form("form[aria-label='Kill switch engage form']", %{
        "reason" => "prod incident",
        "confirmation" => "wrong-key"
      })
      |> render_submit()

    assert invalid_html =~ "Type the exact flag key to confirm this production action."
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").flag_environment.status == :active

    valid_html =
      prod_view
      |> form("form[aria-label='Kill switch engage form']", %{
        "reason" => "prod incident",
        "confirmation" => "checkout-redesign"
      })
      |> render_submit()

    assert valid_html =~ "Kill switch engaged for Production."

    assert Rulestead.fetch_flag!("checkout-redesign", "prod").flag_environment.status ==
             :killswitched
  end

  test "detail page shows an active banner with restore affordance", %{conn: conn} do
    assert {:ok, _payload} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", roles: [:admin]},
               reason: "incident"
             )

    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Kill switch active"
    assert html =~ "Open kill switch"
    assert html =~ "Open audit timeline"
    assert has_element?(view, "button[phx-click='release_kill_switch']")

    released_html =
      view
      |> element("button[phx-click='release_kill_switch']")
      |> render_click()

    refute released_html =~ "Kill switch active"
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").flag_environment.status == :active
  end

  test "release stays idempotent and returns the flag to authored behavior without replaying history",
       %{conn: conn} do
    assert {:ok, _payload} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", roles: [:admin]},
               reason: "incident"
             )

    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/kill?env=prod")

    first_release =
      view
      |> form("form[aria-label='Kill switch release form']", %{
        "reason" => "resolved",
        "confirmation" => "checkout-redesign"
      })
      |> render_submit()

    assert first_release =~ "Kill switch released for Production."
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").flag_environment.status == :active
    assert Rulestead.fetch_flag!("checkout-redesign", "prod").active_ruleset.version == 1

    assert {:ok, second_release} =
             Rulestead.release_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", roles: [:admin]},
               reason: "resolved again"
             )

    assert second_release.flag_environment.status == :active
    assert is_nil(second_release.flag_environment.kill_switch_variant_key)
    assert second_release.active_ruleset.version == 1
  end

  test "kill page uses the current actor for audit reads and hides restricted reasons", %{
    conn: conn
  } do
    assert {:ok, _payload} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "customer checkout incident"
             )

    Application.put_env(:rulestead, :admin_policy, AuditRestrictedPolicy)

    restricted_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 9, email: "operator@example.com", roles: ["admin"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, _view, html} = live(restricted_conn, "/admin/flags/checkout-redesign/kill?env=prod")

    assert html =~ "Kill switch active"
    refute html =~ "customer checkout incident"
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
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
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
