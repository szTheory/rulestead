# credo:disable-for-this-file
defmodule Rulestead.Store.PromotionApplyContractTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    EnvironmentVersion,
    Fake,
    Flag,
    FlagEnvironment,
    Repo,
    Ruleset,
    RuntimeSnapshot,
    Store.Command
  }

  defmodule EctoControl do
    import Ecto.Query

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

    def latest_environment_version!(environment_key) do
      EnvironmentVersion
      |> Repo.get_by(
        environment_key: environment_key,
        version: latest_environment_version_number(environment_key)
      )
    end

    def seed_audience!(attrs) do
      %Audience{} |> Audience.changeset(attrs) |> Repo.insert!()
    end

    def delete_audience!(audience_key) do
      case Repo.get_by(Audience, key: audience_key) do
        nil -> :ok
        audience -> Repo.delete!(audience)
      end
    end

    def archive_audience!(audience_key) do
      case Repo.get_by(Audience, key: audience_key) do
        nil ->
          :ok

        audience ->
          audience |> Ecto.Changeset.change(archived_at: DateTime.utc_now()) |> Repo.update!()
      end
    end

    def update_audience_definition!(audience_key, definition) do
      case Repo.get_by(Audience, key: audience_key) do
        nil -> :ok
        audience -> audience |> Ecto.Changeset.change(definition: definition) |> Repo.update!()
      end
    end

    def update_audience_tenant!(audience_key, tenant_key) do
      case Repo.get_by(Audience, key: audience_key) do
        nil -> :ok
        audience -> audience |> Ecto.Changeset.change(tenant_key: tenant_key) |> Repo.update!()
      end
    end

    defp latest_environment_version_number(environment_key) do
      Repo.one!(
        from(version in EnvironmentVersion,
          where: version.environment_key == ^environment_key,
          select: max(version.version)
        )
      )
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

    defp checkout_repo do
      case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
        :ok -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :owner} -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :allowed} -> :ok
      end
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

    def latest_environment_version!(environment_key) do
      Rulestead.Fake.Control.snapshot!()
      |> Map.fetch!(:environment_versions)
      |> Map.fetch!(environment_key)
      |> Enum.max_by(&elem(&1, 0))
      |> elem(1)
    end

    def seed_audience!(attrs) do
      now = Rulestead.Fake.Control.now!()
      snapshot = Rulestead.Fake.Control.snapshot!()

      Rulestead.Fake.Control.restore!(%{
        snapshot
        | audiences:
            Map.put(snapshot.audiences, attrs.key, %{
              id: "aud-#{attrs.key}",
              key: attrs.key,
              name: attrs.name,
              description: attrs.description,
              tenant_key: Map.get(attrs, :tenant_key),
              definition: Map.get(attrs, :definition),
              inserted_at: now,
              updated_at: now,
              archived_at: Map.get(attrs, :archived_at)
            })
      })
    end

    def delete_audience!(audience_key) do
      snapshot = Rulestead.Fake.Control.snapshot!()

      Rulestead.Fake.Control.restore!(%{
        snapshot
        | audiences: Map.delete(snapshot.audiences, audience_key)
      })
    end

    def archive_audience!(audience_key) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      audience = Map.get(snapshot.audiences, audience_key)

      if is_map(audience) do
        Rulestead.Fake.Control.restore!(%{
          snapshot
          | audiences:
              Map.put(snapshot.audiences, audience_key, %{
                audience
                | archived_at: snapshot.now,
                  updated_at: snapshot.now
              })
        })
      end
    end

    def update_audience_definition!(audience_key, definition) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      audience = Map.get(snapshot.audiences, audience_key)

      if is_map(audience) do
        Rulestead.Fake.Control.restore!(%{
          snapshot
          | audiences:
              Map.put(snapshot.audiences, audience_key, %{
                audience
                | definition: definition,
                  updated_at: snapshot.now
              })
        })
      end
    end

    def update_audience_tenant!(audience_key, tenant_key) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      audience = Map.get(snapshot.audiences, audience_key)

      if is_map(audience) do
        Rulestead.Fake.Control.restore!(%{
          snapshot
          | audiences:
              Map.put(snapshot.audiences, audience_key, %{
                audience
                | tenant_key: tenant_key,
                  updated_at: snapshot.now
              })
        })
      end
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

  test "fake and ecto apply the same promotion contract and persist immutable environment versions" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)

      control.seed_audience!(audience_attrs())
      seed_promotable_flag!(adapter)

      assert {:ok, compare} =
               adapter.compare_environments(
                 Command.CompareEnvironments.new("staging", "test",
                   flag_keys: ["checkout-redesign"],
                   tenant_key: "acme"
                 )
               )

      command = build_apply_command(compare) |> Map.put(:tenant_key, "acme")

      assert {:ok, result} = adapter.apply_promotion(command)
      assert result.compare_token == compare.compare_token
      assert result.compare_schema_version == compare.compare_schema_version
      assert result.applied_flag_keys == ["checkout-redesign"]
      assert result.dependency_closure_keys == compare.dependency_closure_keys
      assert is_binary(result.environment_version_id)
      assert result.environment_version_version == 1
      assert result.snapshot_version == 2

      assert {:ok, target_payload} =
               adapter.fetch_flag(fetch_flag_command("checkout-redesign", "test"))

      assert target_payload.active_ruleset.salt == "checkout-redesign:v2"

      assert target_payload.active_ruleset.rules ==
               hd(compare.flags).proposed_target_state.active_ruleset.rules

      assert {:ok, snapshot} = adapter.fetch_snapshot(fetch_snapshot_command("test"))
      assert snapshot.version == 2
      snapshot_payload = :erlang.binary_to_term(snapshot.payload)

      assert snapshot_payload.flags["checkout-redesign"].active_ruleset.salt ==
               "checkout-redesign:v2"

      environment_version = control.latest_environment_version!("test")
      assert environment_version.environment_key == "test"
      assert environment_version.source_environment_key == "staging"
      assert environment_version.target_environment_key == "test"
      assert environment_version.compare_token == compare.compare_token
      assert environment_version.tenant_key == "acme"
      assert environment_version.applied_flag_keys == ["checkout-redesign"]

      assert environment_version.metadata["tenant"] == %{
               "tenant_key" => "acme",
               "scope_source" => "explicit",
               "validation" => %{"evidence" => "same_tenant_guard", "status" => "passed"}
             }

      assert Map.has_key?(environment_version.authored_snapshot, "checkout-redesign")
    end)
  end

  test "direct apply rejects protected targets in both adapters" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)

      control.seed_audience!(audience_attrs())
      seed_promotable_flag!(adapter, target_environment: "production")

      assert {:ok, compare} =
               adapter.compare_environments(
                 Command.CompareEnvironments.new("staging", "production",
                   flag_keys: ["checkout-redesign"]
                 )
               )

      assert {:error,
              %Rulestead.Error{
                type: :invalid_command,
                message: "promotion to protected targets requires governance"
              }} =
               Rulestead.apply_promotion(build_apply_command(compare))
    end)
  end

  test "public saved plans preserve tenant scope when normalized into replay commands across adapters" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)

      control.seed_audience!(audience_attrs())
      seed_promotable_flag!(adapter)

      assert {:ok, planned} =
               Rulestead.plan_promotion("staging", "test",
                 flag_keys: ["checkout-redesign"],
                 tenant_key: "acme"
               )

      plan = planned["details"]["plan"]
      assert plan["tenant_key"] == "acme"

      assert {:ok, loaded_plan} = Rulestead.Manifest.Plan.load(plan)
      assert loaded_plan["tenant_key"] == "acme"

      command =
        Command.ApplyPromotion.new(%{
          source_environment_key: loaded_plan["source_environment_key"],
          target_environment_key: loaded_plan["target_environment_key"],
          tenant_key: loaded_plan["tenant_key"],
          flag_keys: loaded_plan["flag_keys"],
          compare_token: loaded_plan["compare_token"],
          compare_schema_version: Rulestead.Promotion.Compare.schema_version(),
          source_fingerprint: loaded_plan["source_fingerprint"],
          target_fingerprint: loaded_plan["target_fingerprint"],
          dependency_closure_keys: loaded_plan["dependency_closure_keys"],
          proposed_target_bundle: loaded_plan["proposed_target_bundle"]
        })

      assert command.tenant_key == "acme"
      assert command.compare_token == plan["compare_token"]
      assert command.flag_keys == plan["flag_keys"]
    end)
  end

  test "apply fails closed on missing_reference blockers across adapters" do
    assert_dependency_blocker_case("missing_reference", fn control ->
      control.delete_audience!("vip-users")
    end)
  end

  test "apply fails closed on archived_reference blockers across adapters" do
    assert_dependency_blocker_case("archived_reference", fn control ->
      control.archive_audience!("vip-users")
    end)
  end

  test "apply fails closed on incompatible_reference blockers across adapters" do
    assert_dependency_blocker_case("incompatible_reference", fn control ->
      control.update_audience_definition!("vip-users", %{"clauses" => "invalid-shape"})
    end)
  end

  test "replay apply stays blocked when dependency closure drifts and snapshot unchanged across adapters" do
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)
      control.seed_audience!(audience_attrs())
      seed_promotable_flag!(adapter)

      assert {:ok, compare} =
               adapter.compare_environments(
                 Command.CompareEnvironments.new("staging", "test",
                   flag_keys: ["checkout-redesign"],
                   tenant_key: "acme"
                 )
               )

      command = build_apply_command(compare) |> Map.put(:tenant_key, "acme")
      assert {:ok, snapshot_before} = adapter.fetch_snapshot(fetch_snapshot_command("test"))

      assert {:ok, %{version: stale_version}} =
               adapter.save_draft_ruleset(
                 save_draft_command(
                   "checkout-redesign",
                   "staging",
                   valid_ruleset_attrs(%{
                     salt: "checkout-redesign:v3",
                     rules: [
                       %{
                         key: "force-enabled",
                         strategy: :forced_value,
                         value: %{value: true},
                         conditions: []
                       }
                     ]
                   })
                 )
               )

      assert {:ok, _published} =
               adapter.publish_ruleset(
                 publish_ruleset_command("checkout-redesign", "staging", version: stale_version)
               )

      assert {:error, %Rulestead.Error{message: "promotion compare dependency closure drifted"}} =
               adapter.apply_promotion(command)

      # blocked replay keeps target snapshot unchanged
      assert {:ok, snapshot_after} = adapter.fetch_snapshot(fetch_snapshot_command("test"))
      assert snapshot_after.version == snapshot_before.version
    end)
  end

  defp seed_promotable_flag!(adapter, opts \\ []) do
    target_environment = Keyword.get(opts, :target_environment, "test")

    case adapter do
      Rulestead.Store.Ecto -> seed_promotable_flag_ecto!(target_environment)
      _other -> seed_promotable_flag_fake!(target_environment)
    end
  end

  defp seed_promotable_flag_ecto!(target_environment) do
    assert {:ok, _} =
             Rulestead.Store.Ecto.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   environment_keys: ["staging", target_environment],
                   key: "checkout-redesign"
                 })
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

    assert {:ok, _} =
             Rulestead.Store.Ecto.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 target_environment,
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             Rulestead.Store.Ecto.publish_ruleset(
               publish_ruleset_command("checkout-redesign", target_environment)
             )
  end

  defp seed_promotable_flag_fake!(target_environment) do
    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["staging", target_environment]
      })
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

    assert {:ok, _} =
             Rulestead.Fake.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 target_environment,
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             Rulestead.Fake.publish_ruleset(
               publish_ruleset_command("checkout-redesign", target_environment)
             )
  end

  defp build_apply_command(compare) do
    Command.ApplyPromotion.new(%{
      source_environment_key: compare.source_environment.key,
      target_environment_key: compare.target_environment.key,
      flag_keys: Enum.map(compare.flags, & &1.flag_key),
      compare_token: compare.compare_token,
      compare_schema_version: compare.compare_schema_version,
      source_fingerprint: compare.source_fingerprint,
      target_fingerprint: compare.target_fingerprint,
      dependency_closure_keys: compare.dependency_closure_keys,
      proposed_target_bundle:
        Map.new(compare.flags, fn flag ->
          {flag.flag_key, flag.proposed_target_state}
        end)
    })
  end

  defp audience_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        key: "vip-users",
        name: "VIP Users",
        description: "VIP cohort",
        tenant_key: "acme",
        definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
      },
      overrides
    )
  end

  defp assert_dependency_blocker_case(expected_code, mutate!) do
    # stale_reference and tenant_mismatch remain part of the fail closed dependency matrix.
    Enum.each(@adapters, fn {_label, adapter, control} ->
      control.ensure_started()
      control.reset!()
      Application.put_env(:rulestead, :store, adapter)
      control.seed_audience!(audience_attrs())
      seed_promotable_flag!(adapter)

      assert {:ok, compare} =
               adapter.compare_environments(
                 Command.CompareEnvironments.new("staging", "test",
                   flag_keys: ["checkout-redesign"],
                   tenant_key: "acme"
                 )
               )

      command = build_apply_command(compare) |> Map.put(:tenant_key, "acme")
      mutate!.(control)

      assert {:error,
              %Rulestead.Error{message: "promotion apply blocked by dependency validation"} =
                error} =
               adapter.apply_promotion(command)

      assert Enum.any?(error.details, &(&1.code == expected_code))
      assert (error.metadata[:fail_closed] || error.metadata["fail_closed"]) == true
    end)
  end
end
