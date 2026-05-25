defmodule Rulestead.Promotion.Apply do
  @moduledoc false

  alias Rulestead.{Promotion.Compare, StoreError}
  alias Rulestead.Store.Command

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

  @spec validate_governed_snapshot(Command.ApplyPromotion.t()) :: :ok | {:error, Rulestead.Error.t()}
  def validate_governed_snapshot(%Command.ApplyPromotion{} = command) do
    validate_schema_version(command)
  end

  @spec validate_with_compare(Command.ApplyPromotion.t(), map(), keyword()) ::
          :ok | {:error, Rulestead.Error.t()}
  def validate_with_compare(%Command.ApplyPromotion{} = command, compare, opts \\ []) do
    validate_compare_payload(command, compare, opts)
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

  defp validate_compare_payload(command, compare, opts) do
    allow_protected_target? = Keyword.get(opts, :allow_protected_target?, false)

    cond do
      stale_preview?(command, compare) ->
        {:error, StoreError.invalid_command("promotion compare preview is stale")}

      dependency_drift?(command, compare) ->
        {:error, StoreError.invalid_command("promotion compare dependency closure drifted")}

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
