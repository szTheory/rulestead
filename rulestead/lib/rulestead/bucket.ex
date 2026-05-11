defmodule Rulestead.Bucket do
  @moduledoc false

  @hash_version 1
  @bucket_count 10_000

  @type namespace :: :rollout | :variant

  @spec hash_version() :: pos_integer()
  def hash_version, do: @hash_version

  @spec bucket_count() :: pos_integer()
  def bucket_count, do: @bucket_count

  @spec compute(String.t() | atom(), String.t() | atom(), String.t(), String.t(), namespace()) ::
          integer()
  def compute(flag_key, rule_key, effective_salt, targeting_value, namespace) do
    payload = [
      "v",
      Integer.to_string(@hash_version),
      ?:,
      normalize_namespace(namespace),
      ?:,
      to_string(flag_key),
      ?:,
      to_string(rule_key),
      ?:,
      effective_salt,
      ?:,
      targeting_value
    ]

    <<seed::unsigned-big-integer-size(64), _rest::binary>> = :crypto.hash(:sha256, payload)
    rem(seed, @bucket_count)
  end

  @spec effective_salt(String.t() | nil, String.t() | nil, atom() | String.t() | nil, namespace()) ::
          String.t()
  def effective_salt(ruleset_salt, rollout_salt, bucket_by, namespace) do
    [normalize_string(ruleset_salt), normalize_string(rollout_salt), normalize_bucket_by(bucket_by), normalize_namespace(namespace)]
    |> Enum.join(":")
  end

  defp normalize_namespace(:rollout), do: "rollout"
  defp normalize_namespace(:variant), do: "variant"
  defp normalize_namespace("rollout"), do: "rollout"
  defp normalize_namespace("variant"), do: "variant"
  defp normalize_namespace(namespace), do: namespace |> to_string() |> String.trim()

  defp normalize_bucket_by(nil), do: "subject"
  defp normalize_bucket_by(bucket_by) when is_atom(bucket_by), do: Atom.to_string(bucket_by)
  defp normalize_bucket_by(bucket_by), do: bucket_by |> to_string() |> String.trim()

  defp normalize_string(nil), do: ""
  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: to_string(value)
end
