defmodule Rulestead.Webhooks.CodeRefsPlugTest do
  use Rulestead.RepoCase
  use Plug.Test

  alias Rulestead.Webhooks.CodeRefsPlug
  alias Rulestead.Repo
  alias Rulestead.CodeRefs.CodeReference

  @opts CodeRefsPlug.init(secret: "test_secret_token")

  test "accepts valid JSON payload with valid token and returns 200" do
    payload = Jason.encode!(%{
      references: [
        %{file: "lib/foo.ex", line: 12, flag_key: "flag_1"},
        %{file: "lib/bar.ex", line: 42, flag_key: "flag_2"}
      ]
    })

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "ok"
    assert Jason.decode!(conn.resp_body)["count"] == 2

    assert Repo.aggregate(CodeReference, :count) == 2
  end

  test "rejects requests with missing/invalid tokens with 401" do
    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", "{}")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 401

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", "{}")
      |> put_req_header("authorization", "Bearer wrong_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 401
  end

  test "validates the shape of the incoming JSON to prevent malformed data insertion" do
    payload = Jason.encode!(%{
      references: [
        %{file: 123, line: "not an int", flag_key: nil},
        %{file: "lib/foo.ex", line: 12, flag_key: "flag_1"}
      ]
    })

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["count"] == 1
    assert Repo.aggregate(CodeReference, :count) == 1

    bad_payload = Jason.encode!(%{wrong_shape: true})

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", bad_payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 400
  end
end
