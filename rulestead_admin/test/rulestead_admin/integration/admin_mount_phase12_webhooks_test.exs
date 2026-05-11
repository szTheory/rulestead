defmodule RulesteadAdmin.Integration.AdminMountPhase12WebhooksTest do
  use RulesteadAdmin.ConnCase, async: false

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

    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    on_exit(fn ->
      restore_env(:admin_policy, previous_policy)
    end)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{
          id: "operator-9",
          email: "host-admin@example.com",
          display: "Host Admin"
        },
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "host-style mount reaches phase 12 webhook routes with canonical env state", %{conn: conn} do
    {:ok, _index_view, index_html} = live(conn, "/admin/flags/webhooks?env=prod")
    assert index_html =~ "Webhooks"
    assert index_html =~ "Integration visibility"
    assert index_html =~ "/admin/flags/webhooks?env=prod"

    {:ok, _detail_view, detail_html} = live(conn, "/admin/flags/webhooks/wh-123?env=prod")
    assert detail_html =~ "Webhook Details"
    assert detail_html =~ "wh-123"
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end
