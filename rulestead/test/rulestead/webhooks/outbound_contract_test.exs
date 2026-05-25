# credo:disable-for-this-file
defmodule Rulestead.Webhooks.OutboundContractTest do
  use Rulestead.RepoCase, async: true

  alias Rulestead.Webhooks.{Destination, OutboundEvent, Delivery}

  test "destination changeset validates URL format and required fields" do
    attrs = %{
      name: "Slack",
      url: "https://hooks.slack.com/services/...",
      environment_key: "production",
      subscriptions: ["ruleset.published"]
    }

    changeset = Destination.changeset(%Destination{}, attrs)
    assert changeset.valid?

    # Invalid URL
    invalid_attrs = Map.put(attrs, :url, "not-a-url")
    changeset = Destination.changeset(%Destination{}, invalid_attrs)
    refute changeset.valid?
    assert %{url: ["has invalid format"]} = errors_on(changeset)
  end

  test "outbound event changeset validates required fields" do
    attrs = %{
      event_type: "ruleset.published",
      payload: %{"flag_key" => "feature-1"},
      correlation_id: "corr_123"
    }

    changeset = OutboundEvent.changeset(%OutboundEvent{}, attrs)
    assert changeset.valid?

    # Missing correlation_id
    invalid_attrs = Map.delete(attrs, :correlation_id)
    changeset = OutboundEvent.changeset(%OutboundEvent{}, invalid_attrs)
    refute changeset.valid?
    assert %{correlation_id: ["can't be blank"]} = errors_on(changeset)
  end

  test "delivery changeset validates state enum" do
    # First we need a destination and event (simplified for contract check)
    dest_id = Ecto.UUID.generate()
    event_id = Ecto.UUID.generate()

    attrs = %{
      webhook_destination_id: dest_id,
      webhook_outbound_event_id: event_id,
      state: :pending,
      attempt_count: 0
    }

    changeset = Delivery.changeset(%Delivery{}, attrs)
    assert changeset.valid?

    # Invalid state
    invalid_attrs = Map.put(attrs, :state, :unknown)
    changeset = Delivery.changeset(%Delivery{}, invalid_attrs)
    refute changeset.valid?
    assert %{state: ["is invalid"]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key)) |> to_string()
      end)
    end)
  end
end
