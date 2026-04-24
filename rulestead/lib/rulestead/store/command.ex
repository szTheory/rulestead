defmodule Rulestead.Store.Command do
  @moduledoc """
  Shared key-first command structs for `Rulestead.Store` adapters.

  Public selectors stay on `flag_key` and `environment_key`; internal UUIDs
  remain adapter-private.
  """

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
        permanent: Map.get(attrs, :permanent),
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
end
