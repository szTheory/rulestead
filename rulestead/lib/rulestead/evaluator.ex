# credo:disable-for-this-file
defmodule Rulestead.Evaluator do
  @moduledoc false

  alias Rulestead.{Bucket, Context, EvaluationError, Result}

  @spec evaluate(map(), Context.t() | keyword() | map()) ::
          {:ok, Result.t()} | {:error, Rulestead.Error.t()}
  def evaluate(flag_payload, context) when is_map(flag_payload) do
    context = Context.normalize(context)

    with {:ok, flag} <- fetch_map(flag_payload, :flag),
         {:ok, active_ruleset} <- fetch_map(flag_payload, :active_ruleset) do
      rules = fetch_list(active_ruleset, :rules)
      evaluate_rules(rules, flag_payload, flag, active_ruleset, context)
    else
      {:error, %Rulestead.Error{} = error} -> {:error, error}
    end
  end

  def evaluate(_flag_payload, _context), do: {:error, EvaluationError.malformed_runtime_data()}

  defp evaluate_rules(rules, flag_payload, flag, active_ruleset, context) do
    base_trace = %{
      environment: get_in(flag_payload, [:environment, :key]),
      strict?: context.strict?,
      rule_traces: [],
      warnings: []
    }

    case walk_rules(rules, flag_payload, flag, active_ruleset, context, base_trace) do
      {:match, result, trace} ->
        {:ok, Result.normalize(%{result | debug_trace: Map.put(trace, :outcome, :rule_match)})}

      {:default, trace} ->
        default_value = extract_value(flag[:default_value] || flag["default_value"])

        {:ok,
         Result.new(
           value: default_value,
           enabled?: truthy?(default_value),
           variant: nil,
           reason: :default,
           matched_rule: nil,
           flag_key: stringify(flag[:key] || flag["key"]),
           flag_version: active_ruleset[:version] || active_ruleset["version"],
           debug_trace: Map.put(trace, :outcome, :default)
         )}

      {:error, %Rulestead.Error{} = error} ->
        {:error, error}
    end
  end

  defp walk_rules([], _flag_payload, _flag, _active_ruleset, _context, trace),
    do: {:default, trace}

  defp walk_rules([rule | rest], flag_payload, flag, active_ruleset, context, trace) do
    case evaluate_rule(rule, flag_payload, flag, active_ruleset, context) do
      {:match, result, rule_trace} ->
        {:match, result, append_rule_trace(trace, Map.put(rule_trace, :matched?, true))}

      {:skip, rule_trace} ->
        walk_rules(
          rest,
          flag_payload,
          flag,
          active_ruleset,
          context,
          append_rule_trace(trace, Map.put(rule_trace, :matched?, false))
        )

      {:error, %Rulestead.Error{} = error} ->
        {:error, error}
    end
  end

  defp evaluate_rule(rule, flag_payload, flag, active_ruleset, context) do
    rule_key = stringify(rule[:key] || rule["key"])

    with {:ok, condition_trace} <- evaluate_conditions(fetch_list(rule, :conditions), context),
         {:ok, rollout_trace} <- evaluate_rollout(rule, flag_payload, active_ruleset, context),
         {:ok, result} <-
           build_result(rule, flag, active_ruleset, rule_key, condition_trace, rollout_trace) do
      {:match, result,
       %{
         rule_key: rule_key,
         conditions: condition_trace,
         rollout: result.debug_trace.rollout
       }
       |> maybe_put_audience_trace(rollout_trace[:audience_trace])}
    else
      {:skip, reason, detail} ->
        {:skip,
         %{
           rule_key: rule_key,
           reason: reason,
           conditions: detail[:conditions] || [],
           rollout: detail[:rollout],
           warnings: detail[:warnings] || []
         }
         |> maybe_put_audience_trace(get_in(detail, [:rollout, :audience_trace]))}

      {:error, %Rulestead.Error{} = error} ->
        {:error, error}
    end
  end

  defp evaluate_conditions(conditions, context) do
    traces = Enum.map(conditions, &evaluate_condition(&1, context))

    if Enum.all?(traces, & &1.passed?) do
      {:ok, traces}
    else
      {:skip, :conditions_not_met, %{conditions: traces}}
    end
  end

  defp evaluate_condition(condition, context) do
    attribute = condition[:attribute] || condition["attribute"]
    operator = condition[:operator] || condition["operator"]
    value = condition[:value] || condition["value"] || %{}
    actual = resolve_attribute(context, attribute)
    passed? = compare(operator, actual, value)

    %{
      attribute: attribute,
      operator: operator,
      expected: value,
      actual: actual,
      passed?: passed?,
      reason: condition_reason(actual, passed?)
    }
  end

  defp condition_reason(nil, false), do: :missing_attribute
  defp condition_reason(_actual, true), do: :matched
  defp condition_reason(_actual, false), do: :no_match

  defp evaluate_rollout(rule, flag_payload, active_ruleset, context) do
    strategy = rule[:strategy] || rule["strategy"]
    rollout = rule[:rollout] || rule["rollout"]
    experiment = rule[:experiment] || rule["experiment"]

    cond do
      strategy in [:forced_value, "forced_value"] ->
        {:ok, %{matched?: true}}

      strategy in [:segment_match, "segment_match"] ->
        evaluate_segment_match(rule, flag_payload, context)

      strategy in [:experiment, "experiment"] and is_nil(experiment) ->
        {:skip, :missing_experiment, %{experiment: %{matched?: false}}}

      strategy in [:experiment, "experiment"] ->
        bucket_by = experiment[:bucket_by] || experiment["bucket_by"]

        case resolve_bucket_identity(context, bucket_by) do
          {:ok, identity} ->
            flag_key = stringify(get_in(flag_payload, [:flag, :key]))
            rule_key = stringify(rule[:key] || rule["key"])
            iteration_salt = experiment[:iteration_salt] || experiment["iteration_salt"]

            holdout_percentage =
              experiment[:holdout_percentage] || experiment["holdout_percentage"] || 0

            {:ok,
             %{
               matched?: true,
               bucket_by: stringify(bucket_by),
               identity: identity,
               experiment_bucket:
                 Bucket.compute(
                   flag_key,
                   rule_key,
                   Bucket.effective_salt(iteration_salt, iteration_salt, bucket_by, :experiment),
                   identity,
                   :experiment
                 ),
               holdout_percentage: holdout_percentage,
               iteration_salt: iteration_salt,
               variant_bucket:
                 Bucket.compute(
                   flag_key,
                   rule_key,
                   Bucket.effective_salt(iteration_salt, iteration_salt, bucket_by, :variant),
                   identity,
                   :variant
                 )
             }}

          {:error, :missing_identity} ->
            if context.strict? do
              {:error,
               EvaluationError.missing_targeting_key(
                 metadata: %{
                   bucket_by: stringify(bucket_by),
                   environment: stringify(get_in(flag_payload, [:environment, :key]))
                 }
               )}
            else
              {:skip, :targeting_key_missing,
               %{
                 experiment: %{matched?: false, bucket_by: stringify(bucket_by)},
                 warnings: [
                   %{
                     type: :missing_targeting_key,
                     bucket_by: stringify(bucket_by),
                     strict?: false
                   }
                 ]
               }}
            end
        end

      is_nil(rollout) ->
        {:skip, :missing_rollout, %{rollout: %{matched?: false}}}

      true ->
        bucket_by = rollout[:bucket_by] || rollout["bucket_by"]

        case resolve_bucket_identity(context, bucket_by) do
          {:ok, identity} ->
            percentage = rollout[:percentage] || rollout["percentage"] || 0
            flag_key = stringify(get_in(flag_payload, [:flag, :key]))
            rule_key = stringify(rule[:key] || rule["key"])
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

            if rollout_bucket < percentage * 100 do
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
            else
              {:skip, :rollout_excluded,
               %{
                 rollout: %{
                   matched?: false,
                   bucket_by: stringify(bucket_by),
                   bucket: rollout_bucket
                 }
               }}
            end

          {:error, :missing_identity} ->
            if context.strict? do
              {:error,
               EvaluationError.missing_targeting_key(
                 metadata: %{
                   bucket_by: stringify(bucket_by),
                   environment: stringify(get_in(flag_payload, [:environment, :key]))
                 }
               )}
            else
              {:skip, :targeting_key_missing,
               %{
                 rollout: %{matched?: false, bucket_by: stringify(bucket_by)},
                 warnings: [
                   %{
                     type: :missing_targeting_key,
                     bucket_by: stringify(bucket_by),
                     strict?: false
                   }
                 ]
               }}
            end
        end
    end
  end

  defp build_result(rule, flag, active_ruleset, rule_key, condition_trace, rollout_trace) do
    strategy = rule[:strategy] || rule["strategy"]

    case strategy do
      strategy
      when strategy in [:forced_value, :segment_match, "forced_value", "segment_match"] ->
        value = extract_value(rule[:value] || rule["value"])
        {:ok, result(flag, active_ruleset, rule_key, value, nil, condition_trace, rollout_trace)}

      strategy when strategy in [:percentage_rollout, "percentage_rollout"] ->
        rule_value = extract_value(rule[:value] || rule["value"])

        value =
          if(is_nil(rule_value),
            do: extract_value(flag[:default_value] || flag["default_value"]),
            else: rule_value
          )

        {:ok, result(flag, active_ruleset, rule_key, value, nil, condition_trace, rollout_trace)}

      strategy when strategy in [:variant_split, "variant_split"] ->
        case choose_variant(fetch_list(rule, :variants), rollout_trace[:variant_bucket]) do
          {:ok, variant} ->
            value = extract_value(variant[:value] || variant["value"])
            variant_key = stringify(variant[:key] || variant["key"])

            {:ok,
             result(
               flag,
               active_ruleset,
               rule_key,
               value,
               variant_key,
               condition_trace,
               Map.put(rollout_trace, :variant, variant_key)
             )}

          :error ->
            {:error, EvaluationError.malformed_runtime_data()}
        end

      strategy when strategy in [:experiment, "experiment"] ->
        holdout_percentage = rollout_trace[:holdout_percentage] || 0
        experiment_bucket = rollout_trace[:experiment_bucket] || 0

        if experiment_bucket < holdout_percentage * 100 do
          variants = fetch_list(rule, :variants)
          control_variant = List.first(variants)

          if control_variant do
            value = extract_value(control_variant[:value] || control_variant["value"])
            variant_key = stringify(control_variant[:key] || control_variant["key"])

            {:ok,
             result(
               flag,
               active_ruleset,
               rule_key,
               value,
               variant_key,
               condition_trace,
               Map.put(rollout_trace, :experiment_bucket, "holdout")
             )}
          else
            {:error, EvaluationError.malformed_runtime_data()}
          end
        else
          case choose_variant(fetch_list(rule, :variants), rollout_trace[:variant_bucket]) do
            {:ok, variant} ->
              value = extract_value(variant[:value] || variant["value"])
              variant_key = stringify(variant[:key] || variant["key"])

              {:ok,
               result(
                 flag,
                 active_ruleset,
                 rule_key,
                 value,
                 variant_key,
                 condition_trace,
                 Map.put(rollout_trace, :variant, variant_key)
               )}

            :error ->
              {:error, EvaluationError.malformed_runtime_data()}
          end
        end

      _other ->
        {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp result(flag, active_ruleset, rule_key, value, variant_key, condition_trace, rollout_trace) do
    Result.new(
      value: value,
      enabled?: truthy?(value),
      variant: variant_key,
      reason: :rule_match,
      matched_rule: rule_key,
      flag_key: stringify(flag[:key] || flag["key"]),
      flag_version: active_ruleset[:version] || active_ruleset["version"],
      debug_trace: %{
        matched_rule: rule_key,
        conditions: condition_trace,
        rollout: rollout_trace,
        warnings: []
      }
    )
  end

  defp choose_variant(variants, bucket) when is_list(variants) and is_integer(bucket) do
    target = bucket + 1

    variants
    |> Enum.reduce_while({:error, 0}, fn variant, {:error, acc} ->
      next_acc = acc + (variant[:weight] || variant["weight"] || 0) * 100

      if target <= next_acc do
        {:halt, {:ok, variant}}
      else
        {:cont, {:error, next_acc}}
      end
    end)
    |> case do
      {:ok, variant} -> {:ok, variant}
      _ -> :error
    end
  end

  defp choose_variant(_variants, _bucket), do: :error

  defp resolve_bucket_identity(context, bucket_by) do
    default_identity =
      case bucket_by do
        b when b in [:subject, "subject"] ->
          context.targeting_key

        b when b in [:tenant, "tenant"] ->
          context.tenant_key

        b when b in [:session, "session"] ->
          context.session_id

        b when b in [:account, "account"] ->
          resolve_nested_map(context.attributes, ["account_key"]) ||
            resolve_nested_map(context.attributes, ["account_id"])

        _ ->
          context.targeting_key
      end
      |> stringify_identity()

    identity = Rulestead.Tenancy.compose_bucket_identity(context, bucket_by, default_identity)
    present(identity)
  end

  defp stringify_identity(nil), do: nil
  defp stringify_identity(""), do: nil
  defp stringify_identity(value), do: stringify(value)

  defp present(nil), do: {:error, :missing_identity}
  defp present(""), do: {:error, :missing_identity}
  defp present(value), do: {:ok, stringify(value)}

  defp resolve_attribute(context, "actor"), do: context.actor
  defp resolve_attribute(context, "targeting_key"), do: context.targeting_key
  defp resolve_attribute(context, "tenant_key"), do: context.tenant_key
  defp resolve_attribute(context, "environment"), do: context.environment
  defp resolve_attribute(context, "request_id"), do: context.request_id
  defp resolve_attribute(context, "session_id"), do: context.session_id

  defp resolve_attribute(context, attribute) when is_binary(attribute) do
    case String.split(attribute, ".", trim: true) do
      ["attributes" | rest] ->
        resolve_nested_map(context.attributes, rest)

      ["actor" | rest] ->
        resolve_nested_map(context.actor, rest)

      [single] ->
        Map.get(
          %{
            "targeting_key" => context.targeting_key,
            "tenant_key" => context.tenant_key,
            "environment" => context.environment,
            "request_id" => context.request_id,
            "session_id" => context.session_id
          },
          single
        ) || resolve_nested_map(context.attributes, [single])

      _other ->
        nil
    end
  end

  defp resolve_attribute(_context, _attribute), do: nil

  defp resolve_nested_map(value, []), do: value
  defp resolve_nested_map(nil, _path), do: nil

  defp resolve_nested_map(%_{} = struct, path),
    do: struct |> Map.from_struct() |> resolve_nested_map(path)

  defp resolve_nested_map(map, [segment | rest]) when is_map(map) do
    next =
      case Map.fetch(map, segment) do
        {:ok, value} ->
          value

        :error ->
          fetch_existing_atom_key(map, segment)
      end

    resolve_nested_map(next, rest)
  end

  defp resolve_nested_map(_value, _path), do: nil

  defp compare(:equals, actual, value), do: same_lane?(actual, fetch_value(value, :equals))
  defp compare("equals", actual, value), do: compare(:equals, actual, value)
  defp compare(:eq, actual, value), do: same_lane?(actual, fetch_comparable_value(value, :eq))
  defp compare("eq", actual, value), do: compare(:eq, actual, value)

  defp compare(:neq, actual, value),
    do: not same_lane?(actual, fetch_comparable_value(value, :neq))

  defp compare("neq", actual, value), do: compare(:neq, actual, value)
  defp compare(:in, actual, value), do: compare_list(actual, fetch_comparable_list(value, :in))
  defp compare("in", actual, value), do: compare(:in, actual, value)

  defp compare(:not_in, actual, value),
    do: not compare_list(actual, fetch_comparable_list(value, :not_in))

  defp compare("not_in", actual, value), do: compare(:not_in, actual, value)

  defp compare(:gt, actual, value),
    do: compare_number(actual, fetch_value(value, :gt), &Kernel.>/2)

  defp compare("gt", actual, value), do: compare(:gt, actual, value)

  defp compare(:lt, actual, value),
    do: compare_number(actual, fetch_value(value, :lt), &Kernel.</2)

  defp compare("lt", actual, value), do: compare(:lt, actual, value)

  defp compare(:gte, actual, value),
    do: compare_number(actual, fetch_value(value, :gte), &Kernel.>=/2)

  defp compare("gte", actual, value), do: compare(:gte, actual, value)

  defp compare(:lte, actual, value),
    do: compare_number(actual, fetch_value(value, :lte), &Kernel.<=/2)

  defp compare("lte", actual, value), do: compare(:lte, actual, value)
  defp compare(:regex, actual, value), do: compare_regex(actual, value)
  defp compare("regex", actual, value), do: compare(:regex, actual, value)
  defp compare(:exists, actual, _value), do: not is_nil(actual)
  defp compare("exists", actual, value), do: compare(:exists, actual, value)
  defp compare(_operator, _actual, _value), do: false

  defp compare_list(actual, values) when is_list(values),
    do: Enum.any?(values, &same_lane?(actual, &1))

  defp compare_list(_actual, _values), do: false

  defp compare_number(actual, expected, comparator)
       when is_number(actual) and is_number(expected),
       do: comparator.(actual, expected)

  defp compare_number(_actual, _expected, _comparator), do: false

  defp compare_regex(actual, value) when is_binary(actual) and is_map(value) do
    pattern = fetch_value(value, :pattern) || ""
    options = fetch_value(value, :options) || ""

    case Regex.compile(pattern, options) do
      {:ok, regex} -> Regex.match?(regex, actual)
      {:error, _reason} -> false
    end
  end

  defp compare_regex(_actual, _value), do: false

  defp same_lane?(actual, expected) when is_integer(actual) and is_float(expected),
    do: actual == expected

  defp same_lane?(actual, expected) when is_float(actual) and is_integer(expected),
    do: actual == expected

  defp same_lane?(actual, expected) when is_nil(actual) or is_nil(expected), do: false
  defp same_lane?(actual, expected), do: lane(actual) == lane(expected) and actual == expected

  defp lane(value) when is_binary(value), do: :string
  defp lane(value) when is_integer(value) or is_float(value), do: :number
  defp lane(value) when is_boolean(value), do: :boolean
  defp lane(value) when is_atom(value), do: :atom
  defp lane(_value), do: :other

  defp fetch_map(map, key) when is_map(map) do
    case fetch_value(map, key) do
      value when is_map(value) -> {:ok, value}
      _ -> {:error, EvaluationError.malformed_runtime_data()}
    end
  end

  defp fetch_list(map, key) when is_map(map) do
    case fetch_value(map, key) do
      value when is_list(value) -> value
      _ -> []
    end
  end

  defp fetch_value(map, key) when is_map(map) do
    with :error <- Map.fetch(map, key),
         :error <- Map.fetch(map, Atom.to_string(key)) do
      nil
    else
      {:ok, value} -> value
    end
  end

  defp fetch_value(_map, _key), do: nil

  defp fetch_comparable_value(map, key) when is_map(map) do
    case fetch_value(map, key) do
      nil ->
        case fetch_value(map, :equals) do
          nil -> fetch_value(map, :value)
          value -> value
        end

      value ->
        value
    end
  end

  defp fetch_comparable_value(value, _key), do: value

  defp fetch_comparable_list(map, key) when is_map(map) do
    case fetch_value(map, key) do
      nil -> fetch_value(map, :value)
      value -> value
    end
  end

  defp fetch_comparable_list(value, _key), do: value

  defp extract_value(%{value: value}), do: value
  defp extract_value(%{"value" => value}), do: value
  defp extract_value(value), do: value

  defp truthy?(value) when is_boolean(value), do: value
  defp truthy?(nil), do: false
  defp truthy?(_value), do: true

  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: value
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: to_string(value)

  defp evaluate_segment_match(rule, flag_payload, context) do
    audience_key = stringify(rule[:audience_key] || rule["audience_key"])
    audiences = flag_payload[:audiences] || flag_payload["audiences"] || %{}
    audience = if is_map(audiences), do: Map.get(audiences, audience_key), else: nil

    cond do
      is_nil(audience_key) or audience_key == "" ->
        audience_skip(audience_key, :missing, :audience_missing)

      is_nil(audience) ->
        audience_skip(audience_key, :missing, :audience_missing)

      not is_nil(audience[:archived_at] || audience["archived_at"]) ->
        audience_skip(audience_key, :archived, :audience_archived)

      audience_matches?(audience[:definition] || audience["definition"], context) ->
        {:ok,
         %{
           matched?: true,
           audience_trace: %{
             audience_key: audience_key,
             matched?: true,
             reason: :matched
           }
         }}

      true ->
        {:skip, :audience_missed,
         %{
           rollout: %{
             matched?: false,
             audience_trace: %{
               audience_key: audience_key,
               matched?: false,
               reason: :missed
             }
           }
         }}
    end
  end

  defp audience_skip(audience_key, reason, warning_type) do
    {:skip, warning_type,
     %{
       rollout: %{
         matched?: false,
         audience_trace: %{
           audience_key: audience_key,
           matched?: false,
           reason: reason
         }
       },
       warnings: [%{type: warning_type, audience_key: audience_key}]
     }}
  end

  defp fetch_existing_atom_key(map, segment) when is_binary(segment) do
    Map.get(map, String.to_existing_atom(segment))
  rescue
    ArgumentError -> nil
  end

  defp fetch_existing_atom_key(_map, _segment), do: nil

  defp audience_matches?(definition, context) when is_map(definition) do
    clauses = fetch_list(definition, :clauses) ++ fetch_list(definition, :conditions)

    Enum.all?(clauses, fn clause ->
      attribute = clause[:attribute] || clause["attribute"]
      operator = clause[:operator] || clause["operator"] || clause[:op] || clause["op"]
      value = fetch_value(clause, :value)
      value = if is_nil(value), do: %{}, else: value

      compare(operator, resolve_attribute(context, attribute), value)
    end)
  end

  defp audience_matches?(_definition, _context), do: false

  defp append_rule_trace(trace, rule_trace) do
    trace
    |> Map.update!(:rule_traces, &(&1 ++ [rule_trace]))
    |> Map.update!(:warnings, fn warnings -> warnings ++ Map.get(rule_trace, :warnings, []) end)
    |> maybe_put_matched_rule(rule_trace)
    |> maybe_put_matched_rule_trace(rule_trace)
  end

  defp maybe_put_matched_rule(trace, %{matched?: true, rule_key: rule_key}),
    do: Map.put(trace, :matched_rule, rule_key)

  defp maybe_put_matched_rule(trace, _rule_trace), do: trace

  defp maybe_put_matched_rule_trace(trace, %{matched?: true} = rule_trace),
    do: Map.put(trace, :matched_rule_trace, rule_trace)

  defp maybe_put_matched_rule_trace(trace, _rule_trace), do: trace

  defp maybe_put_audience_trace(trace, nil), do: trace

  defp maybe_put_audience_trace(trace, audience_trace),
    do: Map.put(trace, :audience_trace, audience_trace)
end
