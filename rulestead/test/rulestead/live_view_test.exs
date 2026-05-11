unless Code.ensure_loaded?(Phoenix.LiveView.Socket) do
  defmodule Phoenix.LiveView.Socket do
    defstruct assigns: %{}, private: %{}
  end
end

defmodule Rulestead.LiveViewTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, LiveView}
  alias Rulestead.Runtime.{Cache, Snapshot}

  setup do
    environment_key = "live-view-#{System.unique_integer([:positive])}"

    on_exit(fn ->
      Cache.reset(environment_key)
    end)

    %{environment_key: environment_key}
  end

  test "context_from_socket/2 normalizes configured assigns and session input", %{
    environment_key: environment_key
  } do
    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        current_actor: %{id: " actor-2 "},
        current_environment: " #{environment_key} ",
        tenant_key: " tenant-2 ",
        request_id: " req-789 ",
        rulestead_attributes: %{"role" => "beta"}
      }
    }

    context =
      LiveView.context_from_socket(
        socket,
        actor: {:assign, :current_actor},
        environment: {:assign, :current_environment},
        tenant_key: {:assign, :tenant_key},
        request_id: {:assign, :request_id},
        session_id: {:session, "session_id"},
        attributes: {:assign, :rulestead_attributes},
        session: %{"targeting_key" => " user-2 ", "session_id" => " socket-session "},
        targeting_key_sources: [{:session, "targeting_key"}, {:assign, :fallback_targeting_key}]
      )

    assert %Context{} = context
    assert context.actor == %{id: " actor-2 "}
    assert context.targeting_key == "user-2"
    assert context.environment == environment_key
    assert context.tenant_key == "tenant-2"
    assert context.request_id == "req-789"
    assert context.session_id == "socket-session"
    assert context.attributes == %{"role" => "beta"}
  end

  test "assign_flags/3 resolves multiple runtime-backed projections into socket assigns", %{
    environment_key: environment_key
  } do
    seed_runtime_snapshot(environment_key)

    socket = %Phoenix.LiveView.Socket{
      assigns: %{
        rulestead_context:
          Context.new(
            actor: %{key: "user-1"},
            targeting_key: "user-1",
            environment: environment_key,
            request_id: "req-100"
          )
      }
    }

    updated_socket =
      LiveView.assign_flags(socket, %{
        checkout_enabled: "checkout-redesign",
        checkout_variant: {:variant, "checkout-redesign"},
        checkout_value: {:value, "checkout-redesign", false},
        paywall_result: {:evaluate, "paywall-copy"}
      })

    assert updated_socket.assigns.checkout_enabled == true
    assert updated_socket.assigns.checkout_variant == nil
    assert updated_socket.assigns.checkout_value == true
    assert updated_socket.assigns.paywall_result.flag_key == "paywall-copy"
    assert updated_socket.assigns.paywall_result.value == "new-copy"
    assert updated_socket.assigns.rulestead_context.environment == environment_key
  end

  defp seed_runtime_snapshot(environment_key) do
    snapshot = %{
      environment_key: environment_key,
      version: 3,
      payload:
        :erlang.term_to_binary(%{
          schema_version: 1,
          environment_key: environment_key,
          generated_at: ~U[2026-04-24 00:00:00Z],
          flags: %{
            "checkout-redesign" => %{
              flag: %{
                key: "checkout-redesign",
                default_value: %{value: false},
                flag_type: :release
              },
              environment: %{key: environment_key},
              flag_environment: %{key: "checkout-redesign:#{environment_key}", status: :active},
              active_ruleset: %{
                version: 2,
                salt: "checkout:v2",
                rules: [
                  %{
                    key: "rollout",
                    strategy: :forced_value,
                    value: %{value: true},
                    conditions: [
                      %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
                    ]
                  }
                ]
              }
            },
            "paywall-copy" => %{
              flag: %{
                key: "paywall-copy",
                default_value: %{value: "old-copy"},
                flag_type: :experiment
              },
              environment: %{key: environment_key},
              flag_environment: %{key: "paywall-copy:#{environment_key}", status: :active},
              active_ruleset: %{
                version: 1,
                salt: "paywall:v1",
                rules: [
                  %{
                    key: "copy",
                    strategy: :forced_value,
                    value: %{value: "new-copy"},
                    conditions: [
                      %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
                    ]
                  }
                ]
              }
            }
          }
        }),
      payload_checksum: "checksum",
      metadata: %{schema_version: 1, flag_count: 2},
      published_at: ~U[2026-04-24 00:00:01Z]
    }

    {:ok, compiled} = Snapshot.compile(snapshot)
    {:ok, _applied} = Cache.apply(compiled)
  end
end
