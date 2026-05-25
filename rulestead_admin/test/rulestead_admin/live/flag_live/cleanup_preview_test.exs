# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.CleanupPreviewTest do
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

  defmodule ReadOnlyPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, :read_flags, _resource, _environment_key), do: true
    def can?(_actor, _action, _resource, _environment_key), do: false
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: false
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
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["infra"],
      description: "Ops cleanup candidate",
      lifecycle: %{mode: :expiring, review_by: ~D[2026-04-20], default_source: :flag_type, default_overridden: false},
      environment_keys: ["prod"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    publish_flag!("ops-cleanup")
    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "prod", DateTime.add(now, -7_200, :second))

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: [:admin]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "preview shows evidence, archive consequences, return_to carry-through, and confirm navigation", %{
    conn: conn
  } do
    {:ok, view, html} =
      live(
        conn,
        "/admin/flags/ops-cleanup/cleanup/preview?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dops"
      )

    assert html =~ "Archive this flag"
    assert html =~ "never automatic"
    assert html =~ "What archive changes"
    assert html =~ "Reasons:"
    assert html =~ "Unknowns:"
    assert html =~ "Blockers:"
    assert html =~ "Archive readiness"
    assert html =~ "Evidence quality"
    assert html =~ "Code references"
    assert has_element?(view, "a[href='/admin/flags?env=prod&owner=ops']", "Back to queue")
    assert has_element?(view, "a[href='/admin/flags/ops-cleanup/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dops']", "Back to cleanup review")
    assert has_element?(view, "a[href*='/admin/flags/ops-cleanup/cleanup/confirm?']")
    assert html =~ "Continue to archive confirmation"
  end

  test "preview redirects unauthorized operators before destructive review UI renders", %{conn: conn} do
    Application.put_env(:rulestead, :admin_policy, ReadOnlyPolicy)

    read_only_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 8, email: "viewer@example.com", roles: ["viewer"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    assert {:error, {:live_redirect, %{to: "/admin/flags"}}} =
             live(read_only_conn, "/admin/flags/ops-cleanup/cleanup/preview?env=prod")
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:ownership, %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"})
      |> Map.put_new(:lifecycle, %{mode: :permanent, review_by: nil, default_source: :flag_type, default_overridden: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
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
               Command.SaveDraftRuleset.new(flag_key, "prod", ruleset, actor: @admin_actor)
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
