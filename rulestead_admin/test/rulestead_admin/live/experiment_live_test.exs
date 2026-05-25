# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.ExperimentLiveTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    Application.put_env(:rulestead, :store, Rulestead.Fake)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    seed_environment!("prod", "Production")

    seed_flag!(
      key: "checkout-experiment",
      owner: "growth",
      tags: ["checkout", "experiment"],
      flag_type: :experiment,
      permanent: true,
      default_value: %{value: "control"}
    )

    seed_flag!(
      key: "search-experiment",
      owner: "growth",
      tags: ["search"],
      flag_type: :experiment,
      permanent: true,
      default_value: %{value: "control"}
    )

    seed_flag!(
      key: "not-an-experiment",
      owner: "ops",
      tags: [],
      flag_type: :release,
      permanent: true,
      default_value: %{value: false}
    )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "Visits the experiment index and sees the list layout", %{conn: conn} do
    conn = get(conn, "/admin/flags/experiments?env=prod")
    html = html_response(conn, 200)

    assert html =~ "Experiment inventory"
    assert html =~ "checkout-experiment"
    assert html =~ "search-experiment"
    refute html =~ "not-an-experiment"
  end

  test "Visits a specific experiment show page and validates summary metrics are rendered", %{
    conn: conn
  } do
    # Fake analytics data for "checkout-experiment"
    Process.put({:mock_metrics, "checkout-experiment", "conversion"}, [
      %{variation: "control", exposures: 1000, conversions: 50},
      %{variation: "variant_a", exposures: 1000, conversions: 100}
    ])

    Process.put({:mock_metrics, "checkout-experiment", "error"}, [])

    conn = get(conn, "/admin/flags/experiments/checkout-experiment?env=prod")
    html = html_response(conn, 200)

    assert html =~ "checkout-experiment"
    assert html =~ "Experiment Results"
    assert html =~ "Variant:"
    assert html =~ "vs Control"

    # Check that stats are present
    assert html =~ "Lift"
    assert html =~ "P-Value"
    assert html =~ "Significant"
  end

  test "Simulates a guardrail failure and ensures the warning banner is visible", %{conn: conn} do
    Process.put({:mock_metrics, "search-experiment", "conversion"}, [])

    Process.put({:mock_metrics, "search-experiment", "error"}, [
      %{variation: "control", exposures: 1000, conversions: 10},
      # 61 total errors
      %{variation: "variant_a", exposures: 1000, conversions: 51}
    ])

    conn = get(conn, "/admin/flags/experiments/search-experiment?env=prod")
    html = html_response(conn, 200)

    assert html =~ "Guardrail Warning"
    assert html =~ "Elevated error rates detected"
    assert html =~ "61 errors"
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:description, "Flag #{attrs[:key]}")
      |> Map.put_new(:flag_type, :experiment)
      |> Map.put_new(:value_type, :string)
      |> Map.put_new(:default_value, %{value: "control"})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp seed_environment!(key, name) do
    assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
  end
end
