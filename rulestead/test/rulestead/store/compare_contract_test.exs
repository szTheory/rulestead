defmodule Rulestead.Store.CompareContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    Fake,
    Flag,
    FlagEnvironment,
    Promotion.Compare,
    Repo,
    Store.Command
  }

  defmodule EctoControl do
    alias Rulestead.{Audience, Environment, Fake, Flag, FlagEnvironment, Repo, StoreError}

    def ensure_started do
      checkout_repo()
      :ok
    end

    def reset! do
      checkout_repo()

      Repo.delete_all(Rulestead.AuditEvent)
      Repo.delete_all(Rulestead.RuntimeSnapshot)
      Repo.delete_all(Rulestead.Ruleset)
      Repo.delete_all(FlagEnvironment)
      Repo.delete_all(Flag)
      Repo.delete_all(Audience)
      Repo.delete_all(Environment)

      Enum.each(default_environments(), fn attrs ->
        %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
      end)

      :ok
    end

    def put_flag!(attrs) do
      case put_flag(attrs) do
        {:ok, value} -> value
        {:error, error} -> raise error
      end
    end

    def put_flag(attrs) do
      environment_keys = Map.get(attrs, :environment_keys, ["test"])
      flag_attrs = Map.drop(attrs, [:environment_keys])

      with {:ok, flag} <- insert_flag(flag_attrs),
           :ok <- ensure_environment_keys(environment_keys) do
        Enum.each(environment_keys, fn environment_key ->
          environment = Repo.get_by!(Environment, key: environment_key)

          %FlagEnvironment{}
          |> FlagEnvironment.changeset(%{
            flag_id: flag.id,
            environment_id: environment.id,
            status: :draft
          })
          |> Repo.insert!()
        end)

        {:ok, flag}
      end
    end

    def seed_audience!(attrs) do
      %Audience{}
      |> Audience.changeset(attrs)
      |> Repo.insert!()
    end

    def update_flag_environment!(flag_key, environment_key, attrs) do
      flag = Repo.get_by!(Flag, key: flag_key)
      environment = Repo.get_by!(Environment, key: environment_key)

      flag_environment =
        Repo.get_by!(FlagEnvironment, flag_id: flag.id, environment_id: environment.id)

      flag_environment
      |> FlagEnvironment.changeset(attrs)
      |> Repo.update!()
    end

    defp checkout_repo do
      case Elixir.Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
        :ok -> Elixir.Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :owner} -> Elixir.Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :allowed} -> :ok
      end
    end

    defp insert_flag(attrs) do
      %Flag{}
      |> Flag.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, flag} ->
          {:ok, flag}

        {:error, changeset} ->
          {:error,
           StoreError.invalid_command(
             "flag key already exists",
             metadata: %{flag_key: Map.get(attrs, :key)},
             details:
               Enum.map(changeset.errors, fn {field, {message, _}} ->
                 %{field: to_string(field), message: message}
               end),
             cause: changeset
           )}
      end
    end

    defp ensure_environment_keys(environment_keys) do
      case Enum.find(environment_keys, &(Repo.get_by(Environment, key: &1) == nil)) do
        nil ->
          :ok

        missing_environment ->
          {:error, Rulestead.StoreError.environment_not_found(missing_environment)}
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
    def put_flag!(attrs), do: Rulestead.Fake.Control.put_flag!(attrs)

    def seed_audience!(attrs) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      now = snapshot.now
      key = attrs[:key] || attrs["key"]

      audience = %{
        id: Elixir.Ecto.UUID.generate(),
        key: key,
        description: attrs[:description] || attrs["description"],
        definition: attrs[:definition] || attrs["definition"] || %{},
        archived_at: attrs[:archived_at] || attrs["archived_at"],
        inserted_at: now,
        updated_at: now
      }

      snapshot
      |> put_in([:audiences, key], audience)
      |> Rulestead.Fake.Control.restore!()
    end

    def update_flag_environment!(flag_key, environment_key, attrs) do
      snapshot = Rulestead.Fake.Control.snapshot!()
      current = get_in(snapshot, [:flags, flag_key, :environments, environment_key])
      updated = Map.merge(current, attrs) |> Map.put(:updated_at, snapshot.now)

      snapshot
      |> put_in([:flags, flag_key, :environments, environment_key], updated)
      |> Rulestead.Fake.Control.restore!()
    end
  end

  for {label, store_module, control_module} <- [
        {"ecto", Rulestead.Store.Ecto, EctoControl},
        {"fake", Fake, FakeControl}
      ] do
    describe "#{label} compare projection" do
      @store_module store_module
      @control_module control_module

      setup do
        previous_store = Application.get_env(:rulestead, :store)
        @control_module.ensure_started()
        @control_module.reset!()
        Application.put_env(:rulestead, :store, @store_module)

        on_exit(fn ->
          case previous_store do
            nil -> Application.delete_env(:rulestead, :store)
            value -> Application.put_env(:rulestead, :store, value)
          end
        end)

        :ok
      end

      test "returns blocker findings for missing dependencies hard-stale tokens and archived-target revive conflicts" do
        @control_module.put_flag!(
          valid_flag_attrs(%{environment_keys: ["staging", "production"]})
        )

        publish_ruleset!(
          @store_module,
          "checkout-redesign",
          "staging",
          valid_ruleset_attrs(%{
            rules: [
              %{
                key: "segment-match",
                name: "VIP audience",
                strategy: :segment_match,
                audience_key: "vip-users",
                conditions: []
              }
            ]
          })
        )

        publish_ruleset!(@store_module, "checkout-redesign", "production")

        @control_module.update_flag_environment!("checkout-redesign", "production", %{
          status: :archived
        })

        assert {:ok, initial_compare} =
                 @store_module.compare_environments(
                   Command.CompareEnvironments.new("staging", "production")
                 )

        assert initial_compare.overall_status == :blocker
        assert severities_for(initial_compare, :missing_dependency) == [:blocker]
        assert severities_for(initial_compare, :lifecycle_conflict) == [:blocker]

        publish_ruleset!(
          @store_module,
          "checkout-redesign",
          "staging",
          valid_ruleset_attrs(%{
            salt: "checkout-redesign:v2",
            rules: [
              %{
                key: "force-enabled",
                strategy: :forced_value,
                value: %{value: true},
                conditions: []
              }
            ]
          }), version: 2)

        assert {:ok, stale_compare} =
                 @store_module.compare_environments(
                   Command.CompareEnvironments.new("staging", "production",
                     compare_token: initial_compare.compare_token
                   )
                 )

        assert severities_for(stale_compare, :staleness_conflict) == [:blocker]
      end

      test "returns warnings for operational overrides protected targets missing target rows and unpublished source drafts" do
        @control_module.put_flag!(
          valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging"]})
        )

        @control_module.put_flag!(
          valid_flag_attrs(%{key: "beta-banner", environment_keys: ["staging", "production"]})
        )

        @control_module.seed_audience!(%{
          key: "vip-users",
          definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
        })

        publish_ruleset!(@store_module, "checkout-redesign", "staging")
        publish_ruleset!(@store_module, "beta-banner", "staging")
        publish_ruleset!(@store_module, "beta-banner", "production")

        assert {:ok, %{version: 2}} =
                 @store_module.save_draft_ruleset(
                   save_draft_command(
                     "checkout-redesign",
                     "staging",
                     valid_ruleset_attrs(%{salt: "checkout-redesign:draft"})
                   )
                 )

        assert {:ok, _kill_switch} =
                 @store_module.engage_kill_switch(
                   Command.EngageKillSwitch.new("beta-banner", "production",
                     actor: %{id: "operator-1", type: "user", display: "Operator"},
                     reason: "simulate override"
                   )
                 )

        assert {:ok, compare} =
                 @store_module.compare_environments(
                   Command.CompareEnvironments.new("staging", "production")
                 )

        assert compare.overall_status == :warning

        assert MapSet.subset?(
                 MapSet.new([
                   :soft_mismatch,
                   :operational_override,
                   :governance_requirement,
                   :unpublished_source_work
                 ]),
                 MapSet.new(compare.findings |> Enum.map(& &1.class))
               )
      end
    end
  end

  test "fake and ecto return the same canonical compare contract for equivalent authored inputs" do
    ecto_payload =
      with_store(Rulestead.Store.Ecto, EctoControl, fn ->
        seed_parity_fixture!(Rulestead.Store.Ecto, EctoControl)

        Rulestead.Store.Ecto.compare_environments(
          Command.CompareEnvironments.new("staging", "production",
            flag_keys: ["checkout-redesign", "beta-banner"]
          )
        )
      end)

    fake_payload =
      with_store(Fake, FakeControl, fn ->
        seed_parity_fixture!(Fake, FakeControl)

        Fake.compare_environments(
          Command.CompareEnvironments.new("staging", "production",
            flag_keys: ["checkout-redesign", "beta-banner"]
          )
        )
      end)

    assert {:ok, ecto_payload} = ecto_payload
    assert {:ok, fake_payload} = fake_payload

    assert ecto_payload.compare_schema_version == fake_payload.compare_schema_version
    assert ecto_payload.overall_status == fake_payload.overall_status
    assert ecto_payload.requested_flag_keys == fake_payload.requested_flag_keys
    assert ecto_payload.dependency_closure_keys == fake_payload.dependency_closure_keys
    assert is_binary(ecto_payload.compare_token)
    assert is_binary(fake_payload.compare_token)
    assert is_binary(ecto_payload.source_fingerprint)
    assert is_binary(fake_payload.source_fingerprint)
    assert is_binary(ecto_payload.target_fingerprint)
    assert is_binary(fake_payload.target_fingerprint)
    assert normalize_findings(ecto_payload.findings) == normalize_findings(fake_payload.findings)

    assert normalize_flag_contracts(ecto_payload.flags) ==
             normalize_flag_contracts(fake_payload.flags)
  end

  defp with_store(store_module, control_module, fun) do
    previous_store = Application.get_env(:rulestead, :store)
    control_module.ensure_started()
    control_module.reset!()
    Application.put_env(:rulestead, :store, store_module)

    try do
      fun.()
    after
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end
  end

  defp seed_parity_fixture!(store_module, control_module) do
    control_module.put_flag!(
      valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging", "production"]})
    )

    control_module.put_flag!(
      valid_flag_attrs(%{key: "beta-banner", environment_keys: ["staging"]})
    )

    control_module.seed_audience!(%{
      key: "vip-users",
      definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]}
    })

    publish_ruleset!(store_module, "checkout-redesign", "staging")
    publish_ruleset!(store_module, "checkout-redesign", "production")
    publish_ruleset!(store_module, "beta-banner", "staging")
  end

  defp publish_ruleset!(
         store_module,
         flag_key,
         environment_key,
         ruleset_attrs \\ valid_ruleset_attrs(),
         publish_opts \\ []
       ) do
    assert {:ok, %{version: version}} =
             store_module.save_draft_ruleset(
               save_draft_command(flag_key, environment_key, ruleset_attrs)
             )

    assert {:ok, _payload} =
             store_module.publish_ruleset(
               publish_ruleset_command(
                 flag_key,
                 environment_key,
                 Keyword.put_new(publish_opts, :version, version)
               )
             )
  end

  defp severities_for(compare, class) do
    compare.findings
    |> Enum.filter(&(&1.class == class))
    |> Enum.map(& &1.severity)
    |> Enum.uniq()
  end

  defp normalize_flag_contracts(flags) do
    flags
    |> Enum.map(fn flag ->
      %{
        flag_key: flag.flag_key,
        changed_fields: flag.changed_fields,
        dependency_closure_keys: flag.dependency_closure_keys,
        findings: normalize_findings(flag.findings),
        source_state?: not is_nil(flag.source_state),
        current_target_state?: not is_nil(flag.current_target_state),
        proposed_target_state?: not is_nil(flag.proposed_target_state),
        source_has_unpublished_drafts?: flag.source_has_unpublished_drafts?
      }
    end)
    |> Enum.sort_by(& &1.flag_key)
  end

  defp normalize_findings(findings) do
    findings
    |> Enum.map(fn finding ->
      finding
      |> Map.take([:severity, :class, :code, :message, :metadata])
      |> Map.update(:metadata, nil, &Compare.normalize_term/1)
    end)
    |> Enum.sort_by(&{&1.severity, &1.class, &1.code, inspect(&1.metadata)})
  end
end
