# credo:disable-for-this-file
defmodule Rulestead.Store.Command do
  @moduledoc """
  Shared key-first command structs for `Rulestead.Store` adapters.

  Public selectors stay on `flag_key` and `environment_key`; internal UUIDs
  remain adapter-private.
  """

  alias Rulestead.Admin.LifecycleDefaults
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Governance.ScheduledExecution

  defmodule GovernanceSupport do
    @moduledoc false

    @tenant_scope_sources ["explicit", "host_resolved", "single_tenant"]
    @tenant_validation_evidence ["same_tenant_guard", "single_tenant", "not_applicable"]
    @tenant_validation_status ["passed", "bypassed"]
    @guardrail_statuses ["healthy", "breached", "failed_closed"]
    @guardrail_reasons [
      "healthy",
      "breached",
      "provider_missing",
      "unsupported_scope",
      "unsupported_signal",
      "stale",
      "insufficient_sample",
      "invalid_provider_response"
    ]
    @guardrail_threshold_operators ["lt", "lte", "gt", "gte"]
    @guardrail_environment_scopes ["environment"]
    @guardrail_tenant_scopes ["required", "not_applicable"]

    def fetch_required!(attrs, key) do
      case fetch(attrs, key) do
        nil -> raise KeyError, key: key, term: attrs
        value -> value
      end
    end

    def fetch(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

    def normalize_string(value) when is_binary(value) do
      value
      |> String.trim()
      |> case do
        "" -> nil
        normalized -> normalized
      end
    end

    def normalize_string(nil), do: nil

    def normalize_string(value) when is_atom(value),
      do: value |> Atom.to_string() |> normalize_string()

    def normalize_string(value) when is_integer(value), do: Integer.to_string(value)
    def normalize_string(value), do: value

    def normalize_actor(nil), do: nil

    def normalize_actor(actor) when is_list(actor) or is_map(actor) do
      actor = Map.new(actor)

      %{}
      |> maybe_put("id", fetch(actor, :id) |> normalize_string())
      |> maybe_put("type", fetch(actor, :type) |> normalize_string())
      |> maybe_put("display", fetch(actor, :display) |> normalize_string())
      |> maybe_put("roles", fetch(actor, :roles) || fetch(actor, :role))
    end

    def normalize_actor(_actor), do: nil

    def normalize_metadata(metadata), do: metadata |> normalize_map() |> drop_sensitive_keys()
    def normalize_command(metadata), do: normalize_map(metadata)

    def normalize_tenant_provenance(nil), do: nil

    def normalize_tenant_provenance(value) when is_list(value) or is_map(value) do
      value = normalize_map(value)
      validation = normalize_tenant_validation_map(Map.get(value, "validation"))

      provenance =
        %{}
        |> maybe_put("tenant_key", normalize_string(Map.get(value, "tenant_key")))
        |> maybe_put(
          "scope_source",
          normalize_enum(Map.get(value, "scope_source"), @tenant_scope_sources)
        )
        |> maybe_put("validation", validation)

      if map_size(provenance) == 0, do: nil, else: provenance
    end

    def normalize_tenant_provenance(_value), do: nil

    def tenant_provenance(source, opts \\ []) do
      metadata =
        opts
        |> Keyword.get(:metadata, fetch(source, :metadata))
        |> normalize_metadata()

      fallback =
        opts
        |> Keyword.get(:fallback)
        |> fallback_tenant_provenance()

      existing =
        metadata
        |> metadata_tenant_provenance()
        |> case do
          nil -> fallback
          provenance -> merge_tenant_provenance(fallback, provenance)
        end

      tenant_key =
        existing_tenant_key(existing) ||
          source_tenant_key(source) ||
          metadata_tenant_key(metadata)

      single_tenant? =
        Keyword.get(opts, :tenancy_module, Rulestead.Tenancy.module()) ==
          Rulestead.Tenancy.SingleTenant

      scope_source =
        existing_scope_source(existing) ||
          normalize_enum(metadata["tenant_scope_source"], @tenant_scope_sources) ||
          default_scope_source(tenant_key, single_tenant?)

      validation =
        tenant_validation(
          existing_validation(existing),
          metadata,
          tenant_key,
          single_tenant?
        )

      %{}
      |> maybe_put("tenant_key", tenant_key)
      |> maybe_put("scope_source", scope_source)
      |> maybe_put("validation", validation)
    end

    def with_tenant_provenance(payload, source \\ nil, opts \\ [])
        when is_list(payload) or is_map(payload) do
      payload = normalize_map(payload)
      provenance = tenant_provenance(source || payload, Keyword.put(opts, :metadata, payload))

      payload
      |> maybe_put("tenant_key", Map.get(provenance, "tenant_key"))
      |> Map.put("tenant", provenance)
    end

    def normalize_approval_requirement(%ApprovalRequirement{} = requirement),
      do: requirement |> ApprovalRequirement.serialize() |> normalize_map()

    def normalize_approval_requirement(requirement)
        when is_list(requirement) or is_map(requirement),
        do:
          requirement
          |> ApprovalRequirement.new()
          |> ApprovalRequirement.serialize()
          |> normalize_map()

    def normalize_approval_requirement(_requirement), do: %{}

    def normalize_guardrail_metadata(nil), do: %{}

    def normalize_guardrail_metadata(value) when is_list(value) or is_map(value) do
      value = normalize_map(value)
      tenant_key = normalize_string(Map.get(value, "tenant_key"))

      tenant =
        tenant_provenance(
          %{"tenant_key" => tenant_key},
          metadata: value,
          fallback: Map.get(value, "tenant") || Map.get(value, "tenant_provenance")
        )

      evidence =
        %{}
        |> maybe_put("status", normalize_enum(Map.get(value, "status"), @guardrail_statuses))
        |> maybe_put("reason", normalize_enum(Map.get(value, "reason"), @guardrail_reasons))
        |> maybe_put(
          "threshold_operator",
          normalize_enum(Map.get(value, "threshold_operator"), @guardrail_threshold_operators)
        )
        |> maybe_put("threshold_value", normalize_numeric(Map.get(value, "threshold_value")))
        |> maybe_put("observed_value", normalize_numeric(Map.get(value, "observed_value")))
        |> maybe_put(
          "freshness_window_seconds",
          normalize_non_negative_integer(Map.get(value, "freshness_window_seconds"))
        )
        |> maybe_put("sample_size", normalize_non_negative_integer(Map.get(value, "sample_size")))
        |> maybe_put(
          "min_sample_size",
          normalize_non_negative_integer(Map.get(value, "min_sample_size"))
        )
        |> maybe_put("captured_at", normalize_datetime_string(Map.get(value, "captured_at")))
        |> maybe_put("evaluated_at", normalize_datetime_string(Map.get(value, "evaluated_at")))
        |> maybe_put("metadata", normalize_metadata(Map.get(value, "metadata")))

      %{}
      |> maybe_put("signal_key", normalize_string(Map.get(value, "signal_key")))
      |> maybe_put("environment_key", normalize_string(Map.get(value, "environment_key")))
      |> maybe_put("tenant_key", tenant_key)
      |> maybe_put(
        "environment_scope",
        normalize_enum(Map.get(value, "environment_scope"), @guardrail_environment_scopes)
      )
      |> maybe_put(
        "tenant_scope",
        normalize_enum(Map.get(value, "tenant_scope"), @guardrail_tenant_scopes)
      )
      |> maybe_put(
        "scope_source",
        normalize_enum(Map.get(value, "scope_source"), @tenant_scope_sources)
      )
      |> maybe_put("tenant", tenant)
      |> maybe_put("evidence", if(map_size(evidence) == 0, do: nil, else: evidence))
    end

    def normalize_guardrail_metadata(_value), do: %{}

    def normalize_map(nil), do: %{}
    def normalize_map(value) when is_list(value), do: value |> Map.new() |> normalize_map()

    def normalize_map(map) when is_map(map) do
      Map.new(map, fn
        {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
        {key, value} -> {to_string(key), normalize_value(value)}
      end)
    end

    def normalize_map(_value), do: %{}

    def normalize_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
    def normalize_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
    def normalize_value(%Date{} = value), do: Date.to_iso8601(value)
    def normalize_value(value) when is_map(value), do: normalize_map(value)
    def normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
    def normalize_value(value) when is_boolean(value), do: value
    def normalize_value(nil), do: nil
    def normalize_value(value) when is_atom(value), do: Atom.to_string(value)
    def normalize_value(value), do: value

    def maybe_put(map, _key, nil), do: map
    def maybe_put(map, key, value), do: Map.put(map, key, value)

    defp fallback_tenant_provenance(nil), do: nil

    defp fallback_tenant_provenance(value) do
      normalize_tenant_provenance(value) ||
        value
        |> normalize_map()
        |> metadata_tenant_provenance()
    end

    defp metadata_tenant_provenance(metadata) do
      metadata["tenant"] || metadata["tenant_provenance"]
    end

    defp merge_tenant_provenance(nil, provenance), do: provenance
    defp merge_tenant_provenance(provenance, nil), do: provenance

    defp merge_tenant_provenance(left, right) do
      Map.merge(left, right, fn
        "validation", left_validation, right_validation ->
          Map.merge(left_validation || %{}, right_validation || %{})

        _key, _left, right_value ->
          right_value
      end)
    end

    defp existing_tenant_key(nil), do: nil
    defp existing_tenant_key(provenance), do: normalize_string(Map.get(provenance, "tenant_key"))

    defp existing_scope_source(nil), do: nil

    defp existing_scope_source(provenance),
      do: normalize_enum(Map.get(provenance, "scope_source"), @tenant_scope_sources)

    defp existing_validation(nil), do: nil
    defp existing_validation(provenance), do: Map.get(provenance, "validation")

    defp source_tenant_key(source) do
      source
      |> fetch(:tenant_key)
      |> normalize_string()
    end

    defp metadata_tenant_key(metadata), do: normalize_string(metadata["tenant_key"])

    defp default_scope_source(tenant_key, _single_tenant?) when is_binary(tenant_key),
      do: "explicit"

    defp default_scope_source(_tenant_key, true), do: "single_tenant"
    defp default_scope_source(_tenant_key, false), do: "host_resolved"

    defp tenant_validation(existing, metadata, tenant_key, single_tenant?) do
      existing = normalize_tenant_validation_map(existing) || %{}

      evidence =
        Map.get(existing, "evidence") ||
          normalize_enum(metadata["tenant_validation_evidence"], @tenant_validation_evidence) ||
          default_validation_evidence(tenant_key, single_tenant?)

      status =
        Map.get(existing, "status") ||
          normalize_enum(metadata["tenant_validation_status"], @tenant_validation_status) ||
          default_validation_status(tenant_key)

      %{}
      |> maybe_put("evidence", evidence)
      |> maybe_put("status", status)
      |> case do
        validation when map_size(validation) == 0 -> nil
        validation -> validation
      end
    end

    defp normalize_tenant_validation_map(nil), do: nil

    defp normalize_tenant_validation_map(value) when is_list(value) or is_map(value) do
      value = normalize_map(value)

      validation =
        %{}
        |> maybe_put(
          "evidence",
          normalize_enum(Map.get(value, "evidence"), @tenant_validation_evidence)
        )
        |> maybe_put(
          "status",
          normalize_enum(Map.get(value, "status"), @tenant_validation_status)
        )

      if map_size(validation) == 0, do: nil, else: validation
    end

    defp normalize_tenant_validation_map(_value), do: nil

    defp default_validation_evidence(tenant_key, _single_tenant?) when is_binary(tenant_key),
      do: "same_tenant_guard"

    defp default_validation_evidence(_tenant_key, true), do: "single_tenant"
    defp default_validation_evidence(_tenant_key, false), do: "not_applicable"

    defp default_validation_status(tenant_key) when is_binary(tenant_key), do: "passed"
    defp default_validation_status(_tenant_key), do: "bypassed"

    defp normalize_enum(value, allowed) do
      value = normalize_string(value)
      if value in allowed, do: value, else: nil
    end

    defp normalize_numeric(value) when is_integer(value) or is_float(value), do: value

    defp normalize_numeric(value) when is_binary(value) do
      value = String.trim(value)

      cond do
        value == "" ->
          nil

        String.contains?(value, ".") ->
          case Float.parse(value) do
            {parsed, ""} -> parsed
            _other -> nil
          end

        true ->
          case Integer.parse(value) do
            {parsed, ""} -> parsed
            _other -> nil
          end
      end
    end

    defp normalize_numeric(_value), do: nil

    defp normalize_non_negative_integer(value) when is_integer(value) and value >= 0, do: value

    defp normalize_non_negative_integer(value) when is_float(value) and value >= 0,
      do: trunc(value)

    defp normalize_non_negative_integer(value) when is_binary(value) do
      case Integer.parse(String.trim(value)) do
        {parsed, ""} when parsed >= 0 -> parsed
        _other -> nil
      end
    end

    defp normalize_non_negative_integer(_value), do: nil

    defp normalize_datetime_string(%DateTime{} = value), do: DateTime.to_iso8601(value)
    defp normalize_datetime_string(value), do: normalize_string(value)

    defp drop_sensitive_keys(map) do
      map
      |> Map.drop([
        "admin_session",
        "session",
        "session_data",
        "session_id",
        "session_token",
        "socket"
      ])
      |> Map.new(fn
        {key, value} when is_map(value) -> {key, drop_sensitive_keys(value)}
        {key, value} when is_list(value) -> {key, Enum.map(value, &drop_sensitive_value/1)}
        entry -> entry
      end)
    end

    defp drop_sensitive_value(value) when is_map(value), do: drop_sensitive_keys(value)
    defp drop_sensitive_value(value), do: value
  end

  @owner_kinds [:person, :team, :service]
  @lifecycle_modes [:expiring, :permanent]
  @lifecycle_default_sources [
    :flag_type,
    :operator_override,
    :operator_required,
    :legacy_backfill
  ]

  @spec normalize_ownership(map() | keyword()) :: nil | map()
  def normalize_ownership(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)
    ownership = fetch_nested(attrs, :ownership)
    picker = fetch_nested(attrs, :owner_picker)

    owner_ref =
      ownership
      |> fetch_optional(:owner_ref)
      |> Kernel.||(GovernanceSupport.fetch(attrs, :owner_ref))
      |> Kernel.||(fetch_optional(picker, :owner_ref))
      |> GovernanceSupport.normalize_string()

    owner_kind =
      ownership
      |> fetch_optional(:owner_kind)
      |> Kernel.||(GovernanceSupport.fetch(attrs, :owner_kind))
      |> Kernel.||(fetch_optional(picker, :owner_kind))
      |> normalize_owner_kind()

    owner_display =
      ownership
      |> fetch_optional(:owner_display)
      |> Kernel.||(GovernanceSupport.fetch(attrs, :owner_display))
      |> Kernel.||(fetch_optional(picker, :owner_display))
      |> GovernanceSupport.normalize_string()

    if is_binary(owner_ref) do
      %{
        owner_ref: owner_ref,
        owner_kind: owner_kind || :team,
        owner_display: owner_display
      }
    else
      case GovernanceSupport.normalize_string(GovernanceSupport.fetch(attrs, :owner)) do
        nil -> nil
        normalized -> %{owner_ref: normalized, owner_kind: :team, owner_display: normalized}
      end
    end
  end

  @spec ownership_label(nil | map(), term()) :: nil | String.t()
  def ownership_label(nil, owner), do: GovernanceSupport.normalize_string(owner)

  def ownership_label(ownership, owner) do
    GovernanceSupport.normalize_string(fetch_optional(ownership, :owner_display)) ||
      GovernanceSupport.normalize_string(fetch_optional(ownership, :owner_ref)) ||
      GovernanceSupport.normalize_string(owner)
  end

  @spec normalize_lifecycle(map() | keyword()) :: map()
  def normalize_lifecycle(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)
    lifecycle = fetch_nested(attrs, :lifecycle)

    explicit_mode =
      lifecycle
      |> fetch_optional(:mode)
      |> Kernel.||(GovernanceSupport.fetch(attrs, :lifecycle_mode))
      |> normalize_lifecycle_mode()

    review_by =
      lifecycle
      |> fetch_optional(:review_by)
      |> Kernel.||(GovernanceSupport.fetch(attrs, :review_by))
      |> Kernel.||(GovernanceSupport.fetch(attrs, :expected_expiration))

    suggestion =
      LifecycleDefaults.suggest(
        GovernanceSupport.fetch(attrs, :flag_type),
        authored_mode: explicit_mode,
        authored_review_by: review_by
      )

    permanent? =
      case GovernanceSupport.fetch(attrs, :permanent) do
        value when value in [true, "true", 1, "1"] -> true
        _other -> false
      end

    mode = explicit_mode || if(permanent?, do: :permanent, else: :expiring)

    overridden? =
      lifecycle
      |> fetch_optional(:default_overridden)
      |> normalize_boolean()
      |> Kernel.||(Map.get(suggestion, :default_overridden, false))

    default_source =
      lifecycle
      |> fetch_optional(:default_source)
      |> normalize_default_source()
      |> Kernel.||(default_source_for(mode, suggestion, overridden?))

    %{
      mode: mode,
      review_by: review_by,
      default_source: default_source,
      default_overridden: overridden?
    }
  end

  def normalize_lifecycle(attrs) do
    permanent? =
      case GovernanceSupport.fetch(attrs, :permanent) do
        value when value in [true, "true", 1, "1"] -> true
        _other -> false
      end

    %{
      mode: if(permanent?, do: :permanent, else: :expiring),
      review_by: GovernanceSupport.fetch(attrs, :expected_expiration),
      default_source: :legacy_backfill,
      default_overridden: false
    }
  end

  @spec lifecycle_update(nil | map() | keyword()) :: nil | map()
  def lifecycle_update(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)
    lifecycle = fetch_nested(attrs, :lifecycle)

    lifecycle_provided? =
      not is_nil(lifecycle) or
        not is_nil(GovernanceSupport.fetch(attrs, :permanent)) or
        not is_nil(GovernanceSupport.fetch(attrs, :expected_expiration)) or
        not is_nil(GovernanceSupport.fetch(attrs, :review_by)) or
        not is_nil(GovernanceSupport.fetch(attrs, :lifecycle_mode))

    if lifecycle_provided?, do: normalize_lifecycle(attrs), else: nil
  end

  def lifecycle_update(_attrs), do: nil

  defp fetch_nested(attrs, key) do
    case GovernanceSupport.fetch(attrs, key) do
      value when is_list(value) or is_map(value) -> Map.new(value)
      _other -> nil
    end
  end

  defp fetch_optional(nil, _key), do: nil
  defp fetch_optional(map, key), do: GovernanceSupport.fetch(map, key)

  defp normalize_owner_kind(value) do
    value =
      value
      |> GovernanceSupport.normalize_string()
      |> string_to_existing_atom()

    if value in @owner_kinds, do: value, else: nil
  end

  defp normalize_lifecycle_mode(value) do
    value =
      value
      |> GovernanceSupport.normalize_string()
      |> string_to_existing_atom()

    if value in @lifecycle_modes, do: value, else: nil
  end

  defp normalize_default_source(value) do
    value =
      value
      |> GovernanceSupport.normalize_string()
      |> string_to_existing_atom()

    if value in @lifecycle_default_sources, do: value, else: nil
  end

  defp string_to_existing_atom(nil), do: nil

  defp string_to_existing_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> nil
    end
  end

  defp normalize_boolean(value) when value in [true, "true", 1, "1"], do: true
  defp normalize_boolean(value) when value in [false, "false", 0, "0"], do: false
  defp normalize_boolean(_value), do: nil

  defp default_source_for(_mode, _suggestion, true), do: :operator_override
  defp default_source_for(_mode, %{default_source: source}, false), do: source
  defp default_source_for(_mode, _suggestion, false), do: :legacy_backfill

  defmodule FetchSnapshot do
    @moduledoc false

    @enforce_keys [:environment_key]
    defstruct [:environment_key, version: nil]

    @type t :: %__MODULE__{
            environment_key: String.t() | atom(),
            version: nil | pos_integer()
          }

    @spec new(String.t() | atom(), keyword()) :: t()
    def new(environment_key, opts \\ []) do
      %__MODULE__{
        environment_key: environment_key,
        version: Keyword.get(opts, :version)
      }
    end
  end

  defmodule Page do
    @moduledoc false

    defstruct entries: [],
              limit: 50,
              next_cursor: nil,
              prev_cursor: nil,
              has_next_page?: false,
              has_previous_page?: false

    @type t(entry) :: %__MODULE__{
            entries: [entry],
            limit: pos_integer(),
            next_cursor: nil | String.t(),
            prev_cursor: nil | String.t(),
            has_next_page?: boolean(),
            has_previous_page?: boolean()
          }
  end

  defmodule FetchFlag do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key]
    defstruct [:flag_key, :environment_key, include_ruleset?: true]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            include_ruleset?: boolean()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(flag_key, environment_key, opts \\ []) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        include_ruleset?: Keyword.get(opts, :include_ruleset?, true)
      }
    end
  end

  defmodule CompareEnvironments do
    @moduledoc false

    @enforce_keys [:source_environment_key, :target_environment_key]
    defstruct [
      :source_environment_key,
      :target_environment_key,
      tenant_key: nil,
      flag_keys: nil,
      compare_token: nil
    ]

    @type t :: %__MODULE__{
            source_environment_key: String.t(),
            target_environment_key: String.t(),
            tenant_key: nil | String.t(),
            flag_keys: nil | [String.t()],
            compare_token: nil | String.t()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(source_environment_key, target_environment_key, opts \\ []) do
      %__MODULE__{
        source_environment_key: GovernanceSupport.normalize_string(source_environment_key),
        target_environment_key: GovernanceSupport.normalize_string(target_environment_key),
        tenant_key: GovernanceSupport.normalize_string(Keyword.get(opts, :tenant_key)),
        flag_keys: normalize_flag_keys(Keyword.get(opts, :flag_keys)),
        compare_token: GovernanceSupport.normalize_string(Keyword.get(opts, :compare_token))
      }
    end

    defp normalize_flag_keys(nil), do: nil
    defp normalize_flag_keys([]), do: nil

    defp normalize_flag_keys(flag_keys) when is_list(flag_keys) do
      flag_keys
      |> Enum.map(&GovernanceSupport.normalize_string/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()
      |> case do
        [] -> nil
        normalized -> normalized
      end
    end

    defp normalize_flag_keys(flag_key) do
      normalize_flag_keys([flag_key])
    end
  end

  defmodule ApplyPromotion do
    @moduledoc false

    alias Rulestead.Promotion.Apply
    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [
      :source_environment_key,
      :target_environment_key,
      :flag_keys,
      :compare_token,
      :compare_schema_version,
      :source_fingerprint,
      :target_fingerprint,
      :dependency_closure_keys,
      :proposed_target_bundle
    ]
    defstruct [
      :source_environment_key,
      :target_environment_key,
      :tenant_key,
      :flag_keys,
      :compare_token,
      :compare_schema_version,
      :source_fingerprint,
      :target_fingerprint,
      :dependency_closure_keys,
      :proposed_target_bundle,
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            source_environment_key: String.t(),
            target_environment_key: String.t(),
            tenant_key: nil | String.t(),
            flag_keys: [String.t()],
            compare_token: String.t(),
            compare_schema_version: pos_integer(),
            source_fingerprint: String.t(),
            target_fingerprint: String.t(),
            dependency_closure_keys: [String.t()],
            proposed_target_bundle: map(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        source_environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:source_environment_key)
          |> GovernanceSupport.normalize_string(),
        target_environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:target_environment_key)
          |> GovernanceSupport.normalize_string(),
        tenant_key:
          attrs
          |> GovernanceSupport.fetch(:tenant_key)
          |> GovernanceSupport.normalize_string(),
        flag_keys:
          attrs
          |> GovernanceSupport.fetch_required!(:flag_keys)
          |> normalize_flag_keys(),
        compare_token:
          attrs
          |> GovernanceSupport.fetch_required!(:compare_token)
          |> GovernanceSupport.normalize_string(),
        compare_schema_version:
          attrs
          |> GovernanceSupport.fetch_required!(:compare_schema_version)
          |> normalize_schema_version(),
        source_fingerprint:
          attrs
          |> GovernanceSupport.fetch_required!(:source_fingerprint)
          |> GovernanceSupport.normalize_string(),
        target_fingerprint:
          attrs
          |> GovernanceSupport.fetch_required!(:target_fingerprint)
          |> GovernanceSupport.normalize_string(),
        dependency_closure_keys:
          attrs
          |> GovernanceSupport.fetch_required!(:dependency_closure_keys)
          |> normalize_flag_keys(),
        proposed_target_bundle:
          attrs
          |> GovernanceSupport.fetch_required!(:proposed_target_bundle)
          |> Apply.normalize_proposed_target_bundle(),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_schema_version(version) when is_integer(version) and version > 0, do: version

    defp normalize_schema_version(version) when is_binary(version) do
      case Integer.parse(version) do
        {parsed, ""} when parsed > 0 -> parsed
        _other -> version
      end
    end

    defp normalize_schema_version(version), do: version

    defp normalize_flag_keys(nil), do: []
    defp normalize_flag_keys([]), do: []

    defp normalize_flag_keys(values) when is_list(values) do
      values
      |> Enum.map(&GovernanceSupport.normalize_string/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()
    end

    defp normalize_flag_keys(value), do: normalize_flag_keys([value])
  end

  defmodule PreviewManifestImport do
    @moduledoc false

    alias Rulestead.Manifest
    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:source_environment_key, :target_environment_key, :manifest]
    defstruct [:source_environment_key, :target_environment_key, :manifest]

    @type t :: %__MODULE__{
            source_environment_key: String.t(),
            target_environment_key: String.t(),
            manifest: map()
          }

    @spec new(map() | keyword()) :: t()
    def new(attrs) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        source_environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:source_environment_key)
          |> GovernanceSupport.normalize_string(),
        target_environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:target_environment_key)
          |> GovernanceSupport.normalize_string(),
        manifest:
          attrs
          |> GovernanceSupport.fetch_required!(:manifest)
          |> Manifest.normalize_map()
      }
    end
  end

  defmodule ApplyManifestImport do
    @moduledoc false

    alias Rulestead.Promotion.Apply
    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [
      :target_environment_key,
      :plan_token,
      :target_fingerprint,
      :dependency_closure_keys,
      :flag_keys,
      :proposed_target_bundle
    ]
    defstruct [
      :source_environment_key,
      :target_environment_key,
      :tenant_key,
      :plan_token,
      :target_fingerprint,
      :dependency_closure_keys,
      :flag_keys,
      :proposed_target_bundle,
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            source_environment_key: nil | String.t(),
            target_environment_key: String.t(),
            tenant_key: nil | String.t(),
            plan_token: String.t(),
            target_fingerprint: String.t(),
            dependency_closure_keys: [String.t()],
            flag_keys: [String.t()],
            proposed_target_bundle: map(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        source_environment_key:
          attrs
          |> GovernanceSupport.fetch(:source_environment_key)
          |> GovernanceSupport.normalize_string(),
        target_environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:target_environment_key)
          |> GovernanceSupport.normalize_string(),
        tenant_key:
          attrs
          |> GovernanceSupport.fetch(:tenant_key)
          |> GovernanceSupport.normalize_string(),
        plan_token:
          attrs
          |> GovernanceSupport.fetch_required!(:plan_token)
          |> GovernanceSupport.normalize_string(),
        target_fingerprint:
          attrs
          |> GovernanceSupport.fetch_required!(:target_fingerprint)
          |> GovernanceSupport.normalize_string(),
        dependency_closure_keys:
          attrs
          |> GovernanceSupport.fetch_required!(:dependency_closure_keys)
          |> normalize_flag_keys(),
        flag_keys:
          attrs
          |> GovernanceSupport.fetch_required!(:flag_keys)
          |> normalize_flag_keys(),
        proposed_target_bundle:
          attrs
          |> GovernanceSupport.fetch_required!(:proposed_target_bundle)
          |> Apply.normalize_proposed_target_bundle(),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_flag_keys(nil), do: []

    defp normalize_flag_keys(values) when is_list(values) do
      values
      |> Enum.map(&GovernanceSupport.normalize_string/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()
    end

    defp normalize_flag_keys(value), do: normalize_flag_keys([value])
  end

  defmodule CreateFlag do
    @moduledoc false

    @enforce_keys [:key, :flag_type, :value_type, :default_value]
    defstruct [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :owner,
      :ownership,
      :expected_expiration,
      :permanent,
      :lifecycle,
      environment_keys: [],
      tags: [],
      actor: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            key: String.t() | atom(),
            description: nil | String.t(),
            flag_type: atom(),
            value_type: atom(),
            default_value: map(),
            owner: String.t(),
            ownership: nil | map(),
            expected_expiration: nil | Date.t(),
            permanent: nil | boolean(),
            lifecycle: nil | map(),
            environment_keys: [String.t() | atom()],
            tags: [String.t()],
            actor: nil | map(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)
      ownership = Rulestead.Store.Command.normalize_ownership(attrs)
      lifecycle = Rulestead.Store.Command.normalize_lifecycle(attrs)

      %__MODULE__{
        key: Map.fetch!(attrs, :key),
        description: Map.get(attrs, :description),
        flag_type: Map.fetch!(attrs, :flag_type),
        value_type: Map.fetch!(attrs, :value_type),
        default_value: Map.fetch!(attrs, :default_value),
        owner:
          ownership
          |> Rulestead.Store.Command.ownership_label(Map.get(attrs, :owner)),
        ownership: ownership,
        expected_expiration: Map.get(attrs, :expected_expiration),
        permanent: Map.get(attrs, :permanent, false),
        lifecycle: lifecycle,
        environment_keys: Map.get(attrs, :environment_keys, []),
        tags: Map.get(attrs, :tags, []),
        actor: Keyword.get(opts, :actor, Map.get(attrs, :actor)),
        metadata: Keyword.get(opts, :metadata, Map.get(attrs, :metadata, %{}))
      }
    end
  end

  defmodule UpdateFlag do
    @moduledoc false

    @enforce_keys [:flag_key]
    defstruct [
      :flag_key,
      :description,
      :owner,
      :ownership,
      :expected_expiration,
      :permanent,
      :lifecycle,
      tags: nil,
      actor: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            description: nil | String.t(),
            owner: nil | String.t(),
            ownership: nil | map(),
            expected_expiration: nil | Date.t(),
            permanent: nil | boolean(),
            lifecycle: nil | map(),
            tags: nil | [String.t()],
            actor: nil | map(),
            metadata: map()
          }

    @spec new(String.t() | atom(), map() | keyword(), keyword()) :: t()
    def new(flag_key, attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)
      ownership = Rulestead.Store.Command.normalize_ownership(attrs)
      lifecycle = Rulestead.Store.Command.lifecycle_update(attrs)

      %__MODULE__{
        flag_key: flag_key,
        description: Map.get(attrs, :description),
        owner: Rulestead.Store.Command.ownership_label(ownership, Map.get(attrs, :owner)),
        ownership: ownership,
        expected_expiration: Map.get(attrs, :expected_expiration),
        permanent: Map.get(attrs, :permanent),
        lifecycle: lifecycle,
        tags: Map.get(attrs, :tags),
        actor: Keyword.get(opts, :actor, Map.get(attrs, :actor)),
        metadata: Keyword.get(opts, :metadata, Map.get(attrs, :metadata, %{}))
      }
    end
  end

  defmodule SaveDraftRuleset do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key, :ruleset]
    defstruct [:flag_key, :environment_key, :ruleset, actor: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            ruleset: map(),
            actor: nil | map(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), map(), keyword()) :: t()
    def new(flag_key, environment_key, ruleset, opts \\ []) when is_map(ruleset) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        ruleset: ruleset,
        actor: Keyword.get(opts, :actor),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule PublishRuleset do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key]
    defstruct [:flag_key, :environment_key, version: nil, actor: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            version: nil | non_neg_integer() | String.t(),
            actor: nil | map(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(flag_key, environment_key, opts \\ []) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        version: Keyword.get(opts, :version),
        actor: Keyword.get(opts, :actor),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule ArchiveFlag do
    @moduledoc false

    @enforce_keys [:flag_key]
    defstruct [:flag_key, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), keyword()) :: t()
    def new(flag_key, opts \\ []) do
      %__MODULE__{
        flag_key: flag_key,
        actor: Keyword.get(opts, :actor),
        reason: Keyword.get(opts, :reason),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule ListFlags do
    @moduledoc false

    defstruct environment_key: nil,
              query: nil,
              owner: nil,
              tags: [],
              lifecycle: nil,
              stale: nil,
              readiness: nil,
              evidence_quality: nil,
              flag_type: nil,
              include_archived?: false,
              limit: 50,
              after: nil,
              before: nil,
              offset: 0,
              sort: :flag_key,
              page: nil

    @type t :: %__MODULE__{
            environment_key: nil | String.t() | atom(),
            query: nil | String.t(),
            owner: nil | String.t(),
            tags: [String.t()],
            lifecycle: nil | :active | :potentially_stale | :stale | :archived,
            stale: nil | :fresh | :potentially_stale | :stale,
            readiness: nil | :keep_active | :needs_review | :archive_candidate,
            evidence_quality: nil | :strong | :partial | :weak,
            flag_type: nil | atom(),
            include_archived?: boolean(),
            limit: pos_integer(),
            after: nil | String.t(),
            before: nil | String.t(),
            offset: non_neg_integer(),
            sort: :flag_key | :inserted_at | :updated_at,
            page: nil | Page.t(map())
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        environment_key: Keyword.get(opts, :environment_key),
        query: Keyword.get(opts, :query),
        owner: Keyword.get(opts, :owner),
        tags: Keyword.get(opts, :tags, []),
        lifecycle: Keyword.get(opts, :lifecycle),
        stale: Keyword.get(opts, :stale),
        readiness: Keyword.get(opts, :readiness),
        evidence_quality: Keyword.get(opts, :evidence_quality),
        flag_type: Keyword.get(opts, :flag_type),
        include_archived?: Keyword.get(opts, :include_archived?, false),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before),
        offset: Keyword.get(opts, :offset, 0),
        sort: Keyword.get(opts, :sort, :flag_key),
        page: Keyword.get(opts, :page)
      }
    end
  end

  defmodule ListEnvironments do
    @moduledoc false

    defstruct query: nil, limit: 50

    @type t :: %__MODULE__{
            query: nil | String.t(),
            limit: pos_integer()
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        query: Keyword.get(opts, :query),
        limit: Keyword.get(opts, :limit, 50)
      }
    end
  end

  defmodule ListAudiences do
    @moduledoc false

    defstruct query: nil, limit: 50, include_archived?: false

    @type t :: %__MODULE__{
            query: nil | String.t(),
            limit: pos_integer(),
            include_archived?: boolean()
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        query: Keyword.get(opts, :query),
        limit: Keyword.get(opts, :limit, 50),
        include_archived?: Keyword.get(opts, :include_archived?, false)
      }
    end
  end

  defmodule RecordEvaluation do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key, :last_evaluated_at]
    defstruct [:flag_key, :environment_key, :last_evaluated_at]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            last_evaluated_at: DateTime.t()
          }

    @spec new(String.t() | atom(), String.t() | atom(), DateTime.t()) :: t()
    def new(flag_key, environment_key, %DateTime{} = last_evaluated_at) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        last_evaluated_at: last_evaluated_at
      }
    end
  end

  defmodule AdvanceRollout do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:flag_key, :environment_key, :stage]
    defstruct [
      :flag_key,
      :environment_key,
      :rule_key,
      :stage,
      :percentage,
      :monitoring_window_started_at,
      :monitoring_window_ends_at,
      signal_facts: [],
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            rule_key: nil | String.t(),
            stage: String.t(),
            percentage: nil | non_neg_integer(),
            monitoring_window_started_at: nil | DateTime.t(),
            monitoring_window_ends_at: nil | DateTime.t(),
            signal_facts: [map()],
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), map() | keyword(), keyword()) :: t()
    def new(flag_key, environment_key, attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        flag_key: GovernanceSupport.normalize_string(flag_key),
        environment_key: GovernanceSupport.normalize_string(environment_key),
        rule_key: attrs |> GovernanceSupport.fetch(:rule_key) |> GovernanceSupport.normalize_string(),
        stage:
          attrs
          |> GovernanceSupport.fetch_required!(:stage)
          |> GovernanceSupport.normalize_string(),
        percentage: normalize_percentage(GovernanceSupport.fetch(attrs, :percentage)),
        monitoring_window_started_at: GovernanceSupport.fetch(attrs, :monitoring_window_started_at),
        monitoring_window_ends_at: GovernanceSupport.fetch(attrs, :monitoring_window_ends_at),
        signal_facts: normalize_signal_facts(GovernanceSupport.fetch(attrs, :signal_facts)),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_signal_facts(nil), do: []

    defp normalize_signal_facts(values) when is_list(values) do
      Enum.map(values, &GovernanceSupport.normalize_map/1)
    end

    defp normalize_signal_facts(value), do: [GovernanceSupport.normalize_map(value)]

    defp normalize_percentage(nil), do: nil
    defp normalize_percentage(value) when is_integer(value) and value >= 0 and value <= 100, do: value

    defp normalize_percentage(value) when is_binary(value) do
      case Integer.parse(String.trim(value)) do
        {parsed, ""} when parsed >= 0 and parsed <= 100 -> parsed
        _other -> nil
      end
    end

    defp normalize_percentage(_value), do: nil
  end

  defmodule EvaluateGuardedRollout do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:flag_key, :environment_key, :stage]
    defstruct [
      :flag_key,
      :environment_key,
      :rule_key,
      :stage,
      :monitoring_window_started_at,
      :monitoring_window_ends_at,
      signal_facts: [],
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            rule_key: nil | String.t(),
            stage: String.t(),
            monitoring_window_started_at: nil | DateTime.t(),
            monitoring_window_ends_at: nil | DateTime.t(),
            signal_facts: [map()],
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), map() | keyword(), keyword()) :: t()
    def new(flag_key, environment_key, attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        flag_key: GovernanceSupport.normalize_string(flag_key),
        environment_key: GovernanceSupport.normalize_string(environment_key),
        rule_key: attrs |> GovernanceSupport.fetch(:rule_key) |> GovernanceSupport.normalize_string(),
        stage:
          attrs
          |> GovernanceSupport.fetch_required!(:stage)
          |> GovernanceSupport.normalize_string(),
        monitoring_window_started_at: GovernanceSupport.fetch(attrs, :monitoring_window_started_at),
        monitoring_window_ends_at: GovernanceSupport.fetch(attrs, :monitoring_window_ends_at),
        signal_facts:
          attrs
          |> GovernanceSupport.fetch(:signal_facts)
          |> normalize_signal_facts(),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_signal_facts(nil), do: []

    defp normalize_signal_facts(values) when is_list(values) do
      Enum.map(values, &GovernanceSupport.normalize_map/1)
    end

    defp normalize_signal_facts(value), do: [GovernanceSupport.normalize_map(value)]
  end

  defmodule FetchGuardrailStatus do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:flag_key, :environment_key]
    defstruct [:flag_key, :environment_key, :rule_key, :stage, actor: nil]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            rule_key: nil | String.t(),
            stage: nil | String.t(),
            actor: nil | map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(flag_key, environment_key, opts \\ []) do
      %__MODULE__{
        flag_key: GovernanceSupport.normalize_string(flag_key),
        environment_key: GovernanceSupport.normalize_string(environment_key),
        rule_key: Keyword.get(opts, :rule_key) |> GovernanceSupport.normalize_string(),
        stage: Keyword.get(opts, :stage) |> GovernanceSupport.normalize_string(),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule EngageKillSwitch do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key]
    defstruct [:flag_key, :environment_key, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(flag_key, environment_key, opts \\ []) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        actor: Keyword.get(opts, :actor),
        reason: Keyword.get(opts, :reason),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule ReleaseKillSwitch do
    @moduledoc false

    @enforce_keys [:flag_key, :environment_key]
    defstruct [:flag_key, :environment_key, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), keyword()) :: t()
    def new(flag_key, environment_key, opts \\ []) do
      %__MODULE__{
        flag_key: flag_key,
        environment_key: environment_key,
        actor: Keyword.get(opts, :actor),
        reason: Keyword.get(opts, :reason),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule ListAuditEvents do
    @moduledoc false

    defstruct flag_key: nil,
              environment_key: nil,
              actor: nil,
              actor_id: nil,
              mutation: nil,
              limit: 50,
              before: nil,
              after: nil,
              occurred_after: nil,
              occurred_before: nil,
              metadata: %{}

    @type t :: %__MODULE__{
            flag_key: nil | String.t() | atom(),
            environment_key: nil | String.t() | atom(),
            actor: nil | map(),
            actor_id: nil | String.t(),
            mutation: nil | String.t(),
            limit: pos_integer(),
            before: nil | String.t(),
            after: nil | String.t(),
            occurred_after: nil | DateTime.t(),
            occurred_before: nil | DateTime.t(),
            metadata: map()
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        flag_key: Keyword.get(opts, :flag_key),
        environment_key: Keyword.get(opts, :environment_key),
        actor: Keyword.get(opts, :actor),
        actor_id: Keyword.get(opts, :actor_id),
        mutation: Keyword.get(opts, :mutation),
        limit: Keyword.get(opts, :limit, 50),
        before: Keyword.get(opts, :before),
        after: Keyword.get(opts, :after),
        occurred_after: Keyword.get(opts, :occurred_after),
        occurred_before: Keyword.get(opts, :occurred_before),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule RollbackAuditEvent do
    @moduledoc false

    @enforce_keys [:audit_event_id]
    defstruct [:audit_event_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            audit_event_id: String.t(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(audit_event_id, opts \\ []) when is_binary(audit_event_id) do
      %__MODULE__{
        audit_event_id: audit_event_id,
        actor: Keyword.get(opts, :actor),
        reason: Keyword.get(opts, :reason),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  defmodule SubmitChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [
      :action,
      :environment_key,
      :resource_type,
      :resource_key,
      :command,
      :approval_requirement
    ]
    defstruct [
      :action,
      :environment_key,
      :resource_type,
      :resource_key,
      :command,
      :approval_requirement,
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            action: atom(),
            environment_key: String.t() | nil,
            resource_type: String.t() | nil,
            resource_key: String.t() | nil,
            command: map(),
            approval_requirement: map(),
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        action: GovernanceSupport.fetch_required!(attrs, :action),
        environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:environment_key)
          |> GovernanceSupport.normalize_string(),
        resource_type:
          attrs
          |> GovernanceSupport.fetch_required!(:resource_type)
          |> GovernanceSupport.normalize_string(),
        resource_key:
          attrs
          |> GovernanceSupport.fetch_required!(:resource_key)
          |> GovernanceSupport.normalize_string(),
        command:
          attrs
          |> GovernanceSupport.fetch_required!(:command)
          |> GovernanceSupport.normalize_command(),
        approval_requirement:
          attrs
          |> GovernanceSupport.fetch_required!(:approval_requirement)
          |> GovernanceSupport.normalize_approval_requirement(),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule ApproveChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id]
    defstruct [:change_request_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(change_request_id, opts \\ []) do
      %__MODULE__{
        change_request_id: GovernanceSupport.normalize_string(change_request_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule RejectChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id]
    defstruct [:change_request_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(change_request_id, opts \\ []) do
      %__MODULE__{
        change_request_id: GovernanceSupport.normalize_string(change_request_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule CancelChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id]
    defstruct [:change_request_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(change_request_id, opts \\ []) do
      %__MODULE__{
        change_request_id: GovernanceSupport.normalize_string(change_request_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule ExecuteChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id]
    defstruct [:change_request_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(change_request_id, opts \\ []) do
      %__MODULE__{
        change_request_id: GovernanceSupport.normalize_string(change_request_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule FetchChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id]
    defstruct [:change_request_id]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil
          }

    @spec new(String.t()) :: t()
    def new(change_request_id) do
      %__MODULE__{change_request_id: GovernanceSupport.normalize_string(change_request_id)}
    end
  end

  defmodule ListChangeRequests do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    defstruct environment_key: nil,
              action: nil,
              status: nil,
              resource_type: nil,
              resource_key: nil,
              submitted_by_id: nil,
              limit: 50,
              after: nil,
              before: nil

    @type t :: %__MODULE__{
            environment_key: nil | String.t(),
            action: nil | atom() | String.t(),
            status: nil | atom() | String.t(),
            resource_type: nil | String.t(),
            resource_key: nil | String.t(),
            submitted_by_id: nil | String.t(),
            limit: pos_integer(),
            after: nil | String.t(),
            before: nil | String.t()
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        environment_key:
          Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
        action: Keyword.get(opts, :action),
        status: Keyword.get(opts, :status),
        resource_type: Keyword.get(opts, :resource_type) |> GovernanceSupport.normalize_string(),
        resource_key: Keyword.get(opts, :resource_key) |> GovernanceSupport.normalize_string(),
        submitted_by_id:
          Keyword.get(opts, :submitted_by_id) |> GovernanceSupport.normalize_string(),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before)
      }
    end
  end

  defmodule ScheduleChangeRequest do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:change_request_id, :scheduled_for]
    defstruct [:change_request_id, :scheduled_for, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            change_request_id: String.t() | nil,
            scheduled_for: DateTime.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        change_request_id:
          attrs
          |> GovernanceSupport.fetch_required!(:change_request_id)
          |> GovernanceSupport.normalize_string(),
        scheduled_for: GovernanceSupport.fetch_required!(attrs, :scheduled_for),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule ScheduleGovernedAction do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [
      :action,
      :environment_key,
      :resource_type,
      :resource_key,
      :command,
      :scheduled_for,
      :execution_mode
    ]
    defstruct [
      :action,
      :environment_key,
      :resource_type,
      :resource_key,
      :command,
      :scheduled_for,
      :execution_mode,
      actor: nil,
      reason: nil,
      approval_requirement: %{},
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            action: ScheduledExecution.action(),
            environment_key: String.t() | nil,
            resource_type: String.t() | nil,
            resource_key: String.t() | nil,
            command: map(),
            scheduled_for: DateTime.t() | nil,
            execution_mode: ScheduledExecution.execution_mode(),
            actor: nil | map(),
            reason: nil | String.t(),
            approval_requirement: map(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        action: GovernanceSupport.fetch_required!(attrs, :action),
        environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:environment_key)
          |> GovernanceSupport.normalize_string(),
        resource_type:
          attrs
          |> GovernanceSupport.fetch_required!(:resource_type)
          |> GovernanceSupport.normalize_string(),
        resource_key:
          attrs
          |> GovernanceSupport.fetch_required!(:resource_key)
          |> GovernanceSupport.normalize_string(),
        command:
          attrs
          |> GovernanceSupport.fetch_required!(:command)
          |> GovernanceSupport.normalize_command(),
        scheduled_for: GovernanceSupport.fetch_required!(attrs, :scheduled_for),
        execution_mode:
          attrs
          |> GovernanceSupport.fetch_required!(:execution_mode)
          |> normalize_execution_mode(),
        actor:
          opts
          |> Keyword.get(:actor, GovernanceSupport.fetch(attrs, :actor))
          |> GovernanceSupport.normalize_actor(),
        reason:
          opts
          |> Keyword.get(:reason, GovernanceSupport.fetch(attrs, :reason))
          |> GovernanceSupport.normalize_string(),
        approval_requirement:
          opts
          |> Keyword.get(
            :approval_requirement,
            GovernanceSupport.fetch(attrs, :approval_requirement)
          )
          |> GovernanceSupport.normalize_approval_requirement(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_execution_mode(mode)
         when mode in [:change_request, :policy_bypass, :emergency_bypass],
         do: mode

    defp normalize_execution_mode(_mode), do: :change_request
  end

  defmodule CancelScheduledExecution do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:scheduled_execution_id]
    defstruct [:scheduled_execution_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            scheduled_execution_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(scheduled_execution_id, opts \\ []) do
      %__MODULE__{
        scheduled_execution_id: GovernanceSupport.normalize_string(scheduled_execution_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule RequeueScheduledExecution do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:scheduled_execution_id]
    defstruct [:scheduled_execution_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            scheduled_execution_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(scheduled_execution_id, opts \\ []) do
      %__MODULE__{
        scheduled_execution_id: GovernanceSupport.normalize_string(scheduled_execution_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule ExecuteScheduledExecution do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:scheduled_execution_id]
    defstruct [:scheduled_execution_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            scheduled_execution_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t(), keyword()) :: t()
    def new(scheduled_execution_id, opts \\ []) do
      %__MODULE__{
        scheduled_execution_id: GovernanceSupport.normalize_string(scheduled_execution_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule FetchScheduledExecution do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:scheduled_execution_id]
    defstruct [:scheduled_execution_id]

    @type t :: %__MODULE__{
            scheduled_execution_id: String.t() | nil
          }

    @spec new(String.t()) :: t()
    def new(scheduled_execution_id) do
      %__MODULE__{
        scheduled_execution_id: GovernanceSupport.normalize_string(scheduled_execution_id)
      }
    end
  end

  defmodule ListScheduledExecutions do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    defstruct environment_key: nil,
              state: nil,
              action: nil,
              resource_type: nil,
              resource_key: nil,
              scheduled_by_id: nil,
              change_request_id: nil,
              limit: 50,
              after: nil,
              before: nil

    @type t :: %__MODULE__{
            environment_key: nil | String.t(),
            state: nil | atom() | String.t(),
            action: nil | atom() | String.t(),
            resource_type: nil | String.t(),
            resource_key: nil | String.t(),
            scheduled_by_id: nil | String.t(),
            change_request_id: nil | String.t(),
            limit: pos_integer(),
            after: nil | String.t(),
            before: nil | String.t()
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        environment_key:
          Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
        state: Keyword.get(opts, :state),
        action: Keyword.get(opts, :action),
        resource_type: Keyword.get(opts, :resource_type) |> GovernanceSupport.normalize_string(),
        resource_key: Keyword.get(opts, :resource_key) |> GovernanceSupport.normalize_string(),
        scheduled_by_id:
          Keyword.get(opts, :scheduled_by_id) |> GovernanceSupport.normalize_string(),
        change_request_id:
          Keyword.get(opts, :change_request_id) |> GovernanceSupport.normalize_string(),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before)
      }
    end
  end

  defmodule ReceiveInboundWebhook do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [
      :provider,
      :endpoint_key,
      :delivery_id,
      :received_at,
      :raw_body_sha256,
      :verified_state,
      :correlation_id
    ]
    defstruct [
      :provider,
      :endpoint_key,
      :delivery_id,
      :attempt_id,
      :topic,
      :occurred_at,
      :received_at,
      :raw_body_sha256,
      :verification_metadata,
      :normalized_payload,
      :dedupe_key,
      :verified_state,
      :rejection_reason,
      :correlation_id,
      :metadata
    ]

    @type t :: %__MODULE__{
            provider: String.t(),
            endpoint_key: String.t(),
            delivery_id: String.t(),
            attempt_id: String.t() | nil,
            topic: String.t() | nil,
            occurred_at: DateTime.t() | nil,
            received_at: DateTime.t(),
            raw_body_sha256: String.t(),
            verification_metadata: map(),
            normalized_payload: map() | nil,
            dedupe_key: String.t() | nil,
            verified_state: atom(),
            rejection_reason: String.t() | nil,
            correlation_id: String.t(),
            metadata: map()
          }

    @spec new(map() | keyword()) :: t()
    def new(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        provider:
          attrs
          |> GovernanceSupport.fetch_required!(:provider)
          |> GovernanceSupport.normalize_string(),
        endpoint_key:
          attrs
          |> GovernanceSupport.fetch_required!(:endpoint_key)
          |> GovernanceSupport.normalize_string(),
        delivery_id:
          attrs
          |> GovernanceSupport.fetch_required!(:delivery_id)
          |> GovernanceSupport.normalize_string(),
        attempt_id:
          attrs |> GovernanceSupport.fetch(:attempt_id) |> GovernanceSupport.normalize_string(),
        topic: attrs |> GovernanceSupport.fetch(:topic) |> GovernanceSupport.normalize_string(),
        occurred_at: GovernanceSupport.fetch(attrs, :occurred_at),
        received_at: GovernanceSupport.fetch_required!(attrs, :received_at),
        raw_body_sha256:
          attrs
          |> GovernanceSupport.fetch_required!(:raw_body_sha256)
          |> GovernanceSupport.normalize_string(),
        verification_metadata:
          attrs
          |> GovernanceSupport.fetch(:verification_metadata)
          |> GovernanceSupport.normalize_map(),
        normalized_payload:
          attrs
          |> GovernanceSupport.fetch(:normalized_payload)
          |> GovernanceSupport.normalize_map(),
        dedupe_key:
          attrs |> GovernanceSupport.fetch(:dedupe_key) |> GovernanceSupport.normalize_string(),
        verified_state: attrs |> GovernanceSupport.fetch_required!(:verified_state),
        rejection_reason:
          attrs
          |> GovernanceSupport.fetch(:rejection_reason)
          |> GovernanceSupport.normalize_string(),
        correlation_id:
          attrs
          |> GovernanceSupport.fetch_required!(:correlation_id)
          |> GovernanceSupport.normalize_string(),
        metadata:
          attrs |> GovernanceSupport.fetch(:metadata) |> GovernanceSupport.normalize_metadata()
      }
    end
  end

  defmodule FetchWebhookRecord do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:receipt_id]
    defstruct [:receipt_id, :actor]

    @type t :: %__MODULE__{
            receipt_id: String.t(),
            actor: map() | nil
          }

    @spec new(String.t(), keyword()) :: t()
    def new(receipt_id, opts \\ []) do
      %__MODULE__{
        receipt_id: GovernanceSupport.normalize_string(receipt_id),
        actor: Keyword.get(opts, :actor)
      }
    end
  end

  defmodule ListWebhookRecords do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    defstruct [
      :provider,
      :endpoint_key,
      :verified_state,
      :topic,
      :limit,
      :after,
      :before,
      :actor
    ]

    @type t :: %__MODULE__{
            provider: String.t() | nil,
            endpoint_key: String.t() | nil,
            verified_state: atom() | nil,
            topic: String.t() | nil,
            limit: pos_integer(),
            after: String.t() | nil,
            before: String.t() | nil,
            actor: map() | nil
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        provider: Keyword.get(opts, :provider) |> GovernanceSupport.normalize_string(),
        endpoint_key: Keyword.get(opts, :endpoint_key) |> GovernanceSupport.normalize_string(),
        verified_state: Keyword.get(opts, :verified_state),
        topic: Keyword.get(opts, :topic) |> GovernanceSupport.normalize_string(),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before),
        actor: Keyword.get(opts, :actor)
      }
    end
  end

  defmodule CreateWebhookDestination do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:name, :url, :environment_key]
    defstruct [
      :name,
      :description,
      :url,
      :secret_id,
      :environment_key,
      :subscriptions,
      :enabled,
      :metadata,
      :actor
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            description: String.t() | nil,
            url: String.t(),
            secret_id: String.t() | nil,
            environment_key: String.t(),
            subscriptions: [String.t()],
            enabled: boolean(),
            metadata: map(),
            actor: map() | nil
          }

    @spec new(map() | keyword()) :: t()
    def new(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        name:
          attrs
          |> GovernanceSupport.fetch_required!(:name)
          |> GovernanceSupport.normalize_string(),
        description:
          attrs |> GovernanceSupport.fetch(:description) |> GovernanceSupport.normalize_string(),
        url:
          attrs |> GovernanceSupport.fetch_required!(:url) |> GovernanceSupport.normalize_string(),
        secret_id:
          attrs |> GovernanceSupport.fetch(:secret_id) |> GovernanceSupport.normalize_string(),
        environment_key:
          attrs
          |> GovernanceSupport.fetch_required!(:environment_key)
          |> GovernanceSupport.normalize_string(),
        subscriptions: attrs |> Map.get(:subscriptions, []) |> List.wrap(),
        enabled: Map.get(attrs, :enabled, true),
        metadata: attrs |> Map.get(:metadata, %{}) |> GovernanceSupport.normalize_map(),
        actor: attrs |> Map.get(:actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule UpdateWebhookDestination do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:id]
    defstruct [
      :id,
      :name,
      :description,
      :url,
      :secret_id,
      :subscriptions,
      :enabled,
      :metadata,
      :actor
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            name: String.t() | nil,
            description: String.t() | nil,
            url: String.t() | nil,
            secret_id: String.t() | nil,
            subscriptions: [String.t()] | nil,
            enabled: boolean() | nil,
            metadata: map() | nil,
            actor: map() | nil
          }

    @spec new(String.t(), map() | keyword()) :: t()
    def new(id, attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        id: GovernanceSupport.normalize_string(id),
        name: attrs |> GovernanceSupport.fetch(:name) |> GovernanceSupport.normalize_string(),
        description:
          attrs |> GovernanceSupport.fetch(:description) |> GovernanceSupport.normalize_string(),
        url: attrs |> GovernanceSupport.fetch(:url) |> GovernanceSupport.normalize_string(),
        secret_id:
          attrs |> GovernanceSupport.fetch(:secret_id) |> GovernanceSupport.normalize_string(),
        subscriptions: Map.get(attrs, :subscriptions),
        enabled: Map.get(attrs, :enabled),
        metadata: attrs |> Map.get(:metadata) |> maybe_normalize_map(),
        actor: attrs |> Map.get(:actor) |> GovernanceSupport.normalize_actor()
      }
    end

    defp maybe_normalize_map(nil), do: nil
    defp maybe_normalize_map(map), do: GovernanceSupport.normalize_map(map)
  end

  defmodule FetchWebhookDestination do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:id]
    defstruct [:id, :actor]

    @type t :: %__MODULE__{
            id: String.t(),
            actor: map() | nil
          }

    @spec new(String.t(), keyword()) :: t()
    def new(id, opts \\ []) do
      %__MODULE__{
        id: GovernanceSupport.normalize_string(id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule ListWebhookDestinations do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    defstruct [:environment_key, :limit, :after, :before, :actor]

    @type t :: %__MODULE__{
            environment_key: String.t() | nil,
            limit: pos_integer(),
            after: String.t() | nil,
            before: String.t() | nil,
            actor: map() | nil
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        environment_key:
          Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule ListWebhookDeliveries do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    defstruct [:destination_id, :event_id, :state, :limit, :after, :before, :actor]

    @type t :: %__MODULE__{
            destination_id: String.t() | nil,
            event_id: String.t() | nil,
            state: atom() | nil,
            limit: pos_integer(),
            after: String.t() | nil,
            before: String.t() | nil,
            actor: map() | nil
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        destination_id:
          Keyword.get(opts, :destination_id) |> GovernanceSupport.normalize_string(),
        event_id: Keyword.get(opts, :event_id) |> GovernanceSupport.normalize_string(),
        state: Keyword.get(opts, :state),
        limit: Keyword.get(opts, :limit, 50),
        after: Keyword.get(opts, :after),
        before: Keyword.get(opts, :before),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule RetryWebhookDelivery do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:delivery_id]
    defstruct [:delivery_id, :actor]

    @type t :: %__MODULE__{
            delivery_id: String.t(),
            actor: map() | nil
          }

    @spec new(String.t(), keyword()) :: t()
    def new(delivery_id, opts \\ []) do
      %__MODULE__{
        delivery_id: GovernanceSupport.normalize_string(delivery_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor()
      }
    end
  end

  defmodule StopExperiment do
    @moduledoc false

    alias Rulestead.Store.Command.GovernanceSupport

    @enforce_keys [:flag_key, :environment_key, :rule_id, :winning_variant_id]
    defstruct [
      :flag_key,
      :environment_key,
      :rule_id,
      :winning_variant_id,
      actor: nil,
      reason: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            rule_id: String.t(),
            winning_variant_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), String.t(), String.t() | nil, keyword()) ::
            t()
    def new(flag_key, environment_key, rule_id, winning_variant_id, opts \\ []) do
      %__MODULE__{
        flag_key: GovernanceSupport.normalize_string(flag_key) || flag_key,
        environment_key: GovernanceSupport.normalize_string(environment_key) || environment_key,
        rule_id: GovernanceSupport.normalize_string(rule_id),
        winning_variant_id: GovernanceSupport.normalize_string(winning_variant_id),
        actor: Keyword.get(opts, :actor) |> GovernanceSupport.normalize_actor(),
        reason: Keyword.get(opts, :reason) |> GovernanceSupport.normalize_string(),
        metadata: Keyword.get(opts, :metadata, %{}) |> GovernanceSupport.normalize_metadata()
      }
    end
  end
end
