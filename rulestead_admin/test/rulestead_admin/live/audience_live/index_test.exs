defmodule RulesteadAdmin.Live.AudienceLive.IndexTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  defmodule DenyFlagReadsPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, :read_flags, _resource, _environment_key), do: false

    @impl true
    def can?(_actor, action, _resource, _environment_key)
        when action in [:list_audiences, :list_audience_dependencies, :read],
        do: true

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def change_request_required?(_, _, _, _), do: false

    @impl true
    def allow_self_approval?(_, _, _, _), do: true
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Rulestead.Fake.Control.reset!()
    :ok
  end

  test "renders audience list route", %{conn: conn} do
    conn = init_session(conn)
    {:ok, _view, html} = live(conn, "/admin/flags/audiences?env=test")

    assert html =~ "Audiences"
    assert html =~ "Reusable targeting"
    assert html =~ "Review reusable targeting before changing flags"
    assert html =~ "Dependency visibility can be partial"
  end

  test "audience list exposes route summary and row dependency actions", %{conn: conn} do
    alias Rulestead.Fake.Control

    conn = init_session(conn)
    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    {:ok, view, html} = live(conn, "/admin/flags/audiences?env=test")

    assert html =~ "1 reusable audience in this scope"
    assert html =~ "Review dependencies"
    assert has_element?(view, "section[aria-label='Audience route summary']")
    assert has_element?(view, "table[aria-label='Audience list']")

    assert has_element?(
             view,
             "a[href='/admin/flags/audiences/vip-users?env=test']",
             "Review dependencies"
           )
  end

  test "audience detail surfaces hidden reference copy when flag reads are denied", %{conn: conn} do
    alias Rulestead.Fake.Control

    conn = init_session(conn)
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

    previous = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_policy, DenyFlagReadsPolicy)

    on_exit(fn ->
      if previous do
        Application.put_env(:rulestead, :admin_policy, previous)
      else
        Application.delete_env(:rulestead, :admin_policy)
      end
    end)

    {:ok, _view, html} = live(conn, "/admin/flags/audiences/vip-users?env=test")

    assert html =~ "hidden by your permissions"
    assert html =~ "Hidden reference"
    assert html =~ "(policy denied)"
  end

  test "renders audience detail with visible used-by references", %{conn: conn} do
    alias Rulestead.Fake.Control

    conn = init_session(conn)
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

    {:ok, _view, html} = live(conn, "/admin/flags/audiences/vip-users?env=test")

    assert html =~ "Used by"
    assert html =~ "vip-users"
  end

  defp init_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "test", "name" => "Test"}],
      "rulestead_admin_last_env" => "test"
    })
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
