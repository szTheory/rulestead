defmodule Rulestead.Store.EctoContractTest do
  use Rulestead.StoreContractCase, store: Rulestead.Store.Ecto, control: __MODULE__.Control

  alias Rulestead.{Environment, Flag, FlagEnvironment, Repo}

  defmodule Control do
    alias Ecto.Adapters.SQL.Sandbox
    alias Rulestead.{Environment, Flag, FlagEnvironment, Repo, StoreError}

    def ensure_started do
      checkout_repo()
      :ok
    end

    def reset! do
      checkout_repo()

      Repo.delete_all(Rulestead.AuditEvent)
      Repo.delete_all(Rulestead.Ruleset)
      Repo.delete_all(FlagEnvironment)
      Repo.delete_all(Flag)
      Repo.delete_all(Environment)

      Enum.each(default_environments(), fn attrs ->
        %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
      end)

      :ok
    end

    def put_flag!(attrs) do
      case put_flag(attrs) do
        {:ok, flag} -> flag
        {:error, error} -> raise error
      end
    end

    def put_flag(attrs) do
      environment_keys = Map.get(attrs, :environment_keys, ["test"])
      flag_attrs = Map.drop(attrs, [:environment_keys])

      with {:ok, flag} <- insert_flag(flag_attrs),
           :ok <- ensure_environment_keys(environment_keys) do
        flag_environments =
          Enum.map(environment_keys, fn environment_key ->
            environment = Repo.get_by!(Environment, key: environment_key)

            %FlagEnvironment{}
            |> FlagEnvironment.changeset(%{
              flag_id: flag.id,
              environment_id: environment.id,
              status: :draft
            })
            |> Repo.insert!()
          end)

        {:ok,
         %{
           flag: Map.from_struct(flag),
           archived?: not is_nil(flag.archived_at),
           environment_keys: Enum.map(flag_environments, & &1.environment_id)
         }}
      end
    end

    defp checkout_repo do
      case Sandbox.checkout(Repo) do
        :ok -> Sandbox.mode(Repo, {:shared, self()})
        {:already, :owner} -> Sandbox.mode(Repo, {:shared, self()})
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
        nil -> :ok
        missing_environment -> {:error, StoreError.environment_not_found(missing_environment)}
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

  store_contract_tests()
end
