# credo:disable-for-this-file
defmodule Rulestead.Test.PreviewEvidenceContractStub do
  @moduledoc false
  @behaviour Rulestead.Targeting.PreviewEvidence

  @impl true
  def resolve(_query) do
    Application.get_env(:rulestead, :preview_evidence_stub_result, {:ok, %{}})
  end
end

defmodule Rulestead.Targeting.PreviewEvidenceContractTest do
  use Rulestead.RepoCase, async: false

  import Ecto.Query
  import Rulestead.StoreFixtures

  alias Rulestead.{Audience, Environment, Error, Repo}
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.Targeting.AudienceDependencies

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_phase9_schema!()
    previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)
    previous_stub = Application.get_env(:rulestead, :preview_evidence_stub_result)

    Application.put_env(
      :rulestead,
      :preview_evidence_resolver,
      Rulestead.Test.PreviewEvidenceContractStub
    )

    on_exit(fn ->
      case previous_resolver do
        nil -> Application.delete_env(:rulestead, :preview_evidence_resolver)
        value -> Application.put_env(:rulestead, :preview_evidence_resolver, value)
      end

      case previous_stub do
        nil -> Application.delete_env(:rulestead, :preview_evidence_stub_result)
        value -> Application.put_env(:rulestead, :preview_evidence_stub_result, value)
      end
    end)

    :ok
  end

  test "apply rejects stale fingerprint when host evidence changes across adapters" do
    Enum.each(@adapters, fn adapter ->
      configure_stub!(
        samples: [%{"actor_key" => "host-1", "targeting_key" => "t-1"}],
        impression_summary: %{
          "window_label" => "last_24h",
          "sampled_impressions" => 100,
          "matched_impressions" => 12
        }
      )

      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:ok, preview} = preview_audience_impact(adapter)
      assert preview.preview_schema_version == 2

      configure_stub!(
        samples: [%{"actor_key" => "host-1", "targeting_key" => "t-1"}],
        impression_summary: %{
          "window_label" => "last_24h",
          "sampled_impressions" => 100,
          "matched_impressions" => 99
        }
      )

      assert {:ok, drifted_preview} = preview_audience_impact(adapter)
      refute drifted_preview.preview_fingerprint == preview.preview_fingerprint

      assert {:error, %Error{type: :invalid_command} = error} =
               apply_audience_mutation(adapter, preview)

      assert error.message =~ "stale" or
               Map.get(error.metadata, :expected_preview_fingerprint) != nil or
               Map.get(error.metadata, "expected_preview_fingerprint") != nil
    end)
  end

  test "preview with resolver returns schema v2 and host basis across adapters" do
    configure_stub!(
      samples: [
        %{"actor_key" => "host-1", "targeting_key" => "t-1", "matched?" => true}
      ],
      impression_summary: %{
        "window_label" => "last_24h",
        "sampled_impressions" => 50,
        "matched_impressions" => 8
      }
    )

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:ok, preview} = preview_audience_impact(adapter)

      assert preview.preview_schema_version == 2
      assert String.starts_with?(preview.preview_fingerprint, "audprev_")
      assert preview.preview_basis == "authored_state_with_host_evidence"
      assert preview.impression_evidence.window_label == "last_24h"
    end)
  end

  test "oversized evidence fails closed on preview across adapters" do
    oversized_samples =
      for index <- 1..30 do
        %{"actor_key" => "actor-#{index}", "targeting_key" => "target-#{index}"}
      end

    configure_stub!(samples: oversized_samples, impression_summary: %{})

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:error, %Error{type: :invalid_command} = error} =
               preview_audience_impact(adapter)

      assert error.metadata.code == "preview_evidence_oversized"
    end)
  end

  test "invalid impression key fails closed across adapters" do
    configure_stub!(
      samples: [],
      impression_summary: %{"email" => "x", "window_label" => "last_24h"}
    )

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:error, %Error{type: :invalid_command} = error} =
               preview_audience_impact(adapter)

      assert error.metadata.code == "preview_evidence_invalid"
    end)
  end

  test "policy denied fails closed across adapters" do
    Application.put_env(:rulestead, :preview_evidence_stub_result, {:ok, %{policy_denied: true}})

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:error, %Error{type: :invalid_command} = error} =
               preview_audience_impact(adapter)

      assert error.metadata.code == "preview_evidence_policy_denied"
    end)
  end

  test "explicit command samples preserved with resolver across adapters" do
    configure_stub!(
      samples: [%{"actor_key" => "resolver-1", "targeting_key" => "t-resolver"}],
      impression_summary: %{
        "window_label" => "last_7d",
        "sampled_impressions" => 10,
        "matched_impressions" => 2
      }
    )

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:ok, preview} =
               preview_audience_impact(adapter,
                 samples: [%{"actor_key" => "operator-1", "targeting_key" => "t-op"}]
               )

      assert [%{actor_key: "operator-1"} | _rest] = preview.sample_evidence
      assert Enum.any?(preview.sample_evidence, &(&1.actor_key == "resolver-1"))
    end)
  end

  test "no resolver matches pre-v1.9 semantics across adapters" do
    Application.delete_env(:rulestead, :preview_evidence_resolver)
    Application.delete_env(:rulestead, :preview_evidence_stub_result)

    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      seed_audience_reference!(adapter)

      assert {:ok, preview} = preview_audience_impact(adapter)

      assert preview.preview_basis == "authored_state_and_explicit_samples"
      assert preview.impression_evidence == %{}
    end)
  end

  defp configure_stub!(attrs) do
    Application.put_env(:rulestead, :preview_evidence_stub_result, {:ok, Map.new(attrs)})
  end

  defp preview_audience_impact(adapter, attrs \\ []) do
    command =
      Command.PreviewAudienceImpact.new(
        "vip-users",
        :update,
        Keyword.merge(
          [
            environment_key: "test",
            tenant_key: "tenant-a",
            after_definition: %{
              conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
            }
          ],
          attrs
        )
      )

    case adapter do
      Rulestead.Fake -> Rulestead.Fake.preview_audience_impact(command)
      StoreEcto -> StoreEcto.preview_audience_impact(command)
    end
  end

  defp apply_audience_mutation(adapter, preview) do
    command =
      Command.ApplyAudienceMutation.new(%{
        environment_key: "test",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        operation: :update,
        preview_schema_version: preview.preview_schema_version,
        preview_fingerprint: preview.preview_fingerprint,
        preview_basis: preview.preview_basis,
        affected_reference_keys: AudienceDependencies.reference_keys(preview.affected_references),
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "editor-1", roles: [:editor]},
        reason: "apply with stale host evidence"
      })

    case adapter do
      Rulestead.Fake -> Rulestead.Fake.apply_audience_mutation(command)
      StoreEcto -> StoreEcto.apply_audience_mutation(command)
    end
  end

  defp reset_adapter!(Rulestead.Fake) do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
  end

  defp reset_adapter!(StoreEcto), do: reset_repo!()

  defp seed_audience_reference!(Rulestead.Fake), do: seed_fake_audience_reference!()
  defp seed_audience_reference!(StoreEcto), do: seed_ecto_audience_reference!()

  defp seed_fake_audience_reference! do
    Rulestead.Fake.Control.put_audience!(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })

    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["test"]
      })
    )

    ruleset =
      valid_ruleset_attrs(%{
        rules: [
          %{
            key: "vip-rule",
            name: "VIP audience",
            strategy: :segment_match,
            audience_key: "vip-users",
            conditions: []
          }
        ]
      })

    assert {:ok, _draft} =
             Rulestead.Fake.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset)
             )

    assert {:ok, _published} =
             Rulestead.Fake.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", "test")
             )
  end

  defp seed_ecto_audience_reference! do
    reset_repo!()

    %Audience{}
    |> Audience.changeset(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })
    |> Repo.insert!()

    assert {:ok, _flag} =
             StoreEcto.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   key: "checkout-redesign",
                   environment_keys: ["test"]
                 })
               )
             )

    ruleset =
      valid_ruleset_attrs(%{
        rules: [
          %{
            key: "vip-rule",
            name: "VIP audience",
            strategy: :segment_match,
            audience_key: "vip-users",
            conditions: []
          }
        ]
      })

    assert {:ok, _draft} =
             StoreEcto.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset)
             )

    assert {:ok, _published} =
             StoreEcto.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))
  end

  defp reset_repo! do
    Repo.delete_all(from(a in Rulestead.AuditEvent))
    Repo.delete_all(from(a in Audience))
    Repo.delete_all(from(f in Rulestead.Flag))
    Repo.delete_all(from(fe in Rulestead.FlagEnvironment))
    Repo.delete_all(from(r in Rulestead.Ruleset))
    Repo.delete_all(from(e in Environment))

    for attrs <- default_environments() do
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
    end
  end

  defp default_environments do
    [
      %{key: "development", name: "Development", description: "Local environments"},
      %{key: "staging", name: "Staging", description: "Pre-production environments"},
      %{key: "production", name: "Production", description: "Live environments"},
      %{key: "test", name: "Test", description: "Test environments"}
    ]
  end

  defp ensure_phase9_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS change_requests (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      status text NOT NULL DEFAULT 'submitted',
      governed_action text NOT NULL,
      environment_key text NOT NULL,
      resource_type text NOT NULL,
      resource_key text NOT NULL,
      submitter_id text NOT NULL,
      submitter_type text NOT NULL,
      submitter_display text,
      reason text,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      submitted_at timestamp(6) with time zone NOT NULL,
      resolved_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")
  end
end
