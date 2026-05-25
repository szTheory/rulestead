defmodule Rulestead.Admin.LifecycleDefaults do
  @moduledoc false

  @expiring_types [:release, :experiment, :migration]
  @permanent_types [:kill_switch, :operational, :permission]

  @spec suggest(atom() | String.t(), keyword()) :: map()
  def suggest(flag_type, opts \\ []) do
    authored_mode = Keyword.get(opts, :authored_mode)
    authored_review_by = Keyword.get(opts, :authored_review_by)

    base =
      case normalize_flag_type(flag_type) do
        type when type in @expiring_types ->
          %{
            mode: :expiring,
            rationale: "#{humanize(type)} flags usually need an explicit sunset review.",
            default_source: :flag_type
          }

        type when type in @permanent_types ->
          %{
            mode: :permanent,
            rationale: "#{humanize(type)} flags are usually long-lived operational controls.",
            default_source: :flag_type
          }

        :remote_config ->
          %{
            mode: nil,
            rationale:
              "Remote config needs an explicit operator choice because usage can be temporary or durable.",
            default_source: :operator_required
          }

        _other ->
          %{
            mode: nil,
            rationale: "Choose an explicit lifecycle posture for this flag.",
            default_source: :operator_required
          }
      end

    base
    |> Map.put(:review_by, authored_review_by)
    |> Map.put(:default_overridden, not is_nil(authored_mode) and authored_mode != base.mode)
  end

  defp normalize_flag_type(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      normalized ->
        try do
          String.to_existing_atom(normalized)
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp normalize_flag_type(value) when is_atom(value), do: value
  defp normalize_flag_type(_value), do: nil

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
  end
end
