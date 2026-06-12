defmodule RulesteadDemoWeb.PageControllerTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.Component
  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "FleetDesk host (Phoenix + Rulestead)"
  end

  test "GET / renders configured FleetDesk URL without port-specific copy", %{conn: conn} do
    fleetdesk_frontend_url = "http://127.0.0.1:3999"
    previous = Application.get_env(:rulestead_demo, :fleetdesk_frontend_url)

    Application.put_env(:rulestead_demo, :fleetdesk_frontend_url, fleetdesk_frontend_url)

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:rulestead_demo, :fleetdesk_frontend_url)
      else
        Application.put_env(:rulestead_demo, :fleetdesk_frontend_url, previous)
      end
    end)

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ ~s(href="http://127.0.0.1:3999")
    assert html =~ "Sample customer dispatch product. Flags change what dispatchers see."
    refute html =~ "http://localhost:3000"
    refute html =~ "port 3000"
  end

  test "app layout renders configured FleetDesk nav href" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <RulesteadDemoWeb.Layouts.app flash={%{}} fleetdesk_frontend_url="http://127.0.0.1:3999">
        Layout body
      </RulesteadDemoWeb.Layouts.app>
      """)

    assert html =~ ~s(href="http://127.0.0.1:3999")
    assert html =~ ">FleetDesk</a>"
  end
end
