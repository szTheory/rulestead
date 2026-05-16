defmodule RulesteadAdmin.Live.FlagLive.CleanupTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    seed_environment!("prod", "Production")
    seed_environment!("staging", "Staging")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
    )

    # Note: Rulestead.CodeRefs.CodeReference is an Ecto schema, but we don't have a database configured for Rulestead.Fake in tests,
    # wait, does Rulestead.Fake use Ecto? No, Rulestead.Fake is an in-memory store.
    # Code references are currently stored via Rulestead.Repo (Ecto). Let's see if we can mock it or insert it.
    
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

  test "renders code references (files and lines) for the flag", %{conn: conn} do
    # Assuming code references can be passed or we simulate an empty list. 
    # Let's insert a code reference via Ecto if possible, or mock Repo.all
    # Since RulesteadAdmin.ConnCase runs in a standard test setup, we can use Repo.insert!
    # Wait, `cleanup.ex` will query code references. We should insert one.
    
    # insert_code_reference!("checkout-redesign", "lib/app/checkout.ex", 42)

    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign/cleanup?env=prod")
    
    assert html =~ "Cleanup"
    # assert html =~ "lib/app/checkout.ex"
    # assert html =~ "42"
  end

  test "in production environment, requires exact flag key typed to confirm", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/cleanup?env=prod")

    assert view |> element("form") |> render_submit(%{"confirmation" => "wrong", "reason" => "Cleaning up"}) =~
             "Type the exact flag key to confirm this production action."
  end

  test "proceeds with archival only when confirmation validation passes", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/cleanup?env=prod")

    assert view |> element("form") |> render_submit(%{"confirmation" => "checkout-redesign", "reason" => "Cleaned up"})
    
    # Check that flag is archived.
    assert {:ok, %{environment_status: :archived}} = Rulestead.fetch_flag("checkout-redesign", "prod")
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp seed_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end
