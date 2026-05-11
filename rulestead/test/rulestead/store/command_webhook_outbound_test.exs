defmodule Rulestead.Store.CommandWebhookOutboundTest do
  use ExUnit.Case, async: true

  alias Rulestead.Store.Command.{
    CreateWebhookDestination,
    UpdateWebhookDestination,
    FetchWebhookDestination,
    ListWebhookDestinations,
    ListWebhookDeliveries,
    RetryWebhookDelivery
  }

  test "CreateWebhookDestination command construction" do
    attrs = %{
      name: "Slack",
      url: "https://hooks.slack.com/...",
      environment_key: "production",
      subscriptions: ["ruleset.published"],
      secret_id: "slack-secret"
    }

    command = CreateWebhookDestination.new(attrs)
    assert command.name == "Slack"
    assert command.url == "https://hooks.slack.com/..."
    assert command.subscriptions == ["ruleset.published"]
  end

  test "UpdateWebhookDestination command construction" do
    command = UpdateWebhookDestination.new("dest_123", %{name: "New Name", enabled: false})
    assert command.id == "dest_123"
    assert command.name == "New Name"
    assert command.enabled == false
  end

  test "FetchWebhookDestination command construction" do
    command = FetchWebhookDestination.new("dest_123", actor: %{id: "admin", roles: [:admin]})
    assert command.id == "dest_123"
    assert command.actor["id"] == "admin"
  end

  test "ListWebhookDestinations command construction" do
    command = ListWebhookDestinations.new(environment_key: "production", limit: 10)
    assert command.environment_key == "production"
    assert command.limit == 10
  end

  test "ListWebhookDeliveries command construction" do
    command = ListWebhookDeliveries.new(destination_id: "dest_123", state: :failed)
    assert command.destination_id == "dest_123"
    assert command.state == :failed
  end

  test "RetryWebhookDelivery command construction" do
    command = RetryWebhookDelivery.new("del_123")
    assert command.delivery_id == "del_123"
  end
end
