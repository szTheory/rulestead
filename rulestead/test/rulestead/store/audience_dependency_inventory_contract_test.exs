defmodule Rulestead.Store.AudienceDependencyInventoryContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    Fake,
    Flag,
    FlagEnvironment,
    Repo,
    Store.Command,
    StoreError,
    Targeting.AudienceReferenceProjection
  }

  defmodule EctoControl do
    alias Rulestead.{
      Audience,
      Environment,
      Flag,
      FlagEnvironment,
      Repo,
      StoreError,
      Targeting.AudienceReferenceProjection
    }

    def ensure_started do
      checkout_repo()
      :ok
    end

    def reset! do
      checkout_repo()

      Repo.delete_all(Rulestead.AuditEvent)
      Repo.delete_all(Rulestead.RuntimeSnapshot)
      Repo.delete_all(Rulestead.EnvironmentVersion)
      Repo.delete_all(AudienceReferenceProjection)
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
      Rulestead.StoreFixtures.upsert_audience_for_repo!(attrs)
    end

    def clear_projection! do
      Repo.delete_all(AudienceReferenceProjection)
    end

    def rebuild_projection! do
      case Rulestead.Store.Ecto.rebuild_audience_reference_projection() do
        {:ok, result} -> result
        {:error, error} -> raise error
      end
    end

    defp checkout_repo do
      case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
        :ok -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
        {:already, :owner} -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
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

    def seed_audience!(attrs), do: Rulestead.Fake.Control.put_audience!(attrs)

    def clear_projection! do
      snapshot =
        Rulestead.Fake.Control.snapshot!()
        |> Map.put(:audience_reference_projection, %{})

      Rulestead.Fake.Control.restore!(snapshot)
      :ok
    end

    def rebuild_projection!, do: Rulestead.Fake.Control.rebuild_audience_reference_projection!()
  end

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

  test "Ecto and Fake parity keeps deterministic order and scope fields" do
    ecto_entries = seed_and_read_entries(Rulestead.Store.Ecto, EctoControl)
    fake_entries = seed_and_read_entries(Fake, FakeControl)

    expected_order = [
      {"production", "global", "checkout-redesign", 1, "prod-segment", "vip-users"},
      {"staging", "global", "checkout-redesign", 1, "stage-segment", "beta-users"},
      {"staging", "global", "search-boost", 1, "search-segment", "vip-users"}
    ]

    assert entry_keys(ecto_entries) == expected_order
    assert entry_keys(fake_entries) == expected_order

    assert Enum.all?(ecto_entries, fn entry ->
             is_binary(entry.environment_key) and
               is_binary(entry.tenant_key) and
               is_binary(entry.flag_key) and
               is_integer(entry.ruleset_version) and
               is_binary(entry.rule_key) and
               is_binary(entry.audience_key)
           end)

    assert Enum.all?(ecto_entries, fn entry ->
             is_binary(entry.ruleset_status) and
               is_map(entry.rollout_context) and
               is_map(entry.lifecycle_context) and
               is_integer(entry.reference_count) and
               is_integer(entry.hidden_reference_count)
           end)

    assert Enum.all?(fake_entries, fn entry ->
             is_binary(entry.environment_key) and
               is_binary(entry.tenant_key) and
               String.trim(entry.environment_key) != "" and
               String.trim(entry.tenant_key) != ""
           end)
  end

  for {label, store_module, control_module} <- [
        {"ecto", Rulestead.Store.Ecto, EctoControl},
        {"fake", Fake, FakeControl}
      ] do
    describe "#{label} projection bootstrap" do
      @store_module store_module
      @control_module control_module

      test "pre-existing bootstrap backfill supports page 1 and page 2 with no duplicates and no omissions" do
        seed_inventory_fixture!(@store_module, @control_module)

        @control_module.clear_projection!()

        assert %{inserted_rows: inserted_rows} = @control_module.rebuild_projection!()
        assert inserted_rows > 0

        page_1 = list_dependencies!(@store_module, %{limit: 2, offset: 0})
        page_2 = list_dependencies!(@store_module, %{limit: 2, offset: 2})
        full = list_dependencies!(@store_module, %{limit: 100, offset: 0})

        combined = page_1.entries ++ page_2.entries

        assert MapSet.size(MapSet.new(entry_keys(combined))) == length(combined)
        assert entry_keys(combined) == entry_keys(full.entries)
      end
    end
  end

  defp seed_and_read_entries(store_module, control_module) do
    seed_inventory_fixture!(store_module, control_module)
    list_dependencies!(store_module, %{limit: 100, offset: 0}).entries
  end

  defp seed_inventory_fixture!(store_module, control_module) do
    control_module.ensure_started()
    control_module.reset!()

    control_module.seed_audience!(%{
      key: "vip-users",
      name: "VIP users",
      description: "VIP audience",
      tenant_key: "global",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "vip"}]}
    })

    control_module.seed_audience!(%{
      key: "beta-users",
      name: "Beta users",
      description: "Beta audience",
      tenant_key: "global",
      definition: %{conditions: [%{attribute: "cohort", operator: "eq", value: "beta"}]}
    })

    control_module.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["staging", "production"]
      })
    )

    control_module.put_flag!(
      valid_flag_attrs(%{
        key: "search-boost",
        environment_keys: ["staging"]
      })
    )

    publish_ruleset!(
      store_module,
      "checkout-redesign",
      "production",
      audience_ruleset("checkout-production", "prod-segment", "vip-users")
    )

    publish_ruleset!(
      store_module,
      "checkout-redesign",
      "staging",
      audience_ruleset("checkout-staging", "stage-segment", "beta-users")
    )

    publish_ruleset!(
      store_module,
      "search-boost",
      "staging",
      audience_ruleset("search-staging", "search-segment", "vip-users")
    )
  end

  defp audience_ruleset(salt, rule_key, audience_key) do
    %{
      salt: salt,
      metadata: %{source: "inventory-contract"},
      rules: [
        %{
          key: rule_key,
          name: "Audience segment",
          strategy: :segment_match,
          audience_key: audience_key,
          conditions: []
        }
      ]
    }
  end

  defp publish_ruleset!(store_module, flag_key, environment_key, ruleset, opts \\ []) do
    assert {:ok, _draft} =
             store_module.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
             )

    assert {:ok, _published} =
             store_module.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, opts)
             )
  end

  defp list_dependencies!(store_module, attrs) do
    case store_module.list_audience_dependencies(attrs) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  defp entry_keys(entries) do
    Enum.map(entries, fn entry ->
      {
        entry.environment_key,
        entry.tenant_key,
        entry.flag_key,
        entry.ruleset_version,
        entry.rule_key,
        entry.audience_key
      }
    end)
  end
end
