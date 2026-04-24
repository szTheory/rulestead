defmodule Rulestead.Integration.AdminLifecycleRuntimeTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.StoreFixtures

  setup do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Rulestead.Fake.Control.reset!()
    :ok
  end

  test "telemetry-driven stale tracking records freshness asynchronously and archived flags stay out of runtime evaluation" do
    now = ~U[2026-04-23 16:00:00Z]
    Rulestead.Fake.Control.set_now!(now)

    assert {:ok, _} =
             Rulestead.create_flag(%{
               key: "checkout-redesign",
               description: "Checkout rollout",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               owner: "growth",
               permanent: false,
               expected_expiration: ~D[2026-05-01],
               environment_keys: ["test"],
               tags: ["checkout"]
             })

    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: "checkout-redesign:v1",
        rules: [
          %{
            key: "force-enabled",
            name: "Force enabled",
            strategy: :forced_value,
            value: %{value: true},
            conditions: [
              %{
                attribute: "actor.key",
                operator: :equals,
                value: %{equals: "user-1"}
              }
            ]
          }
        ]
      })

    assert {:ok, _} = Rulestead.save_draft_ruleset(StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset))
    assert {:ok, _} = Rulestead.publish_ruleset(StoreFixtures.publish_ruleset_command("checkout-redesign", "test"))

    stale_detail = Rulestead.fetch_flag!("checkout-redesign", "test")
    assert stale_detail.lifecycle.state == :potentially_stale

    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert_eventually(fn ->
      refreshed_detail = Rulestead.fetch_flag!("checkout-redesign", "test")
      refreshed_detail.lifecycle.state == :active and
        not is_nil(refreshed_detail.lifecycle.last_evaluated_at)
    end)

    assert {:ok, archived} = Rulestead.archive_flag(StoreFixtures.archive_flag_command("checkout-redesign"))
    assert archived.archived?

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
  end

  defp assert_eventually(fun, attempts \\ 20)

  defp assert_eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      assert true
    else
      Process.sleep(25)
      assert_eventually(fun, attempts - 1)
    end
  end

  defp assert_eventually(_fun, 0), do: flunk("condition did not become true")
end
