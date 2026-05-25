defmodule RulesteadDemo.DemoSeedSmokeTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "seed script creates authored state and the demo sign-in path reaches mounted admin", %{conn: conn} do
    Code.eval_file(Path.expand("../../priv/repo/seeds.exs", __DIR__))

    assert {:ok, flag} = Rulestead.fetch_flag("enable-new-dashboard", "staging")
    assert flag.flag.key == "enable-new-dashboard"

    sign_in_conn = get(conn, ~p"/demo/sign-in")
    assert redirected_to(sign_in_conn) == "/admin/flags?env=staging"

    recycled_conn = Phoenix.ConnTest.recycle(sign_in_conn)
    {:ok, _view, html} = live(recycled_conn, "/admin/flags?env=staging")

    assert html =~ "Flag inventory"
    assert html =~ "enable-new-dashboard"
    assert html =~ "Staging"
  end
end
