defmodule Rulestead.Webhooks.InboundContractTest do
  use Rulestead.RepoCase, async: true

  alias Rulestead.Webhooks.InboundReceipt
  alias Rulestead.Webhooks.InboundEvent
  alias Rulestead.Webhooks.ReplayClaim

  test "inbound receipt changeset validates required fields and enum values" do
    now = DateTime.utc_now()
    attrs = %{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_123",
      received_at: now,
      raw_body_sha256: "sha256:abc",
      verified_state: :accepted,
      correlation_id: "corr_123"
    }

    changeset = InboundReceipt.changeset(%InboundReceipt{}, attrs)
    assert changeset.valid?

    # Test invalid enum
    invalid_attrs = Map.put(attrs, :verified_state, :invalid)
    changeset = InboundReceipt.changeset(%InboundReceipt{}, invalid_attrs)
    refute changeset.valid?
    assert %{verified_state: ["is invalid"]} = errors_on(changeset)
  end

  test "inbound receipt accepted? and rejected? helpers" do
    assert InboundReceipt.accepted?(%InboundReceipt{verified_state: :accepted})
    refute InboundReceipt.accepted?(%InboundReceipt{verified_state: :rejected})
    
    assert InboundReceipt.rejected?(%InboundReceipt{verified_state: :rejected})
    assert InboundReceipt.rejected?(%InboundReceipt{verified_state: :malformed})
    refute InboundReceipt.rejected?(%InboundReceipt{verified_state: :accepted})
  end

  test "inbound event envelope constructor" do
    now = DateTime.utc_now()
    event = InboundEvent.new(%{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_123",
      received_at: now,
      payload: %{"action" => "opened"},
      metadata: %{"user" => "jon"},
      correlation_id: "corr_123"
    })

    assert event.provider == "github"
    assert event.payload == %{"action" => "opened"}
  end

  test "replay claims reject duplicate provider delivery identities" do
    receipt = Repo.insert!(%InboundReceipt{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_123",
      received_at: DateTime.utc_now(),
      raw_body_sha256: "sha256:abc",
      verified_state: :accepted,
      correlation_id: "corr_1"
    })

    Repo.insert!(%ReplayClaim{
      provider: "github",
      delivery_id: "del_123",
      receipt_id: receipt.id
    })

    # Try inserting the same provider/delivery_id
    receipt2 = Repo.insert!(%InboundReceipt{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_123",
      received_at: DateTime.utc_now(),
      raw_body_sha256: "sha256:abc",
      verified_state: :accepted,
      correlation_id: "corr_2"
    })

    assert {:error, changeset} = Repo.insert(ReplayClaim.changeset(%ReplayClaim{}, %{
      provider: "github",
      delivery_id: "del_123",
      receipt_id: receipt2.id
    }))

    assert %{provider: ["has already been taken"]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key)) |> to_string()
      end)
    end)
  end
end
