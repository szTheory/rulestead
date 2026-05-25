defmodule RulesteadDemoWeb.Plugs.DemoCors do
  @moduledoc false

  import Plug.Conn

  @allowed_origins MapSet.new([
                     "http://localhost:3000",
                     "http://127.0.0.1:3000"
                   ])

  def init(opts), do: opts

  def call(conn, _opts) do
    conn =
      conn
      |> put_resp_header("vary", "origin")
      |> maybe_put_cors_headers()

    if conn.method == "OPTIONS" do
      conn
      |> send_resp(204, "")
      |> halt()
    else
      conn
    end
  end

  defp maybe_put_cors_headers(conn) do
    case get_req_header(conn, "origin") do
      [origin | _rest] ->
        if MapSet.member?(@allowed_origins, origin) do
          conn
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("access-control-allow-methods", "GET, OPTIONS")
          |> put_resp_header("access-control-allow-headers", "content-type")
          |> put_resp_header("access-control-expose-headers", "cache-control, content-type")
        else
          conn
        end

      _other ->
        conn
    end
  end
end
