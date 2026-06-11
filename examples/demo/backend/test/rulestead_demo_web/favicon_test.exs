defmodule RulesteadDemoWeb.FaviconTest do
  use RulesteadDemoWeb.ConnCase, async: true

  test "root layout declares branded favicon links", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ ~s(rel="icon")
    assert html =~ ~s(type="image/svg+xml")
    assert html =~ ~s(href="/favicon.svg")
    assert html =~ ~s(rel="alternate icon")
    assert html =~ ~s(href="/favicon.ico")
  end

  test "serves branded favicon assets", %{conn: conn} do
    svg_conn = get(conn, ~p"/favicon.svg")

    assert response(svg_conn, 200) =~ ~s(<title id="rs-favicon-title">Rulestead</title>)
    assert get_resp_header(svg_conn, "content-type") == ["image/svg+xml"]

    ico_conn = get(conn, ~p"/favicon.ico")

    assert response(ico_conn, 200) =~ <<0, 0, 1, 0>>
    assert get_resp_header(ico_conn, "content-type") == ["image/vnd.microsoft.icon"]
  end
end
