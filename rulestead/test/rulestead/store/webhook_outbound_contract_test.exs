defmodule Rulestead.Store.WebhookOutboundContractTest do
  @moduledoc """
  Contract tests for outbound webhook store operations.
  """
  use ExUnit.Case, async: true

  defmacro webhook_outbound_contract_tests do
    quote do
      alias Rulestead.Store.Command
      alias Rulestead.Webhooks.Destination

      test "create and fetch destination parity", %{store: store} do
        command =
          Command.CreateWebhookDestination.new(%{
            name: "Slack #{Ecto.UUID.generate()}",
            url: "https://hooks.slack.com/...",
            environment_key: "production",
            subscriptions: ["ruleset.published"]
          })

        {:ok, dest} = store.create_webhook_destination(command)
        assert dest.name == command.name
        assert dest.environment_key == "production"

        {:ok, fetched} =
          store.fetch_webhook_destination(Command.FetchWebhookDestination.new(dest.id))

        assert fetched.id == dest.id
        assert fetched.name == dest.name
      end

      test "list destinations parity", %{store: store} do
        env = "env_#{Ecto.UUID.generate()}"

        for i <- 1..2 do
          command =
            Command.CreateWebhookDestination.new(%{
              name: "Dest #{i} #{Ecto.UUID.generate()}",
              url: "https://example.com/#{i}",
              environment_key: env,
              subscriptions: ["ruleset.published"]
            })

          store.create_webhook_destination(command)
        end

        {:ok, page} =
          store.list_webhook_destinations(
            Command.ListWebhookDestinations.new(environment_key: env)
          )

        assert length(page.entries) == 2
      end

      test "update destination parity", %{store: store} do
        command =
          Command.CreateWebhookDestination.new(%{
            name: "Original Name #{Ecto.UUID.generate()}",
            url: "https://example.com",
            environment_key: "production",
            subscriptions: ["ruleset.published"]
          })

        {:ok, dest} = store.create_webhook_destination(command)

        update_command = Command.UpdateWebhookDestination.new(dest.id, %{name: "Updated Name"})
        {:ok, updated} = store.update_webhook_destination(update_command)

        assert updated.name == "Updated Name"
        assert updated.url == dest.url
      end
    end
  end
end

defmodule Rulestead.Store.EctoWebhookOutboundContractTest do
  use Rulestead.RepoCase, async: true
  import Rulestead.Store.WebhookOutboundContractTest

  setup do
    {:ok, store: Rulestead.Store.Ecto}
  end

  webhook_outbound_contract_tests()
end

defmodule Rulestead.Store.FakeWebhookOutboundContractTest do
  use ExUnit.Case, async: true
  import Rulestead.Store.WebhookOutboundContractTest

  setup do
    Rulestead.Fake.reset()
    {:ok, store: Rulestead.Fake}
  end

  webhook_outbound_contract_tests()
end
