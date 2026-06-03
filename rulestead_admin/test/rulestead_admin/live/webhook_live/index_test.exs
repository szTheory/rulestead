defmodule RulesteadAdmin.Live.WebhookLive.IndexTest do
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
        "current_actor" => %{id: "operator-7", email: "priya@example.com", display: "Priya"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "webhook page renders an empty state describing future webhook records", %{
    conn: conn
  } do
    {:ok, _view, html} = live(conn, "/admin/flags/webhooks?env=prod")

    assert html =~ "Webhooks"
    assert html =~ "Integration visibility"
    assert html =~ "Webhook records not yet available"
    assert html =~ "Inbound rejections"
    assert html =~ "Open audit timeline"
  end

  test "filtered webhook URLs still resolve to the empty state", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/webhooks?env=prod&type=inbound_rejection")
    assert html =~ "Webhook records not yet available"

    {:ok, _view, html2} = live(conn, "/admin/flags/webhooks?env=prod&type=outbound_delivery")
    assert html2 =~ "Webhook records not yet available"
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end
