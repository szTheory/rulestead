defmodule RulesteadAdmin.Live.FlagLive.FormTest do
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
    seed_environment!("prod", "Production")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      expected_expiration: ~D[2026-05-01],
      permanent: false
    )

    publish_flag!("checkout-redesign")

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

  test "new flag requires owner plus expected expiration or permanent and can create metadata", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/new?env=prod")

    assert html =~ "Create flag"
    assert has_element?(view, "form[aria-label='Flag metadata form']")

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

    assert invalid_html =~ "Owner is required"
    assert invalid_html =~ "Choose an expected expiration or mark the flag permanent"

    view
    |> form("form[aria-label='Flag metadata form']", %{
      "flag" => %{
        "key" => "inventory-admin",
        "description" => "Admin inventory page",
        "flag_type" => "release",
        "value_type" => "boolean",
        "default_value" => "true",
        "owner" => "platform",
        "expected_expiration" => "",
        "permanent" => "true",
        "tags" => "admin, inventory"
      }
    })
    |> render_submit()

    assert_redirect(view, "/admin/flags/inventory-admin?env=prod")

    assert {:ok, detail} = Rulestead.fetch_flag("inventory-admin", "prod")
    assert detail.flag.owner == "platform"
    assert detail.flag.permanent == true
    assert detail.flag.flag_type == :release
    assert detail.flag.default_value == %{value: true}
    assert detail.flag.tags == ["admin", "inventory"]
  end

  test "edit flag updates metadata and keeps immutable fields visible", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/edit?env=prod")

    assert html =~ "Edit flag"
    assert has_element?(view, "input[name='flag[key]'][disabled]")
    assert has_element?(view, "select[name='flag[flag_type]'][disabled]")

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "description" => "Updated checkout copy",
          "owner" => "",
          "expected_expiration" => "",
          "permanent" => "false",
          "tags" => "checkout, critical"
        }
      })
      |> render_submit()

    assert invalid_html =~ "Owner is required"
    assert invalid_html =~ "Choose an expected expiration or mark the flag permanent"

    view
    |> form("form[aria-label='Flag metadata form']", %{
      "flag" => %{
        "description" => "Updated checkout copy",
        "owner" => "platform",
        "expected_expiration" => "",
        "permanent" => "true",
        "tags" => "checkout, critical"
      }
    })
    |> render_submit()

    assert_redirect(view, "/admin/flags/checkout-redesign?env=prod")

    assert {:ok, detail} = Rulestead.fetch_flag("checkout-redesign", "prod")
    assert detail.flag.description == "Updated checkout copy"
    assert detail.flag.owner == "platform"
    assert detail.flag.permanent == true
    assert detail.flag.tags == ["checkout", "critical"]
    assert detail.flag.flag_type == :release
    assert detail.flag.default_value == %{value: false}
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:description, "Flag #{attrs[:key]}")
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp publish_flag!(flag_key) do
    ruleset = %{
      salt: "#{flag_key}:prod:v1",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} = Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, "prod", ruleset))
    assert {:ok, _published} = Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, "prod"))
  end

  defp seed_environment!(key, name) do
    assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
  end
end
