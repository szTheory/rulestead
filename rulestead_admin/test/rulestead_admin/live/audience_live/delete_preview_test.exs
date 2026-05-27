defmodule RulesteadAdmin.Live.AudienceLive.DeletePreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Rulestead.Fake.Control.reset!()
    Rulestead.Fake.Control.put_audience!(%{key: "vip-users", description: "VIP"})
    :ok
  end

  test "delete preview is fail-closed with no apply submit", %{conn: conn} do
    conn =
      Phoenix.ConnTest.init_test_session(conn, %{
        "current_actor" => %{id: 1, email: "ops@example.com"},
        "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
        "rulestead_admin_last_env" => "test"
      })

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/delete/preview?env=test")

    assert html =~ "Delete preview"
    assert html =~ "Audience delete is not available in mounted admin"
    assert html =~ "Back to audience"
    refute html =~ "Apply delete"
    refute html =~ ~r/type="submit"/
  end
end
