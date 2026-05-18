defmodule Rulestead.Promotion.Compare do
  @moduledoc false

  alias Rulestead.Store.Command

  @schema_version 1
  @severity_rank %{blocker: 0, warning: 1, info: 2, in_sync: 3}

  @type finding :: %{
          severity: :blocker | :warning | :info,
          class: atom(),
          code: String.t()
        }

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec compare(Command.CompareEnvironments.t()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compare(%Command.CompareEnvironments{} = command) do
    store = Application.fetch_env!(:rulestead, :store)
    store.compare_environments(command)
  end

  @spec fingerprint(term()) :: String.t()
  def fingerprint(term) do
    "sha256:" <> hash_term(term)
  end

  @spec compare_token(map()) :: String.t()
  def compare_token(attrs) when is_map(attrs) do
    token_payload = %{
      schema_version: @schema_version,
      source_environment_key:
        normalize_string(attrs[:source_environment_key] || attrs["source_environment_key"]),
      target_environment_key:
        normalize_string(attrs[:target_environment_key] || attrs["target_environment_key"]),
      compared_flag_keys:
        normalize_string_list(attrs[:compared_flag_keys] || attrs["compared_flag_keys"]),
      dependency_closure_keys:
        normalize_string_list(attrs[:dependency_closure_keys] || attrs["dependency_closure_keys"]),
      source_fingerprint: attrs[:source_fingerprint] || attrs["source_fingerprint"],
      target_fingerprint: attrs[:target_fingerprint] || attrs["target_fingerprint"]
    }

    "cmp_" <> hash_term(token_payload)
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

  @spec new_result(map()) :: map()
  def new_result(attrs) when is_map(attrs) do
    flags = attrs[:flags] || attrs["flags"] || []
    findings = attrs[:findings] || attrs["findings"] || []

    all_findings =
      findings ++
        Enum.flat_map(flags, fn flag ->
          Map.get(flag, :findings, Map.get(flag, "findings", []))
        end)

    %{
      source_environment:
        attrs[:source_environment]
        |> Kernel.||(attrs["source_environment"])
        |> canonical_environment(),
      target_environment:
        attrs[:target_environment]
        |> Kernel.||(attrs["target_environment"])
        |> canonical_environment(),
      compare_token: attrs[:compare_token] || attrs["compare_token"],
      compare_schema_version: @schema_version,
      overall_status: overall_status(all_findings, flags),
      requested_flag_keys:
        normalize_string_list(attrs[:requested_flag_keys] || attrs["requested_flag_keys"]),
      dependency_closure_keys:
        normalize_string_list(attrs[:dependency_closure_keys] || attrs["dependency_closure_keys"]),
      source_fingerprint: attrs[:source_fingerprint] || attrs["source_fingerprint"],
      target_fingerprint: attrs[:target_fingerprint] || attrs["target_fingerprint"],
      findings: sort_findings(findings),
      flags: sort_flags(flags)
    }
  end

  @spec authored_state(map() | nil) :: map() | nil
  def authored_state(nil), do: nil

  def authored_state(payload) when is_map(payload) do
    %{
      flag:
        payload
        |> Map.get(:flag, Map.get(payload, "flag"))
        |> canonical_flag(),
      flag_environment:
        payload
        |> Map.get(:flag_environment, Map.get(payload, "flag_environment"))
        |> canonical_flag_environment(),
      active_ruleset:
        payload
        |> Map.get(:active_ruleset, Map.get(payload, "active_ruleset"))
        |> canonical_ruleset()
    }
  end

  @spec compare_projected(map()) :: map()
  def compare_projected(attrs) when is_map(attrs) do
    source_flags = attrs[:source_flags] || %{}
    target_flags = attrs[:target_flags] || %{}

    requested_flag_keys =
      normalize_string_list(attrs[:requested_flag_keys] || attrs["requested_flag_keys"])

    audiences = attrs[:audiences] || %{}

    scope_keys = scoped_flag_keys(requested_flag_keys, source_flags, target_flags)

    {flags, dependency_keys, top_findings} =
      Enum.reduce(scope_keys, {[], MapSet.new(), []}, fn flag_key,
                                                         {flags, dependency_keys, findings} ->
        source_payload = Map.get(source_flags, flag_key)
        target_payload = Map.get(target_flags, flag_key)
        source_state = authored_state(source_payload)
        target_state = authored_state(target_payload)
        proposed_target_state = if(source_state, do: source_state, else: nil)
        dependency_closure = dependency_closure_keys(source_payload)

        flag_findings =
          []
          |> maybe_add_missing_dependencies(flag_key, dependency_closure, audiences)
          |> maybe_add_archived_target_conflict(flag_key, target_state, source_state)
          |> maybe_add_missing_target_flag_environment(flag_key, source_state, target_state)
          |> maybe_add_operational_override(flag_key, target_state)
          |> maybe_add_protected_target_warning(
            flag_key,
            attrs[:target_environment] || attrs["target_environment"],
            source_state
          )
          |> maybe_add_unpublished_source_work(flag_key, source_payload)
          |> maybe_add_drift_findings(flag_key, source_state, target_state)
          |> maybe_add_target_only_drift(flag_key, source_state, target_state)
          |> sort_findings()

        changed_fields = changed_fields(source_state, target_state)

        flag_entry =
          if changed_fields != [] or flag_findings != [] do
            %{
              flag_key: flag_key,
              changed_fields: changed_fields,
              dependency_closure_keys: dependency_closure,
              findings: flag_findings,
              source_state: source_state,
              current_target_state: target_state,
              proposed_target_state: proposed_target_state,
              source_has_unpublished_drafts?: has_drafts?(source_payload)
            }
          end

        next_flags = if(flag_entry, do: [flag_entry | flags], else: flags)
        next_dependencies = Enum.reduce(dependency_closure, dependency_keys, &MapSet.put(&2, &1))

        {next_flags, next_dependencies, findings ++ flag_findings}
      end)

    dependency_closure_keys = dependency_keys |> MapSet.to_list() |> Enum.sort()
    source_fingerprint = fingerprint(fingerprint_basis(scope_keys, source_flags))
    target_fingerprint = fingerprint(fingerprint_basis(scope_keys, target_flags))

    compare_token =
      compare_token(%{
        source_environment_key:
          get_environment_key(attrs[:source_environment] || attrs["source_environment"]),
        target_environment_key:
          get_environment_key(attrs[:target_environment] || attrs["target_environment"]),
        compared_flag_keys: scope_keys,
        dependency_closure_keys: dependency_closure_keys,
        source_fingerprint: source_fingerprint,
        target_fingerprint: target_fingerprint
      })

    findings =
      case attrs[:compare_token] || attrs["compare_token"] do
        nil ->
          top_findings

        provided_token when provided_token == compare_token ->
          top_findings

        provided_token ->
          [
            finding(:blocker, :staleness_conflict, "compare_token_stale",
              message: "Compare preview is stale",
              provided_compare_token: provided_token,
              expected_compare_token: compare_token
            )
            | top_findings
          ]
      end

    new_result(%{
      source_environment: attrs[:source_environment] || attrs["source_environment"],
      target_environment: attrs[:target_environment] || attrs["target_environment"],
      requested_flag_keys: requested_flag_keys,
      compare_token: compare_token,
      flags: Enum.reverse(flags),
      findings: findings,
      dependency_closure_keys: dependency_closure_keys,
      source_fingerprint: source_fingerprint,
      target_fingerprint: target_fingerprint
    })
  end

  @spec dependency_closure_keys(map() | nil) :: [String.t()]
  def dependency_closure_keys(nil), do: []

  def dependency_closure_keys(payload) when is_map(payload) do
    payload
    |> authored_state()
    |> Map.get(:active_ruleset)
    |> case do
      nil ->
        []

      ruleset ->
        ruleset
        |> Map.get(:rules, Map.get(ruleset, "rules", []))
        |> Enum.flat_map(fn rule ->
          audience_key = Map.get(rule, :audience_key) || Map.get(rule, "audience_key")

          case normalize_string(audience_key) do
            nil -> []
            key -> ["audience:" <> key]
          end
        end)
        |> Enum.uniq()
        |> Enum.sort()
    end
  end

  @spec changed_fields(map() | nil, map() | nil) :: [String.t()]
  def changed_fields(source_state, target_state) do
    compared_sections = [
      {"flag", source_state && source_state.flag, target_state && target_state.flag},
      {"flag_environment", source_state && source_state.flag_environment,
       target_state && target_state.flag_environment},
      {"active_ruleset", source_state && source_state.active_ruleset,
       target_state && target_state.active_ruleset}
    ]

    compared_sections
    |> Enum.flat_map(fn {section, left, right} ->
      if normalize_term(left) == normalize_term(right), do: [], else: [section]
    end)
  end

  @spec protected_target?(String.t() | nil) :: boolean()
  def protected_target?(environment_key) do
    normalize_string(environment_key) in ["prod", "production"]
  end

  @spec normalize_string_list(nil | list()) :: [String.t()]
  def normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def normalize_string_list(_values), do: []

  @spec normalize_term(term()) :: term()
  def normalize_term(%DateTime{} = term), do: DateTime.to_iso8601(term)
  def normalize_term(%NaiveDateTime{} = term), do: NaiveDateTime.to_iso8601(term)
  def normalize_term(%Date{} = term), do: Date.to_iso8601(term)
  def normalize_term(%Time{} = term), do: Time.to_iso8601(term)
  def normalize_term(%_{} = term), do: term |> Map.from_struct() |> normalize_term()

  def normalize_term(%_{} = term) do
    term
    |> Map.from_struct()
    |> normalize_term()
  end

  def normalize_term(term) when is_map(term) do
    term
    |> Enum.map(fn {key, value} -> {normalize_term(key), normalize_term(value)} end)
    |> Enum.sort()
  end

  def normalize_term(term) when is_list(term), do: Enum.map(term, &normalize_term/1)
  def normalize_term(term) when is_atom(term), do: Atom.to_string(term)
  def normalize_term(term), do: term

  defp hash_term(term) do
    term
    |> normalize_term()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

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

  defp overall_status([], []), do: :in_sync

  defp overall_status(findings, _flags) do
    findings
    |> Enum.map(&Map.get(&1, :severity, :info))
    |> Enum.min_by(&Map.fetch!(@severity_rank, &1), fn -> :in_sync end)
  end

  defp sort_flags(flags) do
    Enum.sort_by(flags, fn flag ->
      severities = Enum.map(Map.get(flag, :findings, []), &Map.get(&1, :severity, :info))
      top_severity = Enum.min_by(severities, &Map.fetch!(@severity_rank, &1), fn -> :in_sync end)
      {Map.fetch!(@severity_rank, top_severity), Map.get(flag, :flag_key, "")}
    end)
  end

  defp sort_findings(findings) do
    Enum.sort_by(findings, fn finding ->
      {Map.fetch!(@severity_rank, Map.get(finding, :severity, :info)),
       Map.get(finding, :code, "")}
    end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp canonical_environment(nil), do: %{}

  defp canonical_environment(environment) do
    %{
      key: Map.get(environment, :key) || Map.get(environment, "key"),
      name: Map.get(environment, :name) || Map.get(environment, "name"),
      description: Map.get(environment, :description) || Map.get(environment, "description")
    }
  end

  defp canonical_flag(nil), do: nil

  defp canonical_flag(flag) do
    %{
      key: Map.get(flag, :key) || Map.get(flag, "key"),
      description: Map.get(flag, :description) || Map.get(flag, "description"),
      flag_type: Map.get(flag, :flag_type) || Map.get(flag, "flag_type"),
      value_type: Map.get(flag, :value_type) || Map.get(flag, "value_type"),
      default_value: Map.get(flag, :default_value) || Map.get(flag, "default_value"),
      owner: Map.get(flag, :owner) || Map.get(flag, "owner"),
      expected_expiration:
        Map.get(flag, :expected_expiration) || Map.get(flag, "expected_expiration"),
      permanent: Map.get(flag, :permanent) || Map.get(flag, "permanent"),
      tags: Map.get(flag, :tags) || Map.get(flag, "tags") || [],
      archived_at: Map.get(flag, :archived_at) || Map.get(flag, "archived_at")
    }
  end

  defp canonical_flag_environment(nil), do: nil

  defp canonical_flag_environment(flag_environment) do
    %{
      environment_key:
        Map.get(flag_environment, :environment_key) ||
          Map.get(flag_environment, "environment_key"),
      status: Map.get(flag_environment, :status) || Map.get(flag_environment, "status"),
      kill_switch_variant_key:
        Map.get(flag_environment, :kill_switch_variant_key) ||
          Map.get(flag_environment, "kill_switch_variant_key"),
      active_ruleset_version:
        Map.get(flag_environment, :active_ruleset_version) ||
          Map.get(flag_environment, "active_ruleset_version")
    }
  end

  defp canonical_ruleset(nil), do: nil

  defp canonical_ruleset(ruleset) do
    %{
      version: Map.get(ruleset, :version) || Map.get(ruleset, "version"),
      status: Map.get(ruleset, :status) || Map.get(ruleset, "status"),
      salt: Map.get(ruleset, :salt) || Map.get(ruleset, "salt"),
      metadata: Map.get(ruleset, :metadata) || Map.get(ruleset, "metadata") || %{},
      rules:
        ruleset
        |> Map.get(:rules, Map.get(ruleset, "rules", []))
        |> Enum.map(&canonical_rule/1)
    }
  end

  defp canonical_rule(rule) do
    %{
      key: Map.get(rule, :key) || Map.get(rule, "key"),
      name: Map.get(rule, :name) || Map.get(rule, "name"),
      description: Map.get(rule, :description) || Map.get(rule, "description"),
      strategy: Map.get(rule, :strategy) || Map.get(rule, "strategy"),
      value: Map.get(rule, :value) || Map.get(rule, "value") || %{},
      audience_id: Map.get(rule, :audience_id) || Map.get(rule, "audience_id"),
      audience_key: Map.get(rule, :audience_key) || Map.get(rule, "audience_key"),
      conditions:
        rule
        |> Map.get(:conditions, Map.get(rule, "conditions", []))
        |> Enum.map(&canonical_condition/1),
      variants:
        rule
        |> Map.get(:variants, Map.get(rule, "variants", []))
        |> Enum.map(&canonical_variant/1),
      rollout:
        rule
        |> Map.get(:rollout, Map.get(rule, "rollout"))
        |> canonical_rollout()
    }
  end

  defp canonical_condition(condition) do
    %{
      attribute: Map.get(condition, :attribute) || Map.get(condition, "attribute"),
      operator: Map.get(condition, :operator) || Map.get(condition, "operator"),
      value: Map.get(condition, :value) || Map.get(condition, "value")
    }
  end

  defp canonical_variant(variant) do
    %{
      key: Map.get(variant, :key) || Map.get(variant, "key"),
      value: Map.get(variant, :value) || Map.get(variant, "value"),
      weight: Map.get(variant, :weight) || Map.get(variant, "weight")
    }
  end

  defp canonical_rollout(nil), do: nil

  defp canonical_rollout(rollout) do
    %{
      bucket_by: Map.get(rollout, :bucket_by) || Map.get(rollout, "bucket_by"),
      percentage: Map.get(rollout, :percentage) || Map.get(rollout, "percentage"),
      salt: Map.get(rollout, :salt) || Map.get(rollout, "salt")
    }
  end

  defp scoped_flag_keys([], source_flags, target_flags) do
    (Map.keys(source_flags) ++ Map.keys(target_flags))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp scoped_flag_keys(requested_flag_keys, _source_flags, _target_flags),
    do: requested_flag_keys

  defp maybe_add_missing_dependencies(findings, _flag_key, [], _audiences), do: findings

  defp maybe_add_missing_dependencies(findings, flag_key, dependency_closure, audiences) do
    Enum.reduce(dependency_closure, findings, fn dependency_key, findings ->
      audience_key = String.replace_prefix(dependency_key, "audience:", "")

      case Map.get(audiences, audience_key) do
        nil ->
          [
            finding(:blocker, :missing_dependency, "missing_dependency",
              message: "Published authored state references a missing audience",
              flag_key: flag_key,
              dependency_key: dependency_key
            )
            | findings
          ]

        %{archived_at: archived_at} when not is_nil(archived_at) ->
          [
            finding(:blocker, :missing_dependency, "archived_dependency",
              message: "Published authored state references an archived audience",
              flag_key: flag_key,
              dependency_key: dependency_key
            )
            | findings
          ]

        _audience ->
          findings
      end
    end)
  end

  defp maybe_add_archived_target_conflict(
         findings,
         flag_key,
         %{flag_environment: %{status: :archived}},
         source_state
       )
       when not is_nil(source_state) do
    [
      finding(:blocker, :lifecycle_conflict, "archived_target_revive_required",
        message: "Target environment state is archived and would require an explicit revive path",
        flag_key: flag_key
      )
      | findings
    ]
  end

  defp maybe_add_archived_target_conflict(findings, _flag_key, _target_state, _source_state),
    do: findings

  defp maybe_add_missing_target_flag_environment(findings, flag_key, source_state, nil)
       when not is_nil(source_state) do
    [
      finding(:warning, :soft_mismatch, "missing_target_flag_environment",
        message: "Target environment is missing this flag environment row",
        flag_key: flag_key
      )
      | findings
    ]
  end

  defp maybe_add_missing_target_flag_environment(
         findings,
         _flag_key,
         _source_state,
         _target_state
       ),
       do: findings

  defp maybe_add_operational_override(findings, flag_key, %{
         flag_environment: %{kill_switch_variant_key: value}
       })
       when not is_nil(value) do
    [
      finding(:warning, :operational_override, "target_operational_override",
        message: "Target has an active operational override outside authored compare",
        flag_key: flag_key
      )
      | findings
    ]
  end

  defp maybe_add_operational_override(findings, _flag_key, _target_state), do: findings

  defp maybe_add_protected_target_warning(findings, flag_key, target_environment, source_state)
       when not is_nil(source_state) do
    if protected_target?(get_environment_key(target_environment)) do
      [
        finding(:warning, :governance_requirement, "protected_target_environment",
          message: "Target environment requires governed apply",
          flag_key: flag_key
        )
        | findings
      ]
    else
      findings
    end
  end

  defp maybe_add_protected_target_warning(
         findings,
         _flag_key,
         _target_environment,
         _source_state
       ),
       do: findings

  defp maybe_add_unpublished_source_work(findings, flag_key, source_payload) do
    if has_drafts?(source_payload) do
      [
        finding(:warning, :unpublished_source_work, "source_has_drafts",
          message: "Source has unpublished draft rulesets",
          flag_key: flag_key,
          draft_versions: draft_versions(source_payload)
        )
        | findings
      ]
    else
      findings
    end
  end

  defp maybe_add_drift_findings(findings, _flag_key, nil, _target_state), do: findings

  defp maybe_add_drift_findings(findings, flag_key, source_state, target_state) do
    if changed_fields(source_state, target_state) != [] and not is_nil(target_state) do
      [
        finding(:info, :drift_info, "target_drift",
          message: "Target authored state differs from source",
          flag_key: flag_key
        )
        | findings
      ]
    else
      findings
    end
  end

  defp maybe_add_target_only_drift(findings, flag_key, nil, target_state)
       when not is_nil(target_state) do
    [
      finding(:info, :drift_info, "target_only_flag",
        message: "Target has authored state outside the source compare set",
        flag_key: flag_key
      )
      | findings
    ]
  end

  defp maybe_add_target_only_drift(findings, _flag_key, _source_state, _target_state),
    do: findings

  defp fingerprint_basis(scope_keys, flags_by_key) do
    Enum.map(scope_keys, fn key ->
      {key, flags_by_key |> Map.get(key) |> authored_state(),
       flags_by_key |> Map.get(key) |> dependency_closure_keys()}
    end)
  end

  defp has_drafts?(nil), do: false

  defp has_drafts?(payload) do
    payload
    |> Map.get(:draft_rulesets, Map.get(payload, "draft_rulesets", []))
    |> case do
      [] -> false
      _ -> true
    end
  end

  defp draft_versions(nil), do: []

  defp draft_versions(payload) do
    payload
    |> Map.get(:draft_rulesets, Map.get(payload, "draft_rulesets", []))
    |> Enum.map(&(Map.get(&1, :version) || Map.get(&1, "version")))
    |> Enum.sort()
  end

  defp get_environment_key(nil), do: nil

  defp get_environment_key(environment),
    do: Map.get(environment, :key) || Map.get(environment, "key")

  defp normalize_string(nil), do: nil

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(value) when is_binary(value), do: value |> String.trim() |> empty_to_nil()
  defp normalize_string(value), do: value |> to_string() |> normalize_string()

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(value), do: value
end
