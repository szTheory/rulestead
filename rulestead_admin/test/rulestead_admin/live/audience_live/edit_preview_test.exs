defmodule RulesteadAdmin.Live.AudienceLive.EditPreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Test.ForbiddenPreviewCopy
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

  test "edit preview shows impact fingerprint and confirm link", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

    assert html =~ "audprev_"
    assert html =~ "Continue to confirm"
    assert html =~ "Authored state"
  end

  describe "preview evidence" do
    setup %{conn: conn} do
      conn = init_session(conn)
      with_preview_evidence_resolver(fn -> :ok end)
      %{conn: conn}
    end

    test "renders sample cohort and impression summary when resolver configured", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

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
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

      fingerprint = extract_audprev_fingerprint!(html)
      assert html =~ fingerprint
      assert html =~ "preview_fingerprint=#{fingerprint}"
      assert html =~ "preview_schema_version=#{ImpactPreview.schema_version()}"
    end

    test "continue link carries preview_fingerprint and preview_schema_version", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

      fingerprint = extract_audprev_fingerprint!(html)
      confirm_href = extract_confirm_href!(html, "edit/confirm")

      assert confirm_href =~ "preview_fingerprint=#{fingerprint}"
      assert confirm_href =~ "preview_schema_version=#{ImpactPreview.schema_version()}"

      {:ok, _confirm_view, confirm_html} = live(conn, confirm_href)
      refute confirm_html =~ "Run impact preview before confirming"
    end

    test "audience preview HTML avoids observability product phrases", %{conn: conn} do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

      assert ForbiddenPreviewCopy.offending_phrases(html) == []
    end

  end

  test "surfaces fail-closed alert when resolver returns policy denied", %{conn: conn} do
    conn = init_session(conn)
    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)

    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      RulesteadAdmin.Test.DenyPreviewEvidenceResolver
    )

    on_exit(fn -> restore_preview_evidence_resolver(previous_resolver) end)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

    assert html =~ ~s(role="alert")
    assert html =~ "preview evidence policy denied"
    refute html =~ "Sample cohort"
  end

  test "edit preview omits sample cohort without resolver configured", %{conn: conn} do
    conn = without_preview_evidence_resolver(fn -> init_session(conn) end)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test")

    refute html =~ "Sample cohort"
    assert html =~ "Authored state and explicit samples"
  end

  test "edit preview surfaces drift copy when preview is stale", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=test&drifted=true")

    assert html =~ "Preview refreshed"
    assert html =~ "Authored state changed since preview"
  end

  describe "governance in prod" do
    setup do
      Rulestead.Fake.Control.reset!()
      seed_prod_audience_flags!()
      :ok
    end

    test "above-threshold update shows governed callout and submit CTA", %{conn: conn} do
      conn = init_prod_session(conn)

      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=prod")

      assert html =~ "Change request required"
      assert html =~ "Governance required"
      assert html =~ "Continue to submit"
      refute html =~ "Continue to confirm"
    end

    test "prod edit preview shows governance panel and evidence when resolver configured", %{
      conn: conn
    } do
      with_preview_evidence_resolver(fn ->
        conn = init_prod_session(conn)

        {:ok, _view, html} =
          live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=prod")

        assert html =~ "Change request required" || html =~ "Governance required"
        assert html =~ "Sample cohort"
        assert html =~ "last_24h"
        refute html =~ "impression-weighted"
        refute html =~ "fleet dashboard"
      end)
    end
  end

  test "edit confirm requires preview fingerprint in query", %{conn: conn} do
    conn = init_session(conn)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/confirm?env=test")

    assert html =~ "Run impact preview before confirming"
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
      rules: [%{key: "vip-rule", strategy: :segment_match, audience_key: "vip-users", conditions: []}]
    })
  end

  defp seed_prod_audience_flags! do
    alias Rulestead.Fake.Control

    Control.put_environment!(%{key: "prod", name: "Production"})
    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    for {flag_key, rule_key} <- [
          {"checkout", "vip-rule"},
          {"checkout-b", "vip-rule-b"},
          {"checkout-c", "vip-rule-c"}
        ] do
      Control.put_flag!(%{
        key: flag_key,
        description: "Checkout #{flag_key}",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "growth",
        permanent: true,
        expected_expiration: nil,
        environment_keys: ["prod"]
      })

      publish_ruleset!(flag_key, "prod", %{
        salt: "#{flag_key}:prod",
        rules: [%{key: rule_key, strategy: :segment_match, audience_key: "vip-users", conditions: []}]
      })
    end

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

  defp without_preview_evidence_resolver(fun) when is_function(fun, 0) do
    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)
    Application.delete_env(:rulestead, :preview_evidence_resolver)
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
      Rulestead.save_draft_ruleset!(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))

    Rulestead.publish_ruleset!(Command.PublishRuleset.new(flag_key, environment_key, version: version))
  end
end
