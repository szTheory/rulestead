defmodule RulesteadAdmin.Live.FlagLive.SimulateTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    now = ~U[2026-04-23 16:00:00Z]

    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod"]
    )

    publish_ruleset!("checkout-redesign", "prod")
    Cache.reset("prod")

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: "prod",
         store: Rulestead.Fake,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)

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

  test "running a simulation renders summary-first result details for one actor context", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")

    assert html =~ "Run simulation"

    result_html =
      view
      |> form("form[aria-label='Simulation form']", simulation_params("plan=enterprise\nemail=sam@example.com"))
      |> render_submit()

    assert result_html =~ "Simulation summary"
    assert result_html =~ "Matched rule"
    assert result_html =~ "enterprise-rollout"
    assert result_html =~ "enterprise-on"
    assert result_html =~ "Rule match"
    assert result_html =~ "Bucket result"
    assert result_html =~ "Snapshot version"
    assert result_html =~ "Cache age"
    assert String.contains?(result_html, "Simulation summary")
    assert String.contains?(result_html, "Trace detail")
    assert :binary.match(result_html, "Simulation summary") < :binary.match(result_html, "Trace detail")
  end

  test "trace details stay collapsed until operators explicitly open the disclosure", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")

    result_html =
      view
      |> form("form[aria-label='Simulation form']", simulation_params("plan=enterprise\nemail=sam@example.com"))
      |> render_submit()

    assert has_element?(view, "details[aria-label='Trace detail']")
    assert result_html =~ "Show rule-by-rule detail"
    refute result_html =~ "<details open"
    assert result_html =~ "Condition checks"
    assert result_html =~ "Bucket math"
  end

  test "operators can apply and reset a page-scoped archetype and export an ExUnit fixture literal", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")

    assert html =~ "No saved archetype applied"

    applied_html =
      view
      |> element("button[phx-click='apply_archetype'][phx-value-id='support_case']")
      |> render_click()

    assert applied_html =~ "Support case"
    assert applied_html =~ "support-user-42"
    assert applied_html =~ "plan=enterprise"

    exported_html =
      view
      |> element("button[phx-click='export_fixture']")
      |> render_click()

    fixture_export = fixture_export_text(exported_html)

    assert fixture_export =~ "%Rulestead.Context{"
    assert fixture_export =~ "targeting_key: \"support-user-42\""
    assert fixture_export =~ "environment: \"prod\""
    assert fixture_export =~ "attributes: %{"
    assert fixture_export =~ "\"email\" => \"sam@example.com\""

    reset_html =
      view
      |> element("button[phx-click='reset_archetype']")
      |> render_click()

    assert reset_html =~ "No saved archetype applied"
    refute reset_html =~ "support-user-42"
  end

  defp simulation_params(traits) do
    %{
      "simulation" => %{
        "targeting_key" => "support-user-42",
        "tenant_key" => "acme",
        "session_id" => "sess-42",
        "request_id" => "req-42",
        "traits" => traits
      }
    }
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
  end

  defp publish_ruleset!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "enterprise-rollout",
          strategy: :variant_split,
          conditions: [
            %{
              attribute: "attributes.plan",
              operator: :equals,
              value: %{equals: "enterprise"}
            }
          ],
          rollout: %{bucket_by: :subject, percentage: 100, salt: "enterprise"},
          variants: [
            %{key: "enterprise-on", value: %{value: true}, weight: 100}
          ]
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end

  defp fixture_export_text(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("textarea[aria-label='ExUnit fixture export']")
    |> LazyHTML.text()
  end
end
