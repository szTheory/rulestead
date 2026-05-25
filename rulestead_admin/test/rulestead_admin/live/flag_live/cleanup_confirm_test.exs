# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.CleanupConfirmTest do
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
    seed_environment!("staging", "Staging")

    seed_flag!(
      key: "ops-cleanup",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["infra"],
      description: "Ops cleanup candidate",
      lifecycle: %{mode: :expiring, review_by: ~D[2026-04-20], default_source: :flag_type, default_overridden: false},
      environment_keys: ["prod", "staging"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    publish_flag!("ops-cleanup", "prod")
    publish_flag!("ops-cleanup", "staging")
    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "prod", DateTime.add(now, -7_200, :second))
    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "staging", DateTime.add(now, -7_200, :second))

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

  test "confirm requires a reason in non-production and returns to the queue with archived visibility", %{
    conn: conn
  } do
    confirm_path = confirm_path(conn, "staging")
    {:ok, view, html} = live(conn, confirm_path)

    assert html =~ "Reason required for non-production environments."

    invalid_html =
      view
      |> form("form[aria-label='Archive flag confirmation form']", %{"reason" => "", "confirmation" => ""})
      |> render_submit()

    assert invalid_html =~ "Reason is required."

    view
    |> form("form[aria-label='Archive flag confirmation form']", %{"reason" => "staging cleanup", "confirmation" => ""})
    |> render_submit()

    {redirect_path, _flash} = assert_redirect(view)
    assert redirect_path =~ "include_archived=true"
    assert redirect_path =~ "notice=archived"
    assert redirect_path =~ "highlight=ops-cleanup"

    {:ok, returned_view, returned_html} =
      case live(conn, redirect_path) do
        {:ok, returned_view, returned_html} ->
          {:ok, returned_view, returned_html}

        {:error, {:live_redirect, %{to: redirected_path}}} ->
          live(conn, redirected_path)
      end

    assert returned_html =~ "Archived ops-cleanup in Staging."
    assert has_element?(returned_view, "a[href='/admin/flags/ops-cleanup/timeline?env=staging']", "Open audit timeline")
    assert has_element?(returned_view, "tr[data-flag-key='ops-cleanup'][data-highlighted='true']")
    assert Rulestead.fetch_flag!("ops-cleanup", "staging").flag.archived_at
  end

  test "confirm requires the exact typed key in production", %{conn: conn} do
    confirm_path = confirm_path(conn, "prod")
    {:ok, view, html} = live(conn, confirm_path)

    assert html =~ "Typed key confirmation required for production."

    invalid_html =
      view
      |> form("form[aria-label='Archive flag confirmation form']", %{
        "reason" => "prod cleanup",
        "confirmation" => "wrong-key"
      })
      |> render_submit()

    assert invalid_html =~ "Type the exact flag key to confirm this production action."
    refute Rulestead.fetch_flag!("ops-cleanup", "prod").flag.archived_at
  end

  test "confirm revalidates preview state and redirects back to preview when evidence drifts", %{
    conn: conn
  } do
    confirm_path = confirm_path(conn, "prod")
    {:ok, view, _html} = live(conn, confirm_path)

    assert {:ok, _updated} =
             Rulestead.update_flag("ops-cleanup", %{
               lifecycle: %{
                 mode: :permanent,
                 review_by: nil,
                 default_source: :operator_required,
                 default_overridden: true
               }
             })

    view
    |> form("form[aria-label='Archive flag confirmation form']", %{
      "reason" => "cleanup drifted",
      "confirmation" => "ops-cleanup"
    })
    |> render_submit()

    {redirect_path, _flash} = assert_redirect(view)
    assert redirect_path =~ "/cleanup/preview"
    assert redirect_path =~ "drifted=true"
    refute Rulestead.fetch_flag!("ops-cleanup", "prod").flag.archived_at
  end

  test "confirm redirects unauthorized operators before archive form renders", %{conn: conn} do
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
             live(read_only_conn, "/admin/flags/ops-cleanup/cleanup/confirm?env=prod")
  end

  defp confirm_path(conn, env) do
    preview_path =
      "/admin/flags/ops-cleanup/cleanup/preview?env=#{env}&return_to=%2Fadmin%2Fflags%3Fenv%3D#{env}%26owner%3Dops"

    {:ok, _view, html} = live(conn, preview_path)
    extract_confirm_path(html)
  end

  defp extract_confirm_path(html) do
    [_, path] = Regex.run(~r/href="([^"]*cleanup\/confirm[^"]*)"/, html)
    String.replace(path, "&amp;", "&")
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

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset, actor: @admin_actor)
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
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
