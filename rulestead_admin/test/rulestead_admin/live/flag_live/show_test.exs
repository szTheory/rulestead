defmodule RulesteadAdmin.Live.FlagLive.ShowTest do
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
    seed_environment!("prod", "Production")
    seed_environment!("staging", "Staging")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
    )

    publish_flag!("checkout-redesign", "prod")
    save_draft!("checkout-redesign", "prod", 2, false)
    save_draft!("checkout-redesign", "staging", 1, true)

    assert {:ok, _} = Rulestead.record_evaluation("checkout-redesign", "prod", DateTime.add(now, -600, :second))

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "detail shows description, type, default value, owner, tags, lifecycle, and per-environment status", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Checkout experiment for the new payment flow"
    assert html =~ "Release"
    assert html =~ "Boolean"
    assert html =~ "false"
    assert html =~ "growth"
    assert html =~ "checkout"
    assert html =~ "Production"
    assert html =~ "Staging"
    assert html =~ "Lifecycle"
    assert html =~ "Active"
  end

  test "detail distinguishes active and draft rulesets, links to rules workspace, and renders only an audit placeholder", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Active ruleset"
    assert html =~ "Version 1"
    assert html =~ "Draft ruleset"
    assert html =~ "Version 2"
    assert has_element?(view, "a[href='/admin/flags/checkout-redesign/rules?env=prod']")
    assert html =~ "Open rules workspace"
    assert html =~ "Audit timeline arrives in Phase 7"
    refute html =~ "simulate"
    refute html =~ "kill switch"
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

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp publish_flag!(flag_key, environment_key) do
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

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp save_draft!(flag_key, environment_key, version, value) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v#{version}",
      rules: [
        %{
          key: "#{flag_key}-draft-#{version}",
          strategy: :forced_value,
          value: %{value: value},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
  end

  defp seed_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end
