defmodule RulesteadDemoWeb.FlagController do
  @moduledoc false

  use RulesteadDemoWeb, :controller

  alias Rulestead.{Context, Error, Runtime}
  alias RulesteadDemo
  alias RulesteadDemoWeb.FlagJSON

  def preflight(conn, _params), do: send_resp(conn, 204, "")

  def show(conn, params) do
    with {:ok, environment_key} <- fetch_environment_key(params),
         {:ok, flag_key} <- fetch_required_param(params, "flag_key"),
         context <- request_context(params, environment_key),
         {:ok, result} <- Runtime.evaluate(environment_key, flag_key, context) do
      json(conn, FlagJSON.evaluation(result, environment_key))
    else
      {:error, %Error{} = error} ->
        conn
        |> put_status(error_status(error))
        |> json(FlagJSON.error(error))
    end
  end

  @doc false
  def fetch_environment_key(params) do
    with {:ok, environment_key} <- fetch_required_param(params, "env"),
         true <- environment_key in configured_environment_keys() do
      {:ok, environment_key}
    else
      false ->
        {:error,
         Error.new(
           domain: :evaluation,
           type: :environment_not_found,
           message: "env must be one of the configured demo environments",
           plug_status: 422
         )}

      {:error, _error} = error ->
        error
    end
  end

  @doc false
  def fetch_required_param(params, key) do
    params[key]
    |> blank_to_nil()
    |> case do
      value when is_binary(value) ->
        {:ok, value}

      _other ->
        {:error,
         Error.new(
           domain: :evaluation,
           type: :invalid_command,
           message: "#{key} is required",
           plug_status: 422
         )}
    end
  end

  @doc false
  def request_context(params, environment_key) do
    targeting_key = blank_to_nil(params["targeting_key"])

    Context.new(
      actor: actor_from_targeting_key(targeting_key),
      targeting_key: targeting_key,
      environment: environment_key,
      attributes: custom_attributes(params)
    )
  end

  defp actor_from_targeting_key(nil), do: nil
  defp actor_from_targeting_key(targeting_key), do: %{key: targeting_key}

  defp custom_attributes(params) do
    params
    |> Map.drop(["env", "flag_key", "targeting_key"])
    |> Enum.reject(fn {_key, value} -> blank_to_nil(value) == nil end)
    |> Map.new()
  end

  defp configured_environment_keys do
    RulesteadDemo.demo_environment_keys()
  end

  @doc false
  def error_status(%Error{plug_status: status}) when is_integer(status), do: status
  def error_status(%Error{type: :flag_not_found}), do: 404
  def error_status(%Error{type: :environment_not_found}), do: 404
  def error_status(_error), do: 422

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
  defp blank_to_nil(value), do: value
end
