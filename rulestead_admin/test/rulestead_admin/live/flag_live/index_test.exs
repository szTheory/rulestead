# credo:disable-for-this-file
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
      ownership: %{owner_ref: "growth", owner_kind: :team, owner_display: "Growth"},
      tags: ["checkout", "release"],
      lifecycle: %{
        mode: :permanent,
        review_by: nil,
        default_source: :flag_type,
        default_overridden: false
      }
    )

    seed_flag!(
      key: "ops-cleanup",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["infra"],
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-04-20],
        default_source: :flag_type,
        default_overridden: false
      },
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "search-ranking",
      ownership: %{owner_ref: "growth", owner_kind: :team, owner_display: "Growth"},
      tags: ["search"],
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-04-28],
        default_source: :flag_type,
        default_overridden: false
      }
    )

    seed_flag!(
      key: "remote-config-review",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["config"],
      flag_type: :remote_config,
      lifecycle: %{
        mode: :expiring,
        review_by: ~D[2026-04-20],
        default_source: :flag_type,
        default_overridden: false
      }
    )

    seed_flag!(
      key: "archive-me",
      ownership: %{owner_ref: "ops", owner_kind: :team, owner_display: "Ops"},
      tags: ["legacy"],
      lifecycle: %{
        mode: :permanent,
        review_by: nil,
        default_source: :flag_type,
        default_overridden: false
      }
    )

    publish_flag!("checkout-redesign")
    publish_flag!("ops-cleanup")
    publish_flag!("search-ranking")
    publish_flag!("remote-config-review")
    publish_flag!("archive-me")

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "checkout-redesign",
               "prod",
               DateTime.add(now, -600, :second)
             )

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "search-ranking",
               "prod",
               DateTime.add(now, -2_700, :second)
             )

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "ops-cleanup",
               "prod",
               DateTime.add(now, -7_200, :second)
             )

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

  test "defaults to the current environment, excludes archived flags, and keeps filter state in the URL",
       %{conn: conn} do
    {:ok, view, html} =
      live(conn, "/admin/flags?env=prod&query=checkout&owner=growth&tags=checkout&stale=fresh")

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
    assert html =~ "Lifecycle presets"
    assert html =~ "Owner filter uses the exact owner ref"
    refute has_element?(view, "[data-flag-key='archive-me']")
  end

  test "filters by lifecycle, owner, tags, and stale status and preserves url state across cursor pagination",
       %{conn: conn} do
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

  test "round-trips readiness and evidence-quality filters through the url and renders advisory guidance separately",
       %{
         conn: conn
       } do
    {:ok, view, _html} =
      live(conn, "/admin/flags?env=prod&readiness=archive_candidate&evidence_quality=strong")

    assert has_element?(
             view,
             "select[name='filters[readiness]'] option[selected][value='archive_candidate']"
           )

    assert has_element?(
             view,
             "select[name='filters[evidence_quality]'] option[selected][value='strong']"
           )

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
    refute has_element?(view, "[data-flag-key='remote-config-review']")
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

  test "renders keyboard-safe dense table semantics without hidden environment state", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, "/admin/flags?env=prod")

    assert html =~ "role=\"grid\""
    assert html =~ "aria-label=\"Flag inventory table\""
    assert html =~ "tabindex=\"0\""
    assert html =~ "Monospace key"
    assert html =~ "Last changed"
    assert has_element?(view, "tbody tr[data-flag-key='checkout-redesign'][tabindex='0']")

    assert has_element?(
             view,
             "tbody tr[data-flag-key='checkout-redesign'] a[href='/admin/flags/checkout-redesign?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod']"
           )

    refute html =~ "Current environment hidden"
  end

  test "lifecycle preset and cleanup links preserve the canonical queue url", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags?env=prod&owner=ops")

    assert has_element?(
             view,
             "a[href='/admin/flags?env=prod&owner=ops&readiness=archive_candidate&include_archived=true']",
             "Archive candidates"
           )

    assert has_element?(
             view,
             "a[href='/admin/flags/ops-cleanup/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dops']",
             "Review cleanup"
           )
  end

  test "renders archive return messaging with archived visibility and an audit timeline link", %{
    conn: conn
  } do
    audit_path = URI.encode_www_form("/admin/flags/archive-me/timeline?env=prod")

    path =
      "/admin/flags?env=prod&include_archived=true&notice=archived&flag_key=archive-me&reason=cleanup&audit_path=#{audit_path}&highlight=archive-me"

    {:ok, view, html} =
      case live(conn, path) do
        {:ok, view, html} ->
          {:ok, view, html}

        {:error, {:live_redirect, %{to: redirected_path}}} ->
          live(conn, redirected_path)
      end

    assert html =~ "Archived archive-me in Production."

    assert has_element?(
             view,
             "a[href='/admin/flags/archive-me/timeline?env=prod']",
             "Open audit timeline"
           )

    assert has_element?(view, "tr[data-flag-key='archive-me'][data-highlighted='true']")
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
      |> Map.put_new(:ownership, %{
        owner_ref: "growth",
        owner_kind: :team,
        owner_display: "Growth"
      })
      |> Map.put_new(:lifecycle, %{
        mode: :permanent,
        review_by: nil,
        default_source: :flag_type,
        default_overridden: false
      })
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    if Map.has_key?(attrs, :code_reference_count) or Map.has_key?(attrs, :code_refs_scan) do
      assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
    else
      assert {:ok, _payload} = Rulestead.create_flag(attrs)
    end
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

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, "prod", ruleset))

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new(flag_key, "prod"))
  end
end
