defmodule RulesteadAdmin.Live.WebhookLive.ShowTest do
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

  test "webhook detail page displays correlations and explicitly labels types", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/webhooks/wh-123?env=prod")

    assert html =~ "Webhook Details"
    assert html =~ "Record ID:"
    assert html =~ "wh-123"
    assert html =~ "Inbound accepted event"
    assert html =~ "Received from"
    assert html =~ "Correlations"
    assert html =~ "Related change request"
    assert html =~ "Related schedule"
    assert html =~ "Related flag"
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end
