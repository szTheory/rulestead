defmodule RulesteadAdmin.Live.FlagLive.CleanupTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    seed_environment!("prod", "Production")

    seed_flag!(
      key: "ops-cleanup",
      owner: "ops",
      tags: ["infra"],
      description: "Ops cleanup candidate",
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      environment_keys: ["prod"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "remote-config-review",
      owner: "ops",
      tags: ["config"],
      description: "Remote config needs review",
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      environment_keys: ["prod"],
      flag_type: :remote_config
    )

    publish_flag!("ops-cleanup")
    publish_flag!("remote-config-review")

    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "prod", DateTime.add(now, -7_200, :second))

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

  test "cleanup is advisory-only and removes archive submission controls", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/ops-cleanup/cleanup?env=prod")

    assert html =~ "Phase 36 keeps cleanup advisory only"
    assert html =~ "Recommended next action"
    assert html =~ "Archive candidate"
    assert html =~ "Archive when the review is complete"
    assert html =~ "Fresh scan found no code references"
    assert html =~ "No known code references."
    refute has_element?(view, "form")
    refute html =~ "Archive Flag"
  end

  test "cleanup shows uncertainty and blockers when evidence is weak", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/remote-config-review/cleanup?env=prod")

    assert html =~ "Guidance limited by missing evidence"
    assert html =~ "Primary recommendation:"
    assert html =~ "Keep active"
    assert html =~ "Code-reference scan receipt is missing"
    assert html =~ "Remote config flags require stronger review"
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

    if Map.has_key?(attrs, :code_reference_count) or Map.has_key?(attrs, :code_refs_scan) do
      assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
    else
      assert {:ok, _payload} = Rulestead.create_flag(attrs)
    end
  end

  defp publish_flag!(flag_key) do
    ruleset = %{
      salt: "#{flag_key}:prod:v1",
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
               Command.SaveDraftRuleset.new(flag_key, "prod", ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, "prod", actor: @admin_actor)
             )
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
