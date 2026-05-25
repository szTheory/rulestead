defmodule Rulestead.Webhooks.Destination do
  @moduledoc false
  # A durable outbound webhook destination.

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "webhook_destinations" do
    field(:name, :string)
    field(:description, :string)
    field(:url, :string)
    field(:secret_id, :string)
    field(:environment_key, :string)
    field(:subscriptions, {:array, :string}, default: [])
    field(:enabled, :boolean, default: true)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @subscription_presets %{
    "all_high_impact_governance_events" => [
      "ruleset.published",
      "rollout.advanced",
      "kill_switch.engaged",
      "kill_switch.released",
      "change_request.submitted",
      "change_request.approved",
      "change_request.executed"
    ]
  }

  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [
      :name,
      :description,
      :url,
      :secret_id,
      :environment_key,
      :subscriptions,
      :enabled,
      :metadata
    ])
    |> validate_required([:name, :url, :environment_key, :subscriptions])
    |> validate_length(:name, min: 2, max: 128)
    |> validate_format(:url, ~r/^https?:\/\//)
    |> unique_constraint([:environment_key, :name])
  end

  def subscription_presets, do: @subscription_presets
  def default_subscription_preset, do: "all_high_impact_governance_events"
end
