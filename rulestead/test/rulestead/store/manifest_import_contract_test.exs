# credo:disable-for-this-file
defmodule Rulestead.Store.ManifestImportContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    Fake,
    Flag,
    FlagEnvironment,
    Manifest.Import,
    Repo,
    Ruleset,
    RuntimeSnapshot,
    Store.Command
  }

  defmodule EctoControl do
    alias Rulestead.{
      Audience,
      Environment,
      EnvironmentVersion,
      Flag,
      FlagEnvironment,
      Repo,
      Ruleset,
      RuntimeSnapshot
    }

    def ensure_started do
      checkout_repo()
      ensure_environment_versions_schema!()
      :ok
    end

    def reset! do
      checkout_repo()
      ensure_environment_versions_schema!()

      Repo.delete_all(EnvironmentVersion)
      Repo.delete_all(RuntimeSnapshot)
      Repo.delete_all(Ruleset)
      Repo.delete_all(FlagEnvironment)
      Repo.delete_all(Flag)
      Repo.delete_all(Audience)
      Repo.delete_all(Environment)

      Enum.each(default_environments(), fn attrs ->
        %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
      end)

      :ok
    end

    def seed_audience!(attrs) do
      attrs =
        Map.merge(
          %{
            definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
          },
          attrs
        )

      %Audience{} |> Audience.changeset(attrs) |> Repo.insert!()
    end

    def delete_audience!(audience_key) do
      case Repo.get_by(Audience, key: audience_key) do
        nil -> :ok
        audience -> Repo.delete!(audience)
      end
    end

    defp checkout_repo do
      case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
        :ok -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :owner} -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :allowed} -> :ok
      end
    end

    defp ensure_environment_versions_schema! do
      Repo.query!("""
      CREATE TABLE IF NOT EXISTS environment_versions (
        id uuid PRIMARY KEY,
        environment_key varchar(128) NOT NULL,
        version integer NOT NULL,
        authored_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
        source_environment_key varchar(128),
        target_environment_key varchar(128),
        compare_token varchar(256),
        source_fingerprint varchar(256),
        target_fingerprint varchar(256),
        dependency_closure_keys text[] NOT NULL DEFAULT '{}',
        applied_flag_keys text[] NOT NULL DEFAULT '{}',
        tenant_key varchar(128),
        metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        inserted_at timestamp(6) with time zone NOT NULL,
        updated_at timestamp(6) with time zone NOT NULL
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX IF NOT EXISTS environment_versions_environment_key_version_index ON environment_versions (environment_key, version)"
      )
    end

    defp default_environments do
      [
        %{
          key: "development",
          name: "Development",
          description: "Local and developer-owned environments"
        },
        %{key: "staging", name: "Staging", description: "Pre-production validation environments"},
        %{
          key: "production",
          name: "Production",
          description: "Live customer-facing environments"
        },
        %{key: "test", name: "Test", description: "Automated and ephemeral test environments"}
      ]
    end
  end

  defmodule FakeControl do
    def ensure_started, do: Rulestead.Fake.Control.ensure_started()
    def reset!, do: Rulestead.Fake.Control.reset!()

    def seed_audience!(attrs) do
      now = Rulestead.Fake.Control.now!()
      attrs =
        Map.merge(
          %{
            definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
          },
          attrs
        )

      Rulestead.Fake.Control.restore!(
        Rulestead.Fake.Control.snapshot!()
        |> Map.update!(:audiences, fn audiences ->
          Map.put(audiences, attrs.key, %{
            id: "aud-#{attrs.key}",
            key: attrs.key,
            name: attrs.name,
            description: attrs.description,
            definition: attrs.definition,
            inserted_at: now,
            updated_at: now,
            archived_at: Map.get(attrs, :archived_at)
          })
        end)
      )
    end

    def delete_audience!(audience_key) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      Rulestead.Fake.Control.restore!(%{snapshot | audiences: Map.delete(snapshot.audiences, audience_key)})
    end
  end

  @adapters [
    {"ecto", Rulestead.Store.Ecto, EctoControl},
    {"fake", Fake, FakeControl}
  ]

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "fake and ecto apply the same additive import contract including missing target flag environments" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)
      control.seed_audience!(%{key: "vip-users", name: "VIP Users", description: "VIP cohort"})

      seed_importable_flag!(adapter)

      assert {:ok, manifest} = Rulestead.export_manifest("staging")
      assert {:ok, planned} = Import.plan(manifest, target_environment: "test")
      plan = planned["details"]["plan"]

      assert plan["status"] == "changes"

      assert {:ok, applied} = Import.apply(plan, reason: "sync staging manifest")
      assert applied["status"] == "applied"

      assert {:ok, payload} = Rulestead.fetch_flag("checkout-redesign", "test")
      assert payload.active_ruleset.salt == "checkout-redesign:v2"
    end)
  end

  test "fake and ecto report governance_required for protected targets" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)
      control.seed_audience!(%{key: "vip-users", name: "VIP Users", description: "VIP cohort"})

      seed_importable_flag!(adapter)

      assert {:ok, manifest} = Rulestead.export_manifest("staging")
      assert {:ok, planned} = Import.plan(manifest, target_environment: "production")
      plan = planned["details"]["plan"]

      assert planned["status"] == "governance_required"

      assert {:ok, apply_result} = Import.apply(plan, reason: "should not bypass governance")
      assert apply_result["status"] == "governance_required"
    end)
  end

  test "fake and ecto do not apply when dependency findings are blockers" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)
      control.seed_audience!(%{
        key: "vip-users",
        name: "VIP Users",
        description: "VIP cohort",
        definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
      })

      seed_importable_flag!(adapter)

      assert {:ok, manifest} = Rulestead.export_manifest("staging")
      assert {:ok, planned} = Import.plan(manifest, target_environment: "test")
      plan = planned["details"]["plan"]

      control.delete_audience!("vip-users")

      # archived_reference / incompatible_reference / tenant_mismatch are covered by the same contract.
      assert {:ok, apply_result} = Import.apply(plan, reason: "dependencies drifted")
      assert apply_result["status"] == "blocked"
      assert Enum.any?(apply_result["dependency_findings"], &(&1["code"] == "missing_reference"))

      assert {:error, %Rulestead.Error{type: :flag_not_found}} =
               Rulestead.fetch_flag("checkout-redesign", "test")
    end)
  end

  defp seed_importable_flag!(adapter) do
    case adapter do
      Rulestead.Store.Ecto -> seed_importable_flag_ecto!()
      _other -> seed_importable_flag_fake!()
    end
  end

  defp seed_importable_flag_ecto! do
    assert {:ok, _} =
             Rulestead.Store.Ecto.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging"]})
               )
             )

    assert {:ok, _} =
             Rulestead.Store.Ecto.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 "staging",
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )

    assert {:ok, _} =
             Rulestead.Store.Ecto.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "staging")
             )
  end

  defp seed_importable_flag_fake! do
    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging"]})
    )

    assert {:ok, _} =
             Rulestead.Fake.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 "staging",
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )

    assert {:ok, _} =
             Rulestead.Fake.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "staging")
             )
  end
end
