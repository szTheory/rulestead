defmodule RulesteadAdmin.Live.AudienceLive.ArchivePreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Rulestead.Targeting.ImpactPreview

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Rulestead.Fake.Control.reset!()
    seed_audience_flag!()
    :ok
  end

  test "archive preview shows impact fingerprint and confirm link", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test")

    assert html =~ "audprev_"
    assert html =~ "Continue to archive confirm"
    assert html =~ "Authored state"
  end

  test "archive preview drift copy unchanged", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test&drifted=true")

    assert html =~ "Preview refreshed"
    assert html =~ "Authored state changed since preview"
  end

  describe "preview evidence" do
    setup %{conn: conn} do
      conn = init_session(conn)
      with_preview_evidence_resolver(fn -> :ok end)
      %{conn: conn}
    end

    test "archive preview renders host evidence when resolver configured", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test")

      assert html =~ "Sample cohort"
      assert html =~ "Impression summary"
      assert html =~ "last_24h"
      assert html =~ "fake-vip-users"
      assert html =~ "Authored state with host-supplied evidence"
      assert html =~ "bounded host-supplied evidence"
      refute html =~ "fleet"
      refute html =~ "dashboard"
    end

    test "confirm link preserves preview_fingerprint", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test")

      fingerprint = extract_audprev_fingerprint!(html)
      assert html =~ "preview_fingerprint=#{fingerprint}"
      assert html =~ "preview_schema_version=#{ImpactPreview.schema_version()}"
    end

    test "continue link carries preview_fingerprint and preview_schema_version", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test")

      fingerprint = extract_audprev_fingerprint!(html)
      confirm_href = extract_confirm_href!(html, "archive/confirm")

      assert confirm_href =~ "preview_fingerprint=#{fingerprint}"
      assert confirm_href =~ "preview_schema_version=#{ImpactPreview.schema_version()}"

      {:ok, _confirm_view, confirm_html} = live(conn, confirm_href)
      refute confirm_html =~ "Run impact preview before confirming"
    end
  end

  describe "governance in prod" do
    setup do
      Rulestead.Fake.Control.reset!()
      seed_prod_audience_flags!()
      :ok
    end

    test "archive with references shows governed callout and submit CTA", %{conn: conn} do
      conn = init_prod_session(conn)

      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=prod")

      assert html =~ "Change request required"
      assert html =~ "Governance required"
      assert html =~ "Continue to submit"
      refute html =~ "Continue to archive confirm"
    end
  end

  defp seed_audience_flag! do
    alias Rulestead.Fake.Control

    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    Control.put_flag!(%{
      key: "checkout",
      description: "Checkout",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      environment_keys: ["test"]
    })

    publish_ruleset!("checkout", "test", %{
      salt: "checkout:test",
      rules: [
        %{key: "vip-rule", strategy: :segment_match, audience_key: "vip-users", conditions: []}
      ]
    })
  end

  defp seed_prod_audience_flags! do
    alias Rulestead.Fake.Control

    Control.put_environment!(%{key: "prod", name: "Production"})
    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    Control.put_flag!(%{
      key: "checkout",
      description: "Checkout",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "growth",
      permanent: true,
      expected_expiration: nil,
      environment_keys: ["prod"]
    })

    publish_ruleset!("checkout", "prod", %{
      salt: "checkout:prod",
      rules: [
        %{key: "vip-rule", strategy: :segment_match, audience_key: "vip-users", conditions: []}
      ]
    })

    Control.rebuild_audience_reference_projection!()
  end

  defp init_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
      "rulestead_admin_last_env" => "test"
    })
  end

  defp init_prod_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}],
      "rulestead_admin_last_env" => "prod"
    })
  end

  defp with_preview_evidence_resolver(fun) when is_function(fun, 0) do
    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)

    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Fake.PreviewEvidenceResolver
    )

    on_exit(fn -> restore_preview_evidence_resolver(previous_resolver) end)

    fun.()
  end

  defp restore_preview_evidence_resolver(previous_resolver) do
    case previous_resolver do
      nil -> Application.delete_env(:rulestead, :preview_evidence_resolver)
      value -> Application.put_env(:rulestead, :preview_evidence_resolver, value)
    end
  end

  defp extract_confirm_href!(html, confirm_segment) do
    pattern = ~r/href="([^"]*#{confirm_segment}[^"]*)"/

    case Regex.run(pattern, html, capture: :all_but_first) do
      [href] -> String.replace(href, "&amp;", "&")
      _ -> flunk("expected confirm href containing #{confirm_segment}")
    end
  end

  defp extract_audprev_fingerprint!(html) do
    case Regex.run(~r/(audprev_[a-f0-9]+)/, html) do
      [_, fingerprint] -> fingerprint
      _ -> flunk("expected audprev_ fingerprint in preview HTML")
    end
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    alias Rulestead.Store.Command

    %{version: version} =
      Rulestead.save_draft_ruleset!(
        Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
      )

    Rulestead.publish_ruleset!(
      Command.PublishRuleset.new(flag_key, environment_key, version: version)
    )
  end
end
