# credo:disable-for-this-file
defmodule Rulestead.Webhooks.CodeRefsPlugTest do
  use Rulestead.RepoCase
  import Plug.Conn
  import Plug.Test

  alias Rulestead.CodeRefs.ScanReceipt
  alias Rulestead.Webhooks.CodeRefsPlug
  alias Rulestead.CodeRefs.CodeReference
  alias Rulestead.Repo

  @opts CodeRefsPlug.init(secret: "test_secret_token")

  setup do
    ensure_scan_receipts_schema!()
    :ok
  end

  test "accepts valid JSON payload with valid token and returns 200" do
    payload =
      Jason.encode!(%{
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

  test "accepted empty scans persist a fresh scan receipt even when no code references are present" do
    payload = Jason.encode!(%{references: []})

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["count"] == 0
    assert Repo.aggregate(CodeReference, :count) == 0

    assert %ScanReceipt{reference_count: 0, received_at: %DateTime{}} = latest_scan_receipt()
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

  test "unauthorized and malformed payloads do not advance the stored scan receipt" do
    payload =
      Jason.encode!(%{
        references: [
          %{file: "lib/foo.ex", line: 12, flag_key: "flag_1"}
        ]
      })

    conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert conn.status == 200
    baseline_receipt = latest_scan_receipt()

    unauthorized_conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", payload)
      |> put_req_header("authorization", "Bearer wrong_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert unauthorized_conn.status == 401
    assert latest_scan_receipt().id == baseline_receipt.id

    invalid_conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", Jason.encode!(%{wrong_shape: true}))
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert invalid_conn.status == 400
    assert latest_scan_receipt().id == baseline_receipt.id
  end

  test "validates the shape of the incoming JSON to prevent malformed data insertion" do
    payload =
      Jason.encode!(%{
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

  test "accepted payloads replace code references and persist the latest scan receipt in one write path" do
    first_payload =
      Jason.encode!(%{
        references: [
          %{file: "lib/foo.ex", line: 12, flag_key: "flag_1"},
          %{file: "lib/bar.ex", line: 42, flag_key: "flag_2"}
        ]
      })

    first_conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", first_payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert first_conn.status == 200
    assert Repo.aggregate(CodeReference, :count) == 2

    first_receipt = latest_scan_receipt()

    second_payload =
      Jason.encode!(%{
        references: [
          %{file: "lib/baz.ex", line: 99, flag_key: "flag_3"}
        ]
      })

    second_conn =
      conn(:post, "/api/webhooks/rulestead/code_refs", second_payload)
      |> put_req_header("authorization", "Bearer test_secret_token")
      |> put_req_header("content-type", "application/json")
      |> CodeRefsPlug.call(@opts)

    assert second_conn.status == 200
    assert Repo.aggregate(CodeReference, :count) == 1
    assert [%CodeReference{flag_key: "flag_3"}] = Repo.all(CodeReference)

    assert %ScanReceipt{reference_count: 1, received_at: %DateTime{}} = latest_scan_receipt()
    assert latest_scan_receipt().id != first_receipt.id
  end

  defp latest_scan_receipt do
    ScanReceipt
    |> order_by(desc: :received_at, desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp ensure_scan_receipts_schema! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS code_reference_scans (
      id uuid PRIMARY KEY,
      received_at timestamp(6) with time zone NOT NULL,
      reference_count integer NOT NULL DEFAULT 0,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )
    """)
  end
end
