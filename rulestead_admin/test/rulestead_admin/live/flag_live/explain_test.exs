defmodule RulesteadAdmin.Live.FlagLive.ExplainTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Control.reset!()

    Control.put_audience!(%{
      key: "vip-users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
    })

    Control.put_flag!(%{
      key: "checkout",
      description: "Checkout flag",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      environment_keys: ["test"]
    })

    %{version: version} =
      Rulestead.save_draft_ruleset!(
        Command.SaveDraftRuleset.new("checkout", "test", %{
          salt: "checkout:test",
          rules: [
            %{
              key: "vip-rule",
              strategy: :segment_match,
              audience_key: "vip-users",
              conditions: []
            }
          ]
        })
      )

    Rulestead.publish_ruleset!(Command.PublishRuleset.new("checkout", "test", version: version))

    Cache.reset("test")

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: "test",
         store: Rulestead.Fake,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)

    :ok
  end

  test "renders explain route with permalink form", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/checkout/explain?env=test&targeting_key=user-1")

    assert html =~ "Decision explainer"
    assert html =~ "Traits are never stored"
    assert html =~ "user-1"
    assert html =~ "Explain summary"
    assert :binary.match(html, "Matched rule") < :binary.match(html, "Explain context")
  end

  test "explain surfaces audience trace when simulation runs", %{conn: conn} do
    conn = init_session(conn)

    {:ok, view, _html} =
      live(conn, "/admin/flags/checkout/explain?env=test&targeting_key=user-1&tenant_key=acme")

    html =
      view
      |> form("form[aria-label='Explain lookup form']", %{
        "explain" => %{
          "targeting_key" => "user-1",
          "tenant_key" => "acme",
          "session_id" => "",
          "request_id" => ""
        }
      })
      |> render_submit()

    assert html =~ "Audience targeting"
    assert html =~ "vip-users"

    patched_path = assert_patch(view)
    assert patched_path =~ "tenant_key=acme"
    refute patched_path =~ "tenant=acme"
  end

  test "malformed browser payloads validate without crashing the explain form", %{conn: conn} do
    conn = init_session(conn)
    {:ok, view, _html} = live(conn, "/admin/flags/checkout/explain?env=test")

    html =
      render_change(view, "validate", %{
        "explain" => %{
          "targeting_key" => %{"unexpected" => "nested"},
          "tenant_key" => %{"unexpected" => "tenant"},
          "session_id" => true,
          "request_id" => 42
        }
      })

    assert html =~ "Enter a targeting key to explain a decision"
    assert html =~ "Explain context"
  end

  defp init_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
      "rulestead_admin_last_env" => "test"
    })
  end
end
