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

  test "webhook page shows inbound rejections, accepted events, and outbound deliveries", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/webhooks?env=prod")

    assert html =~ "Webhooks"
    assert html =~ "Integration visibility"
    assert html =~ "Inbound rejections"
    assert html =~ "Inbound accepted"
    assert html =~ "Outbound deliveries"
  end

  test "filters work correctly", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/webhooks?env=prod&type=inbound_rejection")
    assert html =~ "Rejected by verifier"

    {:ok, _view, html2} = live(conn, "/admin/flags/webhooks?env=prod&type=outbound_delivery")
    assert html2 =~ "Delivered to"
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end
