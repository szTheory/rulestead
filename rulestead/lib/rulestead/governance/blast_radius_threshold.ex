defmodule Rulestead.Governance.BlastRadiusThreshold do
  @moduledoc """
  Pure blast-radius threshold evaluation for protected-environment audience mutations.

  Default protected-environment limits (profile `:default`):

  - `:update` — direct apply when `reference_count <= 2`
  - `:archive` — direct apply only when `reference_count == 0`
  - Any indeterminate input — fail-closed (treated as apply-blocked in protected env)

  Override thresholds via `assess/2` opts (`:threshold_profile`, `:protected_environment?`).
  Host-level `Rulestead.Config` integration is intentionally deferred.
  """

  alias Rulestead.Promotion.Compare
  alias Rulestead.StoreError
  alias Rulestead.Targeting.{AudienceDependencies, DependencyValidator, ImpactPreview}

  @default_profile %{
    update_limit: 2,
    archive_limit: 0
  }

  @above_threshold_remediation "This audience change affects more than the direct-apply limit for protected environments. Submit a change request for governed approval."

  @indeterminate_remediation "Blast radius cannot be evaluated safely. Re-run preview after resolving dependency visibility, or cancel the change."

  @spec assess(map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def assess(attrs, opts \\ []) when is_map(attrs) do
    profile = profile_for(opts)
    protected? = protected_environment?(attrs, opts)
    references = normalize_references(Map.get(attrs, :affected_references, []))
    reference_count = length(references)
    distinct_flag_count = distinct_flag_count(references)
    operation = normalize_string(Map.get(attrs, :operation))
    environment_key = normalize_string(Map.get(attrs, :environment_key))
    preview_fingerprint = normalize_string(Map.get(attrs, :preview_fingerprint))
    _preview_schema_version = Map.get(attrs, :preview_schema_version)
    dependency_entries = List.wrap(Map.get(attrs, :dependency_entries))
    hidden_reference_count = Map.get(attrs, :hidden_reference_count, 0) || 0

    rollout_hints = rollout_hints(references)
    lifecycle_hints = lifecycle_hints(references)

    {verdict, breach_reasons} =
      verdict_for(
        attrs,
        references,
        dependency_entries,
        hidden_reference_count,
        protected?,
        operation,
        reference_count,
        profile
      )

    assessment = %{
      verdict: verdict,
      reference_count: reference_count,
      distinct_flag_count: distinct_flag_count,
      rollout_hints: rollout_hints,
      lifecycle_hints: lifecycle_hints,
      threshold_profile: Keyword.get(opts, :threshold_profile, :default),
      operation: operation,
      environment_key: environment_key,
      preview_fingerprint: preview_fingerprint,
      breach_reasons: breach_reasons,
      protected_environment?: protected?,
      authoritative_population_count?: false
    }

    {:ok, assessment}
  end

  @spec validate_protected_apply(map(), map(), keyword()) :: :ok | {:error, Rulestead.Error.t()}
  def validate_protected_apply(command, preview, opts \\ [])
      when is_map(command) and is_map(preview) do
    attrs =
      %{
        environment_key: fetch(command, :environment_key),
        operation: fetch(command, :operation),
        preview_fingerprint: fetch(command, :preview_fingerprint),
        preview_schema_version: fetch(command, :preview_schema_version),
        affected_references: fetch(preview, :affected_references) || [],
        affected_reference_keys: fetch(command, :affected_reference_keys),
        dependency_entries: Keyword.get(opts, :dependency_entries, []),
        audiences: Keyword.get(opts, :audiences),
        hidden_reference_count: Keyword.get(opts, :hidden_reference_count, 0)
      }
      |> maybe_put_shared_targeting(command)

    with {:ok, assessment} <- assess(attrs, opts) do
      governed_apply? = Keyword.get(opts, :governed_apply?, false)

      cond do
        not assessment.protected_environment? ->
          :ok

        assessment.verdict == :above_threshold and governed_apply? ->
          :ok

        assessment.verdict in [:above_threshold, :indeterminate] ->
          {:error, blocked_error(assessment)}

        true ->
          :ok
      end
    end
  end

  defp maybe_put_shared_targeting(attrs, command) do
    case fetch(command, :protected_shared_targeting?) do
      true -> Map.put(attrs, :protected_shared_targeting?, true)
      _ -> attrs
    end
  end

  defp blocked_error(assessment) do
    message =
      case assessment.verdict do
        :above_threshold -> @above_threshold_remediation
        :indeterminate -> @indeterminate_remediation
      end

    findings = findings_from_breach_reasons(assessment.breach_reasons, assessment.verdict)

    StoreError.invalid_command(
      message,
      metadata: %{
        verdict: Atom.to_string(assessment.verdict),
        reference_count: assessment.reference_count,
        threshold_profile: Atom.to_string(assessment.threshold_profile),
        operation: assessment.operation,
        environment_key: assessment.environment_key,
        preview_fingerprint: assessment.preview_fingerprint
      },
      details: findings,
      cause: assessment
    )
  end

  defp findings_from_breach_reasons(breach_reasons, verdict) do
    code =
      case verdict do
        :above_threshold -> "blast_radius_above_threshold"
        :indeterminate -> "blast_radius_indeterminate"
      end

    Enum.map(breach_reasons, fn reason ->
      ImpactPreview.finding(:blocker, :governance, Map.get(reason, :code, code),
        message: Map.get(reason, :remediation),
        metadata: %{
          observed: stringify_observed(Map.get(reason, :observed)),
          limit: stringify_observed(Map.get(reason, :limit))
        }
      )
    end)
  end

  defp stringify_observed(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_observed(value) when is_integer(value), do: value
  defp stringify_observed(value) when is_binary(value), do: value
  defp stringify_observed(value), do: inspect(value)

  defp verdict_for(
         attrs,
         references,
         dependency_entries,
         hidden_reference_count,
         protected?,
         operation,
         reference_count,
         profile
       ) do
    indeterminate_reasons =
      indeterminate_reasons(attrs, references, dependency_entries, hidden_reference_count)

    cond do
      indeterminate_reasons != [] ->
        {:indeterminate, indeterminate_reasons}

      protected? and operation == "archive" and reference_count > profile.archive_limit ->
        above_threshold_reason(operation, reference_count, profile.archive_limit)

      protected? and operation == "update" and reference_count > profile.update_limit ->
        above_threshold_reason(operation, reference_count, profile.update_limit)

      true ->
        {:below_threshold, []}
    end
  end

  defp above_threshold_reason(_operation, reference_count, limit) do
    reason = %{
      code: "blast_radius_above_threshold",
      observed: reference_count,
      limit: limit,
      remediation: @above_threshold_remediation
    }

    {:above_threshold, [reason]}
  end

  defp indeterminate_reasons(attrs, references, dependency_entries, hidden_reference_count) do
    []
    |> maybe_add_indeterminate(blank_fingerprint?(attrs), %{
      code: "blast_radius_missing_preview_inputs",
      observed: "missing_preview_fingerprint",
      limit: "present_preview_fingerprint",
      remediation: @indeterminate_remediation
    })
    |> maybe_add_indeterminate(
      schema_mismatch?(Map.get(attrs, :preview_schema_version)),
      %{
        code: "blast_radius_missing_preview_inputs",
        observed: Map.get(attrs, :preview_schema_version),
        limit: ImpactPreview.schema_version(),
        remediation: @indeterminate_remediation
      }
    )
    |> maybe_add_indeterminate(
      reference_keys_mismatch?(attrs, references),
      %{
        code: "blast_radius_missing_preview_inputs",
        observed: Map.get(attrs, :affected_reference_keys),
        limit: AudienceDependencies.reference_keys(references),
        remediation: @indeterminate_remediation
      }
    )
    |> maybe_add_indeterminate(
      dependency_blockers?(dependency_entries, attrs),
      %{
        code: "blast_radius_unresolved_dependency_truth",
        observed: "dependency_blockers",
        limit: "clear_dependency_blockers",
        remediation: @indeterminate_remediation
      }
    )
    |> maybe_add_indeterminate(
      unavailable_contexts?(references),
      %{
        code: "blast_radius_indeterminate",
        observed: "unavailable_rollout_or_lifecycle_context",
        limit: "resolved_context",
        remediation: @indeterminate_remediation
      }
    )
    |> maybe_add_indeterminate(
      hidden_reference_count > 0,
      %{
        code: "blast_radius_indeterminate",
        observed: hidden_reference_count,
        limit: 0,
        remediation: @indeterminate_remediation
      }
    )
  end

  defp maybe_add_indeterminate(reasons, true, reason), do: reasons ++ [reason]
  defp maybe_add_indeterminate(reasons, false, _reason), do: reasons

  defp blank_fingerprint?(attrs) do
    fingerprint = normalize_string(Map.get(attrs, :preview_fingerprint))
    fingerprint in [nil, ""]
  end

  defp schema_mismatch?(version) do
    version != ImpactPreview.schema_version()
  end

  defp reference_keys_mismatch?(attrs, references) do
    command_keys = normalize_string_list(Map.get(attrs, :affected_reference_keys))
    preview_keys = AudienceDependencies.reference_keys(references)

    references != [] and command_keys != [] and command_keys != preview_keys
  end

  defp dependency_blockers?(entries, _attrs) when entries == [], do: false

  defp dependency_blockers?(entries, attrs) do
    scope = %{
      tenant_key: normalize_string(Map.get(attrs, :tenant_key)),
      audiences: Map.get(attrs, :audiences) || %{}
    }

    entries
    |> DependencyValidator.validate(scope)
    |> DependencyValidator.blockers?()
  end

  defp unavailable_contexts?(references) do
    Enum.any?(references, fn reference ->
      case normalize_string(Map.get(reference, :rule_strategy)) do
        "segment_match" ->
          false

        _other ->
          rollout_unavailable?(Map.get(reference, :rollout_context)) or
            lifecycle_unavailable?(Map.get(reference, :lifecycle_context))
      end
    end)
  end

  defp rollout_unavailable?(%{available?: false}), do: true
  defp rollout_unavailable?(%{"available?" => false}), do: true
  defp rollout_unavailable?(_), do: false

  defp lifecycle_unavailable?(%{available?: false}), do: true
  defp lifecycle_unavailable?(%{"available?" => false}), do: true
  defp lifecycle_unavailable?(_), do: false

  defp protected_environment?(attrs, opts) do
    case Keyword.get(opts, :protected_environment?) do
      value when is_boolean(value) -> value
      _ -> Compare.protected_target?(Map.get(attrs, :environment_key))
    end
  end

  defp profile_for(opts) do
    case Keyword.get(opts, :threshold_profile, :default) do
      :default -> @default_profile
      profile when is_map(profile) -> Map.merge(@default_profile, profile)
      _other -> @default_profile
    end
  end

  defp normalize_references(references) when is_list(references) do
    Enum.reject(references, &(normalize_string(Map.get(&1, :reference_key)) in [nil, ""]))
  end

  defp normalize_references(_), do: []

  defp distinct_flag_count(references) do
    references
    |> Enum.map(fn reference ->
      normalize_string(Map.get(reference, :flag_key) || Map.get(reference, "flag_key"))
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp rollout_hints(references) do
    references
    |> Enum.map(&Map.get(&1, :rollout_context))
    |> Enum.reject(&is_nil/1)
  end

  defp lifecycle_hints(references) do
    references
    |> Enum.map(&Map.get(&1, :lifecycle_context))
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)

  defp normalize_string(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end

  defp normalize_string(_value), do: nil

  defp normalize_string_list(nil), do: []

  defp normalize_string_list(values) when is_list(values),
    do: Enum.map(values, &normalize_string/1)

  defp fetch(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
