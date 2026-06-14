defmodule RulesteadAdmin.Live.FlagLive.SimulateAccessibilityTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command
  alias RulesteadAdmin.TestSupport.AxeAudit

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

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

  test "simulation screen passes the package accessibility audit before and after rendering summary and disclosures",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")
    AxeAudit.assert_accessible!(html)

    result_html =
      view
      |> form("form[aria-label='Simulation form']", simulation_params())
      |> render_submit()

    AxeAudit.assert_accessible!(result_html)
    assert result_html =~ "Decision summary"
    assert result_html =~ "Trace detail"
    assert result_html =~ "Regenerate fixture export"

    assert :binary.match(result_html, "Decision summary") <
             :binary.match(result_html, "Context builder")
  end

  test "visible metadata redacts non-allowlisted traits while fixture export keeps the canonical literal",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")

    result_html =
      view
      |> form("form[aria-label='Simulation form']", simulation_params())
      |> render_submit()

    visible_metadata = section_text(result_html, "#simulation-visible-metadata")
    fixture_export = textarea_text(result_html, "textarea[aria-label='ExUnit fixture export']")

    assert visible_metadata =~ "[REDACTED]"
    refute visible_metadata =~ "sam@example.com"
    refute visible_metadata =~ "203.0.113.8"
    assert fixture_export =~ "\"email\" => \"sam@example.com\""
    assert fixture_export =~ "\"ip\" => \"203.0.113.8\""
  end

  defp section_text(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
  end

  defp textarea_text(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
  end

  defp simulation_params do
    %{
      "simulation" => %{
        "targeting_key" => "support-user-42",
        "tenant_key" => "acme",
        "session_id" => "sess-42",
        "request_id" => "req-42",
        "traits" => "plan=enterprise\nemail=sam@example.com\nip=203.0.113.8"
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

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
             )
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end
