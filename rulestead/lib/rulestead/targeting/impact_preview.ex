# credo:disable-for-this-file
defmodule Rulestead.Targeting.ImpactPreview do
  @moduledoc false

  alias Rulestead.Admin.Redaction
  alias Rulestead.AuditEvent

  @schema_version 2
  @severity_rank %{blocker: 0, warning: 1, info: 2, in_sync: 3}
  @default_preview_basis "authored_state_and_explicit_samples"
  @impression_allowlist ~w(window_label sampled_impressions matched_impressions variant_breakdown)
  @uncertainty_messages %{
    "authored_state_and_explicit_samples" => "authored-state and explicit-sample preview only",
    "authored_state_with_host_evidence" =>
      "authored state with bounded host-supplied evidence; not an authoritative population count",
    "authored_state_host_evidence_unavailable" =>
      "authored-state preview; host evidence unavailable or denied"
  }
  @output_atom_keys %{
    "actor_key" => :actor_key,
    "targeting_key" => :targeting_key,
    "key" => :key,
    "type" => :type,
    "environment_key" => :environment_key,
    "tenant_key" => :tenant_key,
    "matched?" => :matched?,
    "reason" => :reason,
    "result" => :result,
    "traits" => :traits,
    "reference_key" => :reference_key,
    "plan" => :plan,
    "country" => :country,
    "region" => :region,
    "locale" => :locale,
    "account_type" => :account_type,
    "tier" => :tier
  }

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

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec fingerprint(term()) :: String.t()
  def fingerprint(term), do: "sha256:" <> hash_term(term)

  @spec preview_fingerprint(map()) :: String.t()
  def preview_fingerprint(attrs) when is_map(attrs) do
    samples = redacted_samples(fetch(attrs, :samples) || [])
    affected_references = normalize_affected_references(fetch(attrs, :affected_references) || [])
    impression_summary = redacted_impression_summary(fetch(attrs, :impression_summary))

    token_payload = %{
      schema_version: @schema_version,
      environment_key: normalize_string(fetch(attrs, :environment_key)),
      tenant_key: normalize_string(fetch(attrs, :tenant_key)),
      audience_key: normalize_string(fetch(attrs, :audience_key)),
      operation: normalize_string(fetch(attrs, :operation)),
      before_fingerprint: fingerprint(fetch(attrs, :before_definition)),
      after_fingerprint: fingerprint(fetch(attrs, :after_definition)),
      affected_reference_keys: affected_reference_keys(affected_references),
      sample_fingerprint: fingerprint(samples),
      impression_fingerprint: fingerprint(impression_summary),
      preview_basis: preview_basis(attrs)
    }

    "audprev_" <> hash_term(token_payload)
  end

  @spec build(map()) :: map()
  def build(attrs) when is_map(attrs) do
    preview_basis = preview_basis(attrs)
    affected_references = normalize_affected_references(fetch(attrs, :affected_references) || [])
    samples = redacted_samples(fetch(attrs, :samples) || [])
    impression_evidence = redacted_impression_summary(fetch(attrs, :impression_summary))

    %{
      preview_schema_version: @schema_version,
      preview_fingerprint:
        preview_fingerprint(%{
          environment_key: fetch(attrs, :environment_key),
          tenant_key: fetch(attrs, :tenant_key),
          audience_key: fetch(attrs, :audience_key),
          operation: fetch(attrs, :operation),
          before_definition: fetch(attrs, :before_definition),
          after_definition: fetch(attrs, :after_definition),
          affected_references: affected_references,
          samples: samples,
          impression_summary: impression_evidence,
          preview_basis: preview_basis
        }),
      environment_scope: %{environment_key: normalize_string(fetch(attrs, :environment_key))},
      tenant_scope: %{tenant_key: normalize_string(fetch(attrs, :tenant_key))},
      audience_key: normalize_string(fetch(attrs, :audience_key)),
      operation: normalize_string(fetch(attrs, :operation)),
      preview_basis: preview_basis,
      uncertainty: %{
        basis: preview_basis,
        authoritative_population_count?: false,
        message: uncertainty_message(preview_basis)
      },
      sample_evidence: samples,
      impression_evidence: impression_evidence,
      affected_references: affected_references,
      findings: sort_findings(fetch(attrs, :findings) || [])
    }
  end

  @doc false
  @spec redacted_impression_summary(term()) :: map()
  def redacted_impression_summary(nil), do: %{}

  def redacted_impression_summary(summary) when is_map(summary) do
    summary = Map.new(summary, fn {key, value} -> {to_string(key), value} end)

    Enum.reduce(@impression_allowlist, %{}, fn field, acc ->
      case normalize_impression_field(field, Map.get(summary, field)) do
        nil -> acc
        normalized -> Map.put(acc, String.to_existing_atom(field), normalized)
      end
    end)
  rescue
    ArgumentError -> %{}
  end

  def redacted_impression_summary(_summary), do: %{}

  @spec preview_basis(map()) :: String.t()
  def preview_basis(attrs) when is_map(attrs) do
    case normalize_string(fetch(attrs, :preview_basis)) do
      nil -> derive_preview_basis(attrs)
      basis -> basis
    end
  end

  @spec finding(:blocker | :warning | :info, atom(), String.t(), keyword() | map()) :: map()
  def finding(severity, class, code, attrs \\ %{}) do
    metadata =
      attrs
      |> normalize_metadata()
      |> Map.drop(["message"])

    %{
      severity: severity,
      class: class,
      code: code
    }
    |> maybe_put(:message, fetch_message(attrs))
    |> maybe_put(:metadata, if(map_size(metadata) == 0, do: nil, else: metadata))
  end

  @spec normalize_term(term()) :: term()
  def normalize_term(%DateTime{} = term), do: DateTime.to_iso8601(term)
  def normalize_term(%NaiveDateTime{} = term), do: NaiveDateTime.to_iso8601(term)
  def normalize_term(%Date{} = term), do: Date.to_iso8601(term)
  def normalize_term(%Time{} = term), do: Time.to_iso8601(term)
  def normalize_term(%_{} = term), do: term |> Map.from_struct() |> normalize_term()

  def normalize_term(term) when is_map(term) do
    term
    |> Enum.map(fn {key, value} -> {normalize_term(key), normalize_term(value)} end)
    |> Enum.sort()
  end

  def normalize_term(term) when is_list(term), do: Enum.map(term, &normalize_term/1)
  def normalize_term(term) when is_atom(term), do: Atom.to_string(term)
  def normalize_term(term), do: term

  defp derive_preview_basis(attrs) do
    impression = redacted_impression_summary(fetch(attrs, :impression_summary))

    if map_size(impression) > 0 do
      "authored_state_with_host_evidence"
    else
      @default_preview_basis
    end
  end

  defp uncertainty_message(preview_basis) do
    Map.get(@uncertainty_messages, preview_basis, @uncertainty_messages[@default_preview_basis])
  end

  defp normalize_impression_field("window_label", value) when is_binary(value) do
    value |> String.trim() |> blank_to_nil()
  end

  defp normalize_impression_field("sampled_impressions", value), do: normalize_non_negative_integer(value)
  defp normalize_impression_field("matched_impressions", value), do: normalize_non_negative_integer(value)

  defp normalize_impression_field("variant_breakdown", breakdown) when is_list(breakdown) do
    breakdown
    |> Enum.map(&normalize_variant_entry/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      entries -> entries
    end
  end

  defp normalize_impression_field(_key, _value), do: nil

  defp normalize_variant_entry(entry) when is_map(entry) do
    entry = Map.new(entry, fn {key, value} -> {to_string(key), value} end)

    with variant when is_binary(variant) <- fetch(entry, "variant"),
         count when not is_nil(count) <- normalize_non_negative_integer(fetch(entry, "count")) do
      %{variant: variant, count: count}
    else
      _ -> nil
    end
  end

  defp normalize_variant_entry(_entry), do: nil

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

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp redacted_samples(samples) when is_list(samples) do
    samples
    |> Enum.map(&redact_sample/1)
    |> Enum.reject(&empty_sample?/1)
  end

  defp redacted_samples(_samples), do: []

  defp redact_sample(sample) when is_map(sample) do
    audit_context =
      AuditEvent.metadata(%{context: sample})
      |> Map.fetch!("context")

    %{telemetry: redacted} = Redaction.redact_metadata(audit_context, allow: @sample_allowlist)
    atomize_keys(redacted)
  end

  defp redact_sample(_sample), do: %{}

  defp empty_sample?(sample) when is_map(sample), do: map_size(sample) == 0
  defp empty_sample?(_sample), do: true

  defp normalize_affected_references(references) when is_list(references) do
    references
    |> Enum.map(&normalize_reference/1)
    |> Enum.reject(&(Map.get(&1, :reference_key) in [nil, ""]))
    |> Enum.sort_by(&reference_sort_key/1)
  end

  defp normalize_affected_references(_references), do: []

  defp normalize_reference(reference) when is_map(reference) do
    reference
    |> Enum.map(fn {key, value} -> {normalize_output_key(key), normalize_output_value(value)} end)
    |> Map.new()
  end

  defp normalize_reference(_reference), do: %{}

  defp affected_reference_keys(references) do
    references
    |> Enum.map(&Map.get(&1, :reference_key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp reference_sort_key(reference), do: Map.get(reference, :reference_key, "")

  defp normalize_output_value(value) when is_map(value), do: preserve_nested_map(value)
  defp normalize_output_value(value) when is_list(value), do: Enum.map(value, &normalize_output_value/1)
  defp normalize_output_value(value) when is_binary(value), do: normalize_string(value)
  defp normalize_output_value(value), do: value

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {normalize_output_key(key), atomize_value(value)}
    end)
  end

  defp atomize_value(value) when is_map(value), do: atomize_keys(value)
  defp atomize_value(value) when is_list(value), do: Enum.map(value, &atomize_value/1)
  defp atomize_value(value) when is_binary(value), do: normalize_string(value)
  defp atomize_value(value), do: value

  defp preserve_nested_map(map) do
    Map.new(map, fn {key, value} ->
      {key, normalize_output_value(value)}
    end)
  end

  defp normalize_output_key(key) when is_atom(key), do: key
  defp normalize_output_key(key) when is_binary(key), do: Map.get(@output_atom_keys, key, key)

  defp fetch(attrs, key) when is_binary(key),
    do: Map.get(attrs, key) || Map.get(attrs, String.to_existing_atom(key))

  defp fetch(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp normalize_string(value), do: value

  defp sort_findings(findings) when is_list(findings) do
    Enum.sort_by(findings, fn finding ->
      {Map.fetch!(@severity_rank, Map.get(finding, :severity, :info)),
       Map.get(finding, :code, "")}
    end)
  end

  defp sort_findings(_findings), do: []

  defp fetch_message(attrs) when is_list(attrs), do: Keyword.get(attrs, :message)

  defp fetch_message(attrs) when is_map(attrs),
    do: Map.get(attrs, :message) || Map.get(attrs, "message")

  defp fetch_message(_attrs), do: nil

  defp normalize_metadata(attrs) when is_list(attrs),
    do: attrs |> Map.new() |> normalize_metadata()

  defp normalize_metadata(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  defp normalize_metadata(_attrs), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp hash_term(term) do
    term
    |> normalize_term()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
