defmodule Rulestead.Targeting.DependencyValidator do
  @moduledoc false

  alias Rulestead.StoreError
  alias Rulestead.Targeting.DependencyInventory

  @supported_clause_operators ~w(
    equals
    eq
    neq
    in
    not_in
    gt
    lt
    gte
    lte
    regex
    exists
  )

  @typedoc false
  @type finding :: %{
          code: String.t(),
          severity: :blocker,
          message: String.t(),
          environment_key: String.t() | nil,
          tenant_key: String.t() | nil,
          audience_key: String.t() | nil,
          flag_key: String.t() | nil,
          ruleset_version: pos_integer() | nil,
          rule_key: String.t() | nil
        }

  @type scope :: %{
          optional(:tenant_key) => String.t() | nil,
          optional(:expected_reference_keys) => [String.t()],
          optional(:stale_reference_keys) => [String.t()]
        }

  @spec validate(scope(), [map()]) :: [finding()]
  @spec validate([map()], map() | keyword()) :: [finding()]
  def validate(scope, entries) when is_map(scope) and is_list(entries) do
    do_validate(scope, entries)
  end

  def validate(entries, opts) when is_list(entries) and (is_map(opts) or is_list(opts)) do
    opts = normalize_opts(opts)

    scope = %{
      tenant_key: normalize_string(Map.get(opts, :tenant_key)),
      expected_reference_keys: optional_string_list(opts, :expected_reference_keys),
      stale_reference_keys: normalize_string_list(Map.get(opts, :stale_reference_keys))
    }

    do_validate(scope, entries)
  end

  def validate(_scope_or_entries, _entries_or_opts), do: []

  @spec blockers?([finding()]) :: boolean()
  def blockers?(findings) when is_list(findings) do
    Enum.any?(findings, fn finding ->
      case Map.get(finding, :severity) do
        :blocker -> true
        "blocker" -> true
        _other -> false
      end
    end)
  end

  def blockers?(_findings), do: false

  @spec sort_findings([finding()]) :: [finding()]
  def sort_findings(findings) when is_list(findings) do
    Enum.sort_by(findings, fn finding ->
      {severity_rank(finding[:severity]), normalize_string(finding[:code]) || "",
       semantic_tuple(finding)}
    end)
  end

  def sort_findings(_findings), do: []

  @spec to_error([finding()], keyword()) :: Rulestead.Error.t()
  def to_error(findings, opts \\ []) when is_list(findings) do
    sorted = sort_findings(findings)

    StoreError.invalid_command(
      Keyword.get(opts, :message, "dependency validation blocked the operation"),
      metadata: %{dependency_blocker_count: Enum.count(sorted)},
      details: Enum.map(sorted, &finding_detail/1),
      cause: sorted
    )
  end

  defp do_validate(scope, entries) do
    normalized_scope = normalize_scope(scope)
    normalized_entries = Enum.map(entries, &normalize_dependency_entry/1)

    audiences = index_audiences(scope)

    findings =
      normalized_entries
      |> Enum.flat_map(&entry_findings(&1, normalized_scope, audiences))
      |> Kernel.++(stale_findings(normalized_entries, normalized_scope))
      |> Kernel.++(tenant_findings(normalized_entries, normalized_scope))

    sort_findings(findings)
  end

  defp normalize_dependency_entry(entry) do
    entry_map = normalize_map(entry)

    DependencyInventory.normalize_entry(entry_map)
    |> Map.merge(%{
      audience_schema_version:
        Map.get(entry_map, :audience_schema_version) ||
          Map.get(entry_map, "audience_schema_version") ||
          Map.get(entry_map, :definition_schema_version) ||
          Map.get(entry_map, "definition_schema_version"),
      audience_version_hash:
        Map.get(entry_map, :audience_version_hash) ||
          Map.get(entry_map, "audience_version_hash") ||
          Map.get(entry_map, :definition_version_hash) ||
          Map.get(entry_map, "definition_version_hash") ||
          Map.get(entry_map, :version_hash) ||
          Map.get(entry_map, "version_hash")
    })
  end

  defp normalize_scope(scope) do
    scope = normalize_opts(scope)

    %{
      tenant_key: normalize_string(Map.get(scope, :tenant_key)),
      expected_reference_keys: optional_string_list(scope, :expected_reference_keys),
      stale_reference_keys: normalize_string_list(Map.get(scope, :stale_reference_keys))
    }
  end

  defp index_audiences(scope) do
    audiences = Map.get(scope, :audiences) || Map.get(scope, "audiences") || %{}

    if is_map(audiences) do
      Map.new(audiences, fn {key, audience} -> {normalize_string(key), normalize_map(audience)} end)
    else
      %{}
    end
  end

  defp entry_findings(entry, scope, audiences) do
    audience = Map.get(audiences, entry.audience_key)

    []
    |> maybe_add_missing_reference(entry, audience)
    |> maybe_add_archived_reference(entry, audience)
    |> maybe_add_incompatible_reference(entry, audience, scope)
  end

  defp maybe_add_missing_reference(findings, entry, nil) do
    [
      new_finding(
        "missing_reference",
        entry,
        "referenced audience is missing"
      )
      | findings
    ]
  end

  defp maybe_add_missing_reference(findings, _entry, _audience), do: findings

  defp maybe_add_archived_reference(findings, entry, audience) when is_map(audience) do
    archived_at = Map.get(audience, :archived_at) || Map.get(audience, "archived_at")

    if is_nil(archived_at) do
      findings
    else
      [
        new_finding(
          "archived_reference",
          entry,
          "referenced audience is archived"
        )
        | findings
      ]
    end
  end

  defp maybe_add_archived_reference(findings, _entry, _audience), do: findings

  defp maybe_add_incompatible_reference(findings, entry, audience, _scope) when is_map(audience) do
    case incompatible_reason(entry, audience) do
      nil ->
        findings

      reason ->
        [
          new_finding("incompatible_reference", entry, reason)
          | findings
        ]
    end
  end

  defp maybe_add_incompatible_reference(findings, _entry, _audience, _scope), do: findings

  defp incompatible_reason(entry, audience) do
    definition = Map.get(audience, :definition) || Map.get(audience, "definition")

    cond do
      not is_map(definition) ->
        # incompatible_reference includes non-map audience definitions.
        "incompatible reference: audience definition is not a map"

      clause_shape_unsupported?(definition) ->
        # incompatible_reference includes unsupported clause/op shape.
        "incompatible reference: unsupported clause shape or unsupported clause operator"

      schema_version_mismatch?(entry, definition) ->
        # incompatible_reference includes schema version mismatches when metadata is present.
        "incompatible reference: schema version mismatch"

      version_hash_mismatch?(entry, definition) ->
        # incompatible_reference includes version hash mismatches when metadata is present.
        "incompatible reference: version hash mismatch"

      true ->
        nil
    end
  end

  defp clause_shape_unsupported?(definition) do
    case clauses_for_definition(definition) do
      {:error, _reason} ->
        true

      {:ok, clauses} ->
        Enum.any?(clauses, fn
          clause when is_map(clause) ->
            operator = normalize_operator(clause)
            attribute = Map.get(clause, :attribute) || Map.get(clause, "attribute")

            is_nil(normalize_string(attribute)) or operator not in @supported_clause_operators

          _other ->
            true
        end)
    end
  end

  defp clauses_for_definition(definition) do
    clauses = Map.get(definition, :clauses) || Map.get(definition, "clauses")
    conditions = Map.get(definition, :conditions) || Map.get(definition, "conditions")

    cond do
      is_list(clauses) ->
        {:ok, clauses}

      is_list(conditions) ->
        {:ok, conditions}

      is_nil(clauses) and is_nil(conditions) ->
        {:ok, []}

      true ->
        {:error, :unsupported_clause_shape}
    end
  end

  defp schema_version_mismatch?(entry, definition) do
    expected = schema_version_from_entry(entry)

    case {expected, normalize_integer(schema_version_from_definition(definition))} do
      {nil, _current} -> false
      {expected_version, current_version} -> expected_version != current_version
    end
  end

  defp version_hash_mismatch?(entry, definition) do
    expected = version_hash_from_entry(entry)
    current = normalize_string(version_hash_from_definition(definition))

    case expected do
      nil -> false
      expected_hash -> expected_hash != current
    end
  end

  defp stale_findings(entries, scope) do
    stale_reference_keys =
      (scope.stale_reference_keys || [])
      |> MapSet.new()

    changed_reference_keys =
      case scope.expected_reference_keys do
        expected_reference_keys when is_list(expected_reference_keys) ->
          expected_reference_keys
          |> MapSet.new()
          |> MapSet.symmetric_difference(MapSet.new(Enum.map(entries, &reference_key/1)))
          |> MapSet.to_list()

        _other ->
          []
      end

    all_stale_reference_keys =
      stale_reference_keys
      |> MapSet.union(MapSet.new(changed_reference_keys))

    if MapSet.size(all_stale_reference_keys) == 0 do
      []
    else
      entries
      |> Enum.filter(&(reference_key(&1) in all_stale_reference_keys))
      |> Enum.map(fn entry ->
        new_finding(
          "stale_reference",
          entry,
          "dependency preview is stale for referenced audience"
        )
      end)
    end
  end

  defp tenant_findings(entries, scope) do
    command_tenant = normalize_string(scope.tenant_key)
    non_nil_tenants = entries |> Enum.map(&normalize_string(&1.tenant_key)) |> Enum.reject(&is_nil/1)
    unique_tenants = non_nil_tenants |> Enum.uniq() |> Enum.sort()

    cond do
      # tenant precedence:
      # (1) command tenant_key present -> every entry must match it.
      is_binary(command_tenant) ->
        entries
        |> Enum.filter(&(normalize_string(&1.tenant_key) != command_tenant))
        |> Enum.map(fn entry ->
          new_finding(
            "tenant_mismatch",
            entry,
            "dependency tenant does not match command scope tenant"
          )
        end)

      # tenant precedence:
      # (2) command tenant omitted + mixed non-nil tenant keys -> tenant_mismatch.
      command_tenant == nil and length(unique_tenants) > 1 ->
        entries
        |> Enum.filter(&(normalize_string(&1.tenant_key) in unique_tenants))
        |> Enum.map(fn entry ->
          new_finding(
            "tenant_mismatch",
            entry,
            "mixed tenant dependencies detected without explicit tenant scope"
          )
        end)

      # tenant precedence:
      # (3) both nil -> tenant-agnostic; no mismatch.
      true ->
        []
    end
  end

  defp new_finding(code, entry, message) do
    %{
      code: code,
      severity: :blocker,
      message: message,
      environment_key: entry.environment_key,
      tenant_key: entry.tenant_key,
      audience_key: entry.audience_key,
      flag_key: entry.flag_key,
      ruleset_version: entry.ruleset_version,
      rule_key: entry.rule_key
    }
  end

  defp severity_rank(:blocker), do: 0
  defp severity_rank("blocker"), do: 0
  defp severity_rank(:warning), do: 1
  defp severity_rank("warning"), do: 1
  defp severity_rank(_severity), do: 9

  defp semantic_tuple(finding) do
    {
      normalize_string(finding[:environment_key]) || "",
      normalize_string(finding[:tenant_key]) || "",
      normalize_string(finding[:flag_key]) || "",
      normalize_integer(finding[:ruleset_version]) || 0,
      normalize_string(finding[:rule_key]) || "",
      normalize_string(finding[:audience_key]) || ""
    }
  end

  defp finding_detail(finding) do
    %{
      code: normalize_string(finding[:code]),
      severity: normalize_string(finding[:severity]),
      message: normalize_string(finding[:message]),
      environment_key: normalize_string(finding[:environment_key]),
      tenant_key: normalize_string(finding[:tenant_key]),
      audience_key: normalize_string(finding[:audience_key]),
      flag_key: normalize_string(finding[:flag_key]),
      ruleset_version: normalize_integer(finding[:ruleset_version]),
      rule_key: normalize_string(finding[:rule_key])
    }
  end

  defp normalize_opts(opts) when is_list(opts), do: Map.new(opts)
  defp normalize_opts(opts) when is_map(opts), do: opts
  defp normalize_opts(_opts), do: %{}

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_value), do: %{}

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(value), do: value |> to_string() |> normalize_string()

  defp normalize_string_list(values) when is_list(values) do
    values
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_string_list(value), do: normalize_string_list(List.wrap(value))

  defp optional_string_list(map, key) do
    if Map.has_key?(map, key) or Map.has_key?(map, Atom.to_string(key)) do
      normalize_string_list(Map.get(map, key) || Map.get(map, Atom.to_string(key)))
    else
      nil
    end
  end

  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, ""} -> parsed
      _other -> nil
    end
  end

  defp normalize_integer(_value), do: nil

  defp normalize_operator(clause) do
    clause
    |> Map.get(:operator, Map.get(clause, "operator"))
    |> Kernel.||(Map.get(clause, :op, Map.get(clause, "op")))
    |> normalize_string()
  end

  defp schema_version_from_entry(entry) do
    normalize_integer(
      Map.get(entry, :audience_schema_version) ||
        Map.get(entry, "audience_schema_version")
    )
  end

  defp schema_version_from_definition(definition) do
    Map.get(definition, :schema_version) ||
      Map.get(definition, "schema_version") ||
      get_in(definition, [:metadata, :schema_version]) ||
      get_in(definition, ["metadata", "schema_version"])
  end

  defp version_hash_from_entry(entry) do
    normalize_string(
      Map.get(entry, :audience_version_hash) ||
        Map.get(entry, "audience_version_hash")
    )
  end

  defp version_hash_from_definition(definition) do
    Map.get(definition, :version_hash) ||
      Map.get(definition, "version_hash") ||
      get_in(definition, [:metadata, :version_hash]) ||
      get_in(definition, ["metadata", "version_hash"])
  end

  defp reference_key(entry) do
    "flag:#{entry.flag_key}:ruleset:#{entry.ruleset_version}:rule:#{entry.rule_key}"
  end
end
