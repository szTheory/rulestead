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
      owner: "growth",
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
          rollout: %{bucket_by: :subject, percentage: 100, salt: "checkout-rollout"},
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
            %{attribute: "attributes.email", operator: :regex, value: %{pattern: "(", options: "("}}
          ]
        }
      ]
    })
  end

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
