defmodule RulesteadTest do
  use ExUnit.Case, async: true

  alias Rulestead.Context

  test "the package root module loads" do
    assert Rulestead.version() == "0.1.0"
  end

  test "public evaluation helpers project from the canonical evaluator path" do
    payload = deterministic_payload()

    assert {:ok, true} = Rulestead.enabled?(payload, %{actor: %{key: "user-1"}})
    assert {:ok, true} = Rulestead.get_value(payload, Context.new(actor: %{key: "user-1"}), false)
    assert {:ok, "on"} = Rulestead.get_variant(payload, %{actor: %{key: "user-1"}})
    assert {:ok, explanation} = Rulestead.explain(payload, %{actor: %{key: "user-1"}})
    assert explanation =~ "Matched rule"
  end

  test "strict missing sticky identity propagates the typed error unchanged" do
    assert {:error, %Rulestead.Error{type: :missing_targeting_key}} =
             Rulestead.enabled?(sticky_payload(), %{strict?: true})
  end

  test "permissive missing sticky identity emits one sanitized telemetry warning event" do
    parent = self()
    handler_id = "rulestead-warning-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:rulestead, :eval, :warning],
      fn _event, measurements, metadata, _config ->
        send(parent, {:warning_event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, false} = Rulestead.enabled?(sticky_payload(), %{})
    assert_receive {:warning_event, %{count: 1}, %{flag_key: "checkout-redesign", reason: :missing_targeting_key}}
    refute_receive {:warning_event, _, _}
  end

  defp deterministic_payload do
    %{
      flag: %{
        key: "checkout-redesign",
        default_value: %{value: false}
      },
      environment: %{key: "test"},
      flag_environment: %{status: :active},
      active_ruleset: %{
        version: 1,
        salt: "checkout",
        rules: [
          %{
            key: "variant-rollout",
            strategy: :variant_split,
            rollout: %{bucket_by: :subject, percentage: 100, salt: "v1"},
            variants: [
              %{key: "on", weight: 100, value: %{value: true}}
            ]
          }
        ]
      }
    }
  end

  defp sticky_payload do
    %{
      flag: %{
        key: "checkout-redesign",
        default_value: %{value: false}
      },
      environment: %{key: "test"},
      flag_environment: %{status: :active},
      active_ruleset: %{
        version: 1,
        salt: "checkout",
        rules: [
          %{
            key: "sticky-rollout",
            strategy: :percentage_rollout,
            value: %{value: true},
            rollout: %{bucket_by: :subject, percentage: 100, salt: "v1"},
            conditions: []
          }
        ]
      }
    }
  end
end
