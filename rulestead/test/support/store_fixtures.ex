defmodule Rulestead.StoreFixtures do
  @moduledoc false

  alias Rulestead.Store.Command

  @spec valid_flag_attrs(map()) :: map()
  def valid_flag_attrs(overrides \\ %{}) do
    defaults = %{
      key: "checkout-redesign",
      description: "Release the new checkout flow",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "growth", owner_kind: :team, owner_display: "growth"},
      lifecycle: %{
        mode: :permanent,
        review_by: nil,
        default_source: :flag_type,
        default_overridden: false
      },
      tags: ["checkout", "release"],
      environment_keys: ["test"]
    }

    Map.merge(defaults, overrides)
  end

  @spec valid_environment_attrs(map()) :: map()
  def valid_environment_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        key: "qa",
        name: "QA",
        description: "Shared QA environment"
      },
      overrides
    )
  end

  @spec valid_ruleset_attrs(map()) :: map()
  def valid_ruleset_attrs(overrides \\ %{}) do
    defaults = %{
      salt: "checkout-redesign:v1",
      metadata: %{source: "contract"},
      rules: [
        %{
          key: "force-enabled",
          name: "Force enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{
              attribute: "attributes.account.plan",
              operator: :equals,
              value: %{equals: "enterprise"}
            }
          ]
        },
        %{
          key: "target-segment",
          name: "Target segment",
          strategy: :segment_match,
          audience_key: "vip-users",
          conditions: [
            %{
              attribute: "attributes.email",
              operator: :regex,
              value: %{pattern: "@example\\.com$", options: "i"}
            }
          ]
        },
        %{
          key: "variant-split",
          name: "Checkout split",
          strategy: :variant_split,
          rollout: %{
            bucket_by: :subject,
            percentage: 100,
            salt: "checkout-rollout",
            guardrails: [
              %{
                signal_key: "checkout_error_rate",
                threshold_operator: :gte,
                threshold_value: 0.05,
                freshness_window_seconds: 300,
                min_sample_size: 100,
                environment_scope: :environment,
                tenant_scope: :required
              }
            ]
          },
          variants: [
            %{key: "control", weight: 50, value: %{value: "control"}},
            %{key: "treatment", weight: 50, value: %{value: "treatment"}}
          ]
        }
      ]
    }

    Map.merge(defaults, overrides)
  end

  @spec invalid_ruleset_attrs() :: map()
  def invalid_ruleset_attrs do
    %{
      salt: "checkout-redesign:invalid",
      rules: [
        %{
          key: "missing-value",
          strategy: :forced_value,
          value: %{}
        }
      ]
    }
  end

  @spec invalid_variant_weight_ruleset_attrs() :: map()
  def invalid_variant_weight_ruleset_attrs do
    %{
      salt: "checkout-redesign:weights",
      rules: [
        %{
          key: "variant-split",
          strategy: :variant_split,
          variants: [
            %{key: "control", weight: 60, value: %{value: "control"}},
            %{key: "treatment", weight: 30, value: %{value: "treatment"}}
          ]
        }
      ]
    }
  end

  @spec guarded_rollout_ruleset_attrs(map()) :: map()
  def guarded_rollout_ruleset_attrs(overrides \\ %{}) do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "variant-split",
          name: "Checkout split",
          strategy: :variant_split,
          rollout: %{
            bucket_by: :subject,
            percentage: 100,
            salt: "checkout-rollout",
            guardrails: [
              %{
                signal_key: "checkout_error_rate",
                threshold_operator: :gte,
                threshold_value: 0.05,
                freshness_window_seconds: 300,
                min_sample_size: 100,
                environment_scope: :environment,
                tenant_scope: :required
              }
            ]
          },
          variants: [
            %{key: "control", weight: 50, value: %{value: "control"}},
            %{key: "treatment", weight: 50, value: %{value: "treatment"}}
          ]
        }
      ]
    })
    |> Map.merge(overrides)
  end

  @spec invalid_guardrail_ruleset_attrs() :: map()
  def invalid_guardrail_ruleset_attrs do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "variant-split",
          strategy: :variant_split,
          rollout: %{
            bucket_by: :subject,
            percentage: 100,
            salt: "checkout-rollout",
            guardrails: [
              %{
                signal_key: "",
                threshold_operator: :gte,
                threshold_value: -1.0,
                freshness_window_seconds: -5,
                min_sample_size: -1,
                environment_scope: :environment,
                tenant_scope: :required
              }
            ]
          },
          variants: [
            %{key: "control", weight: 50, value: %{value: "control"}},
            %{key: "treatment", weight: 50, value: %{value: "treatment"}}
          ]
        }
      ]
    })
  end

  @spec fetch_flag_command(String.t() | atom(), String.t() | atom(), keyword()) ::
          Command.FetchFlag.t()
  def fetch_flag_command(flag_key \\ "checkout-redesign", environment_key \\ "test", opts \\ []) do
    Command.FetchFlag.new(flag_key, environment_key, opts)
  end

  @spec fetch_snapshot_command(String.t() | atom(), keyword()) :: Command.FetchSnapshot.t()
  def fetch_snapshot_command(environment_key \\ "test", opts \\ []) do
    Command.FetchSnapshot.new(environment_key, opts)
  end

  @spec save_draft_command(String.t() | atom(), String.t() | atom(), map(), keyword()) ::
          Command.SaveDraftRuleset.t()
  def save_draft_command(
        flag_key \\ "checkout-redesign",
        environment_key \\ "test",
        ruleset \\ valid_ruleset_attrs(),
        opts \\ []
      ) do
    Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset, opts)
  end

  @spec publish_ruleset_command(String.t() | atom(), String.t() | atom(), keyword()) ::
          Command.PublishRuleset.t()
  def publish_ruleset_command(
        flag_key \\ "checkout-redesign",
        environment_key \\ "test",
        opts \\ []
      ) do
    Command.PublishRuleset.new(flag_key, environment_key, opts)
  end

  @spec archive_flag_command(String.t() | atom(), keyword()) :: Command.ArchiveFlag.t()
  def archive_flag_command(flag_key \\ "checkout-redesign", opts \\ []) do
    Command.ArchiveFlag.new(flag_key, opts)
  end

  @spec list_flags_command(keyword()) :: Command.ListFlags.t()
  def list_flags_command(opts \\ []) do
    Command.ListFlags.new(opts)
  end

  @spec invalid_path_ruleset_attrs() :: map()
  def invalid_path_ruleset_attrs do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "bad-path",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{attribute: "traits[0].name", operator: :equals, value: %{equals: "vip"}}
          ]
        }
      ]
    })
  end

  @spec invalid_regex_ruleset_attrs() :: map()
  def invalid_regex_ruleset_attrs do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "bad-regex",
          strategy: :segment_match,
          audience_key: "vip-users",
          conditions: [
            %{
              attribute: "attributes.email",
              operator: :regex,
              value: %{pattern: "(", options: "("}
            }
          ]
        }
      ]
    })
  end

  @spec default_auto_advance_policy_attrs(map()) :: map()
  def default_auto_advance_policy_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        enabled: true,
        observation_window_seconds: 300,
        next_stage: "canary-100",
        next_percentage: 100
      },
      overrides
    )
  end

  @spec seed_rollout_with_auto_advance_policy!(module(), String.t(), keyword()) :: :ok
  def seed_rollout_with_auto_advance_policy!(adapter, flag_key, opts \\ []) do
    environment_key = Keyword.get(opts, :environment_key, "test")
    rule_key = Keyword.get(opts, :rule_key, "variant-split")
    policy_attrs = Keyword.get(opts, :policy, default_auto_advance_policy_attrs())

    flag_attrs =
      valid_flag_attrs(%{
        key: flag_key,
        permanent: true,
        environment_keys: [environment_key]
      })

    unless match?({:ok, _}, adapter.create_flag(Command.CreateFlag.new(flag_attrs,
           actor: %{id: "creator", type: "operator", display: "Creator"}
         ))) do
      raise "failed to create flag #{flag_key}"
    end

    unless match?({:ok, _},
             adapter.save_draft_ruleset(
               save_draft_command(flag_key, environment_key, guarded_rollout_ruleset_attrs())
             )
           ) do
      raise "failed to save draft ruleset for #{flag_key}"
    end

    unless match?({:ok, _},
             adapter.publish_ruleset(publish_ruleset_command(flag_key, environment_key))
           ) do
      raise "failed to publish ruleset for #{flag_key}"
    end

    unless match?({:ok, _},
             adapter.upsert_rollout_auto_advance_policy(
               Command.UpsertRolloutAutoAdvancePolicy.new(
                 flag_key,
                 environment_key,
                 rule_key,
                 policy_attrs
               )
             )
           ) do
      raise "failed to upsert auto-advance policy for #{flag_key}"
    end

    :ok
  end

  @spec list_auto_advance_ticks(module(), keyword()) :: [map()]
  def list_auto_advance_ticks(adapter, opts \\ []) do
    environment_key = Keyword.get(opts, :environment_key, "test")
    flag_key = Keyword.get(opts, :flag_key)

    list_opts =
      [
        environment_key: environment_key,
        resource_type: "flag",
        action: :advance_rollout,
        state: :scheduled,
        limit: 100
      ]
      |> maybe_put(:resource_key, flag_key)

    case adapter.list_scheduled_executions(Command.ListScheduledExecutions.new(list_opts)) do
      {:ok, %{scheduled_executions: scheduled_executions}} ->
        Enum.filter(scheduled_executions, &auto_advance_tick?/1)

      {:error, error} ->
        raise error
    end
  end

  @spec execute_auto_advance_tick!(module(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def execute_auto_advance_tick!(adapter, opts \\ []) do
    ticks = list_auto_advance_ticks(adapter, opts)

    scheduled_execution =
      case Keyword.get(opts, :scheduled_execution_id) do
        nil -> List.first(ticks)
        id -> Enum.find(ticks, &(&1.id == id)) || raise "auto-advance tick not found: #{id}"
      end

    unless scheduled_execution do
      raise "no pending auto-advance tick found"
    end

    maybe_set_fake_clock!(adapter, Keyword.get(opts, :evaluated_at))

    adapter.execute_scheduled_execution(
      Command.ExecuteScheduledExecution.new(scheduled_execution.id,
        actor: %{id: "system:scheduler", type: "system", display: "Scheduler"},
        reason: "Execute auto-advance observation window tick",
        metadata: %{
          request_id: "req-auto-advance-#{System.unique_integer([:positive])}",
          source: :scheduled_execution_worker
        }
      )
    )
  end

  defp auto_advance_tick?(scheduled_execution) do
    metadata = Map.get(scheduled_execution, :metadata) || %{}
    source = Map.get(metadata, :source) || Map.get(metadata, "source")
    source in ["guardrail_automation", :guardrail_automation]
  end

  defp maybe_set_fake_clock!(Rulestead.Fake, %DateTime{} = evaluated_at) do
    Rulestead.Fake.Control.set_now!(evaluated_at)
  end

  defp maybe_set_fake_clock!(_adapter, _evaluated_at), do: :ok

  defp maybe_put(keyword, _key, nil), do: keyword
  defp maybe_put(keyword, key, value), do: Keyword.put(keyword, key, value)

  @spec invalid_operator_payload_ruleset_attrs() :: map()
  def invalid_operator_payload_ruleset_attrs do
    valid_ruleset_attrs(%{
      rules: [
        %{
          key: "bad-in",
          strategy: :forced_value,
          value: %{value: true},
          conditions: [
            %{attribute: "attributes.region", operator: :in, value: %{in: ["us", 1]}}
          ]
        }
      ]
    })
  end
end
