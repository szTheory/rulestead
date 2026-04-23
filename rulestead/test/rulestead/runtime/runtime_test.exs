defmodule Rulestead.RuntimeTest do
  use ExUnit.Case, async: true

  alias Rulestead.{Context, Result, Runtime}
  alias Rulestead.Runtime.{Cache, Snapshot}

  setup do
    environment_key = "test-#{System.unique_integer([:positive])}"

    on_exit(fn ->
      Cache.reset(environment_key)
    end)

    %{environment_key: environment_key}
  end

  test "a published environment snapshot compiles into runtime entries keyed by flag_key", %{
    environment_key: environment_key
  } do
    snapshot = published_snapshot(environment_key)

    assert {:ok, compiled} = Snapshot.compile(snapshot)
    assert compiled.environment_key == environment_key
    assert compiled.version == 7
    assert compiled.flag_keys == ["checkout-redesign"]

    assert {:ok, applied} = Cache.apply(compiled)
    assert applied.applied?

    assert {:ok, cached_flag} = Cache.lookup(environment_key, "checkout-redesign")
    assert cached_flag.flag_key == "checkout-redesign"
    assert cached_flag.flag_payload[:flag][:key] == "checkout-redesign"
  end

  test "runtime evaluation reads from ETS and projects cache_age_ms without mutating evaluator internals", %{
    environment_key: environment_key
  } do
    snapshot = published_snapshot(environment_key)
    {:ok, compiled} = Snapshot.compile(snapshot)
    {:ok, _applied} = Cache.apply(compiled)

    assert {:ok, %Result{} = result} =
             Runtime.evaluate(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert result.enabled? == true
    assert result.flag_key == "checkout-redesign"
    assert result.flag_version == 3
    assert is_integer(result.cache_age_ms)
    assert result.cache_age_ms >= 0
    assert result.debug_trace[:matched_rule] == "beta-rollout"
  end

  test "cache misses are explicit and runtime lookup never falls back to store reads" do
    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Runtime.evaluate("missing-env", "missing-flag", %{})

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Cache.lookup("missing-env", "missing-flag")
  end

  defp published_snapshot(environment_key) do
    payload = %{
      schema_version: 1,
      environment_key: environment_key,
      generated_at: ~U[2026-04-23 23:59:30Z],
      flags: %{
        "checkout-redesign" => %{
          flag: %{key: "checkout-redesign", default_value: %{value: false}},
          environment: %{key: environment_key},
          flag_environment: %{key: "checkout-redesign:#{environment_key}", status: :active},
          active_ruleset: %{
            version: 3,
            salt: "checkout:v3",
            rules: [
              %{
                key: "beta-rollout",
                strategy: :forced_value,
                value: %{value: true},
                conditions: [%{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}]
              }
            ]
          }
        }
      }
    }

    %{
      environment_key: environment_key,
      version: 7,
      payload: :erlang.term_to_binary(payload),
      payload_checksum: "checksum",
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: ~U[2026-04-24 00:00:00Z]
    }
  end
end
