defmodule Rulestead.Promotion.CompareTest do
  use ExUnit.Case, async: false

  alias Rulestead.Promotion.Compare
  alias Rulestead.Store.Command

  defmodule CompareStoreStub do
    @behaviour Rulestead.Store

    def compare_environments(%Command.CompareEnvironments{} = command) do
      {:ok,
       %{
         source_environment: %{key: command.source_environment_key},
         target_environment: %{key: command.target_environment_key},
         compare_token: command.compare_token,
         requested_flag_keys: command.flag_keys,
         compare_schema_version: Compare.schema_version()
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

    defp missing, do: raise("unexpected store callback")
  end

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, CompareStoreStub)

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "compare command normalizes source target scope and token into one contract" do
    command =
      Command.CompareEnvironments.new(" staging ", :production,
        flag_keys: ["beta-banner", :checkout_redesign, "beta-banner", nil, " "],
        compare_token: " token-123 "
      )

    assert command.source_environment_key == "staging"
    assert command.target_environment_key == "production"
    assert command.flag_keys == ["beta-banner", "checkout_redesign"]
    assert command.compare_token == "token-123"
  end

  test "public facade delegates compare through the store command" do
    assert {:ok, payload} =
             Rulestead.compare_environments("staging", "production",
               flag_keys: [:checkout_redesign, "beta-banner"],
               compare_token: "preview-token"
             )

    assert payload.source_environment.key == "staging"
    assert payload.target_environment.key == "production"
    assert payload.requested_flag_keys == ["beta-banner", "checkout_redesign"]
    assert payload.compare_token == "preview-token"
    assert payload.compare_schema_version == Compare.schema_version()
  end

  test "compare tokens stay stable for the same scoped authored set and change with dependency churn" do
    source_fingerprint = Compare.fingerprint(%{flag_key: "checkout-redesign", version: 7})
    target_fingerprint = Compare.fingerprint(%{flag_key: "checkout-redesign", version: 4})

    attrs = %{
      source_environment_key: "staging",
      target_environment_key: "production",
      compared_flag_keys: ["checkout-redesign"],
      dependency_closure_keys: ["audience:vip-users"],
      source_fingerprint: source_fingerprint,
      target_fingerprint: target_fingerprint
    }

    token = Compare.compare_token(attrs)

    assert token ==
             Compare.compare_token(Map.merge(attrs, %{compared_flag_keys: ["checkout-redesign"]}))

    refute token ==
             Compare.compare_token(%{
               attrs
               | dependency_closure_keys: ["audience:vip-users", "audience:cart-abandoners"]
             })
  end

  test "compare payload exposes source target proposed state and non-authored warnings without implying apply" do
    payload =
      Compare.new_result(%{
        source_environment: %{key: "staging"},
        target_environment: %{key: "production"},
        requested_flag_keys: ["checkout-redesign"],
        compare_token: "cmp_123",
        findings: [
          Compare.finding(:warning, :unpublished_source_work, "source_has_drafts",
            message: "Source has unpublished draft rulesets"
          )
        ],
        flags: [
          %{
            flag_key: "checkout-redesign",
            changed_fields: ["ruleset", "owner"],
            dependency_closure_keys: ["audience:vip-users"],
            findings: [
              Compare.finding(:info, :drift_info, "target_owner_mismatch",
                message: "Target owner differs from source"
              )
            ],
            source_state: %{
              ownership: %{owner_ref: "growth", owner_kind: :team},
              active_ruleset_version: 7
            },
            current_target_state: %{
              ownership: %{owner_ref: "platform", owner_kind: :team},
              active_ruleset_version: 4
            },
            proposed_target_state: %{
              ownership: %{owner_ref: "growth", owner_kind: :team},
              active_ruleset_version: 7
            }
          }
        ]
      })

    assert payload.compare_schema_version == Compare.schema_version()
    assert payload.overall_status == :warning
    assert payload.findings |> Enum.map(& &1.class) == [:unpublished_source_work]
    assert hd(payload.flags).source_state.active_ruleset_version == 7
    assert hd(payload.flags).current_target_state.active_ruleset_version == 4
    assert hd(payload.flags).proposed_target_state.active_ruleset_version == 7
  end
end
