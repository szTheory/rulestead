# credo:disable-for-this-file
defmodule Rulestead.Store.ManifestExportContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    Fake,
    Flag,
    FlagEnvironment,
    Manifest,
    Repo,
    Ruleset,
    Store.Command
  }

  defmodule EctoControl do
    alias Rulestead.{Audience, Environment, Flag, FlagEnvironment, Repo, Ruleset}

    def ensure_started do
      checkout_repo()
      :ok
    end

    def reset! do
      checkout_repo()

      Repo.delete_all(Ruleset)
      Repo.delete_all(FlagEnvironment)
      Repo.delete_all(Flag)
      Repo.delete_all(Audience)
      Repo.delete_all(Environment)

      Enum.each(default_environments(), fn attrs ->
        %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
      end)
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
  end

  for {label, adapter, control} <- [
        {"ecto", Rulestead.Store.Ecto, EctoControl},
        {"fake", Fake, FakeControl}
      ] do
    describe "#{label} manifest export" do
      @adapter adapter
      @control control

      setup do
        previous_store = Application.get_env(:rulestead, :store)
        @control.ensure_started()
        @control.reset!()

        if @adapter == Rulestead.Store.Ecto do
          Rulestead.StoreFixtures.seed_default_audience_for_repo!()
        end

        Application.put_env(:rulestead, :store, @adapter)

        on_exit(fn ->
          case previous_store do
            nil -> Application.delete_env(:rulestead, :store)
            value -> Application.put_env(:rulestead, :store, value)
          end
        end)

        seed_export_fixture!()

        :ok
      end

      test "exports the same normalized manifest payload and bytes" do
        assert {:ok, manifest} = Rulestead.export_manifest("staging")
        assert {:ok, encoded} = Manifest.serialize(manifest)

        assert manifest == expected_manifest()
        assert {:ok, reloaded} = Manifest.load(encoded)
        assert reloaded == manifest
      end
    end
  end

  defp seed_export_fixture! do
    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging"]})
               )
             )

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command("checkout-redesign", "staging", valid_ruleset_attrs())
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(publish_ruleset_command("checkout-redesign", "staging"))
  end

  defp expected_manifest do
    %{
      "schema_version" => 1,
      "kind" => "rulestead_environment_manifest",
      "environment_key" => "staging",
      "flags" => [
        %{
          "flag_key" => "checkout-redesign",
          "flag" => %{
            "description" => "Release the new checkout flow",
            "flag_type" => "release",
            "value_type" => "boolean",
            "default_value" => %{"value" => false},
            "owner" => "growth",
            "permanent" => true,
            "tags" => ["checkout", "release"]
          },
          "environment" => %{
            "status" => "active",
            "active_ruleset_version" => 1
          },
          "active_ruleset" => %{
            "version" => 1,
            "salt" => "checkout-redesign:v1",
            "metadata" => %{"source" => "contract"},
            "rules" => [
              %{
                "key" => "force-enabled",
                "name" => "Force enabled",
                "strategy" => "forced_value",
                "value" => %{"value" => true},
                "variants" => [],
                "conditions" => [
                  %{
                    "attribute" => "attributes.account.plan",
                    "operator" => "equals",
                    "value" => %{"equals" => "enterprise"}
                  }
                ]
              },
              %{
                "key" => "target-segment",
                "name" => "Target segment",
                "strategy" => "segment_match",
                "value" => %{},
                "variants" => [],
                "audience_key" => "vip-users",
                "environment_key" => "staging",
                "tenant_key" => "global",
                "conditions" => [
                  %{
                    "attribute" => "attributes.email",
                    "operator" => "regex",
                    "value" => %{"options" => "i", "pattern" => "@example\\.com$"}
                  }
                ]
              },
              %{
                "key" => "variant-split",
                "name" => "Checkout split",
                "strategy" => "variant_split",
                "value" => %{},
                "conditions" => [],
                "variants" => [
                  %{"key" => "control", "weight" => 50, "value" => %{"value" => "control"}},
                  %{"key" => "treatment", "weight" => 50, "value" => %{"value" => "treatment"}}
                ],
                "rollout" => %{
                  "bucket_by" => "subject",
                  "guardrails" => [
                    %{
                      "environment_scope" => "environment",
                      "freshness_window_seconds" => 300,
                      "min_sample_size" => 100,
                      "signal_key" => "checkout_error_rate",
                      "tenant_scope" => "required",
                      "threshold_operator" => "gte",
                      "threshold_value" => 0.05
                    }
                  ],
                  "percentage" => 100,
                  "salt" => "checkout-rollout"
                }
              }
            ]
          }
        }
      ]
    }
  end
end
