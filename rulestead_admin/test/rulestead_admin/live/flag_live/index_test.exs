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
      case live(
             conn,
             "/admin/flags/flags?env=prod&view=custom&query=checkout&owner=growth&tags=checkout&stale=fresh"
           ) do
        {:ok, view, html} ->
          {:ok, view, html}

        {:error, {:live_redirect, %{to: redirected_path}}} ->
          live(conn, redirected_path)
      end

    assert html =~ "Feature flags"
    assert html =~ "Environment"
    assert html =~ "Production"
    assert has_element?(view, ".rs-shell__header [aria-label='Access']", "Admin")
    refute html =~ ~s(class="rs-shell__context-item" data-tone=)
    refute has_element?(view, "main aside.rs-policy-state")
    assert html =~ "checkout-redesign"
    refute html =~ "archive-me"
    assert has_element?(view, "form[aria-label='Flag filters']")
    assert has_element?(view, "form.rs-filter-panel[aria-label='Flag filters']")
    refute has_element?(view, "form.rs-filter-panel a", "Create flag")
    assert has_element?(view, "input[name='filters[query]'][value='checkout growth']")
    assert has_element?(view, ".rs-omnisearch__token", "checkout")
    assert has_element?(view, ".rs-omnisearch__token", "growth")
    refute has_element?(view, "input[name='filters[owner]']")
    refute has_element?(view, "input[name='filters[tags]']")

    assert has_element?(
             view,
             ".rs-results-header form[aria-label='Sort flags'] select[name='filters[sort]']"
           )

    refute has_element?(view, "form.rs-filter-panel label", "Sort")

    refute has_element?(view, "button[phx-click='toggle_advanced_filters']")
    refute has_element?(view, ".rs-filter-panel__more")

    assert has_element?(
             view,
             "nav[aria-label='Flag inventory views'] a[aria-current='page']",
             "Custom"
           )

    refute has_element?(view, "fieldset.rs-view-selector")
    refute html =~ "<legend>View</legend>"
    refute html =~ "Quick Views"
    refute has_element?(view, "[data-flag-key='archive-me']")
  end

  test "omnisearch matches owners and tags", %{conn: conn} do
    {:ok, owner_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=ops")

    assert has_element?(owner_view, "[data-flag-key='ops-cleanup']")
    assert has_element?(owner_view, "[data-flag-key='remote-config-review']")
    refute has_element?(owner_view, "[data-flag-key='checkout-redesign']")

    {:ok, tag_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=infra")

    assert has_element?(tag_view, "[data-flag-key='ops-cleanup']")
    refute has_element?(tag_view, "[data-flag-key='remote-config-review']")
  end

  test "filters by inventory view and omnisearch terms while preserving url state",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=ops")

    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "#flags-empty")

    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=ops+infra")

    view
    |> element("nav[aria-label='Flag inventory views'] a", "Stale signal")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "env=prod"
    assert path =~ "view=recently_stale"
    assert path =~ "query=ops+infra"
    refute path =~ "lifecycle="
    refute path =~ "stale="
    refute path =~ "limit="
    refute path =~ "owner="
    refute path =~ "tags="

    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    refute has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "a[rel='next']")

    {:ok, paged_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=growth")

    paged_view
    |> element("a[aria-label='Remove growth']")
    |> render_click()

    path = assert_patch(paged_view)
    refute path =~ "limit="
    refute path =~ "query="
  end

  test "triage views explain why matching flags appear", %{conn: conn} do
    {:ok, needs_review_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=needs_review")

    assert has_element?(
             needs_review_view,
             ".rs-results-header__hint",
             "Flags with incomplete cleanup evidence"
           )

    assert has_element?(needs_review_view, "[data-flag-key='search-ranking']")
    assert has_element?(needs_review_view, ".rs-triage-note", "Review needed")
    assert has_element?(needs_review_view, ".rs-triage-note", "Refresh code refs")

    {:ok, archive_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=archive_candidates")

    assert has_element?(archive_view, ".rs-results-header__hint", "strong evidence")
    assert has_element?(archive_view, "[data-flag-key='ops-cleanup']")
    assert has_element?(archive_view, ".rs-triage-note", "Ready to archive")
    assert has_element?(archive_view, ".rs-triage-note", "No code references found")
    assert has_element?(archive_view, ".rs-triage-note a", "Review cleanup")

    {:ok, stale_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=recently_stale")

    assert has_element?(stale_view, ".rs-results-header__hint", "stale evaluation")
    assert has_element?(stale_view, "[data-flag-key='ops-cleanup']")
    assert has_element?(stale_view, ".rs-triage-note", "Stale signal")
    assert has_element?(stale_view, ".rs-triage-note", "Last evaluated")

    {:ok, archived_view, _html} = live(conn, "/admin/flags/flags?env=prod&view=archived")

    assert has_element?(archived_view, ".rs-results-header__hint", "removed from active")
    assert has_element?(archived_view, "[data-flag-key='archive-me']")
    assert has_element?(archived_view, ".rs-triage-note", "Archived")
    assert has_element?(archived_view, ".rs-triage-note a", "Open timeline")
  end

  test "removes the empty state after a filtered stream resets to matching results", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=missing")

    assert has_element?(view, "#flags-empty", "No flags found")

    view
    |> element("a[aria-label='Remove missing']")
    |> render_click()

    assert_patch(view)

    view
    |> element("input[name='filters[query_text]']")
    |> render_change(%{"value" => "growth"})

    assert has_element?(view, "[data-flag-key='checkout-redesign']")
    refute has_element?(view, "#flags-empty")
  end

  test "typed omnisearch text filters transiently without committing URL state", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    view
    |> element("input[name='filters[query_text]']")
    |> render_change(%{"value" => "op"})

    assert has_element?(view, ".rs-omnisearch__group", "Owners")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")
    refute has_element?(view, ".rs-omnisearch__token", "op")
    assert has_element?(view, "input[name='filters[query]'][value='']")
    assert has_element?(view, "input[name='filters[query_text]'][value='op']")
  end

  test "typed omnisearch accepts browser form payload without committing URL state", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    render_change(view, "omnisearch_changed", %{
      "_target" => ["filters", "query_text"],
      "filters" => %{"query_text" => "op"}
    })

    assert has_element?(view, ".rs-omnisearch__group", "Owners")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")
    refute has_element?(view, ".rs-omnisearch__token", "op")
    assert has_element?(view, "input[name='filters[query]'][value='']")
    assert has_element?(view, "input[name='filters[query_text]'][value='op']")
  end

  test "omnisearch suggestions update the query URL", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    view
    |> element("input[name='filters[query_text]']")
    |> render_change(%{"value" => "op"})

    assert has_element?(view, ".rs-omnisearch__group", "Owners")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")

    view
    |> element("a.rs-omnisearch__option[href$='query=owner%3Aops']", "ops")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "query=owner%3Aops"
    refute path =~ "owner="
    assert has_element?(view, ".rs-omnisearch__token", "owner")
    assert has_element?(view, ".rs-omnisearch__token", "ops")
    assert has_element?(view, "input[name='filters[query_text]'][value='']")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    assert has_element?(view, "[data-flag-key='remote-config-review']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")

    view
    |> element("input[name='filters[query_text]']")
    |> render_change(%{"value" => "in"})

    assert has_element?(view, ".rs-omnisearch__group", "Tags")

    view
    |> element("a.rs-omnisearch__option[href*='query=owner%3Aops+tag%3Ainfra']", "infra")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "query=owner%3Aops+tag%3Ainfra"
    refute path =~ "tags="
    assert has_element?(view, ".rs-omnisearch__token", "owner")
    assert has_element?(view, ".rs-omnisearch__token", "ops")
    assert has_element?(view, ".rs-omnisearch__token", "tag")
    assert has_element?(view, ".rs-omnisearch__token", "infra")
    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    refute has_element?(view, "[data-flag-key='remote-config-review']")

    view
    |> element("a[aria-label='Remove owner:ops']")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "query=tag%3Ainfra"
    refute path =~ "owner%3Aops"
    refute has_element?(view, ".rs-omnisearch__token", "owner")
    refute has_element?(view, ".rs-omnisearch__token", "ops")
    assert has_element?(view, ".rs-omnisearch__token", "tag")
    assert has_element?(view, ".rs-omnisearch__token", "infra")
  end

  test "omnisearch suggestion chips distinguish flags owners and tags", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    view
    |> element("input[name='filters[query_text]']")
    |> render_change(%{"value" => "checkout"})

    view
    |> element("a.rs-omnisearch__option[href$='query=key%3Acheckout-redesign']")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "query=key%3Acheckout-redesign"
    assert has_element?(view, ".rs-omnisearch__token", "key")
    assert has_element?(view, ".rs-omnisearch__token", "checkout-redesign")
    assert has_element?(view, "[data-flag-key='checkout-redesign']")
    refute has_element?(view, "[data-flag-key='search-ranking']")
  end

  test "submitting typed omnisearch text commits it as a removable token", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    view
    |> form("form[aria-label='Flag filters']", %{
      "filters" => %{"view" => "all", "query" => "", "query_text" => "growth"}
    })
    |> render_submit()

    path = assert_patch(view)
    assert path =~ "query=growth"
    assert has_element?(view, ".rs-omnisearch__token", "growth")
    assert has_element?(view, "[data-flag-key='checkout-redesign']")
    assert has_element?(view, "[data-flag-key='search-ranking']")
    refute has_element?(view, "[data-flag-key='ops-cleanup']")
  end

  test "legacy readiness and evidence-quality filters render as a custom view",
       %{
         conn: conn
       } do
    {:ok, view, _html} =
      case live(conn, "/admin/flags/flags?env=prod&readiness=archive_candidate&evidence_quality=strong") do
        {:ok, view, html} ->
          {:ok, view, html}

        {:error, {:live_redirect, %{to: redirected_path}}} ->
          live(conn, redirected_path)
      end

    assert has_element?(
             view,
             "nav[aria-label='Flag inventory views'] a[aria-current='page']",
             "Custom"
           )

    assert has_element?(view, "[data-flag-key='ops-cleanup']")
    refute has_element?(view, "[data-flag-key='checkout-redesign']")

    {:ok, custom_view, _html} =
      live(conn, "/admin/flags/flags?env=prod&view=custom&readiness=needs_review&evidence_quality=weak")

    assert has_element?(custom_view, "[data-flag-key='search-ranking']")
    refute has_element?(custom_view, "[data-flag-key='remote-config-review']")
    refute has_element?(custom_view, "[data-flag-key='ops-cleanup']")
  end

  test "renders keyboard-safe dense table semantics without hidden environment state", %{
    conn: conn
  } do
    {:ok, view, html} = live(conn, "/admin/flags/flags?env=prod&view=all")

    assert html =~ "aria-label=\"Feature flags list\""
    assert html =~ "tabindex=\"0\""
    assert html =~ "Last changed"
    assert has_element?(view, "li[data-flag-key='checkout-redesign'][tabindex='0']")

    assert has_element?(
             view,
             "li[data-flag-key='checkout-redesign'] [data-meta='lifecycle']",
             "Permanent"
           )

    assert has_element?(
             view,
             "li[data-flag-key='search-ranking'] [data-meta='lifecycle']",
             "Expires Apr 28, 2026"
           )

    assert has_element?(
             view,
             "li[data-flag-key='checkout-redesign'] [data-meta='owner']",
             "Growth"
           )

    assert has_element?(
             view,
             "li[data-flag-key='checkout-redesign'] [data-meta='type']",
             "Release"
           )

    refute html =~ "<strong>Lifecycle:</strong>"
    refute html =~ "<strong>Owner:</strong>"
    refute html =~ "<strong>Type:</strong>"

    assert has_element?(
             view,
             "li[data-flag-key='checkout-redesign'] a[href='/admin/flags/checkout-redesign?env=prod&return_to=%2Fadmin%2Fflags%2Fflags%3Fenv%3Dprod%26view%3Dall']"
           )

    refute html =~ "Current environment hidden"
  end

  test "inventory view selector preserves queue context and canonicalizes triage intent", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/flags?env=prod&view=all&query=ops")

    view
    |> element("nav[aria-label='Flag inventory views'] a", "Ready to archive")
    |> render_click()

    path = assert_patch(view)
    assert path =~ "env=prod"
    assert path =~ "view=archive_candidates"
    assert path =~ "query=ops"
    refute path =~ "readiness="
    refute path =~ "include_archived="
  end

  test "renders archive return messaging with archived visibility and an audit timeline link", %{
    conn: conn
  } do
    audit_path = URI.encode_www_form("/admin/flags/archive-me/timeline?env=prod")

    path =
      "/admin/flags/flags?env=prod&include_archived=true&notice=archived&flag_key=archive-me&reason=cleanup&audit_path=#{audit_path}&highlight=archive-me"

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

    assert has_element?(view, "li[data-flag-key='archive-me'][data-highlighted='true']")
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
