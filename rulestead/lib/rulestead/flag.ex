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
    field(:owner, :string)
    field(:expected_expiration, :date)
    field(:permanent, :boolean, default: false)
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
    attrs = normalize_embeds(attrs)

    flag
    |> cast(attrs, [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :owner,
      :expected_expiration,
      :permanent,
      :tags,
      :archived_at
    ])
    |> cast_embed(:ownership, required: true, with: &Ownership.changeset/2)
    |> cast_embed(:lifecycle, required: true, with: &LifecycleMetadata.changeset/2)
    |> update_change(:key, &normalize_key/1)
    |> update_change(:owner, &normalize_string/1)
    |> update_change(:tags, &normalize_tags/1)
    |> validate_required([:key, :flag_type, :value_type, :default_value, :owner])
    |> validate_length(:key, min: 2, max: 128)
    |> validate_length(:owner, min: 1, max: 255)
    |> validate_format(:key, ~r/^[a-z0-9][a-z0-9:_-]*$/)
    |> validate_lifecycle_mode()
    |> validate_lifecycle_contract()
    |> unique_constraint(:key)
  end

  @spec flag_types() :: [atom()]
  def flag_types, do: @flag_types

  @spec value_types() :: [atom()]
  def value_types, do: @value_types

  defp normalize_key(value) when is_binary(value), do: String.trim(value)
  defp normalize_key(value), do: value

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value

  defp validate_lifecycle_mode(changeset) do
    permanent = get_field(changeset, :permanent, false)
    expected_expiration = get_field(changeset, :expected_expiration)

    cond do
      permanent and is_nil(expected_expiration) ->
        changeset

      not permanent and not is_nil(expected_expiration) ->
        changeset

      permanent and not is_nil(expected_expiration) ->
        changeset
        |> add_error(:permanent, "must be false when expected expiration is set")
        |> add_error(:expected_expiration, "must be blank when permanent is true")

      true ->
        changeset
        |> add_error(:permanent, "must be true when expected expiration is blank")
        |> add_error(:expected_expiration, "must be set when permanent is false")
    end
  end

  defp validate_lifecycle_contract(changeset) do
    lifecycle = get_field(changeset, :lifecycle)
    flag_type = get_field(changeset, :flag_type)
    permanent = get_field(changeset, :permanent, false)
    expected_expiration = get_field(changeset, :expected_expiration)
    expected_mode = if(permanent, do: :permanent, else: :expiring)

    changeset
    |> validate_remote_config_posture(flag_type, lifecycle)
    |> validate_lifecycle_mode_matches(lifecycle, expected_mode, expected_expiration)
  end

  defp validate_remote_config_posture(changeset, :remote_config, nil) do
    add_error(changeset, :lifecycle, "must choose permanent or expected expiration for remote config")
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
        add_error(changeset, :lifecycle, "must choose permanent or expected expiration for remote config")
    end
  end

  defp validate_remote_config_posture(changeset, _flag_type, _lifecycle), do: changeset

  defp validate_lifecycle_mode_matches(changeset, nil, _expected_mode, _expected_expiration), do: changeset

  defp validate_lifecycle_mode_matches(changeset, lifecycle, expected_mode, expected_expiration) do
    changeset =
      if lifecycle.mode && lifecycle.mode != expected_mode do
        add_error(changeset, :lifecycle, "must match the authored permanent or expiration posture")
      else
        changeset
      end

    if lifecycle.mode == :expiring and is_nil(expected_expiration) do
      add_error(changeset, :lifecycle, "reviewed expiring flags must set an expected expiration")
    else
      changeset
    end
  end

  defp normalize_embeds(attrs) when is_map(attrs) do
    attrs
    |> normalize_ownership_attr()
    |> normalize_lifecycle_attr()
  end

  defp normalize_embeds(attrs), do: attrs

  defp normalize_ownership_attr(attrs) do
    ownership = Map.get(attrs, :ownership) || Map.get(attrs, "ownership")

    if is_nil(ownership) do
      case Ownership.default_from_owner(Map.get(attrs, :owner) || Map.get(attrs, "owner")) do
        nil -> attrs
        fallback -> Map.put(attrs, :ownership, fallback)
      end
    else
      attrs
    end
  end

  defp normalize_lifecycle_attr(attrs) do
    lifecycle = Map.get(attrs, :lifecycle) || Map.get(attrs, "lifecycle")

    if is_nil(lifecycle) do
      Map.put(attrs, :lifecycle, LifecycleMetadata.default_from_flag(attrs))
    else
      attrs
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
