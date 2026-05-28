defmodule RulesteadAdmin.Live.AudienceLive.EditConfirmGovernanceTest do
  use RulesteadAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Rulestead.Fake.Control
  alias Rulestead.Store.Command

  defmodule GovernanceTestPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule DenyFlagReadsPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, :read_flags, _resource, _environment_key), do: false

    @impl true
    def can?(_actor, action, _resource, _environment_key)
        when action in [
               :list_audiences,
               :list_audience_dependencies,
               :read,
               :submit_change_request
             ],
        do: true

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup do
    Control.reset!()
    seed_prod_audience_flags!()
    previous = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_policy, GovernanceTestPolicy)

    on_exit(fn ->
      if previous do
        Application.put_env(:rulestead, :admin_policy, previous)
      else
        Application.delete_env(:rulestead, :admin_policy)
      end
    end)

    :ok
  end

  test "prod above-threshold confirm hides Apply and shows Submit change request", %{conn: conn} do
    conn = init_prod_session(conn)
    confirm_href = confirm_href_from_preview(conn)

    {:ok, _view, html} = live(conn, confirm_href)

    refute html =~ "Apply update"
    assert html =~ "Submit change request"
    assert html =~ "Required approvals"
    assert html =~ "You may approve your own request"
  end

  test "submit change request redirects to CR show with unchanged flash", %{conn: conn} do
    conn = init_prod_session(conn)
    confirm_href = confirm_href_from_preview(conn)

    {:ok, confirm_view, _html} = live(conn, confirm_href)

    assert {:ok, _cr_view, html} =
             confirm_view
             |> form("form[aria-label='Submit audience update change request']", %{
               "reason" => "Governed audience update"
             })
             |> render_submit()
             |> follow_redirect(conn)

    assert html =~ "/change-requests/"
    assert html =~ "Change request review"
    assert html =~ "Status: Submitted"
    assert html =~ "Apply audience mutation"
  end

  test "partial visibility blocks submit and apply", %{conn: conn} do
    previous = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_policy, DenyFlagReadsPolicy)

    on_exit(fn ->
      if previous do
        Application.put_env(:rulestead, :admin_policy, previous)
      else
        Application.delete_env(:rulestead, :admin_policy)
      end
    end)

    conn = init_prod_session(conn)
    confirm_href = prod_confirm_href()

    {:ok, _view, html} = live(conn, confirm_href)

    refute html =~ "Apply update"
    refute html =~ "Submit change request"
    assert html =~ "Cannot evaluate safely"
    assert html =~ "hidden by your permissions"
  end

  defp confirm_href_from_preview(conn) do
    {:ok, _preview_view, preview_html} =
      live(conn, "/admin/flags/audiences/vip-users/edit/preview?env=prod")

    case extract_confirm_href(preview_html) do
      nil -> prod_confirm_href()
      href -> String.replace(href, "&amp;", "&")
    end
  end

  defp prod_confirm_href do
    {:ok, audiences} = Rulestead.list_audiences(include_archived?: true)
    audience = Enum.find(audiences, &(&1.key == "vip-users"))

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "prod",
        after_definition: audience.definition,
        reason: "Governed confirm test"
      )

    "/admin/flags/audiences/vip-users/edit/confirm?env=prod&preview_fingerprint=#{preview.preview_fingerprint}&preview_schema_version=#{preview.preview_schema_version}"
  end

  defp extract_confirm_href(html) do
    Regex.run(~r/href="([^"]*\/edit\/confirm[^"]+)"/, html, capture: :all_but_first)
    |> case do
      [href | _] -> href
      _ -> nil
    end
  end

  defp seed_prod_audience_flags! do
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
        rules: [
          %{key: rule_key, strategy: :segment_match, audience_key: "vip-users", conditions: []}
        ]
      })
    end

    Control.rebuild_audience_reference_projection!()
  end

  defp init_prod_session(conn) do
    Phoenix.ConnTest.init_test_session(conn, %{
      "current_actor" => %{id: 1, email: "ops@example.com"},
      "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}],
      "rulestead_admin_last_env" => "prod"
    })
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    %{version: version} =
      Rulestead.save_draft_ruleset!(
        Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
      )

    Rulestead.publish_ruleset!(
      Command.PublishRuleset.new(flag_key, environment_key, version: version)
    )
  end
end
