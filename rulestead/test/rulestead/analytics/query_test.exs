defmodule Rulestead.Analytics.QueryTest do
  use Rulestead.RepoCase, async: true

  alias Rulestead.Analytics.Event
  alias Rulestead.Analytics.Query
  alias Rulestead.Repo

  setup do
    # Clear events table just in case, though DataCase usually handles it
    Repo.delete_all(Event)

    # Insert exposures
    insert_event(%{
      kind: "exposure",
      actor_id: "usr_1",
      event_name: "button_color_evaluated",
      env: "production",
      metadata: %{"flag_key" => "button_color", "value" => "red"}
    })

    insert_event(%{
      kind: "exposure",
      actor_id: "usr_2",
      event_name: "button_color_evaluated",
      env: "production",
      metadata: %{"flag_key" => "button_color", "value" => "blue"}
    })

    insert_event(%{
      kind: "exposure",
      actor_id: "usr_3",
      event_name: "button_color_evaluated",
      env: "production",
      metadata: %{"flag_key" => "button_color", "value" => "red"}
    })

    # Insert conversions
    insert_event(%{
      kind: "custom",
      actor_id: "usr_1",
      event_name: "checkout",
      env: "production"
    })

    insert_event(%{
      kind: "custom",
      actor_id: "usr_2",
      event_name: "checkout",
      env: "production"
    })

    # A non-converting user
    # usr_3 did not checkout

    # Irrelevant event
    insert_event(%{
      kind: "custom",
      actor_id: "usr_4",
      event_name: "page_view",
      env: "production"
    })

    :ok
  end

  defp insert_event(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    
    attrs = Map.merge(%{
      id: Ecto.UUID.generate(),
      occurred_at: now,
      inserted_at: now,
      updated_at: now
    }, attrs)

    %Event{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  describe "experiment_metrics/3" do
    test "groups events by experiment variation and calculates total exposures" do
      metrics = Query.experiment_metrics("button_color", "checkout", "production")

      assert is_list(metrics)
      assert length(metrics) == 2

      red = Enum.find(metrics, &(&1.variation == "red"))
      blue = Enum.find(metrics, &(&1.variation == "blue"))

      assert red.exposures == 2
      assert blue.exposures == 1
    end

    test "calculates total conversions for a given target event per variant" do
      metrics = Query.experiment_metrics("button_color", "checkout", "production")

      red = Enum.find(metrics, &(&1.variation == "red"))
      blue = Enum.find(metrics, &(&1.variation == "blue"))

      # usr_1 exposed to red, and converted
      # usr_3 exposed to red, did not convert
      assert red.conversions == 1

      # usr_2 exposed to blue, converted
      assert blue.conversions == 1
    end
  end
end
