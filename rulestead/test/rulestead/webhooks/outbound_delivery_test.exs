# credo:disable-for-this-file
defmodule Rulestead.Webhooks.OutboundDeliveryTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Oban.WebhookDeliveryWorker
  alias Rulestead.Webhooks.{Delivery, Destination, OutboundEvent}
  alias Rulestead.Repo

  @moduletag capture_log: true

  setup do
    ensure_oban_jobs!()

    dest =
      Repo.insert!(%Destination{
        name: "Test Destination",
        environment_key: "env_test",
        url: "http://localhost:0/dummy",
        secret_id: "sec_123"
      })

    event =
      Repo.insert!(%OutboundEvent{
        event_type: "fake.event",
        payload: %{"foo" => "bar"},
        environment_key: "env_test",
        correlation_id: "cor_123"
      })

    delivery =
      Repo.insert!(%Delivery{
        webhook_destination_id: dest.id,
        webhook_outbound_event_id: event.id,
        state: :pending,
        attempt_count: 0
      })

    {:ok, %{dest: dest, event: event, delivery: delivery}}
  end

  defp start_server(response) do
    {:ok, listen_socket} =
      :gen_tcp.listen(0, [:binary, packet: :line, active: false, reuseaddr: true])

    {:ok, port} = :inet.port(listen_socket)

    task =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listen_socket, 5000)
        read_request(socket)
        # Wait a tiny bit to make sure the client is ready to receive
        Process.sleep(10)
        :gen_tcp.send(socket, response)
        :gen_tcp.close(socket)
        :gen_tcp.close(listen_socket)
      end)

    {port, task}
  end

  defp read_request(socket) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, "\r\n"} -> :ok
      {:ok, _} -> read_request(socket)
      _ -> :error
    end
  end

  test "successful delivery updates state to :succeeded", %{dest: dest, delivery: delivery} do
    {port, task} = start_server("HTTP/1.1 200 OK\r\nContent-Length: 7\r\n\r\nSuccess")

    dest |> Ecto.Changeset.change(url: "http://localhost:#{port}") |> Repo.update!()

    assert :ok = WebhookDeliveryWorker.perform(%{args: %{"delivery_id" => delivery.id}})

    updated = Repo.get(Delivery, delivery.id)
    assert updated.state == :succeeded
    assert updated.last_response_code == 200
    assert updated.last_response_body == "Success"
    assert updated.attempt_count == 1

    Task.await(task)
  end

  test "failed delivery with < 3 attempts updates to :pending and increments attempt", %{
    dest: dest,
    delivery: delivery
  } do
    {port, task} =
      start_server("HTTP/1.1 500 Internal Server Error\r\nContent-Length: 5\r\n\r\nError")

    dest |> Ecto.Changeset.change(url: "http://localhost:#{port}") |> Repo.update!()

    assert :ok = WebhookDeliveryWorker.perform(%{args: %{"delivery_id" => delivery.id}})

    updated = Repo.get(Delivery, delivery.id)
    assert updated.state == :pending
    assert updated.last_response_code == 500
    assert updated.last_response_body == "Error"
    assert updated.attempt_count == 1
    assert updated.next_attempt_at != nil

    Task.await(task)
  end

  test "failed delivery with >= 3 attempts updates to :exhausted", %{
    dest: dest,
    delivery: delivery
  } do
    {port, task} =
      start_server("HTTP/1.1 500 Internal Server Error\r\nContent-Length: 5\r\n\r\nError")

    dest |> Ecto.Changeset.change(url: "http://localhost:#{port}") |> Repo.update!()
    delivery |> Ecto.Changeset.change(attempt_count: 2) |> Repo.update!()

    assert :ok = WebhookDeliveryWorker.perform(%{args: %{"delivery_id" => delivery.id}})

    updated = Repo.get(Delivery, delivery.id)
    assert updated.state == :exhausted
    assert updated.last_response_code == 500
    assert updated.terminal_failure_reason == "Exhausted retries after 3 attempts"

    Task.await(task)
  end

  test "connection timeout updates to :pending", %{dest: dest, delivery: delivery} do
    dest |> Ecto.Changeset.change(url: "http://localhost:9999") |> Repo.update!()

    assert :ok = WebhookDeliveryWorker.perform(%{args: %{"delivery_id" => delivery.id}})

    updated = Repo.get(Delivery, delivery.id)
    assert updated.state == :pending
    assert updated.attempt_count == 1
    assert String.contains?(updated.last_response_body, "econnrefused")
  end

  defp ensure_oban_jobs! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.oban_jobs (
      id bigserial PRIMARY KEY,
      state text NOT NULL DEFAULT 'scheduled',
      queue text NOT NULL DEFAULT 'default',
      worker text NOT NULL,
      args jsonb NOT NULL DEFAULT '{}'::jsonb,
      meta jsonb NOT NULL DEFAULT '{}'::jsonb,
      tags text[] NOT NULL DEFAULT '{}',
      errors jsonb[] NOT NULL DEFAULT '{}',
      attempt integer NOT NULL DEFAULT 0,
      max_attempts integer NOT NULL DEFAULT 3,
      priority integer NOT NULL DEFAULT 0,
      attempted_by text[],
      attempted_at timestamp(6) with time zone,
      cancelled_at timestamp(6) with time zone,
      completed_at timestamp(6) with time zone,
      discarded_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      scheduled_at timestamp(6) with time zone NOT NULL
    )")
  end
end
