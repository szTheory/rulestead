defmodule Rulestead.Analytics.Event do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "rulestead_analytics_events" do
    field(:kind, :string)
    field(:actor_id, :string)
    field(:event_name, :string)
    field(:env, :string)
    field(:metadata, :map, default: %{})
    field(:occurred_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}
end
