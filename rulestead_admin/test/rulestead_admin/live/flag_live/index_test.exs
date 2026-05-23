defmodule RulesteadAdmin.Live.FlagLive.IndexTest do
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
      permanent: true
    )

    seed_flag!(
      key: "ops-cleanup",
      owner: "ops",
      tags: ["infra"],
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "search-ranking",
      owner: "growth",
      tags: ["search"],
      expected_expiration: ~D[2026-04-28],
      permanent: false
    )

    seed_flag!(
      key: "remote-config-review",
      owner: "ops",
      tags: ["config"],
      flag_type: :remote_config,
      expected_expiration: ~D[2026-04-20],
      permanent: false
    )

    seed_flag!(
      key: "archive-me",
      owner: "ops",
      tags: ["legacy"],
      permanent: true
    )

    publish_flag!("checkout-redesign")
    publish_flag!("ops-cleanup")
    publish_flag!("search-ranking")
    publish_flag!("remote-config-review")
    publish_flag!("archive-me")

    assert {:ok, _} = Rulestead.record_evaluation("checkout-redesign", "prod", DateTime.add(now, -600, :second))
    assert {:ok, _} = Rulestead.record_evaluation("search-ranking", "prod", DateTime.add(now, -2_700, :second))
    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "prod", DateTime.add(now, -7_200, :second))

    assert {:ok, _} = Rulestead.archive_flag(Command.ArchiveFlag.new("archive-me"))

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

  test "defaults to the current environment, excludes archived flags, and keeps filter state in the URL", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags?env=prod&query=checkout&owner=growth&tags=checkout&stale=fresh")

    assert html =~ "Flag inventory"
    assert html =~ "Environment"
    assert html =~ "Production"
    assert html =~ "checkout-redesign"
    refute html =~ "archive-me"
    assert has_element?(view, "form[aria-label='Flag filters']")
    assert has_element?(view, "input[name='filters[query]'][value='checkout']")
    assert has_element?(view, "input[name='filters[owner]'][value='growth']")
    assert has_element?(view, "input[name='filters[tags]'][value='checkout']")
    assert has_element?(view, "select[name='filters[stale]'] option[selected][value='fresh']")
    refute has_element?(view, "[data-flag-key='archive-me']")
  end

  test "filters by lifecycle, owner, tags, and stale status and preserves url state across cursor pagination", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags?env=prod&owner=growth")

    assert has_element?(view, "[data-flag-key='checkout-redesign']")
    assert has_element?(view, "[data-flag-key='search-ranking']")

    view
    |> form("form[aria-label='Flag filters']", %{
      "filters" => %{
        "query" => "",
        "owner" => "growth",
        "tags" => "search",
        "lifecycle" => "potentially_stale",
        "stale" => "potentially_stale",
        "limit" => "1"
      }
    })
    |> render_change()

    path = assert_patch(view)
    assert path =~ "env=prod"
    assert path =~ "lifecycle=potentially_stale"
    assert path =~ "limit=1"
    assert path =~ "owner=growth"
    assert path =~ "stale=potentially_stale"
    assert path =~ "tags=search"

    assert has_element?(view, "[data-flag-key='search-ranking']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")
    refute has_element?(view, "a[rel='next']")

    {:ok, paged_view, _html} = live(conn, "/admin/flags?env=prod&owner=growth")

    paged_view
    |> form("form[aria-label='Flag filters']", %{
      "filters" => %{
        "query" => "",
        "owner" => "growth",
        "tags" => "",
        "lifecycle" => "",
        "stale" => "",
        "limit" => "1"
      }
    })
    |> render_change()

    path = assert_patch(paged_view)
    assert path =~ "limit=1"
    assert has_element?(paged_view, "a[rel='next']")

    next_cursor = next_page_cursor(paged_view)

    paged_view
    |> element("a[rel='next']")
    |> render_click()

    path = assert_patch(paged_view)
    assert path =~ "after=#{next_cursor}"
    assert path =~ "limit=1"
    assert path =~ "owner=growth"
    assert has_element?(paged_view, "[data-flag-key='search-ranking']")
    assert has_element?(paged_view, "a[rel='prev']")

    paged_view
    |> element("a[rel='prev']")
    |> render_click()

    assert has_element?(paged_view, "[data-flag-key='checkout-redesign']")
  end

  test "round-trips readiness and evidence-quality filters through the url and renders advisory guidance separately", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags?env=prod&readiness=archive_candidate&evidence_quality=strong")

    assert has_element?(view, "select[name='filters[readiness]'] option[selected][value='archive_candidate']")
    assert has_element?(view, "select[name='filters[evidence_quality]'] option[selected][value='strong']")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")

    view
    |> form("form[aria-label='Flag filters']", %{
      "filters" => %{
        "query" => "",
        "owner" => "",
        "tags" => "",
        "lifecycle" => "",
        "stale" => "",
        "readiness" => "needs_review",
        "evidence_quality" => "weak",
        "limit" => "25"
      }
    })
    |> render_change()

    path = assert_patch(view)
    assert path =~ "readiness=needs_review"
    assert path =~ "evidence_quality=weak"
    assert has_element?(view, "[data-flag-key='search-ranking']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "[data-flag-key='ops-cleanup']")
  end

  test "renders lifecycle freshness and archive-readiness badges as separate signals with uncertainty-first copy",
       %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags?env=prod")

    assert html =~ "Archive readiness"
    assert html =~ "Evidence quality"
    assert html =~ "Archive candidate"
    assert html =~ "Strong"
    assert html =~ "Needs review"
    assert html =~ "Weak"
    assert html =~ "Guidance limited by missing evidence"
    assert html =~ "Recent scan missing"
  end

  test "renders keyboard-safe dense table semantics without hidden environment state", %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags?env=prod")

    assert html =~ "role=\"grid\""
    assert html =~ "aria-label=\"Flag inventory table\""
    assert html =~ "tabindex=\"0\""
    assert html =~ "Monospace key"
    assert html =~ "Last changed"
    assert has_element?(view, "tbody tr[data-flag-key='checkout-redesign'][tabindex='0']")
    assert has_element?(view, "tbody tr[data-flag-key='checkout-redesign'] a[href='/admin/flags/checkout-redesign?env=prod']")
    refute html =~ "Current environment hidden"
  end

  defp next_page_cursor(view) do
    html = render(view)

    [_, cursor] = Regex.run(~r/after=([^"&]+).*rel="next"/s, html)
    cursor
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

  defp seed_environment!(key, name) do
    assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
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
end
