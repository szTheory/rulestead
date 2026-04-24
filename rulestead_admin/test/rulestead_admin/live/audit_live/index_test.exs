defmodule RulesteadAdmin.Live.AuditLive.IndexTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy
    def can?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule DenyPolicy do
    @behaviour Rulestead.Admin.Policy
    def can?(_actor, _action, _resource, _environment_key), do: false
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
    ensure_environment!("staging", "Staging")
    seed_flag!("checkout-redesign", ["prod"])
    seed_flag!("search-ranking", ["staging"])
    publish_ruleset!("checkout-redesign", "prod")
    publish_ruleset!("search-ranking", "staging")

    assert {:ok, _} =
             Rulestead.engage_kill_switch("checkout-redesign", "prod", %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "incident"
             )

    assert {:ok, _} =
             Rulestead.release_kill_switch("checkout-redesign", "prod", %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "resolved"
             )

    Application.put_env(:rulestead, :admin_policy, DenyPolicy)

    assert {:error, %Rulestead.Error{type: :unauthorized}} =
             Rulestead.engage_kill_switch("search-ranking", "staging", %{id: "viewer-1", display: "Sam", roles: [:viewer]},
               reason: "denied attempt"
             )

    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

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

  test "global audit filters by actor, environment, date range, and mutation type while keeping denied actions visible", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/audit?env_filter=all")

    assert html =~ "Kill switch engaged"
    assert html =~ "Kill switch released"
    assert html =~ "Kill switch engage denied"
    assert html =~ "checkout-redesign"
    assert html =~ "search-ranking"

    filtered_html =
      view
      |> form("form[aria-label='Audit filters']", %{
        "filters" => %{
          "actor" => "Priya",
          "env_filter" => "prod",
          "mutation" => "kill_switch.release",
          "from" => "2026-04-23",
          "to" => "2026-04-23"
        }
      })
      |> render_change()

    assert filtered_html =~ "Kill switch released"
    refute filtered_html =~ "Kill switch engage denied"
    refute filtered_html =~ "search-ranking"
  end

  test "global audit renders ruleset reorder diff metadata from publish events", %{conn: conn} do
    operator = %{id: "operator-9", display: "On-call operator", roles: [:admin]}

    first_ruleset = %{
      salt: "checkout-redesign:prod:v2",
      rules: [
        %{key: "force-enabled", strategy: :forced_value, value: %{value: true}, conditions: []},
        %{key: "target-segment", strategy: :forced_value, value: %{value: true}, conditions: []},
        %{key: "variant-split", strategy: :forced_value, value: %{value: false}, conditions: []}
      ]
    }

    second_ruleset = %{
      salt: "checkout-redesign:prod:v3",
      rules: [
        %{key: "variant-split", strategy: :forced_value, value: %{value: false}, conditions: []},
        %{key: "force-enabled", strategy: :forced_value, value: %{value: true}, conditions: []},
        %{key: "target-segment", strategy: :forced_value, value: %{value: true}, conditions: []}
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "prod", first_ruleset,
                 actor: operator,
                 metadata: %{request_id: "req-1", source: "rules-test"}
               )
             )

    assert {:ok, _publish} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", "prod",
                 actor: operator,
                 version: 2,
                 metadata: %{request_id: "req-1", source: "rules-test"}
               )
             )

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "prod", second_ruleset,
                 actor: operator,
                 metadata: %{request_id: "req-2", source: "rules-test"}
               )
             )

    assert {:ok, _publish} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", "prod",
                 actor: operator,
                 version: 3,
                 metadata: %{request_id: "req-2", source: "rules-test"}
               )
             )

    {:ok, _view, html} = live(conn, "/admin/flags/audit?env_filter=prod&mutation=ruleset.publish")

    assert html =~ "Ruleset publish"
    assert html =~ "variant-split"
    assert html =~ "force-enabled"
    assert html =~ "target-segment"
    assert html =~ "from 2"
    assert html =~ "to 0"
  end

  defp seed_flag!(attrs) do
    assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
  end

  defp seed_flag!(key, environment_keys) do
    seed_flag!(%{
      key: key,
      owner: "growth",
      tags: ["ops"],
      description: "#{key} flag",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      environment_keys: environment_keys
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
