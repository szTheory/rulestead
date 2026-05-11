# Phase 03: Context, Rules, Deterministic Bucketing, Pure Evaluator - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead.ex` | utility | request-response | `rulestead/lib/rulestead.ex` | exact |
| `rulestead/lib/rulestead/context.ex` | model | transform | `rulestead/lib/rulestead/error.ex` | partial |
| `rulestead/lib/rulestead/result.ex` | model | transform | `rulestead/lib/rulestead/error.ex` | partial |
| `rulestead/lib/rulestead/evaluation_error.ex` | utility | request-response | `rulestead/lib/rulestead/evaluation_error.ex` | exact |
| `rulestead/lib/rulestead/evaluator.ex` | service | request-response | `rulestead/lib/rulestead/fake.ex` | partial |
| `rulestead/lib/rulestead/bucket.ex` | utility | transform | `rulestead/lib/rulestead/ruleset/rollout.ex` | partial |
| `rulestead/lib/rulestead/explainer.ex` | service | transform | `rulestead/lib/rulestead/fake.ex` | partial |
| `rulestead/lib/rulestead/ruleset.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset.ex` | exact |
| `rulestead/lib/rulestead/ruleset/rule.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset/rule.ex` | exact |
| `rulestead/lib/rulestead/ruleset/condition.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset/condition.ex` | exact |
| `rulestead/lib/rulestead/ruleset/rollout.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset/rollout.ex` | exact |
| `rulestead/test/rulestead/{context_test,bucket_property_test,evaluator_test}.exs` | test | transform | `rulestead/test/support/store_contract_case.ex` | role-match |

## Pattern Assignments

### `rulestead/lib/rulestead.ex` (utility, request-response)

**Analog:** `rulestead/lib/rulestead.ex`

**Public facade shape** (`rulestead/lib/rulestead.ex:13-15`, `24-50`, `135-155`):
```elixir
alias Rulestead.{ConfigError, Error, EvaluationError, Store, StoreError}
alias Rulestead.Store.Command

@spec fetch_flag(String.t() | atom(), String.t() | atom(), keyword()) :: Store.result(map())
def fetch_flag(flag_key, environment_key, opts \\ []) do
  flag_key
  |> Command.FetchFlag.new(environment_key, opts)
  |> fetch_flag()
end

@spec evaluate(String.t() | atom(), term(), keyword()) :: {:error, Error.t()}
def evaluate(flag_key, context, opts \\ []) do
  {:error,
   EvaluationError.not_implemented(
     metadata: evaluator_metadata(flag_key, opts),
     details: evaluator_details(context)
   )}
end

@spec evaluate!(String.t() | atom(), term(), keyword()) :: no_return()
def evaluate!(flag_key, context, opts \\ []) do
  flag_key
  |> evaluate(context, opts)
  |> unwrap!()
end
```

**Error normalization + bang handling** (`rulestead/lib/rulestead.ex:157-165`, `229-265`):
```elixir
defp run_store(operation, args) do
  case configured_store() do
    {:ok, adapter} -> invoke_store(adapter, operation, args)
    {:error, %Error{} = error} -> {:error, error}
  end
end

defp do_invoke_store(adapter, operation, args) do
  result = apply(adapter, operation, args)
  normalize_store_result(result, adapter, operation)
rescue
  error in [Error] ->
    {:error, error}

  exception ->
    {:error,
     StoreError.unavailable(
       metadata: %{adapter: inspect(adapter), operation: Atom.to_string(operation)},
       cause: exception
     )}
end

defp unwrap!({:ok, value}), do: value
defp unwrap!({:error, %Error{} = error}), do: raise(error)
```

**Copy into Phase 3:** keep the root module as a thin facade. Add `enabled?/2`, `get_value/3`, `get_variant/2`, `explain/2`, and real `evaluate/3` here, but push the evaluator logic into dedicated modules.

---

### `rulestead/lib/rulestead/context.ex` (model, transform)

**Analog:** `rulestead/lib/rulestead/error.ex`

**Struct + normalization pattern** (`rulestead/lib/rulestead/error.ex:10-12`, `47-55`, `91-111`):
```elixir
@enforce_keys [:domain, :type, :message]
defexception [:domain, :type, :message, metadata: %{}, details: [], cause: nil, plug_status: nil]

@type t :: %__MODULE__{
        domain: domain(),
        type: type(),
        message: String.t(),
        metadata: metadata(),
        details: [detail()],
        cause: term(),
        plug_status: nil | pos_integer()
      }

@spec new(keyword() | map()) :: t()
def new(attrs) when is_list(attrs) or is_map(attrs) do
  attrs = Map.new(attrs)

  %__MODULE__{...}
end

@spec normalize(t() | keyword() | map()) :: t()
def normalize(%__MODULE__{} = error), do: new(Map.from_struct(error))
def normalize(attrs) when is_list(attrs) or is_map(attrs), do: new(attrs)
```

**Copy into Phase 3:** make `Context.new/1` do immediate normalization from keyword/map input into one authoritative struct. Follow the same typed-struct + normalizer pattern, but use regular `defstruct` rather than `defexception`.

**Naming constraint:** phase context locks `actor` as canonical and allows `subject` only as a temporary input alias during normalization.

---

### `rulestead/lib/rulestead/result.ex` (model, transform)

**Analog:** `rulestead/lib/rulestead/error.ex`

**Typed public struct pattern** (`rulestead/lib/rulestead/error.ex:39-55`, `91-103`):
```elixir
@type metadata_scalar :: nil | boolean | integer | float | atom | String.t()
@type metadata :: %{optional(metadata_key()) => metadata_scalar()}

@type t :: %__MODULE__{
        domain: domain(),
        type: type(),
        message: String.t(),
        metadata: metadata(),
        details: [detail()],
        cause: term(),
        plug_status: nil | pos_integer()
      }

%__MODULE__{
  domain: normalize_domain(Map.get(attrs, :domain)),
  type: normalize_type(Map.get(attrs, :type)),
  message: normalize_message(Map.get(attrs, :message), Map.get(attrs, :type)),
  metadata: normalize_metadata(Map.get(attrs, :metadata, %{})),
  details: normalize_details(Map.get(attrs, :details, [])),
  cause: Map.get(attrs, :cause),
  plug_status: Map.get(attrs, :plug_status)
}
```

**Copy into Phase 3:** give `%Rulestead.Result{}` a closed, typed field set with stable defaults and any debug-trace normalization in one constructor. Keep it safe for direct pattern matching in tests.

---

### `rulestead/lib/rulestead/evaluation_error.ex` (utility, request-response)

**Analog:** `rulestead/lib/rulestead/evaluation_error.ex`

**Typed error constructor namespace** (`rulestead/lib/rulestead/evaluation_error.ex:6-33`):
```elixir
alias Rulestead.Error

@spec new(Error.type(), String.t(), keyword()) :: Error.t()
def new(type, message, opts \\ []) do
  build(type, message, opts)
end

defp build(type, message, opts) do
  Error.new(
    Keyword.merge(
      [
        domain: :evaluation,
        type: type,
        message: message
      ],
      opts
    )
  )
end
```

**Copy into Phase 3:** extend this module instead of inventing ad hoc `%Rulestead.Error{}` literals throughout evaluator code. Add compact constructors for strict-mode and malformed-runtime-data failures.

---

### `rulestead/lib/rulestead/evaluator.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/fake.ex`

**Core orchestration with guarded context lookup** (`rulestead/lib/rulestead/fake.ex:146-189`, `427-476`):
```elixir
def handle_call({:fetch_flag, command}, _from, state) do
  reply =
    with_fetch_context(state, command.flag_key, command.environment_key, fn flag,
                                                                            environment,
                                                                            flag_environment ->
      {:ok, build_flag_payload(flag, environment, flag_environment, command.include_ruleset?)}
    end)

  {:reply, reply, state}
end

defp with_fetch_context(state, flag_key, environment_key, fun) do
  with {:ok, environment} <- fetch_environment(state, environment_key),
       {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment.key) do
    fun.(flag, environment, flag_environment)
  end
end

defp with_mutable_context(state, flag_key, environment_key, fun) do
  with {:ok, environment} <- fetch_environment(state, environment_key),
       {:ok, flag, flag_environment} <- fetch_flag_environment(state, flag_key, environment.key),
       :ok <- ensure_not_archived(flag_key, flag) do
    fun.(flag, environment, flag_environment)
  end
end
```

**Structured payload assembly** (`rulestead/lib/rulestead/fake.ex:587-603`):
```elixir
defp build_flag_payload(flag, environment, flag_environment, include_ruleset?) do
  %{
    flag: flag_summary(flag),
    environment: environment,
    flag_environment: flag_environment_summary(flag_environment),
    active_ruleset:
      if(include_ruleset?,
        do:
          active_ruleset_payload(flag, environment.key, flag_environment.active_ruleset_version)
      ),
    draft_rulesets:
      if(include_ruleset?,
        do: draft_ruleset_payloads(flag, environment.key),
        else: []
      )
  }
end
```

**Copy into Phase 3:** keep evaluator orchestration as a `with` pipeline returning `{:ok, %Result{}} | {:error, %Rulestead.Error{}}`. Use small helpers for context lookup, rule walking, and fallback construction; do not bury the whole evaluator in one function.

---

### `rulestead/lib/rulestead/bucket.ex` (utility, transform)

**Analog:** `rulestead/lib/rulestead/ruleset/rollout.ex`

**Small focused API with closed enum** (`rulestead/lib/rulestead/ruleset/rollout.ex:10-31`):
```elixir
@bucket_by_values [:subject, :account, :tenant, :session]

embedded_schema do
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
  field(:percentage, :integer)
  field(:salt, :string)
end

@spec bucket_by_values() :: [atom()]
def bucket_by_values, do: @bucket_by_values
```

**Copy into Phase 3:** follow the same style for a tiny bucketing module: one closed public contract, a small number of pure functions, and no hidden fallback chain. Phase context locks `0..9999` buckets and `:sha256` over canonical inputs.

---

### `rulestead/lib/rulestead/explainer.ex` (service, transform)

**Analog:** `rulestead/lib/rulestead/fake.ex`

**Render from the same evaluation facts used by the machine-readable payload** (`rulestead/lib/rulestead/fake.ex:587-603`, `613-640`):
```elixir
%{
  flag: flag_summary(flag),
  environment: environment,
  flag_environment: flag_environment_summary(flag_environment),
  active_ruleset: ...,
  draft_rulesets: ...
}

defp flag_summary(flag) do
  Map.take(flag, [
    :id,
    :key,
    :description,
    :flag_type,
    :value_type,
    :default_value,
    :owner,
    :expected_expiration,
    :tags,
    :archived_at,
    :inserted_at,
    :updated_at
  ])
end
```

**Copy into Phase 3:** keep `debug_trace` as the source of truth and render human text from it in a separate module. Do not mix prose generation into the evaluator hot path.

---

### `rulestead/lib/rulestead/ruleset.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/ruleset.ex`

**Top-level embed boundary** (`rulestead/lib/rulestead/ruleset.ex:15-43`):
```elixir
schema "rulesets" do
  field(:version, :integer)
  field(:status, Ecto.Enum, values: @statuses, default: :draft)
  field(:salt, :string)
  field(:published_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})

  belongs_to(:flag_environment, Rulestead.FlagEnvironment)

  embeds_many(:rules, Rule, on_replace: :delete)

  timestamps(type: :utc_datetime_usec)
end

def changeset(ruleset, attrs) do
  ruleset
  |> cast(attrs, [:flag_environment_id, :version, :status, :salt, :published_at, :metadata])
  |> update_change(:salt, &normalize_string/1)
  |> cast_embed(:rules, with: &Rule.changeset/2)
  |> validate_required([:flag_environment_id, :version, :status])
  |> validate_number(:version, greater_than: 0)
  |> validate_length(:salt, max: 255)
  |> validate_published_status()
  |> foreign_key_constraint(:flag_environment_id)
  |> unique_constraint([:flag_environment_id, :version])
end
```

**Copy into Phase 3:** tighten semantics in place rather than introducing a second runtime authoring shape. The planner should keep the persisted ruleset document as the evaluator input boundary.

---

### `rulestead/lib/rulestead/ruleset/rule.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/ruleset/rule.ex`

**Embedded rule shape + changeset pipeline** (`rulestead/lib/rulestead/ruleset/rule.ex:12-44`):
```elixir
@strategies [:forced_value, :percentage_rollout, :variant_split, :segment_match]

embedded_schema do
  field(:key, :string)
  field(:name, :string)
  field(:description, :string)
  field(:strategy, Ecto.Enum, values: @strategies)
  field(:value, :map, default: %{})
  field(:audience_id, :binary_id)
  field(:audience_key, :string)

  embeds_many(:conditions, Condition, on_replace: :delete)
  embeds_many(:variants, Variant, on_replace: :delete)
  embeds_one(:rollout, Rollout, on_replace: :update)
end

def changeset(rule, attrs) do
  rule
  |> cast(attrs, [:key, :name, :description, :strategy, :value, :audience_id, :audience_key])
  |> update_change(:key, &normalize_string/1)
  |> update_change(:name, &normalize_string/1)
  |> update_change(:description, &normalize_string/1)
  |> update_change(:audience_key, &normalize_string/1)
  |> cast_embed(:conditions, with: &Condition.changeset/2)
  |> cast_embed(:variants, with: &Variant.changeset/2)
  |> cast_embed(:rollout, with: &Rollout.changeset/2)
  |> validate_required([:key, :strategy])
  |> validate_length(:key, min: 1, max: 128)
  |> validate_rule_shape()
end
```

**Rule-specific validation pattern** (`rulestead/lib/rulestead/ruleset/rule.ex:49-107`):
```elixir
defp validate_rule_shape(changeset) do
  changeset
  |> validate_audience_reference()
  |> validate_variant_weights()
  |> validate_rollout_requirements()
  |> validate_forced_value()
end
```

**Copy into Phase 3:** keep all Phase 3 semantic tightening as composable validators on this existing embed. Add operator-payload and sticky-rollout validation here or in the child embeds, not in the evaluator.

---

### `rulestead/lib/rulestead/ruleset/condition.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/ruleset/condition.ex`

**Operator enum + normalization entry point** (`rulestead/lib/rulestead/ruleset/condition.ex:10-27`):
```elixir
@operators [:equals, :in, :not_in, :gt, :lt, :gte, :lte, :regex, :exists]

embedded_schema do
  field(:attribute, :string)
  field(:operator, Ecto.Enum, values: @operators)
  field(:value, :map, default: %{})
end

def changeset(condition, attrs) do
  condition
  |> cast(attrs, [:attribute, :operator, :value])
  |> update_change(:attribute, &normalize_string/1)
  |> validate_required([:attribute, :operator])
  |> validate_length(:attribute, min: 1, max: 255)
end
```

**Copy into Phase 3:** preserve this module as the persisted-shape validator, but replace the loose `:map` semantics with operator-specific validation and normalization. Dot-path parsing belongs here or in a dedicated helper called from here.

---

### `rulestead/lib/rulestead/ruleset/rollout.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/ruleset/rollout.ex`

**Bucketing config embed** (`rulestead/lib/rulestead/ruleset/rollout.ex:10-28`):
```elixir
@bucket_by_values [:subject, :account, :tenant, :session]

embedded_schema do
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
  field(:percentage, :integer)
  field(:salt, :string)
end

def changeset(rollout, attrs) do
  rollout
  |> cast(attrs, [:bucket_by, :percentage, :salt])
  |> update_change(:salt, &normalize_string/1)
  |> validate_required([:bucket_by, :percentage])
  |> validate_number(:percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  |> validate_length(:salt, max: 255)
end
```

**Copy into Phase 3:** keep author-facing percentages at `0..100` here, then compile to basis points in runtime code. Add any validation tied to sticky identity requirements here if it can be caught before evaluation.

---

### `rulestead/test/rulestead/{context_test,bucket_property_test,evaluator_test}.exs` (test, transform)

**Analog:** `rulestead/test/support/store_contract_case.ex` and `rulestead/test/support/store_fixtures.ex`

**Shared setup pattern** (`rulestead/test/support/store_contract_case.ex:8-37`):
```elixir
using opts do
  quote bind_quoted: [opts: opts] do
    use ExUnit.Case, async: false

    import Rulestead.StoreContractCase
    import Rulestead.StoreFixtures

    setup do
      previous_store = Application.get_env(:rulestead, :store)
      @store_control.ensure_started()
      @store_control.reset!()
      Application.put_env(:rulestead, :store, @store_module)

      on_exit(fn ->
        @store_control.reset!()
        ...
      end)

      :ok
    end
  end
end
```

**Fixture-builder pattern** (`rulestead/test/support/store_fixtures.ex:34-57`, `73-88`):
```elixir
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
          %{attribute: "tenant_key", operator: :equals, value: %{equals: "acme"}}
        ]
      }
    ]
  }

  Map.merge(defaults, overrides)
end

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
```

**Invariant-style assertions** (`rulestead/test/support/store_contract_case.ex:42-167`):
```elixir
test "returns a typed variant-weight error when rule weights do not sum to 100" do
  @store_control.put_flag!(valid_flag_attrs())

  assert {:error, %Error{domain: :ruleset, type: :variant_weights_invalid} = error} =
           @store_module.save_draft_ruleset(
             save_draft_command(
               "checkout-redesign",
               "test",
               invalid_variant_weight_ruleset_attrs()
             )
           )

  assert Enum.any?(error.details, &(&1[:message] == "weights must sum to 100"))
end
```

**Copy into Phase 3:** keep tests builder-driven and invariant-focused. Add separate files for context normalization, evaluator behavior, and StreamData bucketing properties; do not collapse everything into one root test file.

## Shared Patterns

### Public API tuples and bang variants
**Source:** `rulestead/lib/rulestead.ex:24-50`, `135-155`, `264-265`
**Apply to:** `Rulestead.evaluate/3`, `evaluate!/3`, `enabled?/2`, `get_value/3`, `get_variant/2`, `explain/2`
```elixir
@spec evaluate(String.t() | atom(), term(), keyword()) :: {:error, Error.t()}
def evaluate(flag_key, context, opts \\ []) do
  ...
end

@spec evaluate!(String.t() | atom(), term(), keyword()) :: no_return()
def evaluate!(flag_key, context, opts \\ []) do
  flag_key
  |> evaluate(context, opts)
  |> unwrap!()
end

defp unwrap!({:ok, value}), do: value
defp unwrap!({:error, %Error{} = error}), do: raise(error)
```

### Stable error envelope
**Source:** `rulestead/lib/rulestead/error.ex:10-12`, `47-55`, `91-103`, `183-199`
**Apply to:** evaluator failures, strict-mode failures, malformed runtime-data handling
```elixir
@enforce_keys [:domain, :type, :message]
defexception [:domain, :type, :message, metadata: %{}, details: [], cause: nil, plug_status: nil]

%__MODULE__{
  domain: normalize_domain(Map.get(attrs, :domain)),
  type: normalize_type(Map.get(attrs, :type)),
  message: normalize_message(Map.get(attrs, :message), Map.get(attrs, :type)),
  metadata: normalize_metadata(Map.get(attrs, :metadata, %{})),
  details: normalize_details(Map.get(attrs, :details, [])),
  cause: Map.get(attrs, :cause),
  plug_status: Map.get(attrs, :plug_status)
}
```

### Changeset-first semantic validation
**Source:** `rulestead/lib/rulestead/ruleset.ex:32-42`, `rulestead/lib/rulestead/ruleset/rule.ex:31-55`, `rulestead/lib/rulestead/ruleset/condition.ex:21-27`, `rulestead/lib/rulestead/ruleset/rollout.ex:21-28`
**Apply to:** all Phase 3 authoring-shape tightening for conditions, rollout config, and rule semantics
```elixir
|> cast_embed(:rules, with: &Rule.changeset/2)
|> validate_required([:flag_environment_id, :version, :status])
|> validate_number(:version, greater_than: 0)

|> cast_embed(:conditions, with: &Condition.changeset/2)
|> cast_embed(:variants, with: &Variant.changeset/2)
|> cast_embed(:rollout, with: &Rollout.changeset/2)
|> validate_rule_shape()
```

### Fake-backed invariant testing
**Source:** `rulestead/test/support/store_contract_case.ex:20-37`, `42-167`
**Apply to:** evaluator tests, explain/evaluate consistency tests, strict/permissive mode coverage
```elixir
setup do
  previous_store = Application.get_env(:rulestead, :store)
  @store_control.ensure_started()
  @store_control.reset!()
  Application.put_env(:rulestead, :store, @store_module)

  on_exit(fn ->
    @store_control.reset!()
    ...
  end)

  :ok
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/lib/rulestead/context.ex` | model | transform | No existing plain public struct-builder module yet; only `%Rulestead.Error{}` shows the project’s current typed-struct normalization style. |
| `rulestead/lib/rulestead/result.ex` | model | transform | No existing result/trace struct exists yet; copy conventions from `%Rulestead.Error{}`. |
| `rulestead/lib/rulestead/bucket.ex` | utility | transform | No existing hashing utility exists yet; only rollout config and property-test guidance define the contract. |
| `rulestead/lib/rulestead/explainer.ex` | service | transform | No renderer module exists yet; use evaluator facts as the source and keep prose generation separate. |

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/test`, `.planning`, `prompts`
**Files scanned:** 18
**Pattern extraction date:** 2026-04-23
