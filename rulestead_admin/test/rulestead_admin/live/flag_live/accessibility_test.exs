defmodule RulesteadAdmin.Live.FlagLive.AccessibilityTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("prod", "Production")
    ensure_environment!("staging", "Staging")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
    )

    publish_flag!("checkout-redesign", "prod")
    save_draft!("checkout-redesign", "prod", 2, false)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "list page passes the package accessibility audit", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags?env=prod")
    assert_accessible(html)
    assert html =~ "Flag inventory table"
    assert html =~ "Flag filters"
  end

  test "detail page passes the package accessibility audit", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")
    assert_accessible(html)
    assert html =~ "Open rules workspace"
    assert html =~ "Audit timeline arrives in Phase 7"
  end

  test "metadata forms pass the package accessibility audit in invalid and valid render states", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/new?env=prod")
    assert_accessible(html)

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "key" => "inventory-admin",
          "description" => "Admin inventory page",
          "flag_type" => "release",
          "value_type" => "boolean",
          "default_value" => "true",
          "owner" => "",
          "expected_expiration" => "",
          "permanent" => "false",
          "tags" => "admin, inventory"
        }
      })
      |> render_submit()

    assert_accessible(invalid_html)
    assert invalid_html =~ "Owner is required"

    edit_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, _edit_view, edit_html} = live(edit_conn, "/admin/flags/checkout-redesign/edit?env=prod")
    assert_accessible(edit_html)
  end

  defp assert_accessible(html) do
    doc = LazyHTML.from_fragment(html)

    unlabeled_controls =
      doc
      |> LazyHTML.query("input:not([type='hidden']), select, textarea")
      |> Enum.filter(&(not wrapped_by_label?(&1) and missing_aria_label?(&1)))

    empty_buttons =
      doc
      |> LazyHTML.query("button, a")
      |> Enum.filter(&(String.trim(LazyHTML.text(&1)) == ""))

    table_issues =
      doc
      |> LazyHTML.query("table")
      |> Enum.filter(&(missing_aria_label?(&1) and Enum.empty?(LazyHTML.query(&1, "caption"))))

    assert unlabeled_controls == []
    assert empty_buttons == []
    assert table_issues == []
  end

  defp wrapped_by_label?(node) do
    case LazyHTML.parent_node(node) do
      nil -> false
      parent -> parent["label"] != []
    end
  end

  defp missing_aria_label?(node) do
    case LazyHTML.attribute(node, "aria-label") do
      [] -> true
      labels -> Enum.all?(labels, &(String.trim(&1) == ""))
    end
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

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp publish_flag!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key))
  end

  defp save_draft!(flag_key, environment_key, version, value) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v#{version}",
      rules: [
        %{
          key: "#{flag_key}-draft-#{version}",
          strategy: :forced_value,
          value: %{value: value},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))
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
