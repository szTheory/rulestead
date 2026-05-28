defmodule Rulestead.Fake.Control do
  @moduledoc false
  # Test-only controls for `Rulestead.Fake`.
  #
  # These helpers are intentionally separate from the shared `Rulestead.Store`
  # behaviour so production callers cannot rely on fake-only affordances.

  alias Rulestead.Fake
  alias Rulestead.Runtime.{Config, Notifier}
  alias Rulestead.Store.Command

  @spec ensure_started() :: :ok
  def ensure_started do
    case Process.whereis(Fake) do
      nil ->
        case Fake.start_link() do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> raise "failed to start Rulestead.Fake: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end

  @spec reset!(keyword()) :: :ok
  def reset!(opts \\ []) do
    ensure_started()

    case Fake.reset(opts) do
      :ok -> :ok
      {:error, error} -> raise error
    end

    if Keyword.get(opts, :seed_defaults, true) do
      put_audience!(default_audience_seed_attrs())
    end

    :ok
  end

  defp default_audience_seed_attrs do
    %{
      key: "vip-users",
      name: "VIP Users",
      description: "VIP cohort for default ruleset fixtures",
      definition: %{
        conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]
      }
    }
  end

  @spec put_environment!(map()) :: map()
  def put_environment!(attrs) do
    ensure_started()

    case Fake.put_environment(attrs) do
      {:ok, environment} -> environment
      {:error, error} -> raise error
    end
  end

  @spec put_flag!(map()) :: map()
  def put_flag!(attrs) do
    ensure_started()

    case Fake.put_flag(normalize_seed_attrs(attrs)) do
      {:ok, flag} -> flag
      {:error, error} -> raise error
    end
  end

  @spec put_flag(map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def put_flag(attrs) do
    ensure_started()
    Fake.put_flag(normalize_seed_attrs(attrs))
  end

  @spec put_audience!(map()) :: map()
  def put_audience!(attrs) do
    ensure_started()

    case Fake.put_audience(attrs) do
      {:ok, audience} -> audience
      {:error, error} -> raise error
    end
  end

  @spec snapshot!() :: map()
  def snapshot! do
    ensure_started()

    case Fake.snapshot() do
      {:ok, state} -> state
      {:error, error} -> raise error
    end
  end

  @spec restore!(map()) :: :ok
  def restore!(state) when is_map(state) do
    ensure_started()

    case GenServer.call(Fake, {:control, :restore, state}) do
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  @spec now!() :: DateTime.t()
  def now! do
    ensure_started()

    case Fake.now() do
      {:ok, now} -> now
      {:error, error} -> raise error
    end
  end

  @spec set_now!(DateTime.t()) :: DateTime.t()
  def set_now!(%DateTime{} = now) do
    ensure_started()

    case Fake.set_now(now) do
      {:ok, updated_now} -> updated_now
      {:error, error} -> raise error
    end
  end

  @spec advance_time!(integer()) :: DateTime.t()
  def advance_time!(seconds) when is_integer(seconds) do
    ensure_started()

    case Fake.advance_time(seconds) do
      {:ok, updated_now} -> updated_now
      {:error, error} -> raise error
    end
  end

  @spec latest_snapshot!(String.t() | atom()) :: map()
  def latest_snapshot!(environment_key) do
    ensure_started()

    case GenServer.call(Fake, {:control, :latest_snapshot, environment_key}) do
      {:ok, snapshot} -> snapshot
      {:error, error} -> raise error
    end
  end

  @spec disconnect!() :: :ok
  def disconnect! do
    ensure_started()
    GenServer.call(Fake, {:control, :disconnect})
  end

  @spec reconnect!() :: :ok
  def reconnect! do
    ensure_started()
    GenServer.call(Fake, {:control, :reconnect})
  end

  @spec list_audience_dependencies!(map()) :: map()
  def list_audience_dependencies!(command \\ %{}) do
    ensure_started()

    case Fake.list_audience_dependencies(command) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec list_change_requests!(keyword()) :: map()
  def list_change_requests!(opts \\ []) do
    ensure_started()

    case Fake.list_change_requests(Command.ListChangeRequests.new(opts)) do
      {:ok, page} -> page
      {:error, error} -> raise error
    end
  end

  @spec rebuild_audience_reference_projection!() :: map()
  def rebuild_audience_reference_projection! do
    ensure_started()

    case Fake.rebuild_audience_reference_projection() do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec put_test_flag!(String.t() | atom(), term(), keyword()) :: map()
  def put_test_flag!(flag_key, value, opts \\ []) do
    ensure_started()

    environment_key = opts |> Keyword.get(:environment, "test") |> to_string()
    ensure_environment!(environment_key)

    put_flag!(%{
      key: to_string(flag_key),
      flag_type: :release,
      value_type: infer_value_type(value),
      default_value: %{value: value},
      ownership: %{owner_ref: "test-suite", owner_kind: :team, owner_display: "test-suite"},
      lifecycle: %{
        mode: :expiring,
        review_by: Date.utc_today(),
        default_source: :operator_override,
        default_overridden: true
      },
      environment_keys: [environment_key]
    })

    ruleset = %{
      salt: "#{flag_key}:#{environment_key}",
      rules: [
        %{
          key: "forced-value",
          strategy: :forced_value,
          value: %{value: value},
          conditions: []
        }
      ]
    }

    case Fake.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)) do
      {:ok, _draft} -> :ok
      {:error, error} -> raise error
    end

    case Fake.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key)) do
      {:ok, _published} -> fetch_flag!(flag_key, environment_key)
      {:error, error} -> raise error
    end
  end

  @spec seed_bucket!(String.t() | atom(), String.t() | atom(), String.t() | atom()) :: map()
  def seed_bucket!(flag_key, targeting_key, variant) do
    ensure_started()
    environment_key = "test"
    ensure_environment!(environment_key)

    put_flag!(%{
      key: to_string(flag_key),
      flag_type: :experiment,
      value_type: :variant,
      default_value: %{value: nil},
      ownership: %{owner_ref: "test-suite", owner_kind: :team, owner_display: "test-suite"},
      lifecycle: %{
        mode: :expiring,
        review_by: Date.utc_today(),
        default_source: :operator_override,
        default_overridden: true
      },
      environment_keys: [environment_key]
    })

    ruleset = %{
      salt: "#{flag_key}:#{targeting_key}",
      rules: [
        %{
          key: "seeded-variant",
          strategy: :variant_split,
          conditions: [
            %{
              attribute: "targeting_key",
              operator: :equals,
              value: %{equals: to_string(targeting_key)}
            }
          ],
          rollout: %{bucket_by: :subject, percentage: 100, salt: "seeded"},
          variants: [
            %{key: to_string(variant), value: %{value: to_string(variant)}, weight: 100}
          ]
        }
      ]
    }

    case Fake.save_draft_ruleset(Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)) do
      {:ok, _draft} -> :ok
      {:error, error} -> raise error
    end

    case Fake.publish_ruleset(Command.PublishRuleset.new(flag_key, environment_key)) do
      {:ok, _published} -> fetch_flag!(flag_key, environment_key)
      {:error, error} -> raise error
    end
  end

  @spec publish!(module() | atom(), String.t() | atom(), pos_integer(), keyword()) :: :ok
  def publish!(pubsub, environment_key, snapshot_version, opts \\ []) do
    notifier = Keyword.get(opts, :notifier, Config.notifier())

    case Notifier.broadcast(
           notifier,
           %{environment_key: to_string(environment_key), snapshot_version: snapshot_version},
           Keyword.merge(
             [
               pubsub: pubsub,
               pubsub_topic: Keyword.get(opts, :pubsub_topic, Config.pubsub_topic())
             ],
             opts
           )
         ) do
      :ok -> :ok
      {:error, error} -> raise "failed to publish invalidation: #{inspect(error)}"
    end
  end

  defp ensure_environment!(environment_key) do
    state = snapshot!()

    if Map.has_key?(state.environments, environment_key) do
      :ok
    else
      put_environment!(%{key: environment_key, name: String.capitalize(environment_key)})
      :ok
    end
  end

  defp fetch_flag!(flag_key, environment_key) do
    case Fake.fetch_flag(Command.FetchFlag.new(flag_key, environment_key)) do
      {:ok, payload} -> payload
      {:error, error} -> raise error
    end
  end

  defp normalize_seed_attrs(attrs) when is_map(attrs) do
    attrs
    |> Map.put(:ownership, Command.normalize_ownership(attrs))
    |> Map.put(:lifecycle, Command.normalize_lifecycle(attrs))
  end

  defp normalize_seed_attrs(attrs), do: attrs

  defp infer_value_type(value) when is_boolean(value), do: :boolean
  defp infer_value_type(value) when is_binary(value), do: :string
  defp infer_value_type(value) when is_integer(value), do: :integer
  defp infer_value_type(value) when is_float(value), do: :float
  defp infer_value_type(_value), do: :json
end
