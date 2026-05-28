defmodule Rulestead.Test.PreviewEvidenceStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  def resolve(_query) do
    {:ok,
     %{
       samples: [%{"actor_key" => "a1", "email" => "secret@example.com"}],
       impression_summary: %{
         "window_label" => "last_24h",
         "sampled_impressions" => 10,
         "matched_impressions" => 3
       }
     }}
  end
end

defmodule Rulestead.Test.PreviewEvidenceDeniedStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  def resolve(_query), do: {:error, :denied}
end

defmodule Rulestead.Test.PreviewEvidenceRaiseStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  def resolve(_query), do: raise("resolver boom")
end

defmodule Rulestead.Test.PreviewEvidenceOversizedStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  def resolve(_query) do
    samples =
      for index <- 1..26 do
        %{"actor_key" => "actor-#{index}", "targeting_key" => "target-#{index}"}
      end

    {:ok, %{samples: samples, impression_summary: %{}}}
  end
end

defmodule Rulestead.Test.PreviewEvidenceInvalidImpressionStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  def resolve(_query) do
    {:ok,
     %{
       samples: [],
       impression_summary: %{"window_label" => "last_24h", "email" => "secret@example.com"}
     }}
  end
end

defmodule Rulestead.Targeting.PreviewEvidenceTest do
  use ExUnit.Case, async: false

  alias Rulestead.Targeting.PreviewEvidence
  alias Rulestead.Targeting.PreviewEvidence.Limits

  setup do
    previous = Application.get_env(:rulestead, :preview_evidence_resolver)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:rulestead, :preview_evidence_resolver)
        value -> Application.put_env(:rulestead, :preview_evidence_resolver, value)
      end
    end)

    Application.delete_env(:rulestead, :preview_evidence_resolver)
    :ok
  end

  test "returns empty map when no resolver is configured" do
    assert {:ok, %{}} = PreviewEvidence.resolve(%{audience_key: "vip-users"})
  end

  test "returns redacted samples from configured stub resolver" do
    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceStub
    )

    assert {:ok, evidence} =
             PreviewEvidence.resolve(%{
               environment_key: "production",
               tenant_key: "acme",
               audience_key: "vip-users",
               operation: "update"
             })

    assert [%{"actor_key" => "a1"} = sample] = Map.fetch!(evidence, :samples)
    refute Map.has_key?(sample, "email")
    assert evidence.impression_summary.window_label == "last_24h"
  end

  test "rejects impression summaries with unknown keys fail-closed" do
    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceInvalidImpressionStub
    )

    assert {:error, error} = PreviewEvidence.resolve(%{audience_key: "vip-users"})
    assert error.metadata.code == "preview_evidence_invalid"
  end

  test "rejects more than 25 sample rows" do
    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceOversizedStub
    )

    assert {:error, error} = PreviewEvidence.resolve(%{audience_key: "vip-users"})
    assert error.metadata.code == "preview_evidence_oversized"
  end

  test "maps resolver denial to preview_evidence_policy_denied" do
    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceDeniedStub
    )

    assert {:error, error} = PreviewEvidence.resolve(%{audience_key: "vip-users"})
    assert error.metadata.code == "preview_evidence_policy_denied"
  end

  test "rescues resolver exceptions fail-closed" do
    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceRaiseStub
    )

    assert {:error, error} = PreviewEvidence.resolve(%{audience_key: "vip-users"})
    assert error.metadata.code == "preview_evidence_resolver_failed"
  end

  test "merge_samples preserves explicit command row over duplicate resolver row" do
    command = [%{"actor_key" => "a1", "targeting_key" => "t1", "plan" => "pro"}]
    resolver = [%{"actor_key" => "a1", "targeting_key" => "t1", "plan" => "basic"}]

    merged = Limits.merge_samples(command, resolver)

    assert [%{"actor_key" => "a1", "targeting_key" => "t1", "plan" => "pro"}] = merged
  end
end
