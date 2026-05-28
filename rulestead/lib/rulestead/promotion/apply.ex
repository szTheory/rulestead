# credo:disable-for-this-file
defmodule Rulestead.Promotion.Apply do
  @moduledoc false

  alias Rulestead.{Promotion.Compare, StoreError}
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.{DependencyInventory, DependencyValidator}

  @spec apply(Command.ApplyPromotion.t()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def apply(%Command.ApplyPromotion{} = command) do
    with :ok <- validate(command) do
      store = Application.fetch_env!(:rulestead, :store)
      store.apply_promotion(command)
    end
  end

  @spec validate(Command.ApplyPromotion.t(), keyword()) :: :ok | {:error, Rulestead.Error.t()}
  def validate(%Command.ApplyPromotion{} = command, opts \\ []) do
    with :ok <- validate_schema_version(command),
         {:ok, compare} <- revalidate_compare(command),
         :ok <- validate_with_compare(command, compare, opts) do
      :ok
    end
  end

  @spec validate_governed(Command.ApplyPromotion.t()) :: :ok | {:error, Rulestead.Error.t()}
  def validate_governed(%Command.ApplyPromotion{} = command) do
    validate(command, allow_protected_target?: true)
  end

  @spec validate_governed_snapshot(Command.ApplyPromotion.t(), map() | nil) ::
          :ok | {:error, Rulestead.Error.t()}
  def validate_governed_snapshot(%Command.ApplyPromotion{} = command, compare \\ nil) do
    with :ok <- validate_schema_version(command),
         {:ok, compare} <- fetch_compare_for_governed_snapshot(command, compare),
         :ok <- validate_dependency_findings(command, compare) do
      :ok
    end
  end

  @spec validate_with_compare(Command.ApplyPromotion.t(), map(), keyword()) ::
          :ok | {:error, Rulestead.Error.t()}
  def validate_with_compare(%Command.ApplyPromotion{} = command, compare, opts \\ []) do
    validate_compare_payload(command, compare, opts)
  end

  @spec validate_live_dependencies(Command.ApplyPromotion.t(), map() | [map()], keyword()) ::
          :ok | {:error, Rulestead.Error.t()}
  def validate_live_dependencies(%Command.ApplyPromotion{} = command, audiences, opts \\ []) do
    findings =
      DependencyValidator.validate(
        %{
          tenant_key: command.tenant_key,
          audiences: normalize_dependency_audiences(audiences)
        },
        promotion_dependency_entries(command)
      )
      |> DependencyValidator.sort_findings()

    if DependencyValidator.blockers?(findings) do
      {:error,
       dependency_validation_error(
         findings,
         command,
         Keyword.get(opts, :message, "promotion apply blocked by dependency validation")
       )}
    else
      :ok
    end
  end

  @spec normalize_proposed_target_bundle(map() | nil) :: map()
  def normalize_proposed_target_bundle(nil), do: %{}

  def normalize_proposed_target_bundle(bundle) when is_map(bundle) do
    bundle
    |> Enum.map(fn {flag_key, state} ->
      canonical_state =
        state
        |> Compare.authored_state()
        |> normalize_map()

      {to_string(flag_key), canonical_state}
    end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Map.new()
  end

  def normalize_proposed_target_bundle(_bundle), do: %{}

  defp validate_schema_version(%Command.ApplyPromotion{compare_schema_version: version}) do
    if version == Compare.schema_version() do
      :ok
    else
      {:error, StoreError.invalid_command("promotion compare schema version is unsupported")}
    end
  end

  defp revalidate_compare(command) do
    Compare.compare(
      Command.CompareEnvironments.new(
        command.source_environment_key,
        command.target_environment_key,
        flag_keys: command.flag_keys,
        compare_token: command.compare_token,
        tenant_key: command.tenant_key
      )
    )
  end

  defp fetch_compare_for_governed_snapshot(_command, compare) when is_map(compare),
    do: {:ok, compare}

  defp fetch_compare_for_governed_snapshot(command, nil), do: revalidate_compare(command)

  defp validate_compare_payload(command, compare, opts) do
    allow_protected_target? = Keyword.get(opts, :allow_protected_target?, false)

    cond do
      dependency_drift?(command, compare) ->
        {:error, StoreError.invalid_command("promotion compare dependency closure drifted")}

      dependency_blocker_findings(compare) != [] ->
        {:error,
         dependency_validation_error(
           dependency_blocker_findings(compare),
           command,
           "promotion apply blocked by dependency validation"
         )}

      stale_preview?(command, compare) ->
        {:error, StoreError.invalid_command("promotion compare preview is stale")}

      Compare.protected_target?(command.target_environment_key) and not allow_protected_target? ->
        {:error, StoreError.invalid_command("promotion to protected targets requires governance")}

      blocker_findings?(compare) ->
        {:error, StoreError.invalid_command("promotion compare preview has blocker findings")}

      true ->
        :ok
    end
  end

  defp stale_preview?(command, compare) do
    command.compare_schema_version != compare.compare_schema_version or
      command.compare_token != compare.compare_token or
      command.source_fingerprint != compare.source_fingerprint or
      command.target_fingerprint != compare.target_fingerprint or
      Enum.any?(all_findings(compare), &(&1[:class] == :staleness_conflict))
  end

  defp dependency_drift?(command, compare) do
    sort_strings(command.dependency_closure_keys) != sort_strings(compare.dependency_closure_keys)
  end

  defp validate_dependency_findings(command, compare) do
    findings = dependency_blocker_findings(compare)

    if findings == [] do
      :ok
    else
      {:error,
       dependency_validation_error(
         findings,
         command,
         "promotion apply blocked by dependency validation"
       )}
    end
  end

  defp dependency_blocker_findings(compare) do
    compare
    |> Map.get(:dependency_findings, [])
    |> Enum.map(&normalize_dependency_finding/1)
    |> DependencyValidator.sort_findings()
    |> Enum.filter(fn finding -> finding.severity == :blocker end)
  end

  defp blocker_findings?(compare) do
    Enum.any?(all_findings(compare), fn finding ->
      finding[:severity] == :blocker and finding[:class] != :staleness_conflict
    end)
  end

  defp all_findings(compare) do
    compare_findings = Map.get(compare, :findings, [])

    flag_findings =
      compare
      |> Map.get(:flags, [])
      |> Enum.flat_map(&Map.get(&1, :findings, []))

    compare_findings ++ flag_findings
  end

  defp sort_strings(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  defp sort_strings(_values), do: []

  defp promotion_dependency_entries(%Command.ApplyPromotion{} = command) do
    command.proposed_target_bundle
    |> Enum.flat_map(fn {flag_key, state} ->
      active_ruleset = Map.get(state, "active_ruleset", Map.get(state, :active_ruleset, %{}))

      active_ruleset
      |> Map.get("rules", Map.get(active_ruleset, :rules, []))
      |> Enum.flat_map(fn rule ->
        if normalize_string(Map.get(rule, "strategy") || Map.get(rule, :strategy)) ==
             "segment_match" do
          metadata = Map.get(rule, "metadata") || Map.get(rule, :metadata) || %{}

          [
            DependencyInventory.normalize_entry(%{
              environment_key: command.target_environment_key,
              tenant_key: command.tenant_key || "global",
              audience_key: Map.get(rule, "audience_key") || Map.get(rule, :audience_key),
              flag_key: to_string(flag_key),
              ruleset_version:
                Map.get(active_ruleset, "version") || Map.get(active_ruleset, :version),
              rule_key: Map.get(rule, "key") || Map.get(rule, :key),
              ruleset_status: "published",
              rollout_context: Map.get(rule, "rollout") || Map.get(rule, :rollout) || %{},
              lifecycle_context: %{available?: false},
              visibility: %{status: "visible"},
              reference_count: 1,
              hidden_reference_count: 0,
              audience_schema_version:
                Map.get(rule, "audience_schema_version") ||
                  Map.get(rule, :audience_schema_version) ||
                  Map.get(metadata, "audience_schema_version") ||
                  Map.get(metadata, :audience_schema_version),
              audience_version_hash:
                Map.get(rule, "audience_version_hash") ||
                  Map.get(rule, :audience_version_hash) ||
                  Map.get(metadata, "audience_version_hash") ||
                  Map.get(metadata, :audience_version_hash)
            })
          ]
        else
          []
        end
      end)
    end)
    |> Enum.reject(&(&1.malformed? or is_nil(&1.audience_key)))
    |> DependencyInventory.sort_entries()
  end

  defp normalize_dependency_audiences(audiences) when is_map(audiences) do
    Map.new(audiences, fn {key, audience} ->
      normalized_key = normalize_string(key)
      normalized_audience = audience || %{}

      {normalized_key,
       %{
         key: normalized_key,
         tenant_key:
           normalize_string(
             Map.get(normalized_audience, :tenant_key) ||
               Map.get(normalized_audience, "tenant_key")
           ),
         archived_at:
           Map.get(normalized_audience, :archived_at) ||
             Map.get(normalized_audience, "archived_at"),
         definition:
           Map.get(normalized_audience, :definition) || Map.get(normalized_audience, "definition")
       }}
    end)
  end

  defp normalize_dependency_audiences(audiences) when is_list(audiences) do
    audiences
    |> Enum.reduce(%{}, fn audience, acc ->
      key = normalize_string(Map.get(audience, :key) || Map.get(audience, "key"))

      if is_nil(key) do
        acc
      else
        Map.put(acc, key, %{
          key: key,
          tenant_key:
            normalize_string(Map.get(audience, :tenant_key) || Map.get(audience, "tenant_key")),
          archived_at: Map.get(audience, :archived_at) || Map.get(audience, "archived_at"),
          definition: Map.get(audience, :definition) || Map.get(audience, "definition")
        })
      end
    end)
  end

  defp normalize_dependency_audiences(_audiences), do: %{}

  defp normalize_dependency_finding(finding) do
    %{
      code: normalize_string(Map.get(finding, :code) || Map.get(finding, "code")),
      severity: normalize_severity(Map.get(finding, :severity) || Map.get(finding, "severity")),
      message: normalize_string(Map.get(finding, :message) || Map.get(finding, "message")),
      environment_key:
        normalize_string(
          Map.get(finding, :environment_key) || Map.get(finding, "environment_key")
        ),
      tenant_key:
        normalize_string(Map.get(finding, :tenant_key) || Map.get(finding, "tenant_key")),
      audience_key:
        normalize_string(Map.get(finding, :audience_key) || Map.get(finding, "audience_key")),
      flag_key: normalize_string(Map.get(finding, :flag_key) || Map.get(finding, "flag_key")),
      ruleset_version: Map.get(finding, :ruleset_version) || Map.get(finding, "ruleset_version"),
      rule_key: normalize_string(Map.get(finding, :rule_key) || Map.get(finding, "rule_key"))
    }
  end

  defp normalize_severity(:blocker), do: :blocker
  defp normalize_severity("blocker"), do: :blocker
  defp normalize_severity(value), do: value

  defp dependency_validation_error(findings, command, message) do
    error = DependencyValidator.to_error(findings, message: message)

    serialized_findings =
      Enum.map(findings, fn finding ->
        %{
          code: finding.code,
          severity: finding.severity,
          message: finding.message,
          environment_key: finding.environment_key,
          tenant_key: finding.tenant_key,
          audience_key: finding.audience_key,
          flag_key: finding.flag_key,
          ruleset_version: finding.ruleset_version,
          rule_key: finding.rule_key
        }
      end)

    metadata =
      (error.metadata || %{})
      |> Map.merge(%{
        fail_closed: true,
        source_environment_key: command.source_environment_key,
        target_environment_key: command.target_environment_key,
        tenant_key: command.tenant_key,
        dependency_findings: serialized_findings
      })

    %{error | metadata: metadata}
  end

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(value), do: value |> to_string() |> normalize_string()

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
      {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
      {key, value} -> {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_map(_value), do: %{}

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(nil), do: nil
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value
end
