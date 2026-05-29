defmodule RulesteadDemoWeb.FlagStreamController do
  @moduledoc false

  use RulesteadDemoWeb, :controller

  alias Rulestead.Error
  alias Rulestead.Runtime.{Cache, Config, Notifier}
  alias RulesteadDemo

  def preflight(conn, _params), do: send_resp(conn, 204, "")

  def show(conn, params) do
    with {:ok, environment_key} <- fetch_environment_key(params),
         :ok <- subscribe_runtime_refresh(),
         {:ok, conn} <- open_stream(conn),
         {:ok, snapshot_version} <- snapshot_version(environment_key),
         {:ok, conn} <- configuration_changed(conn, environment_key, snapshot_version),
         {:ok, conn} <- stream_updates(conn, environment_key, snapshot_version) do
      conn
    else
      {:error, %Error{} = error} ->
        conn
        |> put_status(error.plug_status || 422)
        |> json(%{error: %{code: to_string(error.type), message: error.message}})

      {:error, conn} ->
        conn
    end
  end

  defp fetch_environment_key(params) do
    case blank_to_nil(params["env"]) do
      environment_key when is_binary(environment_key) ->
        if environment_key in configured_environment_keys() do
          {:ok, environment_key}
        else
          {:error,
           Error.new(
             domain: :evaluation,
             type: :environment_not_found,
             message: "env must be one of the configured demo environments",
             plug_status: 422
           )}
        end

      _other ->
        {:error,
         Error.new(
           domain: :evaluation,
           type: :invalid_command,
           message: "env is required",
           plug_status: 422
         )}
    end
  end

  defp open_stream(conn) do
    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache, no-transform")
      |> put_resp_header("x-accel-buffering", "no")
      |> send_chunked(200)

    {:ok, conn}
  rescue
    Plug.Conn.AlreadySentError -> {:error, conn}
  end

  defp snapshot_version(environment_key) do
    case Cache.runtime_metadata(environment_key) do
      {:ok, %{snapshot_version: version}} when is_integer(version) -> {:ok, version}
      {:ok, _metadata} -> {:ok, 0}
      {:error, _error} -> {:ok, 0}
    end
  end

  defp subscribe_runtime_refresh do
    Notifier.subscribe(
      Config.notifier(),
      pubsub: Config.pubsub(),
      pubsub_topic: Config.pubsub_topic()
    )
  end

  defp configuration_changed(conn, environment_key, version) do
    payload =
      Jason.encode!(%{
        type: "configuration-changed",
        environmentKey: environment_key,
        snapshotVersion: version
      })

    with {:ok, conn} <- chunk(conn, "event: configuration-changed\n"),
         {:ok, conn} <- chunk(conn, "data: #{payload}\n\n") do
      {:ok, conn}
    else
      {:error, _reason} -> {:error, conn}
    end
  end

  defp stream_updates(conn, environment_key, current_version) do
    receive do
      {:rulestead_runtime_refresh,
       %{environment_key: ^environment_key, snapshot_version: snapshot_version}}
      when snapshot_version > current_version ->
        with {:ok, conn} <- configuration_changed(conn, environment_key, snapshot_version) do
          stream_updates(conn, environment_key, snapshot_version)
        end

      {:rulestead_runtime_refresh, _other_notice} ->
        stream_updates(conn, environment_key, current_version)
    after
      25_000 ->
        {:ok, conn}
    end
  end

  defp configured_environment_keys do
    RulesteadDemo.demo_environment_keys()
  end

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
