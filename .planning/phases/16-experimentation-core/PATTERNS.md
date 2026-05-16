# Phase 16: Experimentation Core - Pattern Map

**Mapped:** 2024-05-16
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rulestead/ruleset/experiment.ex` | model | structural | `lib/rulestead/ruleset/rollout.ex` | exact |
| `lib/rulestead/ruleset/rule.ex` | model | structural | `lib/rulestead/ruleset/rule.ex` | exact |
| `lib/rulestead/evaluator.ex` | service | synchronous evaluation | `lib/rulestead/evaluator.ex` | exact |
| `lib/rulestead/telemetry.ex` | telemetry | event-driven | `lib/rulestead/telemetry.ex` | exact |

## Pattern Assignments

### `lib/rulestead/ruleset/experiment.ex` (model, structural)

**Analog:** `lib/rulestead/ruleset/rollout.ex`

**Imports and schema pattern** (lines 1-13):
```elixir
defmodule Rulestead.Ruleset.Rollout do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  @bucket_by_values [:subject, :account, :tenant, :session]

  embedded_schema do
    field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
    field(:percentage, :integer)
    field(:salt, :string)
  end
```

**Changeset and validation pattern** (lines 18-26):
```elixir
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(rollout, attrs) do
    rollout
    |> cast(attrs, [:bucket_by, :percentage, :salt])
    |> update_change(:salt, &normalize_string/1)
    |> validate_required([:bucket_by, :percentage])
    |> validate_number(:percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_length(:salt, max: 255)
  end
```

---

### `lib/rulestead/ruleset/rule.ex` (model, structural)

**Analog:** `lib/rulestead/ruleset/rule.ex`

**Strategy enum pattern** (lines 10-10):
```elixir
  @strategies [:forced_value, :percentage_rollout, :variant_split, :segment_match]
```

**Embed pattern** (lines 20-22):
```elixir
    embeds_many(:conditions, Condition, on_replace: :delete)
    embeds_many(:variants, Variant, on_replace: :delete)
    embeds_one(:rollout, Rollout, on_replace: :update)
```

**Changeset pattern** (lines 33-35):
```elixir
    |> cast_embed(:conditions, with: &Condition.changeset/2)
    |> cast_embed(:variants, with: &Variant.changeset/2)
    |> cast_embed(:rollout, with: &Rollout.changeset/2)
```

**Custom validation pattern** (lines 72-87):
```elixir
  defp validate_rollout_requirements(changeset) do
    strategy = get_field(changeset, :strategy)
    rollout = get_field(changeset, :rollout)
    variants = get_field(changeset, :variants, [])

    cond do
      strategy == :percentage_rollout and is_nil(rollout) ->
        add_error(changeset, :rollout, "must be present for percentage_rollout rules")

      strategy == :variant_split and is_nil(rollout) ->
        add_error(changeset, :rollout, "must be present for variant_split rules")
```

---

### `lib/rulestead/evaluator.ex` (service, synchronous evaluation)

**Analog:** `lib/rulestead/evaluator.ex`

**Rule evaluation dispatch pattern** (lines 135-151):
```elixir
  defp evaluate_rollout(rule, flag_payload, active_ruleset, context) do
    strategy = rule[:strategy] || rule["strategy"]
    rollout = rule[:rollout] || rule["rollout"]

    cond do
      strategy in [:forced_value, :segment_match, "forced_value", "segment_match"] ->
        {:ok, %{matched?: true}}

      is_nil(rollout) ->
        {:skip, :missing_rollout, %{rollout: %{matched?: false}}}
```

**Bucket computation and salt pattern** (lines 159-166):
```elixir
            ruleset_salt = active_ruleset[:salt] || active_ruleset["salt"]
            rollout_salt = rollout[:salt] || rollout["salt"]
            rollout_bucket =
              Bucket.compute(
                flag_key,
                rule_key,
                Bucket.effective_salt(ruleset_salt, rollout_salt, bucket_by, :rollout),
                identity,
                :rollout
              )
```

**Match formatting pattern** (lines 169-181):
```elixir
              {:ok,
               %{
                 matched?: true,
                 bucket_by: stringify(bucket_by),
                 identity: identity,
                 bucket: rollout_bucket,
                 percentage: percentage,
                 variant_bucket:
                   Bucket.compute(
                     flag_key,
                     rule_key,
                     Bucket.effective_salt(ruleset_salt, rollout_salt, bucket_by, :variant),
                     identity,
                     :variant
                   )
               }}
```

---

### `lib/rulestead/telemetry.ex` (telemetry, event-driven)

**Analog:** `lib/rulestead/telemetry.ex`

**Metadata map pattern** (lines 75-87):
```elixir
  @spec result_metadata(Result.t(), Context.t() | map() | keyword() | nil, map()) :: map()
  def result_metadata(%Result{} = result, context, attrs \\ %{}) do
    context = normalize_context(context)
    trace = result.debug_trace || %{}

    attrs
    |> Map.new()
    |> Map.put_new(:flag_key, stringify(result.flag_key))
    |> Map.put_new(:environment, stringify(trace[:environment] || context.environment))
    |> Map.put_new(:reason, normalize_atom(result.reason))
    |> Map.put_new(:cache_age_ms, result.cache_age_ms)
    |> Map.put_new(:snapshot_version, result.flag_version)
    |> Map.put_new(:has_targeting_key?, not is_nil(context.targeting_key))
    |> Map.put_new(:matched_rule_count, matched_rule_count(trace, result))
  end
```

## Shared Patterns

### Value Stringification and Atom Normalization
**Source:** `lib/rulestead/evaluator.ex` and `lib/rulestead/telemetry.ex`
**Apply to:** All evaluator and telemetry additions
```elixir
  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: String.trim(value)
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: to_string(value)
```

### Deterministic Bucketing
**Source:** `lib/rulestead/evaluator.ex`
**Apply to:** Experiment evaluation logic
```elixir
  Bucket.compute(flag_key, rule_key, Bucket.effective_salt(ruleset_salt, experiment_salt, bucket_by, :experiment), identity, :experiment)
```

## Metadata

**Analog search scope:** `**/rule*.ex`, `**/evaluator*.ex`, `**/telemetry*.ex`
**Files scanned:** 18
**Pattern extraction date:** 2024-05-16