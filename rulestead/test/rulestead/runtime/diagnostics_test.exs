defmodule Rulestead.Runtime.DiagnosticsTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Runtime.{Cache, Snapshot}

  setup do
    environment_key = "diagnostics-#{System.unique_integer([:positive])}"
    snapshot = published_snapshot(environment_key)

    {:ok, compiled} = Snapshot.compile(snapshot)
    {:ok, _applied} = Cache.apply(compiled)

    on_exit(fn ->
      Cache.reset(environment_key)
    end)

    %{environment_key: environment_key}
  end

  test "keyed runtime APIs match the pure projection semantics when a snapshot exists", %{
    environment_key: environment_key
  } do
    context = Context.new(actor: %{key: "user-1"}, attributes: %{email: "hidden@example.com"})

    assert {:ok, result} = Runtime.evaluate(environment_key, "checkout-redesign", context)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", context)
    assert {:ok, true} = Runtime.get_value(environment_key, "checkout-redesign", context, false)
    assert {:ok, "on"} = Runtime.get_variant(environment_key, "checkout-redesign", context)
    assert result.variant == "on"
  end

  test "runtime diagnostics are bounded and exposed from both facades", %{environment_key: environment_key} do
    assert %{node: _, environments: environments} = Rulestead.diagnostics()
    assert %{node: _, environments: runtime_environments} = Runtime.diagnostics()

    assert environments == runtime_environments

    assert environment =
             Enum.find(runtime_environments, &(&1.environment_key == environment_key))

    assert environment.snapshot_version == 9
    assert environment.source == :ets
    assert environment.refresh_status == :ready
    assert environment.disk_backup_status == :disabled
    assert is_integer(environment.cache_age_ms)
  end

  test "runtime explain output composes evaluation facts with safe runtime metadata and omits raw context", %{
    environment_key: environment_key
  } do
    context = %{
      actor: %{key: "user-1", email: "hidden@example.com"},
      targeting_key: "raw-targeting-key",
      attributes: %{plan: "enterprise", request_ip: "127.0.0.1"}
    }

    assert {:ok, explanation} = Runtime.explain(environment_key, "checkout-redesign", context)

    assert explanation =~ "Matched rule variant-rollout."
    assert explanation =~ "Environment #{environment_key}"
    assert explanation =~ "snapshot v9"
    assert explanation =~ "source ets"
    refute explanation =~ "hidden@example.com"
    refute explanation =~ "raw-targeting-key"
    refute explanation =~ "127.0.0.1"
    refute explanation =~ "enterprise"
  end

  defp published_snapshot(environment_key) do
    payload = %{
      schema_version: 1,
      environment_key: environment_key,
      generated_at: ~U[2026-04-24 00:10:00Z],
      flags: %{
        "checkout-redesign" => %{
          flag: %{key: "checkout-redesign", default_value: %{value: false}},
          environment: %{key: environment_key},
          flag_environment: %{key: "checkout-redesign:#{environment_key}", status: :active},
          active_ruleset: %{
            version: 4,
            salt: "checkout:v4",
            rules: [
              %{
                key: "variant-rollout",
                strategy: :variant_split,
                rollout: %{bucket_by: :subject, percentage: 100, salt: "v4"},
                variants: [
                  %{key: "on", weight: 100, value: %{value: true}}
                ]
              }
            ]
          }
        }
      }
    }

    %{
      environment_key: environment_key,
      version: 9,
      payload: :erlang.term_to_binary(payload),
      payload_checksum: "checksum",
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: ~U[2026-04-24 00:10:30Z]
    }
  end
end
