# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.CleanupTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

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
    seed_environment!("prod", "Production")

    seed_flag!(
      key: "ops-cleanup",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["infra"],
      description: "Ops cleanup candidate",
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-04-20],
        default_source: :flag_type,
        default_overridden: false
      },
      environment_keys: ["prod"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "remote-config-review",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["config"],
      description: "Remote config needs review",
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-04-20],
        default_source: :flag_type,
        default_overridden: false
      },
      environment_keys: ["prod"],
      flag_type: :remote_config
    )

    publish_flag!("ops-cleanup")
    publish_flag!("remote-config-review")

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "ops-cleanup",
               "prod",
               DateTime.add(now, -7_200, :second)
             )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => @admin_actor,
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "cleanup is the canonical review surface and links into route-backed archive preview", %{
    conn: conn
  } do
    {:ok, view, html} =
      live(
        conn,
        "/admin/flags/ops-cleanup/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dops"
      )

    assert html =~ "canonical pre-mutation checkpoint"
    assert html =~ "Recommended next action"
    assert html =~ "Archive candidate"
    assert html =~ "Archive when the review is complete"
    assert html =~ "Fresh scan found no code references"
    assert html =~ "Archive consequences"
    assert html =~ "No code references found"
    assert has_element?(view, "a[href='/admin/flags?env=prod&owner=ops']", "Back to flags")

    assert has_element?(
             view,
             "a[href='/admin/flags/ops-cleanup/cleanup/preview?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dops']",
             "Preview archive"
           )

    refute has_element?(view, "form")
    refute html =~ "Phase 36 keeps cleanup advisory only"
  end

  test "cleanup shows uncertainty and blockers when evidence is weak", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/remote-config-review/cleanup?env=prod")

    assert html =~ "Guidance limited by missing evidence"
    assert html =~ "Primary recommendation"
    assert html =~ "Keep active"
    assert html =~ "Code-reference scan receipt is missing"
    assert html =~ "Remote config flags require stronger review"
  end

  test "cleanup remains available to read-only operators", %{conn: conn} do
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

    {:ok, _view, html} = live(read_only_conn, "/admin/flags/ops-cleanup/cleanup?env=prod")

    assert html =~ "Cleanup verdict"
    assert html =~ "Archive candidate"
    refute html =~ "Preview archive"
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:ownership, %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"})
      |> Map.put_new(:lifecycle, %{
        mode: :permanent,
        review_by: nil,
        default_source: :flag_type,
        default_overridden: false
      })
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
