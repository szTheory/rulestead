defmodule Rulestead.Oban.WebhookDeliveryWorker do
  @moduledoc false
  use Rulestead.Oban.Worker

  alias Rulestead.Repo
  alias Rulestead.Webhooks.Delivery
  alias Rulestead.Webhooks.DeliverySigner

  @delivery_max_attempts 3

  @spec perform(map()) :: :ok | {:error, term()}
  def perform(job) when is_map(job) do
    args = Map.get(job, :args, %{})
    delivery_id = Map.get(args, "delivery_id")
    
    case Repo.get(Delivery, delivery_id) |> Repo.preload([:webhook_destination, :webhook_outbound_event]) do
      nil -> :ok
      %Delivery{state: state} when state in [:succeeded, :exhausted] -> :ok
      delivery -> do_delivery(delivery)
    end
  end

  defp do_delivery(delivery) do
    dest = delivery.webhook_destination
    event = delivery.webhook_outbound_event

    attempt_count = delivery.attempt_count + 1
    
    delivery = 
      delivery
      |> Delivery.changeset(%{
        state: :delivering, 
        last_attempt_at: DateTime.utc_now(),
        attempt_count: attempt_count
      })
      |> Repo.update!()

    Rulestead.Telemetry.webhook_delivery_event(:attempted, delivery)

    payload_json = Jason.encode!(event.payload)
    
    headers = DeliverySigner.sign_payload(payload_json, dest.secret_id)
              |> Map.put("content-type", "application/json")
              |> Map.put("rulestead-delivery-id", delivery.id)

    request = {
      String.to_charlist(dest.url), 
      Enum.map(headers, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end), 
      ~c"application/json", 
      payload_json
    }
    
    case :httpc.request(:post, request, [timeout: 5000], []) do
      {:ok, {{_, status_code, _}, _resp_headers, response_body}} when status_code in 200..299 ->
        {:ok, delivery} = 
          delivery
          |> Delivery.changeset(%{
            state: :succeeded,
            last_response_code: status_code,
            last_response_body: to_string(response_body) |> String.slice(0, 1024)
          })
          |> Repo.update()
          
        Rulestead.Telemetry.webhook_delivery_event(:succeeded, delivery)
        :ok

      {:ok, {{_, status_code, _}, _resp_headers, response_body}} ->
        handle_failure(delivery, status_code, to_string(response_body), attempt_count)

      {:error, reason} ->
        handle_failure(delivery, nil, inspect(reason), attempt_count)
    end
  end

  defp handle_failure(delivery, status_code, error_body, attempt_count) do
    if attempt_count >= @delivery_max_attempts do
      {:ok, delivery} = 
        delivery
        |> Delivery.changeset(%{
          state: :exhausted,
          last_response_code: status_code,
          last_response_body: error_body |> String.slice(0, 1024),
          terminal_failure_reason: "Exhausted retries after #{attempt_count} attempts"
        })
        |> Repo.update()
        
      Rulestead.Telemetry.webhook_delivery_event(:exhausted, delivery)
      :ok
    else
      # Re-enqueue
      {:ok, delivery} = 
        delivery
        |> Delivery.changeset(%{
          state: :pending,
          last_response_code: status_code,
          last_response_body: error_body |> String.slice(0, 1024),
          next_attempt_at: DateTime.add(DateTime.utc_now(), attempt_count * 10, :second)
        })
        |> Repo.update()
        
      Rulestead.Telemetry.webhook_delivery_event(:failed, delivery)
      
      Rulestead.Store.Ecto.requeue_webhook_delivery(delivery, attempt_count * 10)
      
      :ok
    end
  end
end
