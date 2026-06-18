defmodule Rulestead.Config do
  @moduledoc """
  Validated host-app seam configuration for Rulestead.

  `Rulestead.Config` is stable in the 1.x contract (`api_stability.md` —
  "Stable rulestead Modules"). It owns the validated configuration schema for
  the Plug, LiveView, Oban, Runtime, and Tenancy integration points.

  ## Configuration

  Rulestead reads its configuration from `Application.get_env(:rulestead, :host)`.
  All keys are optional — the defaults below are used for any key not supplied.

  ```elixir
  # config/config.exs
  config :rulestead, :host,
    environment_key: "production",
    plug: [
      context_assign: :rulestead_context,
      targeting_key_sources: [
        {:session, "targeting_key"},
        {:cookie, "rulestead_targeting_key"},
        {:header, "x-rulestead-targeting-key"}
      ]
    ],
    runtime: [
      api: Rulestead.Runtime,
      pubsub: MyApp.PubSub
    ]
  ```

  ## Public API

  - `validate/1` — validate a keyword list, returning `{:ok, config}` or `{:error, reason}`
  - `validate!/1` — validate a keyword list, raising on invalid input
  - `load/1` — load from application env, merge overrides, and validate; raises on invalid config
  - `defaults/0` — return the compiled default configuration keyword list
  - `schema/0` — return the raw NimbleOptions schema keyword list

  ## Defaults

  | Key | Default |
  |-----|---------|
  | `environment_key` | `"dev"` |
  | `plug.context_assign` | `:rulestead_context` |
  | `live_view.assign_flags_mode` | `:enabled` |
  | `oban.enabled` | `true` |
  | `runtime.notifier` | `Rulestead.Runtime.Notifier.PhoenixPubSub` |
  | `tenancy.module` | `Rulestead.Tenancy.SingleTenant` |

  The full default set is returned by `defaults/0`.
  """
  # Validated Phase 5 host-app seam configuration.
  #
  # This schema owns the explicit defaults for the Plug, LiveView, and Oban
  # integration points added in Phase 5, along with the runtime facade module the
  # generated host code is expected to target.

  @defaults [
    environment_key: "dev",
    plug: [
      context_assign: :rulestead_context,
      targeting_key_sources: [
        {:session, "targeting_key"},
        {:cookie, "rulestead_targeting_key"},
        {:header, "x-rulestead-targeting-key"}
      ]
    ],
    live_view: [
      context_assign: :rulestead_context,
      targeting_key_sources: [
        {:session, "targeting_key"},
        {:assign, :targeting_key}
      ],
      assign_flags_mode: :enabled
    ],
    oban: [
      enabled: true,
      context_key: "rulestead_context",
      middlewares: [{Rulestead.Oban.Middleware, []}]
    ],
    runtime: [
      api: Rulestead.Runtime,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
      health_peer_provider: nil,
      pubsub: nil,
      pubsub_topic: "rulestead:runtime_snapshot"
    ],
    tenancy: [
      module: Rulestead.Tenancy.SingleTenant
    ]
  ]

  @raw_schema [
    environment_key: [
      type: :string,
      required: true
    ],
    plug: [
      type: :keyword_list,
      required: true,
      keys: [
        context_assign: [type: :atom, required: true],
        targeting_key_sources: [type: {:list, :any}, required: true]
      ]
    ],
    live_view: [
      type: :keyword_list,
      required: true,
      keys: [
        context_assign: [type: :atom, required: true],
        targeting_key_sources: [type: {:list, :any}, required: true],
        assign_flags_mode: [type: {:in, [:enabled, :variant, :value, :evaluate]}, required: true]
      ]
    ],
    oban: [
      type: :keyword_list,
      required: true,
      keys: [
        enabled: [type: :boolean, required: true],
        context_key: [type: :string, required: true],
        middlewares: [type: {:list, :any}, required: true]
      ]
    ],
    runtime: [
      type: :keyword_list,
      required: true,
      keys: [
        api: [type: :atom, required: true],
        notifier: [type: :atom, required: true],
        health_peer_provider: [
          type: {:custom, __MODULE__, :validate_optional_module, []},
          required: false
        ],
        pubsub: [type: {:custom, __MODULE__, :validate_pubsub, []}, required: false],
        pubsub_topic: [type: :string, required: true]
      ]
    ],
    tenancy: [
      type: :keyword_list,
      required: true,
      keys: [
        module: [type: :atom, required: true]
      ]
    ]
  ]

  @compiled_schema NimbleOptions.new!(@raw_schema)

  @type t :: keyword() | map()

  @spec schema() :: keyword()
  def schema, do: @raw_schema

  @spec defaults() :: keyword()
  def defaults, do: @defaults

  @spec validate(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(opts \\ []) when is_list(opts) do
    defaults()
    |> merge(opts)
    |> NimbleOptions.validate(@compiled_schema)
  end

  @spec validate!(keyword()) :: t()
  def validate!(opts \\ []) when is_list(opts) do
    defaults()
    |> merge(opts)
    |> NimbleOptions.validate!(@compiled_schema)
  end

  @spec load(keyword()) :: t()
  def load(overrides \\ []) when is_list(overrides) do
    app_config =
      Application.get_env(:rulestead, :host, [])
      |> normalize_keyword()

    defaults()
    |> merge(app_config)
    |> merge(overrides)
    |> NimbleOptions.validate!(@compiled_schema)
  end

  defp merge(base, overrides) do
    Keyword.merge(base, normalize_keyword(overrides), fn _key, left, right ->
      if Keyword.keyword?(left) and Keyword.keyword?(right) do
        merge(left, right)
      else
        right
      end
    end)
  end

  def validate_pubsub(nil), do: {:ok, nil}
  def validate_pubsub(pubsub) when is_atom(pubsub), do: {:ok, pubsub}
  def validate_pubsub(_pubsub), do: {:error, "expected nil or a module atom"}

  def validate_optional_module(nil), do: {:ok, nil}
  def validate_optional_module(module) when is_atom(module), do: {:ok, module}
  def validate_optional_module(_module), do: {:error, "expected nil or a module atom"}

  defp normalize_keyword(value) when is_list(value), do: value
  defp normalize_keyword(_value), do: []
end
