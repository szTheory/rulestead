defmodule RulesteadDemoWeb.ExplainController do
  @moduledoc false

  use RulesteadDemoWeb, :controller

  alias Rulestead.{Error, Runtime}
  alias RulesteadDemoWeb.{ExplainJSON, FlagController}

  def preflight(conn, _params), do: send_resp(conn, 204, "")

  def show(conn, params) do
    with {:ok, environment_key} <- FlagController.fetch_environment_key(params),
         {:ok, flag_key} <- FlagController.fetch_required_param(params, "flag_key"),
         context <- FlagController.request_context(params, environment_key),
         {:ok, explanation} <- Runtime.explain(environment_key, flag_key, context),
         {:ok, result} <- Runtime.evaluate(environment_key, flag_key, context) do
      json(conn, ExplainJSON.explain(explanation, result, environment_key))
    else
      {:error, %Error{} = error} ->
        conn
        |> put_status(FlagController.error_status(error))
        |> json(ExplainJSON.error(error))
    end
  end
end
