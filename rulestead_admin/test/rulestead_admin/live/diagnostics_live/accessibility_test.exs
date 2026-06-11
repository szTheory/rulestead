defmodule RulesteadAdmin.Live.DiagnosticsLive.AccessibilityTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Runtime.{Cache, Snapshot}
  alias RulesteadAdmin.TestSupport.AxeAudit

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Cache.reset("prod")
    Cache.reset("staging")

    {:ok, _applied} =
      "prod"
      |> snapshot_fixture()
      |> Snapshot.compile()
      |> then(fn {:ok, compiled} -> Cache.apply(compiled) end)

    on_exit(fn ->
      Cache.reset("prod")
      Cache.reset("staging")
    end)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "diagnostics screen exposes named regions and remains accessible after async load and refresh",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/diagnostics?env=prod")
    AxeAudit.assert_accessible!(html)

    loaded_html = render_async(view)
    AxeAudit.assert_accessible!(loaded_html)

    assert has_element?(view, "section[aria-label='Topology scope']")
    assert has_element?(view, "section[aria-label='Infrastructure health summary']")
    assert has_element?(view, "main h1.sr-only", "Diagnostics")
    refute has_element?(view, ".rs-shell__header h1")
    assert has_element?(view, "button[aria-label='Refresh diagnostics']")
    refute has_element?(view, ".rs-shell__header button[aria-label='Refresh diagnostics']")

    refreshed_html =
      view
      |> element("button[phx-click='refresh']")
      |> render_click()

    AxeAudit.assert_accessible!(refreshed_html)
    assert refreshed_html =~ "Refresh requested"
  end

  test "degraded diagnostics state stays readable without relying on color alone", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/diagnostics?env=staging")

    degraded_html = render_async(view)
    AxeAudit.assert_accessible!(degraded_html)

    assert has_element?(view, "section[aria-label='Topology scope']")
    assert degraded_html =~ "Health snapshot unavailable"
    assert degraded_html =~ "No current-node runtime snapshot is loaded for staging."
    assert degraded_html =~ "Use refresh after a sync lands."
  end

  defp snapshot_fixture(environment_key) do
    now = DateTime.utc_now()

    payload = %{
      schema_version: 1,
      environment_key: environment_key,
      generated_at: DateTime.add(now, -5, :second),
      flags: %{
        "checkout-redesign" => %{
          flag: %{key: "checkout-redesign", default_value: %{value: false}},
          environment: %{key: environment_key},
          flag_environment: %{key: "checkout-redesign:#{environment_key}", status: :active},
          active_ruleset: %{
            version: 4,
            salt: "checkout:v4",
            rules: []
          }
        }
      }
    }

    %{
      environment_key: environment_key,
      version: 12,
      payload: :erlang.term_to_binary(payload),
      payload_checksum: "checksum",
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: DateTime.add(now, -4_500, :millisecond)
    }
  end
end
