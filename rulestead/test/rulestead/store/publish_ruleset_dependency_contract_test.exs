defmodule Rulestead.Store.PublishRulesetDependencyContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.Fake
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.DependencyValidator

  test "validate/2 emits missing_reference with canonical identity fields" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{}, tenant_key: "tenant-a"},
        [dependency_entry()]
      )

    assert [
             %{
               code: "missing_reference",
               severity: :blocker,
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               flag_key: "checkout-redesign",
               ruleset_version: 2,
               rule_key: "vip-rule"
             }
           ] = findings
  end

  test "validate/2 emits archived_reference when audience is archived" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{archived_at: ~U[2026-01-01 00:00:00Z]})
          }
        },
        [dependency_entry()]
      )

    assert Enum.any?(findings, &(&1.code == "archived_reference"))
  end

  test "validate/2 marks incompatible_reference for unsupported clause op shape" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" =>
              audience(%{
                definition: %{
                  conditions: [%{"attribute" => "plan", "operator" => "unsupported_operator"}]
                }
              })
          }
        },
        [dependency_entry()]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "unsupported clause"
  end

  test "validate/2 marks incompatible_reference on schema version mismatch when metadata is present" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{definition: %{"conditions" => [], "schema_version" => 1}})
          }
        },
        [dependency_entry(%{audience_schema_version: 2})]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "schema version"
  end

  test "validate/2 marks incompatible_reference on version hash mismatch when metadata is present" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{definition: %{"conditions" => [], "version_hash" => "v1"}})
          }
        },
        [dependency_entry(%{audience_version_hash: "v2"})]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "version hash"
  end

  test "validate/2 emits stale_reference when stale reference key is supplied" do
    entry = dependency_entry()

    findings =
      DependencyValidator.validate(
        [entry],
        stale_reference_keys: [reference_key(entry)],
        audiences: %{"vip-users" => audience()}
      )

    assert Enum.any?(findings, &(&1.code == "stale_reference"))
  end

  test "tenant precedence enforces explicit scope tenant on every dependency entry" do
    findings =
      DependencyValidator.validate(
        %{tenant_key: "tenant-a", audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: "tenant-b"})]
      )

    assert [%{code: "tenant_mismatch", message: message}] = findings
    assert message =~ "command scope tenant"
  end

  test "tenant precedence emits tenant_mismatch for mixed tenant dependencies when scope omits tenant" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{"vip-users" => audience()}},
        [
          dependency_entry(%{tenant_key: "tenant-a"}),
          dependency_entry(%{tenant_key: "tenant-b", rule_key: "vip-rule-2"})
        ]
      )

    assert Enum.map(findings, & &1.code) == ["tenant_mismatch", "tenant_mismatch"]
    assert Enum.all?(findings, &String.contains?(&1.message, "mixed tenant"))
  end

  test "tenant precedence treats nil tenant scope as tenant-agnostic when dependencies are nil" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: nil})]
      )

    assert findings == []
  end

  test "to_error keeps deterministic blocker details and blockers?/1 detects blockers" do
    findings =
      DependencyValidator.validate(
        %{tenant_key: "tenant-a", audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: "tenant-b"})]
      )

    assert DependencyValidator.blockers?(findings)

    assert %Rulestead.Error{domain: :store, type: :invalid_command, details: [detail]} =
             DependencyValidator.to_error(findings)

    assert detail.code == "tenant_mismatch"
    assert detail.environment_key == "production"
  end

  test "sort_findings keeps deterministic severity/code and semantic tuple ordering" do
    findings = [
      finding("tenant_mismatch", "production", "tenant-b", "checkout-redesign", 2, "c", "c"),
      finding("archived_reference", "production", "tenant-a", "checkout-redesign", 2, "a", "a"),
      finding("missing_reference", "staging", "tenant-a", "checkout-redesign", 1, "a", "a")
    ]

    sorted = DependencyValidator.sort_findings(findings)

    assert Enum.map(sorted, & &1.code) == [
             "archived_reference",
             "missing_reference",
             "tenant_mismatch"
           ]
  end

  defmodule EctoControl do
    alias Rulestead.{Audience, AuditEvent, Environment, Flag, FlagEnvironment, Repo, Ruleset}
    alias Rulestead.StoreError

    def ensure_started do
      checkout_repo()
      :ok
    end

    def reset! do
      checkout_repo()
      Repo.delete_all(AuditEvent)
      Repo.delete_all(Rulestead.RuntimeSnapshot)
      Repo.delete_all(Rulestead.EnvironmentVersion)
      Repo.delete_all(Rulestead.Targeting.AudienceReferenceProjection)
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

    def put_flag!(attrs) do
      case put_flag(attrs) do
        {:ok, flag} -> flag
        {:error, error} -> raise error
      end
    end

    def put_audience!(attrs) do
      %Audience{}
      |> Audience.changeset(attrs)
      |> Repo.insert!()
    end

    def latest_audit_event do
      AuditEvent
      |> Repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond), :desc)
      |> List.first()
      |> case do
        nil -> nil
        event -> AuditEvent.serialize(event)
      end
    end

    defp put_flag(attrs) do
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
        missing_environment -> {:error, Rulestead.StoreError.environment_not_found(missing_environment)}
      end
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
        %{key: "development", name: "Development", description: "Local and developer-owned environments"},
        %{key: "staging", name: "Staging", description: "Pre-production validation environments"},
        %{key: "production", name: "Production", description: "Live customer-facing environments"},
        %{key: "test", name: "Test", description: "Automated and ephemeral test environments"}
      ]
    end
  end

  defmodule FakeControl do
    def ensure_started, do: Rulestead.Fake.Control.ensure_started()
    def reset!, do: Rulestead.Fake.Control.reset!()
    def put_flag!(attrs), do: Rulestead.Fake.Control.put_flag!(attrs)
    def put_audience!(attrs), do: Rulestead.Fake.Control.put_audience!(attrs)

    def latest_audit_event do
      Rulestead.Fake.Control.snapshot!()
      |> Map.get(:audit_events, [])
      |> List.first()
    end
  end

  for {label, store_module, control_module} <- [
        {"ecto", Rulestead.Store.Ecto, EctoControl},
        {"fake", Fake, FakeControl}
      ] do
    describe "#{label} publish dependency gating" do
      @store_module store_module
      @control_module control_module

      test "publish fails closed with missing_reference findings and audit evidence" do
        @control_module.ensure_started()
        @control_module.reset!()

        @control_module.put_flag!(
          valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["test"]})
        )

        assert {:ok, _draft} =
                 @store_module.save_draft_ruleset(
                   Command.SaveDraftRuleset.new("checkout-redesign", "test", dependency_ruleset("ghost-users"))
                 )

        assert {:error, %Rulestead.Error{type: :invalid_command, details: details}} =
                 @store_module.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))

        assert Enum.any?(details, &dependency_code?(&1, "missing_reference"))

        assert %{
                 event_type: "ruleset.publish_blocked",
                 metadata: %{"dependency_findings" => dependency_findings}
               } = @control_module.latest_audit_event()

        assert Enum.any?(dependency_findings, &dependency_code?(&1, "missing_reference"))
      end

      test "publish remains successful when dependency references are valid" do
        @control_module.ensure_started()
        @control_module.reset!()

        @control_module.put_audience!(%{
          key: "vip-users",
          tenant_key: "global",
          description: "VIP users",
          definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
        })

        @control_module.put_flag!(
          valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["test"]})
        )

        assert {:ok, _draft} =
                 @store_module.save_draft_ruleset(
                   Command.SaveDraftRuleset.new("checkout-redesign", "test", dependency_ruleset("vip-users"))
                 )

        assert {:ok, payload} =
                 @store_module.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))

        assert published_payload?(payload)
      end
    end
  end

  defp dependency_entry(overrides \\ %{}) do
    Map.merge(
      %{
        environment_key: "production",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        flag_key: "checkout-redesign",
        ruleset_version: 2,
        rule_key: "vip-rule"
      },
      overrides
    )
  end

  defp audience(overrides \\ %{}) do
    Map.merge(
      %{
        key: "vip-users",
        archived_at: nil,
        definition: %{
          "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "enterprise"}]
        }
      },
      overrides
    )
  end

  defp finding(code, environment_key, tenant_key, flag_key, ruleset_version, rule_key, audience_key) do
    %{
      code: code,
      severity: :blocker,
      message: "#{code} message",
      environment_key: environment_key,
      tenant_key: tenant_key,
      audience_key: audience_key,
      flag_key: flag_key,
      ruleset_version: ruleset_version,
      rule_key: rule_key
    }
  end

  defp reference_key(entry) do
    "flag:#{entry.flag_key}:ruleset:#{entry.ruleset_version}:rule:#{entry.rule_key}"
  end

  defp dependency_ruleset(audience_key) do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "vip-rule",
          name: "VIP audience",
          strategy: :segment_match,
          audience_key: audience_key,
          conditions: []
        }
      ]
    })
  end

  defp dependency_code?(entry, code) do
    Map.get(entry, :code) == code or Map.get(entry, "code") == code
  end

  defp published_payload?(%{ruleset: %{status: :published}}), do: true
  defp published_payload?(%{flag: %{key: _key}}), do: true
  defp published_payload?(_payload), do: false
end
