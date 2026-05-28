defmodule Rulestead.Admin.Redaction do
  @moduledoc false
  # Allowlist-driven redaction for admin telemetry and audit metadata.

  alias Rulestead.Targeting.DependencyInventory

  @redacted "[REDACTED]"

  @spec redact_metadata(map(), keyword()) :: %{audit: map(), telemetry: map()}
  def redact_metadata(metadata, opts \\ []) when is_map(metadata) do
    allow = opts |> Keyword.get(:allow, []) |> Enum.map(&normalize_path/1)

    %{
      audit: redact_map(metadata, allow, :audit),
      telemetry: redact_map(metadata, allow, :telemetry)
    }
  end

  defp redact_map(map, allow, target, prefix \\ [])

  defp redact_map(map, allow, target, prefix) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      key_string = to_string(key)
      path = prefix ++ [key_string]

      case redact_value(value, allow, target, path) do
        nil when target == :telemetry -> acc
        redacted -> Map.put(acc, key, redacted)
      end
    end)
  end

  defp redact_value(value, allow, target, path) when is_map(value) do
    redact_map(value, allow, target, path)
  end

  defp redact_value(value, allow, :audit, path) do
    if allowed_path?(allow, path), do: value, else: @redacted
  end

  defp redact_value(value, allow, :telemetry, path) do
    if allowed_path?(allow, path), do: value, else: nil
  end

  defp allowed_path?(allow, path) do
    Enum.any?(allow, fn allowed ->
      direct_match?(path, allowed) || direct_match?(tl_or_empty(path), allowed)
    end)
  end

  defp normalize_path(path) when is_binary(path), do: String.split(path, ".", trim: true)
  defp normalize_path(path) when is_list(path), do: Enum.map(path, &to_string/1)

  @spec redact_dependency_inventory([map()], keyword()) :: map()
  def redact_dependency_inventory(entries, opts \\ [])

  def redact_dependency_inventory(entries, opts) when is_list(entries) do
    redaction_opts =
      [
        visible_audience_keys: Keyword.get(opts, :visible_audience_keys),
        include_redacted_placeholders?: Keyword.get(opts, :include_redacted_placeholders?, false),
        visibility_resolver: Keyword.get(opts, :visibility_resolver)
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    DependencyInventory.redacted_result(entries, redaction_opts)
  end

  def redact_dependency_inventory(_entries, _opts),
    do: %{
      entries: [],
      reference_count: 0,
      hidden_reference_count: 0,
      redacted: false,
      redacted_entries: []
    }

  defp direct_match?(path, allowed),
    do: path == allowed || Enum.take(path, length(allowed)) == allowed

  defp tl_or_empty([_head | tail]), do: tail
end
