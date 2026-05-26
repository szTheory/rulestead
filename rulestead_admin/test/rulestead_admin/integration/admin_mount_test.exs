defmodule RulesteadAdmin.Integration.AdminMountTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_admin_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, RulesteadAdmin.TestPolicy)

    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      if is_nil(previous_admin_policy) do
        Application.delete_env(:rulestead, :admin_policy)
      else
        Application.put_env(:rulestead, :admin_policy, previous_admin_policy)
      end
    end)

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
               ownership: %{
                 owner_ref: "team:growth",
                 owner_kind: :team,
                 owner_display: "Growth Team"
               },
               lifecycle: %{
                 mode: :expiring,
                 review_by: ~D[2026-05-01],
                 default_source: :flag_type,
                 default_overridden: false
               },
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

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "prod", ruleset)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "prod"))

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

    conn = host_conn(conn)

    {:ok, conn: conn}
  end

  test "host-style mount honors the public env and route conventions without leaking internals",
       %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/admin/flags?env=prod", flash: %{}}}} =
             live(conn, "/admin/flags")

    redirected_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()
    {:ok, _list_view, list_html} = live(redirected_conn, "/admin/flags?env=prod")
    assert list_html =~ "Flag inventory"
    assert list_html =~ "Environment"
    assert list_html =~ "Production"
    assert list_html =~ ~s(href="/admin/flags?env=dev")
    assert list_html =~ ~s(href="/admin/flags?env=prod")
    assert list_html =~ "/admin/flags/checkout-redesign"

    detail_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _detail_view, detail_html} =
      live(detail_conn, "/admin/flags/checkout-redesign?env=prod")

    assert detail_html =~ "Open rules workspace"
    assert detail_html =~ "Production"
    assert detail_html =~ "/admin/flags/checkout-redesign/rules?env=prod"
    assert detail_html =~ "/admin/flags/checkout-redesign/kill?env=prod"
    assert detail_html =~ "/admin/flags/checkout-redesign/timeline?env=prod"

    rules_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _rules_view, rules_html} =
      live(rules_conn, "/admin/flags/checkout-redesign/rules?env=prod")

    assert rules_html =~ "Rules workspace"
    assert rules_html =~ "Reusable audience"
    assert rules_html =~ "Save draft"
    assert rules_html =~ "Production"

    simulate_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _simulate_view, simulate_html} =
      live(simulate_conn, "/admin/flags/checkout-redesign/simulate?env=prod")

    assert simulate_html =~ "Run simulation"
    assert simulate_html =~ "Production"

    rollouts_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _rollouts_view, rollouts_html} =
      live(rollouts_conn, "/admin/flags/checkout-redesign/rollouts?env=prod")

    assert rollouts_html =~ "Rollout controls"
    assert rollouts_html =~ "Production"
  end

  test "mounted lifecycle routes keep env query and cleanup review available through the public host seam",
       %{conn: conn} do
    lifecycle_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _view, lifecycle_html} =
      live(lifecycle_conn, "/admin/flags?env=prod&readiness=archive_candidate")

    assert lifecycle_html =~ "Flag inventory"
    assert lifecycle_html =~ "Production"
    assert lifecycle_html =~ "/admin/flags?env=prod"

    cleanup_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _cleanup_view, cleanup_html} =
      live(
        cleanup_conn,
        "/admin/flags/checkout-redesign/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod"
      )

    assert cleanup_html =~ "Cleanup review"
    assert cleanup_html =~ "Production"
    assert cleanup_html =~ "Back to queue"

    preview_conn = conn |> Phoenix.ConnTest.recycle() |> host_conn()

    {:ok, _preview_view, preview_html} =
      live(
        preview_conn,
        "/admin/flags/checkout-redesign/cleanup/preview?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod"
      )

    assert preview_html =~ "Archive preview"
    assert preview_html =~ "Production"
    assert preview_html =~ "/admin/flags/checkout-redesign/cleanup/confirm?env=prod"
  end

  test "mounted host seam denies requests that omit the host-owned actor prerequisite",
       _context do
    conn =
      Phoenix.ConnTest.build_conn()
      |> host_conn(actor: nil, environments: [%{"key" => "prod", "name" => "Production"}])

    assert {:error, {:redirect, %{to: "/admin/flags"}}} =
             live(conn, "/admin/flags?env=prod")
  end

  defp host_conn(conn, opts \\ []) do
    actor = Keyword.get(opts, :actor, %{id: 9, email: "host-admin@example.com"})

    session = %{
      "rulestead_admin_last_env" => Keyword.get(opts, :last_env, "prod"),
      "rulestead_admin_environments" => Keyword.get(opts, :environments, default_environments())
    }

    session =
      if actor do
        Map.put(session, "current_actor", actor)
      else
        session
      end

    Phoenix.ConnTest.init_test_session(conn, session)
  end

  defp default_environments do
    [
      %{"key" => "dev", "name" => "Development"},
      %{"key" => "staging", "name" => "Staging"},
      %{"key" => "prod", "name" => "Production"}
    ]
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
