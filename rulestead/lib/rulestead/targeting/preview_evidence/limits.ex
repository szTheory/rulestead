defmodule Rulestead.Targeting.PreviewEvidence.Limits do
  @moduledoc false

  alias Rulestead.Admin.Redaction
  alias Rulestead.AuditEvent
  alias Rulestead.StoreError

  @max_sample_rows 25
  @max_payload_bytes 16_384
  @max_variant_breakdown_entries 20

  @impression_allowlist ~w(window_label sampled_impressions matched_impressions variant_breakdown)

  @sample_allowlist [
    "actor_key",
    "targeting_key",
    "key",
    "type",
    "environment_key",
    "tenant_key",
    "matched?",
    "reason",
    "result",
    "traits.plan",
    "traits.country",
    "traits.region",
    "traits.locale",
    "traits.account_type",
    "traits.tier"
  ]

  @spec max_sample_rows() :: pos_integer()
  def max_sample_rows, do: @max_sample_rows

  @spec max_payload_bytes() :: pos_integer()
  def max_payload_bytes, do: @max_payload_bytes

  @spec merge_samples([map()], [map()], keyword()) :: [map()]
  def merge_samples(command_samples, resolver_samples, opts \\ []) do
    max_rows = Keyword.get(opts, :max_sample_rows, @max_sample_rows)

    (List.wrap(command_samples) ++ List.wrap(resolver_samples))
    |> dedupe_samples()
    |> Enum.take(max_rows)
  end

  @spec validate_and_redact(map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def validate_and_redact(evidence_map, opts \\ []) when is_map(evidence_map) do
    evidence_map = Map.new(evidence_map)
    max_rows = Keyword.get(opts, :max_sample_rows, @max_sample_rows)

    with :ok <- check_policy_denied(evidence_map),
         {:ok, samples} <- validate_samples(fetch(evidence_map, :samples), max_rows),
         {:ok, impression_summary} <-
           validate_impression_summary(fetch(evidence_map, :impression_summary)),
         normalized <- %{samples: samples, impression_summary: impression_summary},
         :ok <- enforce_payload_size!(normalized) do
      {:ok, normalized}
    end
  end

  @spec enforce_payload_size!(map()) :: :ok | {:error, Rulestead.Error.t()}
  def enforce_payload_size!(map) when is_map(map) do
    if payload_byte_size(map) > @max_payload_bytes do
      {:error, oversized_error()}
    else
      :ok
    end
  end

  defp check_policy_denied(evidence_map) do
    if truthy?(fetch(evidence_map, :policy_denied)) do
      {:error, policy_denied_error()}
    else
      :ok
    end
  end

  defp validate_samples(nil, _max_rows), do: {:ok, []}

  defp validate_samples(samples, max_rows) when is_list(samples) do
    if length(samples) > max_rows do
      {:error, oversized_error()}
    else
      {:ok, Enum.map(samples, &redact_sample/1) |> Enum.reject(&empty_sample?/1)}
    end
  end

  defp validate_samples(_samples, _max_rows), do: {:error, invalid_error()}

  defp validate_impression_summary(nil), do: {:ok, %{}}
  defp validate_impression_summary(%{} = summary), do: normalize_impression_summary(summary)
  defp validate_impression_summary(_summary), do: {:error, invalid_error()}

  defp normalize_impression_summary(summary) do
    summary = Map.new(summary)

    if unknown_impression_keys?(summary) do
      {:error, invalid_error()}
    else
      build_impression_summary(summary)
    end
  end

  defp unknown_impression_keys?(summary) do
    summary
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.any?(&(&1 not in @impression_allowlist))
  end

  defp build_impression_summary(summary) do
    with {:ok, window_label} <- optional_string_field(summary, :window_label),
         {:ok, sampled_impressions} <- optional_count_field(summary, :sampled_impressions),
         {:ok, matched_impressions} <- optional_count_field(summary, :matched_impressions),
         {:ok, variant_breakdown} <-
           normalize_variant_breakdown(fetch(summary, :variant_breakdown)) do
      impression =
        %{}
        |> maybe_put(:window_label, window_label)
        |> maybe_put(:sampled_impressions, sampled_impressions)
        |> maybe_put(:matched_impressions, matched_impressions)
        |> maybe_put(:variant_breakdown, variant_breakdown)

      {:ok, impression}
    else
      {:error, _} = error -> error
    end
  end

  defp optional_string_field(summary, key) do
    case fetch(summary, key) do
      nil ->
        {:ok, nil}

      value when is_binary(value) ->
        normalized = value |> String.trim() |> blank_to_nil()
        {:ok, normalized}

      _other ->
        {:error, invalid_error()}
    end
  end

  defp optional_count_field(summary, key) do
    case fetch(summary, key) do
      nil ->
        {:ok, nil}

      value ->
        case normalize_non_negative_integer(value) do
          nil -> {:error, invalid_error()}
          count -> {:ok, count}
        end
    end
  end

  defp normalize_variant_breakdown(nil), do: {:ok, nil}

  defp normalize_variant_breakdown(breakdown) when is_list(breakdown) do
    if length(breakdown) > @max_variant_breakdown_entries do
      {:error, invalid_error()}
    else
      normalize_variant_breakdown_entries(breakdown)
    end
  end

  defp normalize_variant_breakdown(_breakdown), do: {:error, invalid_error()}

  defp normalize_variant_entry(entry) when is_map(entry) do
    entry = Map.new(entry, fn {key, value} -> {to_string(key), value} end)

    if Map.keys(entry) -- ["variant", "count"] != [] do
      {:error, invalid_error()}
    else
      with variant when is_binary(variant) <- fetch(entry, "variant"),
           count when not is_nil(count) <- normalize_non_negative_integer(fetch(entry, "count")) do
        {:ok, %{variant: variant, count: count}}
      else
        _ -> {:error, invalid_error()}
      end
    end
  end

  defp normalize_variant_entry(_entry), do: {:error, invalid_error()}

  defp normalize_variant_breakdown_entries(breakdown) do
    Enum.reduce_while(breakdown, {:ok, []}, fn entry, {:ok, acc} ->
      case normalize_variant_entry(entry) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp dedupe_samples(samples) do
    samples
    |> Enum.reduce({[], MapSet.new()}, &dedupe_sample/2)
    |> elem(0)
    |> Enum.reverse()
  end

  defp dedupe_sample(sample, {acc, seen}) do
    case dedupe_key(sample) do
      nil ->
        {[sample | acc], seen}

      key ->
        if MapSet.member?(seen, key) do
          {acc, seen}
        else
          {[sample | acc], MapSet.put(seen, key)}
        end
    end
  end

  defp dedupe_key(sample) when is_map(sample) do
    actor_key = fetch(sample, :actor_key)
    targeting_key = fetch(sample, :targeting_key)

    if is_binary(actor_key) and is_binary(targeting_key) do
      {actor_key, targeting_key}
    else
      nil
    end
  end

  defp dedupe_key(_sample), do: nil

  defp redact_sample(sample) when is_map(sample) do
    audit_context =
      AuditEvent.metadata(%{context: sample})
      |> Map.fetch!("context")

    %{telemetry: redacted} = Redaction.redact_metadata(audit_context, allow: @sample_allowlist)
    redacted
  end

  defp redact_sample(_sample), do: %{}

  defp empty_sample?(sample) when is_map(sample), do: map_size(sample) == 0
  defp empty_sample?(_sample), do: true

  defp payload_byte_size(map) do
    map
    |> normalize_term()
    |> :erlang.term_to_binary()
    |> byte_size()
  end

  defp normalize_term(term) when is_map(term) do
    term
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> {to_string(key), normalize_term(value)} end)
    |> Map.new()
  end

  defp normalize_term(term) when is_list(term), do: Enum.map(term, &normalize_term/1)
  defp normalize_term(term), do: term

  defp normalize_non_negative_integer(value) when is_integer(value) and value >= 0, do: value

  defp normalize_non_negative_integer(value) when is_float(value) and value >= 0,
    do: trunc(value)

  defp normalize_non_negative_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, ""} when parsed >= 0 -> parsed
      _other -> nil
    end
  end

  defp normalize_non_negative_integer(_value), do: nil

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp fetch(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp invalid_error do
    StoreError.invalid_command("preview evidence invalid",
      metadata: %{code: "preview_evidence_invalid"}
    )
  end

  defp oversized_error do
    StoreError.invalid_command("preview evidence oversized",
      metadata: %{code: "preview_evidence_oversized"}
    )
  end

  defp policy_denied_error do
    StoreError.invalid_command("preview evidence policy denied",
      metadata: %{code: "preview_evidence_policy_denied"}
    )
  end
end
