defmodule RulesteadDemoWeb.FlagJSON do
  @moduledoc false

  alias Rulestead.{Error, Result}

  def evaluation(%Result{} = result, environment_key) do
    %{
      flagKey: result.flag_key,
      environmentKey: to_string(environment_key),
      enabled: result.enabled?,
      value: result.value,
      variant: result.variant,
      reason: to_string(result.reason),
      flagVersion: result.flag_version,
      cacheAgeMs: result.cache_age_ms,
      matchedRule: result.matched_rule
    }
  end

  def error(%Error{} = error) do
    %{
      error: %{
        code: to_string(error.type),
        message: error.message
      }
    }
  end
end
