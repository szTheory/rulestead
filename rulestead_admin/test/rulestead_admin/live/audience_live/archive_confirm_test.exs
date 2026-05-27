defmodule RulesteadAdmin.Live.AudienceLive.ArchiveConfirmTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Control.reset!()
    seed_audience_flag!()
    :ok
  end

  test "archive confirm applies archive after preview fingerprint and reason", %{conn: conn} do
    conn = init_session(conn)

    {:ok, preview_view, preview_html} =
      live(conn, "/admin/flags/audiences/vip-users/archive/preview?env=test")

    assert preview_html =~ "audprev_"

    confirm_href =
      preview_html
      |> extract_confirm_href()
      |> String.replace("&amp;", "&")

    {:ok, confirm_view, _confirm_html} = live(conn, confirm_href)

    assert {:error, {:live_redirect, %{to: to}}} =
             confirm_view
             |> form("form[aria-label='Confirm audience archive']", %{"reason" => "retire vip"})
             |> render_submit()

    assert to =~ "/audiences/vip-users"

    {:ok, audiences} = Rulestead.list_audiences(include_archived?: true)
    audience = Enum.find(audiences, &(&1.key == "vip-users"))
    assert audience
    assert Map.get(audience, :archived_at)
  end

  defp seed_audience_flag! do
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

  defp init_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
      "rulestead_admin_last_env" => "test"
    })
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    %{version: version} =
      Rulestead.save_draft_ruleset!(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset))

    Rulestead.publish_ruleset!(Command.PublishRuleset.new(flag_key, environment_key, version: version))
  end

  defp extract_confirm_href(html) do
    Regex.run(~r/href="([^"]*\/archive\/confirm[^"]+)"/, html, capture: :all_but_first)
    |> List.first()
  end
end
