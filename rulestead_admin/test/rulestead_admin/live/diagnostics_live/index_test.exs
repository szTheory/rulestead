defmodule RulesteadAdmin.Live.DiagnosticsLive.IndexTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Runtime.{Cache, Snapshot}

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_runtime = Application.get_env(:rulestead, :runtime)

    prod_environment = "prod"
    staging_environment = "staging"

    Cache.reset(prod_environment)
    Cache.reset(staging_environment)

    compiled_snapshot = prod_environment |> snapshot_fixture() |> compile_snapshot!()
    {:ok, _applied} = Cache.apply(compiled_snapshot)

    on_exit(fn ->
      Cache.reset(prod_environment)
      Cache.reset(staging_environment)
      restore_env(:runtime, previous_runtime)
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

    {:ok, conn: conn, previous_runtime: previous_runtime}
  end

  test "diagnostics renders a summary-first current-node health page for the selected environment",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/diagnostics?env=prod")

    loaded_html = render_async(view)

    assert html =~ "Infrastructure health"
    assert loaded_html =~ "Current node only"
    assert loaded_html =~ "Infrastructure health"
    assert loaded_html =~ "Cache age"
    assert loaded_html =~ "Sync latency"
    assert loaded_html =~ "Snapshot version"
    assert loaded_html =~ "Refresh state"
    assert loaded_html =~ "Repo"
    assert loaded_html =~ "Redis"
    assert loaded_html =~ "PubSub"
    assert loaded_html =~ "Production"
    assert has_element?(view, "a[href='/admin/flags/diagnostics?env=staging']")

    assert :binary.match(loaded_html, "Current health summary") <
             :binary.match(loaded_html, "Freshness details")
  end

  test "diagnostics keeps mounted-admin environment semantics and allows explicit refresh", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/diagnostics?env=prod")

    initial_html = render_async(view)

    assert has_element?(view, "button[phx-click='refresh'][aria-label='Refresh diagnostics']")
    assert initial_html =~ "Current</span>"

    refreshed_html =
      view
      |> element("button[phx-click='refresh']")
      |> render_click()

    assert refreshed_html =~ "Refresh requested"
    assert refreshed_html =~ "Current node only"
    assert refreshed_html =~ "Environment"
  end

  test "diagnostics renders warning copy when selected environment has no health snapshot", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/diagnostics?env=staging")

    loaded_html = render_async(view)

    assert loaded_html =~ "Health snapshot unavailable"
    assert loaded_html =~ "No current-node runtime snapshot is loaded for staging."
    assert loaded_html =~ "Current node only"
    assert loaded_html =~ "Use refresh after a sync lands"
    refute loaded_html =~ "FunctionClauseError"
  end

  test "diagnostics switches to host-provided topology copy only when a peer provider is configured",
       %{
         conn: conn,
         previous_runtime: previous_runtime
       } do
    Application.put_env(
      :rulestead,
      :runtime,
      Keyword.merge(previous_runtime || [], health_peer_provider: __MODULE__.PeerProvider)
    )

    {:ok, view, _html} = live(conn, "/admin/flags/diagnostics?env=prod")
    loaded_html = render_async(view)

    assert loaded_html =~ "Host-provided topology"
    assert loaded_html =~ "This screen includes host-supplied peer context."
    refute loaded_html =~ "It does not imply undiscovered peers are healthy."
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)

  defmodule PeerProvider do
    @behaviour Rulestead.Runtime.HealthPeerProvider

    @impl true
    def peer_nodes do
      [
        %{
          node: :peer@node,
          topology_scope: :peer_snapshot,
          environments: [%{environment_key: "prod", refresh_status: :ready}]
        }
      ]
    end
  end

  defp compile_snapshot!(snapshot) do
    {:ok, compiled} = Snapshot.compile(snapshot)
    compiled
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
