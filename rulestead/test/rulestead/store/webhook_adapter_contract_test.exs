defmodule Rulestead.Store.WebhookAdapterContractTest do
  @moduledoc """
  Contract tests for webhook-related store operations.
  """
  use ExUnit.Case, async: true

  # This test uses both Ecto and Fake to ensure parity.
  # Since it's a contract test, we'll run it once for each.
  
  defmacro webhook_contract_tests do
    quote do
      alias Rulestead.Store.Command

      test "receive_inbound_webhook and fetch parity", %{store: store} do
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
        command = Command.ReceiveInboundWebhook.new(%{
          provider: "github",
          endpoint_key: "default",
          delivery_id: "del_contract_#{Ecto.UUID.generate()}",
          received_at: now,
          raw_body_sha256: "sha256:contract",
          verified_state: :accepted,
          correlation_id: "corr_contract_#{Ecto.UUID.generate()}"
        })

        {:ok, receipt} = store.receive_inbound_webhook(command)
        assert receipt.provider == "github"
        assert receipt.verified_state == :accepted

        {:ok, fetched} = store.fetch_webhook_record(Command.FetchWebhookRecord.new(receipt.id))
        assert fetched.id == receipt.id
        assert fetched.correlation_id == receipt.correlation_id
      end

      test "list_webhook_records parity", %{store: store} do
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
        
        # Insert a few records
        for i <- 1..3 do
          command = Command.ReceiveInboundWebhook.new(%{
            provider: "github",
            endpoint_key: "default",
            delivery_id: "del_list_#{i}_#{Ecto.UUID.generate()}",
            received_at: now,
            raw_body_sha256: "sha256:list",
            verified_state: :accepted,
            correlation_id: "corr_list_#{i}_#{Ecto.UUID.generate()}"
          })
          store.receive_inbound_webhook(command)
        end

        {:ok, page} = store.list_webhook_records(Command.ListWebhookRecords.new(provider: "github"))
        assert length(page.entries) >= 3
      end

      test "duplicate webhook delivery rejection", %{store: store} do
        now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
        delivery_id = "del_dup_#{Ecto.UUID.generate()}"
        
        command = Command.ReceiveInboundWebhook.new(%{
          provider: "github",
          endpoint_key: "default",
          delivery_id: delivery_id,
          received_at: now,
          raw_body_sha256: "sha256:dup",
          verified_state: :accepted,
          correlation_id: "corr_dup_1_#{Ecto.UUID.generate()}"
        })

        {:ok, _} = store.receive_inbound_webhook(command)

        # Try inserting the same delivery_id
        command2 = Command.ReceiveInboundWebhook.new(%{
          provider: "github",
          endpoint_key: "default",
          delivery_id: delivery_id,
          received_at: now,
          raw_body_sha256: "sha256:dup",
          verified_state: :accepted,
          correlation_id: "corr_dup_2_#{Ecto.UUID.generate()}"
        })

        assert {:error, %Rulestead.Error{type: :invalid_command}} = store.receive_inbound_webhook(command2)
      end
    end
  end
end

defmodule Rulestead.Store.EctoWebhookContractTest do
  use Rulestead.RepoCase, async: true
  import Rulestead.Store.WebhookAdapterContractTest
  
  setup do
    {:ok, store: Rulestead.Store.Ecto}
  end

  webhook_contract_tests()
end

defmodule Rulestead.Store.FakeWebhookContractTest do
  use ExUnit.Case, async: true
  import Rulestead.Store.WebhookAdapterContractTest

  setup do
    Rulestead.Fake.reset()
    {:ok, store: Rulestead.Fake}
  end

  webhook_contract_tests()
end
