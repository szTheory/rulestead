defmodule Rulestead.Webhooks.InboundThreatModelTest do
  use Rulestead.RepoCase, async: false

  setup do
    Rulestead.Fake.reset()
    :ok
  end

  alias Rulestead.Webhooks.InboundEvent
  alias Rulestead.Store.Command

  test "rejected inbound intent emits telemetry and persists receipt" do
    # 1. Setup a test handler to capture telemetry
    parent = self()
    handler_id = "test-webhook-telemetry-#{Ecto.UUID.generate()}"
    :telemetry.attach(handler_id, [:rulestead, :ops, :webhook, :rejected], fn name, measurements, metadata, _config ->
      send(parent, {:telemetry_event, name, measurements, metadata})
    end, nil)

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # 2. Record a rejected receipt
    command = Command.ReceiveInboundWebhook.new(%{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_fail",
      received_at: DateTime.utc_now(),
      raw_body_sha256: "sha256:fail",
      verified_state: :rejected,
      rejection_reason: "invalid signature",
      correlation_id: "corr_fail"
    })

    {:ok, receipt} = Rulestead.receive_inbound_webhook(command)
    assert receipt.verified_state == :rejected

    # 3. Assert telemetry was emitted
    assert_receive {:telemetry_event, [:rulestead, :ops, :webhook, :rejected], %{count: 1}, metadata}
    assert metadata.webhook_provider == "github"
    assert metadata.rejection_reason == "invalid signature"
  end

  test "accepted inbound intent links receipt ID in audit metadata" do
    # 1. Setup a flag
    seed_environment!("development")

    {:ok, flag} = Rulestead.create_flag(%{
      key: "audit-link-feature",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "admin",
      permanent: true,
      environment_keys: ["development"]
    }, actor: %{id: "admin", roles: [:admin]})

    {:ok, _} =
      Rulestead.save_draft_ruleset(
        Command.SaveDraftRuleset.new(flag.flag.key, "development", %{rules: []},
          actor: %{id: "admin", roles: [:admin]}
        )
      )

    # 2. Setup a verified inbound event
    receipt_id = Ecto.UUID.generate()
    event = InboundEvent.new(%{
      provider: "github",
      endpoint_key: "dev-webhook",
      delivery_id: "del_audit",
      received_at: DateTime.utc_now(),
      payload: %{
        "action" => "schedule_governed_action",
        "flag_key" => flag.flag.key,
        "environment_key" => "development",
        "command_operation" => "release_kill_switch",
        "command_attrs" => %{},
        "scheduled_for" => DateTime.utc_now(),
        "execution_mode" => :policy_bypass,
        "reason" => "Inbound from GitHub"
      },
      metadata: %{},
      correlation_id: "corr_audit"
    })

    receipt = %{id: receipt_id}

    # 3. Execute
    {:ok, result} = Rulestead.execute_inbound_event(event, receipt)

    # 4. Check fake stored metadata
    snapshot =
      case Rulestead.Fake.snapshot() do
        {:ok, state} -> state
        state -> state
      end

    assert result.scheduled_execution.metadata["webhook_receipt_id"] == receipt_id

    scheduled_execution = snapshot.scheduled_executions[result.scheduled_execution.id]
    assert scheduled_execution.metadata["webhook_receipt_id"] == receipt_id
    assert scheduled_execution.metadata["webhook_provider"] == "github"
  end

  defp seed_environment!(key) do
    attrs = %{
      key: key,
      name: String.upcase(key)
    }

    changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)

    case Rulestead.Repo.insert(changeset) do
      {:ok, _env} -> :ok
      {:error, %Ecto.Changeset{errors: [key: {"has already been taken", _}]}} -> :ok
    end
  end
end
