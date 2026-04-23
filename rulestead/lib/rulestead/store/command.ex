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
              include_archived?: false,
              limit: 50,
              offset: 0,
              sort: :flag_key

    @type t :: %__MODULE__{
            environment_key: nil | String.t() | atom(),
            query: nil | String.t(),
            include_archived?: boolean(),
            limit: pos_integer(),
            offset: non_neg_integer(),
            sort: :flag_key | :inserted_at | :updated_at
          }

    @spec new(keyword()) :: t()
    def new(opts \\ []) do
      %__MODULE__{
        environment_key: Keyword.get(opts, :environment_key),
        query: Keyword.get(opts, :query),
        include_archived?: Keyword.get(opts, :include_archived?, false),
        limit: Keyword.get(opts, :limit, 50),
        offset: Keyword.get(opts, :offset, 0),
        sort: Keyword.get(opts, :sort, :flag_key)
      }
    end
  end
end
