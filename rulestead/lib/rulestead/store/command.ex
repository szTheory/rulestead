defmodule Rulestead.Store.Command do
  @moduledoc """
  Shared key-first command structs for `Rulestead.Store` adapters.

  Public selectors stay on `flag_key` and `environment_key`; internal UUIDs
  remain adapter-private.
  """

  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Governance.ScheduledExecution

  defmodule GovernanceSupport do
    @moduledoc false

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
    def normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
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

    def normalize_approval_requirement(%ApprovalRequirement{} = requirement),
      do: requirement |> ApprovalRequirement.serialize() |> normalize_map()

    def normalize_approval_requirement(requirement) when is_list(requirement) or is_map(requirement),
      do: requirement |> ApprovalRequirement.new() |> ApprovalRequirement.serialize() |> normalize_map()

    def normalize_approval_requirement(_requirement), do: %{}

    def normalize_map(nil), do: %{}
    def normalize_map(value) when is_list(value), do: value |> Map.new() |> normalize_map()

    def normalize_map(map) when is_map(map) do
      Map.new(map, fn
        {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
        {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
        {key, value} -> {to_string(key), normalize_value(value)}
      end)
    end

    def normalize_map(_value), do: %{}

    def normalize_value(value) when is_map(value), do: normalize_map(value)
    def normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
    def normalize_value(value) when is_boolean(value), do: value
    def normalize_value(nil), do: nil
    def normalize_value(value) when is_atom(value), do: Atom.to_string(value)
    def normalize_value(value), do: value

    def maybe_put(map, _key, nil), do: map
    def maybe_put(map, key, value), do: Map.put(map, key, value)

    defp drop_sensitive_keys(map) do
      map
      |> Map.drop(["admin_session", "session", "session_data", "session_id", "session_token", "socket"])
      |> Map.new(fn
        {key, value} when is_map(value) -> {key, drop_sensitive_keys(value)}
        {key, value} when is_list(value) -> {key, Enum.map(value, &drop_sensitive_value/1)}
        entry -> entry
      end)
    end

    defp drop_sensitive_value(value) when is_map(value), do: drop_sensitive_keys(value)
    defp drop_sensitive_value(value), do: value
  end

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

  defmodule CreateFlag do
    @moduledoc false

    @enforce_keys [:key, :flag_type, :value_type, :default_value, :owner]
    defstruct [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :owner,
      :expected_expiration,
      :permanent,
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
            expected_expiration: nil | Date.t(),
            permanent: nil | boolean(),
            environment_keys: [String.t() | atom()],
            tags: [String.t()],
            actor: nil | map(),
            metadata: map()
          }

    @spec new(map() | keyword(), keyword()) :: t()
    def new(attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        key: Map.fetch!(attrs, :key),
        description: Map.get(attrs, :description),
        flag_type: Map.fetch!(attrs, :flag_type),
        value_type: Map.fetch!(attrs, :value_type),
        default_value: Map.fetch!(attrs, :default_value),
        owner: Map.fetch!(attrs, :owner),
        expected_expiration: Map.get(attrs, :expected_expiration),
        permanent: Map.get(attrs, :permanent, false),
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
      :expected_expiration,
      :permanent,
      tags: nil,
      actor: nil,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            description: nil | String.t(),
            owner: nil | String.t(),
            expected_expiration: nil | Date.t(),
            permanent: nil | boolean(),
            tags: nil | [String.t()],
            actor: nil | map(),
            metadata: map()
          }

    @spec new(String.t() | atom(), map() | keyword(), keyword()) :: t()
    def new(flag_key, attrs, opts \\ []) when is_map(attrs) or is_list(attrs) do
      attrs = Map.new(attrs)

      %__MODULE__{
        flag_key: flag_key,
        description: Map.get(attrs, :description),
        owner: Map.get(attrs, :owner),
        expected_expiration: Map.get(attrs, :expected_expiration),
        permanent: Map.get(attrs, :permanent),
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

    @enforce_keys [:action, :environment_key, :resource_type, :resource_key, :command, :approval_requirement]
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
          attrs |> GovernanceSupport.fetch_required!(:environment_key) |> GovernanceSupport.normalize_string(),
        resource_type:
          attrs |> GovernanceSupport.fetch_required!(:resource_type) |> GovernanceSupport.normalize_string(),
        resource_key:
          attrs |> GovernanceSupport.fetch_required!(:resource_key) |> GovernanceSupport.normalize_string(),
        command:
          attrs |> GovernanceSupport.fetch_required!(:command) |> GovernanceSupport.normalize_command(),
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
        environment_key: Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
        action: Keyword.get(opts, :action),
        status: Keyword.get(opts, :status),
        resource_type: Keyword.get(opts, :resource_type) |> GovernanceSupport.normalize_string(),
        resource_key: Keyword.get(opts, :resource_key) |> GovernanceSupport.normalize_string(),
        submitted_by_id: Keyword.get(opts, :submitted_by_id) |> GovernanceSupport.normalize_string(),
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
          attrs |> GovernanceSupport.fetch_required!(:change_request_id) |> GovernanceSupport.normalize_string(),
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

    @enforce_keys [:action, :environment_key, :resource_type, :resource_key, :command, :scheduled_for, :execution_mode]
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
          attrs |> GovernanceSupport.fetch_required!(:environment_key) |> GovernanceSupport.normalize_string(),
        resource_type:
          attrs |> GovernanceSupport.fetch_required!(:resource_type) |> GovernanceSupport.normalize_string(),
        resource_key:
          attrs |> GovernanceSupport.fetch_required!(:resource_key) |> GovernanceSupport.normalize_string(),
        command:
          attrs |> GovernanceSupport.fetch_required!(:command) |> GovernanceSupport.normalize_command(),
        scheduled_for: GovernanceSupport.fetch_required!(attrs, :scheduled_for),
        execution_mode:
          attrs |> GovernanceSupport.fetch_required!(:execution_mode) |> normalize_execution_mode(),
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
          |> Keyword.get(:approval_requirement, GovernanceSupport.fetch(attrs, :approval_requirement))
          |> GovernanceSupport.normalize_approval_requirement(),
        metadata:
          opts
          |> Keyword.get(:metadata, GovernanceSupport.fetch(attrs, :metadata))
          |> GovernanceSupport.normalize_metadata()
      }
    end

    defp normalize_execution_mode(mode) when mode in [:change_request, :policy_bypass, :emergency_bypass],
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
      %__MODULE__{scheduled_execution_id: GovernanceSupport.normalize_string(scheduled_execution_id)}
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
        environment_key: Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
        state: Keyword.get(opts, :state),
        action: Keyword.get(opts, :action),
        resource_type: Keyword.get(opts, :resource_type) |> GovernanceSupport.normalize_string(),
        resource_key: Keyword.get(opts, :resource_key) |> GovernanceSupport.normalize_string(),
        scheduled_by_id: Keyword.get(opts, :scheduled_by_id) |> GovernanceSupport.normalize_string(),
        change_request_id: Keyword.get(opts, :change_request_id) |> GovernanceSupport.normalize_string(),
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
        provider: attrs |> GovernanceSupport.fetch_required!(:provider) |> GovernanceSupport.normalize_string(),
        endpoint_key:
          attrs |> GovernanceSupport.fetch_required!(:endpoint_key) |> GovernanceSupport.normalize_string(),
        delivery_id:
          attrs |> GovernanceSupport.fetch_required!(:delivery_id) |> GovernanceSupport.normalize_string(),
        attempt_id: attrs |> GovernanceSupport.fetch(:attempt_id) |> GovernanceSupport.normalize_string(),
        topic: attrs |> GovernanceSupport.fetch(:topic) |> GovernanceSupport.normalize_string(),
        occurred_at: GovernanceSupport.fetch(attrs, :occurred_at),
        received_at: GovernanceSupport.fetch_required!(attrs, :received_at),
        raw_body_sha256:
          attrs |> GovernanceSupport.fetch_required!(:raw_body_sha256) |> GovernanceSupport.normalize_string(),
        verification_metadata:
          attrs |> GovernanceSupport.fetch(:verification_metadata) |> GovernanceSupport.normalize_map(),
        normalized_payload:
          attrs |> GovernanceSupport.fetch(:normalized_payload) |> GovernanceSupport.normalize_map(),
        dedupe_key: attrs |> GovernanceSupport.fetch(:dedupe_key) |> GovernanceSupport.normalize_string(),
        verified_state: attrs |> GovernanceSupport.fetch_required!(:verified_state),
        rejection_reason:
          attrs |> GovernanceSupport.fetch(:rejection_reason) |> GovernanceSupport.normalize_string(),
        correlation_id:
          attrs |> GovernanceSupport.fetch_required!(:correlation_id) |> GovernanceSupport.normalize_string(),
        metadata: attrs |> GovernanceSupport.fetch(:metadata) |> GovernanceSupport.normalize_metadata()
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
    defstruct [:name, :description, :url, :secret_id, :environment_key, :subscriptions, :enabled, :metadata, :actor]

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
        name: attrs |> GovernanceSupport.fetch_required!(:name) |> GovernanceSupport.normalize_string(),
        description: attrs |> GovernanceSupport.fetch(:description) |> GovernanceSupport.normalize_string(),
        url: attrs |> GovernanceSupport.fetch_required!(:url) |> GovernanceSupport.normalize_string(),
        secret_id: attrs |> GovernanceSupport.fetch(:secret_id) |> GovernanceSupport.normalize_string(),
        environment_key:
          attrs |> GovernanceSupport.fetch_required!(:environment_key) |> GovernanceSupport.normalize_string(),
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
    defstruct [:id, :name, :description, :url, :secret_id, :subscriptions, :enabled, :metadata, :actor]

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
        description: attrs |> GovernanceSupport.fetch(:description) |> GovernanceSupport.normalize_string(),
        url: attrs |> GovernanceSupport.fetch(:url) |> GovernanceSupport.normalize_string(),
        secret_id: attrs |> GovernanceSupport.fetch(:secret_id) |> GovernanceSupport.normalize_string(),
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
        environment_key: Keyword.get(opts, :environment_key) |> GovernanceSupport.normalize_string(),
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
        destination_id: Keyword.get(opts, :destination_id) |> GovernanceSupport.normalize_string(),
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
    defstruct [:flag_key, :environment_key, :rule_id, :winning_variant_id, actor: nil, reason: nil, metadata: %{}]

    @type t :: %__MODULE__{
            flag_key: String.t() | atom(),
            environment_key: String.t() | atom(),
            rule_id: String.t(),
            winning_variant_id: String.t() | nil,
            actor: nil | map(),
            reason: nil | String.t(),
            metadata: map()
          }

    @spec new(String.t() | atom(), String.t() | atom(), String.t(), String.t() | nil, keyword()) :: t()
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
