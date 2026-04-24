defmodule RulesteadAdmin.Live.FlagLive.TimelineTest do
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
    seed_flag!()
    publish_ruleset!("checkout-redesign", "prod")

    assert {:ok, _} =
             Rulestead.engage_kill_switch("checkout-redesign", "prod", %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "incident"
             )

    Application.put_env(:rulestead, :admin_policy, DenyPolicy)

    assert {:error, %Rulestead.Error{type: :unauthorized}} =
             Rulestead.engage_kill_switch("checkout-redesign", "prod", %{id: "viewer-1", display: "Viewer", roles: [:viewer]},
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

  test "per-flag timeline shows reverse-chronological redacted rows and appends rollback as a linked event", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Kill switch engage denied"
    assert html =~ "Kill switch engaged"
    assert html =~ "Denied action remains visible in the audit ledger."
    refute html =~ "viewer@example.com"
    assert html =~ "Show raw detail"

    rollback_html =
      view
      |> element("button[phx-click='rollback']")
      |> render_click()

    assert rollback_html =~ "Rollback appended as audit event"
    assert rollback_html =~ "Rollback applied"
    assert rollback_html =~ "Rollback of audit event"
  end

  test "timeline row disclosure keeps readable diff first and raw data behind details", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/timeline?env=prod")

    assert html =~ "Readable diff"
    assert html =~ "status active"
    assert html =~ "status killswitched"
    assert html =~ "Show raw detail"
  end

  defp seed_flag! do
    attrs = %{
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
    }

    assert %{flag: %{key: "checkout-redesign"}} = Control.put_flag!(attrs)
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
