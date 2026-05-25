defmodule Rulestead.Flag do
  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Flag.{LifecycleMetadata, Ownership}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @flag_types [
    :release,
    :experiment,
    :kill_switch,
    :permission,
    :remote_config,
    :operational,
    :migration
  ]
  @value_types [:boolean, :string, :integer, :float, :json, :variant]

  schema "flags" do
    field(:key, :string)
    field(:description, :string)
    field(:flag_type, Ecto.Enum, values: @flag_types)
    field(:value_type, Ecto.Enum, values: @value_types)
    field(:default_value, :map, default: %{})
    embeds_one(:ownership, Ownership, on_replace: :update)
    embeds_one(:lifecycle, LifecycleMetadata, on_replace: :update)
    field(:tags, {:array, :string}, default: [])
    field(:archived_at, :utc_datetime_usec)

    has_many(:flag_environments, Rulestead.FlagEnvironment)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(flag, attrs) do
    flag
    |> cast(attrs, [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :tags,
      :archived_at
    ])
    |> cast_embed(:ownership, required: true, with: &Ownership.changeset/2)
    |> cast_embed(:lifecycle, required: true, with: &LifecycleMetadata.changeset/2)
    |> update_change(:key, &normalize_key/1)
    |> update_change(:tags, &normalize_tags/1)
    |> validate_required([:key, :flag_type, :value_type, :default_value])
    |> validate_length(:key, min: 2, max: 128)
    |> validate_format(:key, ~r/^[a-z0-9][a-z0-9:_-]*$/)
    |> validate_lifecycle_contract()
    |> unique_constraint(:key)
  end

  @spec flag_types() :: [atom()]
  def flag_types, do: @flag_types

  @spec value_types() :: [atom()]
  def value_types, do: @value_types

  defp normalize_key(value) when is_binary(value), do: String.trim(value)
  defp normalize_key(value), do: value

  defp validate_lifecycle_contract(changeset) do
    lifecycle = get_field(changeset, :lifecycle)
    flag_type = get_field(changeset, :flag_type)

    changeset
    |> validate_remote_config_posture(flag_type, lifecycle)
    |> validate_lifecycle_review_by(lifecycle)
  end

  defp validate_remote_config_posture(changeset, :remote_config, nil) do
    add_error(
      changeset,
      :lifecycle,
      "must choose permanent or expected expiration for remote config"
    )
  end

  defp validate_remote_config_posture(changeset, :remote_config, %{mode: nil}) do
    case get_change(changeset, :lifecycle) do
      %Ecto.Changeset{} = lifecycle_changeset ->
        put_change(
          changeset,
          :lifecycle,
          add_error(
            lifecycle_changeset,
            :mode,
            "must choose permanent or expected expiration for remote config"
          )
        )

      _other ->
        add_error(
          changeset,
          :lifecycle,
          "must choose permanent or expected expiration for remote config"
        )
    end
  end

  defp validate_remote_config_posture(changeset, _flag_type, _lifecycle), do: changeset

  defp validate_lifecycle_review_by(changeset, nil), do: changeset

  defp validate_lifecycle_review_by(changeset, lifecycle) do
    if lifecycle.mode == :expiring and is_nil(lifecycle.review_by) do
      case get_change(changeset, :lifecycle) do
        %Ecto.Changeset{} = lifecycle_changeset ->
          put_change(
            changeset,
            :lifecycle,
            add_error(
              lifecycle_changeset,
              :review_by,
              "reviewed expiring flags must set an expected expiration"
            )
          )

        _ ->
          add_error(
            changeset,
            :lifecycle,
            "reviewed expiring flags must set an expected expiration"
          )
      end
    else
      changeset
    end
  end

  defp normalize_tags(tags) when is_list(tags) do
    tags
    |> Enum.map(&normalize_tag/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_tags(tags), do: tags

  defp normalize_tag(tag) when is_binary(tag) do
    case String.trim(tag) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_tag(_tag), do: nil
end
