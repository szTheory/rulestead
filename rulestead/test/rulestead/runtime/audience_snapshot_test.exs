# credo:disable-for-this-file
defmodule Rulestead.Runtime.AudienceSnapshotTest do
  use ExUnit.Case, async: true

  alias Rulestead.Runtime.Snapshot

  @published_at ~U[2026-05-27 09:00:00Z]
  @generated_at ~U[2026-05-27 09:00:01Z]

  describe "compiled audience snapshots" do
    test "compile carries snapshot-local audiences and stable audience_keys" do
      assert {:ok, snapshot} =
               Snapshot.compile(
                 runtime_snapshot(%{
                   flags: %{
                     "checkout-redesign" => %{
                       flag: %{key: "checkout-redesign", default_value: %{value: false}},
                       environment: %{key: "production"},
                       active_ruleset: %{version: 1, rules: []}
                     }
                   },
                   audiences: %{
                     "vip-users" => %{
                       definition: %{
                         clauses: [
                           %{
                             attribute: "attributes.plan",
                             op: "eq",
                             value: "vip"
                           }
                         ]
                       },
                       archived_at: nil
                     }
                   }
                 })
               )

      assert snapshot.audience_keys == ["vip-users"]

      assert snapshot.audiences["vip-users"] == %{
               audience_key: "vip-users",
               definition: %{
                 clauses: [
                   %{attribute: "attributes.plan", op: "eq", value: "vip"}
                 ]
               },
               archived_at: nil
             }

      assert snapshot.flags["checkout-redesign"].flag_payload.audiences == snapshot.audiences
    end

    test "compile rejects malformed audience definitions through runtime data errors" do
      assert {:error, %Rulestead.Error{type: :malformed_runtime_data}} =
               Snapshot.compile(
                 runtime_snapshot(%{
                   audiences: %{
                     "vip-users" => %{definition: "not a definition", archived_at: nil}
                   }
                 })
               )
    end

    test "compile keeps old payloads without audiences backward compatible" do
      assert {:ok, snapshot} = Snapshot.compile(runtime_snapshot(%{}))

      assert snapshot.audiences == %{}
      assert snapshot.audience_keys == []
    end
  end

  describe "snapshot-local segment_match evaluation" do
    test "segment_match resolves a matching audience from compiled snapshot data" do
      assert {:ok, result} =
               Rulestead.Evaluator.evaluate(segment_payload(), %{attributes: %{plan: "vip"}})

      assert result.value == true
      assert result.matched_rule == "vip-audience"

      assert %{audience_key: "vip-users", matched?: true, reason: :matched} =
               result.debug_trace.matched_rule_trace.audience_trace
    end

    test "segment_match skips when the compiled audience definition misses" do
      assert {:ok, result} =
               Rulestead.Evaluator.evaluate(segment_payload(), %{attributes: %{plan: "starter"}})

      assert result.reason == :default

      assert %{audience_key: "vip-users", matched?: false, reason: :missed} =
               first_rule_trace(result).audience_trace
    end

    test "segment_match evaluates store-shaped audience conditions from compiled snapshots" do
      assert {:ok, snapshot} =
               Snapshot.compile(
                 runtime_snapshot(%{
                   flags: %{
                     "checkout-redesign" => segment_payload()
                   },
                   audiences: %{
                     "vip-users" => %{
                       definition: %{
                         conditions: [
                           %{attribute: "plan", operator: "eq", value: "vip"}
                         ]
                       },
                       archived_at: nil
                     }
                   }
                 })
               )

      payload = snapshot.flags["checkout-redesign"].flag_payload

      assert {:ok, matched} = Rulestead.Evaluator.evaluate(payload, %{attributes: %{plan: "vip"}})
      assert matched.reason == :rule_match

      assert {:ok, missed} =
               Rulestead.Evaluator.evaluate(payload, %{attributes: %{plan: "starter"}})

      assert missed.reason == :default

      assert %{audience_key: "vip-users", matched?: false, reason: :missed} =
               first_rule_trace(missed).audience_trace
    end

    test "segment_match skips and warns when the compiled audience is missing" do
      payload = put_in(segment_payload(), [:audiences], %{})

      assert {:ok, result} =
               Rulestead.Evaluator.evaluate(payload, %{attributes: %{plan: "vip"}})

      assert result.reason == :default

      assert first_rule_trace(result).warnings == [
               %{type: :audience_missing, audience_key: "vip-users"}
             ]

      assert %{audience_key: "vip-users", matched?: false, reason: :missing} =
               first_rule_trace(result).audience_trace
    end

    test "segment_match skips and warns when the compiled audience is archived" do
      payload = put_in(segment_payload(), [:audiences, "vip-users", :archived_at], @published_at)

      assert {:ok, result} =
               Rulestead.Evaluator.evaluate(payload, %{attributes: %{plan: "vip"}})

      assert result.reason == :default

      assert first_rule_trace(result).warnings == [
               %{type: :audience_archived, audience_key: "vip-users"}
             ]

      assert %{audience_key: "vip-users", matched?: false, reason: :archived} =
               first_rule_trace(result).audience_trace
    end

    test "segment_match runtime evaluation does not call live lookup dependencies" do
      evaluator_source = File.read!("lib/rulestead/evaluator.ex")

      refute evaluator_source =~ ~r/Rulestead\.(Store|Repo|Admin|Audit|Observability)/
      refute evaluator_source =~ ~r/:telemetry|Telemetry/
    end
  end

  defp runtime_snapshot(payload_overrides) do
    payload =
      %{
        schema_version: 1,
        environment_key: "production",
        generated_at: @generated_at,
        flags: %{}
      }
      |> Map.merge(payload_overrides)

    %{
      environment_key: "production",
      version: 1,
      published_at: @published_at,
      payload: :erlang.term_to_binary(payload),
      metadata: %{}
    }
  end

  defp segment_payload do
    %{
      flag: %{key: "checkout-redesign", default_value: %{value: false}},
      environment: %{key: "production"},
      audiences: %{
        "vip-users" => %{
          audience_key: "vip-users",
          definition: %{
            clauses: [
              %{attribute: "plan", op: "eq", value: "vip"}
            ]
          },
          archived_at: nil
        }
      },
      active_ruleset: %{
        version: 1,
        salt: "checkout:v1",
        rules: [
          %{
            key: "vip-audience",
            strategy: :segment_match,
            audience_key: "vip-users",
            value: %{value: true},
            conditions: []
          }
        ]
      }
    }
  end

  defp first_rule_trace(result), do: List.first(result.debug_trace.rule_traces)
end
