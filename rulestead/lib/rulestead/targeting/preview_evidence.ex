defmodule Rulestead.Targeting.PreviewEvidence do
  @moduledoc false

  alias Rulestead.StoreError
  alias Rulestead.Targeting.PreviewEvidence.{Limits, Query}

  @type result ::
          map()
          | keyword()
          | {:ok, map() | keyword()}
          | {:error, atom() | String.t()}

  @callback resolve(query :: map()) :: result()

  @spec resolve(map() | keyword(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def resolve(query, opts \\ []) do
    query = Query.new(query)

    case resolver_module(opts) do
      nil ->
        {:ok, %{}}

      resolver when is_atom(resolver) ->
        if function_exported?(resolver, :resolve, 1) do
          normalize_resolver_result(apply(resolver, :resolve, [query]), opts)
        else
          resolver_failed(:invalid_resolver)
        end
    end
  rescue
    _ -> resolver_failed(:invalid_provider_response)
  end

  @spec resolver_module(keyword()) :: module() | nil
  def resolver_module(opts \\ []) do
    Keyword.get(opts, :resolver) ||
      Application.get_env(:rulestead, :preview_evidence_resolver)
  end

  defp normalize_resolver_result({:ok, evidence}, opts) when is_map(evidence) or is_list(evidence) do
    evidence |> Map.new() |> normalize_evidence_map(opts)
  end

  defp normalize_resolver_result({:error, reason}, _opts), do: resolver_failed(reason)

  defp normalize_resolver_result(evidence, opts) when is_map(evidence) or is_list(evidence) do
    evidence |> Map.new() |> normalize_evidence_map(opts)
  end

  defp normalize_evidence_map(%{} = evidence, opts) do
    cond do
      map_size(evidence) == 0 ->
        Limits.validate_and_redact(%{samples: [], impression_summary: %{}}, opts)

      true ->
        Limits.validate_and_redact(evidence, opts)
    end
  end

  defp resolver_failed(reason) do
    code =
      case reason do
        :denied -> "preview_evidence_policy_denied"
        _ -> "preview_evidence_resolver_failed"
      end

    {:error,
     StoreError.invalid_command("preview evidence resolver failed",
       metadata: %{code: code, reason: reason}
     )}
  end
end
