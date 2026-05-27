defmodule Rulestead.Governance.AudienceMutationChangeRequest do
  @moduledoc false

  alias Rulestead.Governance.BlastRadiusThreshold
  alias Rulestead.Promotion.Compare
  alias Rulestead.Store.Command
  alias Rulestead.StoreError
  alias Rulestead.Targeting.AudienceDependencies

  @required_command_keys ~w(audience_key operation preview_schema_version preview_fingerprint)

  @spec validate_submit(Command.SubmitChangeRequest.t(), map()) ::
          :ok | {:error, Rulestead.Error.t()}
  def validate_submit(%Command.SubmitChangeRequest{action: :apply_audience_mutation} = command, current_preview)
      when is_map(current_preview) do
    mutation_command = command.command || %{}

    with :ok <- ensure_protected_environment(command.environment_key),
         :ok <- ensure_required_command_keys(mutation_command),
         :ok <- ensure_matching_preview_fingerprint(mutation_command, current_preview),
         {:ok, assessment} <- assess_submission(command, current_preview),
         :ok <- ensure_above_threshold(assessment) do
      :ok
    end
  end

  def validate_submit(%Command.SubmitChangeRequest{action: action}, _current_preview) do
    {:error,
     StoreError.invalid_command(
       "audience mutation change request validation requires apply_audience_mutation action",
       metadata: %{action: Atom.to_string(action)}
     )}
  end

  @spec build_submission_metadata(map(), map()) :: map()
  def build_submission_metadata(assessment, current_preview) when is_map(assessment) and is_map(current_preview) do
    references = Map.get(current_preview, :affected_references) || Map.get(current_preview, "affected_references") || []

    %{
      "blast_radius_assessment" => normalize_assessment(assessment),
      "affected_reference_summary" => %{
        "reference_count" => length(references),
        "distinct_flag_count" => distinct_flag_count(references),
        "reference_keys" => AudienceDependencies.reference_keys(references),
        "rollout_hints" => rollout_hints(references),
        "lifecycle_hints" => lifecycle_hints(references)
      }
    }
  end

  defp ensure_protected_environment(environment_key) do
    if Compare.protected_target?(environment_key) do
      :ok
    else
      {:error,
       StoreError.invalid_command("audience change requests require a protected environment",
         metadata: %{environment_key: environment_key}
       )}
    end
  end

  defp ensure_required_command_keys(mutation_command) do
    missing =
      Enum.reject(@required_command_keys, fn key ->
        value = Map.get(mutation_command, key) || Map.get(mutation_command, String.to_atom(key))
        not is_nil(value) and value != ""
      end)

    if missing == [] do
      :ok
    else
      {:error,
       StoreError.invalid_command(
         "audience mutation change request is missing required command fields",
         metadata: %{missing_fields: missing}
       )}
    end
  end

  defp ensure_matching_preview_fingerprint(mutation_command, current_preview) do
    submitted =
      Map.get(mutation_command, "preview_fingerprint") ||
        Map.get(mutation_command, :preview_fingerprint)

    current =
      Map.get(current_preview, :preview_fingerprint) ||
        Map.get(current_preview, "preview_fingerprint")

    if submitted == current do
      :ok
    else
      {:error,
       StoreError.invalid_command(
         "audience preview fingerprint does not match current preview",
         metadata: %{
           preview_fingerprint: submitted,
           expected_preview_fingerprint: current
         }
       )}
    end
  end

  defp assess_submission(command, current_preview) do
    mutation_command = command.command || %{}
    references = Map.get(current_preview, :affected_references) || Map.get(current_preview, "affected_references") || []

    attrs = %{
      environment_key: command.environment_key,
      operation: fetch(mutation_command, "operation"),
      preview_fingerprint: fetch(mutation_command, "preview_fingerprint"),
      preview_schema_version: fetch(mutation_command, "preview_schema_version"),
      affected_references: references,
      affected_reference_keys: fetch(mutation_command, "affected_reference_keys"),
      tenant_key: fetch(mutation_command, "tenant_key")
    }

    BlastRadiusThreshold.assess(attrs)
  end

  defp ensure_above_threshold(%{verdict: :above_threshold}), do: :ok

  defp ensure_above_threshold(%{verdict: :below_threshold}) do
    {:error,
     StoreError.invalid_command(
       "Direct apply is allowed for this blast radius; do not submit a change request.",
       metadata: %{verdict: "below_threshold"}
     )}
  end

  defp ensure_above_threshold(%{verdict: :indeterminate, breach_reasons: breach_reasons}) do
    remediation =
      case List.first(breach_reasons || []) do
        %{remediation: message} when is_binary(message) -> message
        %{"remediation" => message} when is_binary(message) -> message
        _ -> "Blast radius cannot be evaluated safely."
      end

    {:error,
     StoreError.invalid_command(remediation,
       metadata: %{verdict: "indeterminate"},
       details: breach_reasons || []
     )}
  end

  defp normalize_assessment(assessment) do
    assessment
    |> Map.new(fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), normalize_value(value)}
      {key, value} -> {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_value(value) when is_map(value), do: normalize_assessment(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value

  defp distinct_flag_count(references) do
    references
    |> Enum.map(fn reference ->
      Map.get(reference, :flag_key) || Map.get(reference, "flag_key")
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp rollout_hints(references) do
    references
    |> Enum.map(&Map.get(&1, :rollout_context) || Map.get(&1, "rollout_context"))
    |> Enum.reject(&is_nil/1)
  end

  defp lifecycle_hints(references) do
    references
    |> Enum.map(&Map.get(&1, :lifecycle_context) || Map.get(&1, "lifecycle_context"))
    |> Enum.reject(&is_nil/1)
  end

  defp fetch(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_atom(key))
  end
end
