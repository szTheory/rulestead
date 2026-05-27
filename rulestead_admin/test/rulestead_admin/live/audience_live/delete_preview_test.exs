defmodule RulesteadAdmin.Live.AudienceLive.DeletePreviewTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Rulestead.Fake.Control.reset!()
    Rulestead.Fake.Control.put_audience!(%{key: "vip-users", description: "VIP"})
    :ok
  end

  describe "preview evidence" do
    setup %{conn: conn} do
      conn =
        Phoenix.ConnTest.init_test_session(conn, %{
          "current_actor" => %{id: 1, email: "ops@example.com"},
          "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
          "rulestead_admin_last_env" => "test"
        })

      with_preview_evidence_resolver(fn -> :ok end)
      %{conn: conn}
    end

    test "shows impact evidence and unsupported delete callout when resolver configured", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live(conn, "/admin/flags/audiences/vip-users/delete/preview?env=test")

      assert html =~ "Audience delete is not available in mounted admin"
      refute html =~ "Apply delete"
      assert html =~ "Sample cohort"
      assert html =~ "last_24h"
      assert html =~ "Impact preview"
    end
  end

  test "delete preview omits sample cohort without resolver configured", %{conn: conn} do
    conn =
      Phoenix.ConnTest.init_test_session(conn, %{
        "current_actor" => %{id: 1, email: "ops@example.com"},
        "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
        "rulestead_admin_last_env" => "test"
      })

    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)
    Application.delete_env(:rulestead, :preview_evidence_resolver)
    on_exit(fn -> restore_preview_evidence_resolver(previous_resolver) end)

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/delete/preview?env=test")

    assert html =~ "Impact preview"
    refute html =~ "Sample cohort"
  end

  test "delete preview is fail-closed with no apply submit", %{conn: conn} do
    conn =
      Phoenix.ConnTest.init_test_session(conn, %{
        "current_actor" => %{id: 1, email: "ops@example.com"},
        "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
        "rulestead_admin_last_env" => "test"
      })

    {:ok, _view, html} =
      live(conn, "/admin/flags/audiences/vip-users/delete/preview?env=test")

    assert html =~ "Delete preview"
    assert html =~ "Audience delete is not available in mounted admin"
    assert html =~ "Back to audience"
    refute html =~ "Apply delete"
    refute html =~ ~r/type="submit"/
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
end
