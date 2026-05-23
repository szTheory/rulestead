defmodule Rulestead.Webhooks.CodeRefsPlug do
  @moduledoc false
  # Ingress endpoint for receiving code references from CI.

  import Plug.Conn
  alias Rulestead.Repo
  alias Rulestead.CodeRefs.CodeReference
  alias Rulestead.CodeRefs.ScanReceipt

  def init(opts), do: opts

  def call(conn, opts) do
    expected_token = Keyword.get(opts, :secret) || System.get_env("RULESTEAD_CI_TOKEN")

    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token == expected_token and not is_nil(expected_token) ->
        case read_body_json(conn) do
          {:ok, body, conn} ->
            handle_payload(conn, body)

          {:error, _reason, conn} ->
            send_json_resp(conn, 400, %{error: "invalid JSON"})
        end

      _ ->
        send_json_resp(conn, 401, %{error: "unauthorized"})
    end
  end

  defp handle_payload(conn, %{"references" => references}) when is_list(references) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    valid_references =
      references
      |> Enum.filter(&valid_reference?/1)
      |> Enum.map(fn ref ->
        %{
          id: Ecto.UUID.generate(),
          flag_key: ref["flag_key"],
          file: ref["file"],
          line: ref["line"],
          inserted_at: now,
          updated_at: now
        }
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:delete_old, CodeReference)
    |> Ecto.Multi.insert_all(:insert_new, CodeReference, valid_references)
    |> Ecto.Multi.insert(
      :scan_receipt,
      ScanReceipt.changeset(%ScanReceipt{}, %{
        received_at: now,
        reference_count: length(valid_references)
      })
    )
    |> Repo.transact()
    |> case do
      {:ok, _} ->
        send_json_resp(conn, 200, %{status: "ok", count: length(valid_references)})

      {:error, _, _, _} ->
        send_json_resp(conn, 500, %{error: "internal server error"})
    end
  end

  defp handle_payload(conn, _body) do
    send_json_resp(conn, 400, %{error: "invalid payload shape"})
  end

  defp valid_reference?(%{"flag_key" => flag_key, "file" => file, "line" => line})
       when is_binary(flag_key) and is_binary(file) and is_integer(line),
       do: true

  defp valid_reference?(_), do: false

  defp read_body_json(conn) do
    case conn.body_params do
      %Plug.Conn.Unfetched{} ->
        case read_body(conn) do
          {:ok, body, conn} ->
            case Jason.decode(body) do
              {:ok, decoded} -> {:ok, decoded, conn}
              {:error, _} -> {:error, :invalid_json, conn}
            end

          {:more, _, conn} ->
            {:error, :too_large, conn}

          {:error, reason} ->
            {:error, reason, conn}
        end

      params ->
        {:ok, params, conn}
    end
  end

  defp send_json_resp(conn, status, payload) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(payload))
    |> halt()
  end
end
