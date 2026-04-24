defmodule Rulestead.TestHelpersTest do
  use ExUnit.Case, async: false

  import Rulestead.TestHelpers

  alias Rulestead.Fake.Control

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    Control.reset!()

    on_exit(fn ->
      Control.reset!()

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "with_flag/3 uses the macro syntax and restores fake state after the block" do
    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Rulestead.fetch_flag("checkout-redesign", "test")

    with_flag "checkout-redesign", true do
      assert {:ok, payload} = Rulestead.fetch_flag("checkout-redesign", "test")
      assert {:ok, true} = Rulestead.enabled?(payload, %{targeting_key: "actor-1"})
    end

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Rulestead.fetch_flag("checkout-redesign", "test")
  end

  test "put_flag/3 seeds fake-backed evaluation state and clear_flags/0 resets it" do
    assert %{flag: %{key: "beta-banner"}} = put_flag("beta-banner", false, environment: "test")

    assert {:ok, payload} = Rulestead.fetch_flag("beta-banner", "test")
    assert {:ok, false} = Rulestead.enabled?(payload, %{targeting_key: "actor-2"})

    assert :ok = clear_flags()

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Rulestead.fetch_flag("beta-banner", "test")
  end

  test "seed_bucket/3 pins a variant for a specific targeting key through the fake-backed contract" do
    assert %{flag: %{key: "checkout-color"}} = seed_bucket("checkout-color", "user-123", "blue")

    assert {:ok, payload} = Rulestead.fetch_flag("checkout-color", "test")
    assert {:ok, "blue"} = Rulestead.get_variant(payload, %{targeting_key: "user-123"})
    assert {:ok, nil} = Rulestead.get_variant(payload, %{targeting_key: "someone-else"})
  end

  test "assert_flag_evaluated/2 observes the eval telemetry stop event through the stable contract" do
    assert %{flag: %{key: "telemetry-flag"}} = put_flag("telemetry-flag", true)

    result =
      assert_flag_evaluated "telemetry-flag" do
        assert {:ok, payload} = Rulestead.fetch_flag("telemetry-flag", "test")
        Rulestead.enabled?(payload, %{targeting_key: "actor-3", attributes: %{plan: "pro"}})
      end

    assert {:ok, true} = result
  end
end

defmodule Rulestead.TestHelperHarnessTest do
  use ExUnit.Case, async: false

  test "test helper harness starts the fake store and uses it as the default adapter" do
    assert Process.whereis(Rulestead.Fake)
    assert Application.get_env(:rulestead, :store) == Rulestead.Fake
  end
end
