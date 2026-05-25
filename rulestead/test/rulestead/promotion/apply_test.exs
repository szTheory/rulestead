# credo:disable-for-this-file
defmodule Rulestead.Promotion.ApplyTest do
  use ExUnit.Case, async: false

  alias Rulestead.{
    Error,
    Promotion.Compare,
    Store.Command
  }

  defmodule PromotionStoreStub do
    @behaviour Rulestead.Store

    alias Rulestead.Promotion.Compare
    alias Rulestead.Store.Command

    def compare_environments(%Command.CompareEnvironments{} = command) do
      payload =
        case command.compare_token do
          "cmp_stale" ->
            compare_payload(command.compare_token || "cmp_fresh",
              tenant_key: command.tenant_key,
              findings: [
                Compare.finding(:blocker, :staleness_conflict, "compare_token_stale")
              ]
            )

          "cmp_blocked" ->
            compare_payload(command.compare_token || "cmp_blocked",
              tenant_key: command.tenant_key,
              findings: [
                Compare.finding(:blocker, :missing_dependency, "dependency_missing")
              ]
            )

          "cmp_dependency_drift" ->
            compare_payload(command.compare_token || "cmp_dependency_drift",
              tenant_key: command.tenant_key,
              dependency_closure_keys: ["audience:vip-users", "audience:new-users"]
            )

          _other ->
            compare_payload(command.compare_token || "cmp_ok",
              tenant_key: command.tenant_key
            )
        end

      {:ok, payload}
    end

    def apply_promotion(%Command.ApplyPromotion{} = command) do
      send(self(), {:apply_promotion_called, command})

      {:ok,
       %{
         compare_token: command.compare_token,
         compare_schema_version: command.compare_schema_version,
         applied_flag_keys: command.flag_keys,
         dependency_closure_keys: command.dependency_closure_keys
       }}
    end

    def fetch_flag(_), do: missing()
    def fetch_snapshot(_), do: missing()
    def create_flag(_), do: missing()
    def update_flag(_), do: missing()
    def save_draft_ruleset(_), do: missing()
    def publish_ruleset(_), do: missing()
    def archive_flag(_), do: missing()
    def list_flags(_), do: missing()
    def list_environments(_), do: missing()
    def list_audiences(_), do: missing()
    def record_evaluation(_), do: missing()
    def engage_kill_switch(_), do: missing()
    def release_kill_switch(_), do: missing()
    def list_audit_events(_), do: missing()
    def rollback_audit_event(_), do: missing()
    def submit_change_request(_), do: missing()
    def approve_change_request(_), do: missing()
    def reject_change_request(_), do: missing()
    def cancel_change_request(_), do: missing()
    def execute_change_request(_), do: missing()
    def fetch_change_request(_), do: missing()
    def list_change_requests(_), do: missing()
    def schedule_change_request(_), do: missing()
    def schedule_governed_action(_), do: missing()
    def cancel_scheduled_execution(_), do: missing()
    def requeue_scheduled_execution(_), do: missing()
    def execute_scheduled_execution(_), do: missing()
    def fetch_scheduled_execution(_), do: missing()
    def list_scheduled_executions(_), do: missing()
    def receive_inbound_webhook(_), do: missing()
    def fetch_webhook_record(_), do: missing()
    def list_webhook_records(_), do: missing()
    def create_webhook_destination(_), do: missing()
    def update_webhook_destination(_), do: missing()
    def fetch_webhook_destination(_), do: missing()
    def list_webhook_destinations(_), do: missing()
    def list_webhook_deliveries(_), do: missing()
    def retry_webhook_delivery(_), do: missing()
    def preview_manifest_import(_), do: missing()
    def apply_manifest_import(_), do: missing()

    defp compare_payload(compare_token, overrides) do
      overrides = Map.new(overrides)

      %{
        source_environment: %{key: "staging"},
        target_environment: %{key: "qa"},
        compare_token: compare_token,
        compare_schema_version: Compare.schema_version(),
        requested_flag_keys: ["checkout-redesign", "vip-checkout"],
        source_fingerprint: "sha256:source",
        target_fingerprint: "sha256:target",
        dependency_closure_keys: ["audience:vip-users"],
        findings: Map.get(overrides, :findings, []),
        flags: [
          %{
            flag_key: "checkout-redesign",
            findings: [],
            source_state: %{flag: %{key: "checkout-redesign"}},
            current_target_state: %{flag: %{key: "checkout-redesign"}},
            proposed_target_state: %{
              flag: %{key: "checkout-redesign"},
              flag_environment: %{environment_key: "qa"},
              active_ruleset: %{version: 7}
            }
          },
          %{
            flag_key: "vip-checkout",
            findings: [],
            source_state: %{flag: %{key: "vip-checkout"}},
            current_target_state: %{flag: %{key: "vip-checkout"}},
            proposed_target_state: %{
              flag: %{key: "vip-checkout"},
              flag_environment: %{environment_key: "qa"},
              active_ruleset: %{version: 3}
            }
          }
        ]
      }
      |> Map.merge(overrides)
    end

    defp missing, do: raise("unexpected store callback")
  end

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, PromotionStoreStub)

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "promotion command normalizes the direct-apply bundle into one deterministic contract" do
    command =
      Command.ApplyPromotion.new(
        %{
          source_environment_key: " staging ",
          target_environment_key: :qa,
          flag_keys: ["vip-checkout", :checkout_redesign, "vip-checkout", nil, " "],
          compare_token: " cmp_live ",
          compare_schema_version: Compare.schema_version(),
          source_fingerprint: "sha256:source",
          target_fingerprint: "sha256:target",
          dependency_closure_keys: ["audience:vip-users", "audience:vip-users", " "],
          proposed_target_bundle: %{
            "vip-checkout" => %{"active_ruleset" => %{"version" => 3}},
            "checkout-redesign" => %{"active_ruleset" => %{"version" => 7}}
          }
        },
        actor: %{id: " operator-1 ", type: :user, display: " Release Operator "},
        reason: " Ship it ",
        metadata: %{socket: "discard", note: "kept"}
      )

    assert command.source_environment_key == "staging"
    assert command.target_environment_key == "qa"
    assert command.flag_keys == ["checkout_redesign", "vip-checkout"]
    assert command.compare_token == "cmp_live"
    assert command.compare_schema_version == Compare.schema_version()
    assert command.dependency_closure_keys == ["audience:vip-users"]
    assert Map.keys(command.proposed_target_bundle) == ["checkout-redesign", "vip-checkout"]

    assert command.actor == %{
             "display" => "Release Operator",
             "id" => "operator-1",
             "type" => "user"
           }

    assert command.reason == "Ship it"
    assert command.metadata == %{"note" => "kept"}
  end

  test "apply rejects saved plan when live scope diverges" do
    plan = %{
      "schema_version" => Rulestead.Manifest.Plan.schema_version(),
      "kind" => "rulestead_apply_plan",
      "mode" => "promote",
      "target_environment_key" => "qa",
      "source_environment_key" => "staging",
      "plan_token" => "plan_123",
      "compare_token" => "cmp_ok",
      "source_fingerprint" => "sha256:source",
      "target_fingerprint" => "sha256:target",
      "dependency_closure_keys" => ["audience:vip-users"],
      "flag_keys" => ["checkout-redesign"],
      "tenant_key" => "acme",
      "proposed_target_bundle" => %{
        "checkout-redesign" => %{"active_ruleset" => %{"version" => 1}}
      }
    }

    assert {:ok, result} =
             Rulestead.apply_promotion_plan(plan, reason: "drifting tenant", tenant_key: "other")

    assert result["status"] == "stale"
    assert Enum.any?(result["findings"], &(&1["message"] =~ "tenant drifted"))
  end

  test "apply delegates through compare revalidation before store mutation" do
    command = valid_command()

    assert {:ok, result} = Rulestead.apply_promotion(command)
    assert result.compare_token == "cmp_ok"
    assert result.compare_schema_version == Compare.schema_version()
    assert result.applied_flag_keys == ["checkout-redesign", "vip-checkout"]
    assert result.dependency_closure_keys == ["audience:vip-users"]

    assert_receive {:apply_promotion_called, %Command.ApplyPromotion{} = applied_command}
    assert applied_command.flag_keys == ["checkout-redesign", "vip-checkout"]
  end

  test "saved promote apply preserves reviewed tenant scope on the replay command" do
    assert {:ok, planned} =
             Rulestead.plan_promotion("staging", "qa",
               flag_keys: ["checkout-redesign"],
               tenant_key: "acme"
             )

    plan = planned["details"]["plan"]

    assert {:ok, result} =
             Rulestead.apply_promotion_plan(plan,
               reason: "ship tenant-scoped change",
               tenant_key: "acme"
             )

    assert result["status"] == "applied"

    assert_receive {:apply_promotion_called, %Command.ApplyPromotion{} = applied_command}
    assert applied_command.tenant_key == "acme"
  end

  test "apply fails before mutation when the compare preview is stale blocker-bearing or dependency-divergent" do
    assert {:error, %Error{type: :invalid_command, message: "promotion compare preview is stale"}} =
             Rulestead.apply_promotion(valid_command(compare_token: "cmp_stale"))

    refute_receive {:apply_promotion_called, _}

    assert {:error,
            %Error{
              type: :invalid_command,
              message: "promotion compare preview has blocker findings"
            }} =
             Rulestead.apply_promotion(valid_command(compare_token: "cmp_blocked"))

    refute_receive {:apply_promotion_called, _}

    assert {:error,
            %Error{
              type: :invalid_command,
              message: "promotion compare dependency closure drifted"
            }} =
             Rulestead.apply_promotion(valid_command(compare_token: "cmp_dependency_drift"))

    refute_receive {:apply_promotion_called, _}
  end

  defp valid_command(overrides \\ []) do
    attrs =
      %{
        source_environment_key: "staging",
        target_environment_key: "qa",
        flag_keys: ["checkout-redesign", "vip-checkout"],
        compare_token: "cmp_ok",
        compare_schema_version: Compare.schema_version(),
        source_fingerprint: "sha256:source",
        target_fingerprint: "sha256:target",
        dependency_closure_keys: ["audience:vip-users"],
        proposed_target_bundle: %{
          "checkout-redesign" => %{
            "flag" => %{"key" => "checkout-redesign"},
            "flag_environment" => %{"environment_key" => "qa"},
            "active_ruleset" => %{"version" => 7}
          },
          "vip-checkout" => %{
            "flag" => %{"key" => "vip-checkout"},
            "flag_environment" => %{"environment_key" => "qa"},
            "active_ruleset" => %{"version" => 3}
          }
        }
      }
      |> Map.merge(Map.new(overrides))

    Command.ApplyPromotion.new(attrs)
  end
end
