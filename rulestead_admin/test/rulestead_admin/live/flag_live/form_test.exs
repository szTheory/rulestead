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
      ownership: %{owner_ref: "growth", owner_kind: :team, owner_display: "growth"},
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-05-01],
        default_source: :flag_type,
        default_overridden: false
      },
      tags: ["checkout", "release"]
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

  test "new flag requires ownership and lifecycle posture and can create metadata", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/new?env=prod")

    assert html =~ "Create flag"
    assert has_element?(view, "form[aria-label='Flag metadata form']")
    assert html =~ "checkout-one-click-buy"
    assert html =~ "Enables one-click checkout for returning customers"
    assert html =~ "Release (most common)"
    assert html =~ "Boolean (most common)"
    assert html =~ "team:checkout"
    refute html =~ "Flag was not created"
    refute html =~ "Key is required"
    refute html =~ "Owner reference is required"
    refute html =~ "Review by is required"
    assert has_element?(view, "input[name='flag[owner_kind]'][value='person']")
    assert has_element?(view, "input[name='flag[owner_kind]'][value='team']")
    assert has_element?(view, "input[name='flag[owner_kind]'][value='service']")
    assert has_element?(view, "input[name='flag[value_type]'][value='json']")
    refute has_element?(view, "select[name='flag[value_type]']")
    refute has_element?(view, ".rs-date-picker__calendar summary")

    css = File.read!("priv/static/css/rulestead_admin.css")

    assert css =~ ".rs-date-picker__entry:focus-within .rs-date-picker__calendar"

    refute css =~ ".rs-date-picker:focus-within .rs-date-picker__calendar"
    assert css =~ ".rs-shell input[type=\"text\"]:disabled"
    assert css =~ "cursor: not-allowed"

    assert occurs_before?(html, "Owner type", "Display name")
    assert occurs_before?(html, "Display name", "Owner ID")

    preset_html =
      view
      |> element("button[phx-click='set_review_by'][phx-value-days='30']")
      |> render_click()

    assert preset_html =~ ~s(value="2026-05-23")

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "key" => "inventory-admin",
          "description" => "Admin inventory page",
          "flag_type" => "release",
          "value_type" => "boolean",
          "default_value" => "true",
          "owner_ref" => "",
          "owner_display" => "",
          "review_by" => "",
          "tags" => "admin, inventory"
        }
      })
      |> render_submit()

    assert invalid_html =~ "Owner reference is required"

    view
    |> form("form[aria-label='Flag metadata form']", %{
      "flag" => %{
        "key" => "inventory-admin",
        "description" => "Admin inventory page",
        "flag_type" => "release",
        "value_type" => "boolean",
        "default_value" => "true",
        "owner_ref" => "team:platform",
        "owner_kind" => "team",
        "owner_display" => "Platform Team",
        "lifecycle_mode" => "permanent",
        "review_by" => "",
        "tags" => "admin, inventory"
      }
    })
    |> render_submit()

    assert_redirect(view, "/admin/flags/inventory-admin?env=prod")

    assert {:ok, detail} = Rulestead.fetch_flag("inventory-admin", "prod")
    assert detail.flag.ownership.owner_ref == "team:platform"
    assert detail.flag.ownership.owner_kind == :team
    assert detail.flag.ownership.owner_display == "Platform Team"
    assert detail.flag.lifecycle.mode == :permanent
    assert detail.flag.flag_type == :release
    assert detail.flag.default_value == %{value: true}
    assert detail.flag.tags == ["admin", "inventory"]
  end

  test "new flag can be created with the visible ecommerce example values", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/new?env=prod")

    view
    |> form("form[aria-label='Flag metadata form']", %{
      "flag" => %{
        "key" => "checkout-one-click-buy",
        "description" =>
          "Enables one-click checkout for returning customers while the team monitors conversion and support tickets.",
        "flag_type" => "release",
        "value_type" => "boolean",
        "default_value" => "false",
        "owner_ref" => "team:checkout",
        "owner_kind" => "team",
        "owner_display" => "Checkout Team",
        "lifecycle_mode" => "permanent",
        "review_by" => "",
        "tags" => "checkout, release, revenue"
      }
    })
    |> render_submit()

    {redirect_path, flash} = assert_redirect(view)
    assert redirect_path == "/admin/flags/checkout-one-click-buy?env=prod"
    assert flash["info"] == "Flag checkout-one-click-buy was created."

    assert {:ok, detail} = Rulestead.fetch_flag("checkout-one-click-buy", "prod")
    assert detail.flag.description =~ "Enables one-click checkout"
    assert detail.flag.ownership.owner_ref == "team:checkout"
    assert detail.flag.ownership.owner_display == "Checkout Team"
    assert detail.flag.tags == ["checkout", "release", "revenue"]
  end

  test "new flag validates key format before calling the store", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/new?env=prod")

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "key" => "checkout.one_click_buy",
          "description" => "Enables one-click checkout for returning customers.",
          "flag_type" => "release",
          "value_type" => "boolean",
          "default_value" => "false",
          "owner_ref" => "team:checkout",
          "owner_kind" => "team",
          "owner_display" => "Checkout Team",
          "lifecycle_mode" => "permanent",
          "review_by" => "",
          "tags" => "checkout, release, revenue"
        }
      })
      |> render_submit()

    assert invalid_html =~ "Flag was not created"

    assert invalid_html =~
             "Use lowercase letters, numbers, colon, underscore, or hyphen. Start with a letter or number."

    refute invalid_html =~ "store command is invalid"
    assert {:error, _error} = Rulestead.fetch_flag("checkout.one_click_buy", "prod")
  end

  test "field changes do not show unrelated required-field errors before submit", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/new?env=prod")

    change_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "owner_kind" => "person"
        }
      })
      |> render_change()

    refute change_html =~ "Flag was not created"
    refute change_html =~ "Key is required"
    refute change_html =~ "Owner reference is required"
    refute change_html =~ "Review by is required"

    invalid_date_change_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "review_by" => "2026-99-99"
        }
      })
      |> render_change()

    refute invalid_date_change_html =~ "Use a real review date in YYYY-MM-DD format"

    invalid_date_blur_html =
      view
      |> element("#flag_review_by")
      |> render_blur(%{"field" => "review_by"})

    assert invalid_date_blur_html =~ "Use a real review date in YYYY-MM-DD format"
  end

  test "new flag explains invalid review dates without crashing", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/new?env=prod")

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "key" => "checkout-one-click-buy-review-date",
          "description" => "Enables one-click checkout for returning customers.",
          "flag_type" => "release",
          "value_type" => "boolean",
          "default_value" => "false",
          "owner_ref" => "team:checkout",
          "owner_kind" => "team",
          "owner_display" => "Checkout Team",
          "lifecycle_mode" => "expiring",
          "review_by" => "2026-99-99",
          "tags" => "checkout, release, revenue"
        }
      })
      |> render_submit()

    assert invalid_html =~ "Flag was not created"
    assert invalid_html =~ "Use a real review date in YYYY-MM-DD format"
    assert {:error, _error} = Rulestead.fetch_flag("checkout-one-click-buy-review-date", "prod")
  end

  test "edit flag updates authored ownership and lifecycle metadata while keeping immutable fields visible",
       %{
         conn: conn
       } do
    {:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/edit?env=prod")

    assert html =~ "Edit flag"
    assert has_element?(view, "input[name='flag[key]'][disabled]")
    assert has_element?(view, "input[name='flag[flag_type]'][disabled]")

    invalid_html =
      view
      |> form("form[aria-label='Flag metadata form']", %{
        "flag" => %{
          "description" => "Updated checkout copy",
          "owner_ref" => "",
          "owner_kind" => "team",
          "owner_display" => "",
          "review_by" => "",
          "tags" => "checkout, critical"
        }
      })
      |> render_submit()

    assert invalid_html =~ "Owner reference is required"

    view
    |> form("form[aria-label='Flag metadata form']", %{
      "flag" => %{
        "description" => "Updated checkout copy",
        "owner_ref" => "team:platform",
        "owner_kind" => "team",
        "owner_display" => "Platform Team",
        "lifecycle_mode" => "permanent",
        "review_by" => "",
        "tags" => "checkout, critical"
      }
    })
    |> render_submit()

    {redirect_path, flash} = assert_redirect(view)
    assert redirect_path == "/admin/flags/checkout-redesign?env=prod"
    assert flash["info"] == "Metadata saved for checkout-redesign."

    assert {:ok, detail} = Rulestead.fetch_flag("checkout-redesign", "prod")
    assert detail.flag.description == "Updated checkout copy"
    assert detail.flag.ownership.owner_ref == "team:platform"
    assert detail.flag.ownership.owner_display == "Platform Team"
    assert detail.flag.lifecycle.mode == :permanent
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

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, "prod", ruleset))

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, "prod"))
  end

  defp seed_environment!(key, name) do
    assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
  end

  defp occurs_before?(html, before_text, after_text) do
    {before_index, _length} = :binary.match(html, before_text)
    {after_index, _length} = :binary.match(html, after_text)
    before_index < after_index
  end
end
