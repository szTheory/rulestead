defmodule Rulestead.TenancyPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Rulestead.Context

  property "default tenancy seam preserves bucketing identity without widening" do
    check all(
            targeting_key <- string(:alphanumeric, min_length: 1),
            tenant_key <- string(:alphanumeric, min_length: 1),
            session_id <- string(:alphanumeric, min_length: 1),
            bucket_by <- member_of([:subject, :tenant, :session])
          ) do
      context =
        Context.new(%{
          targeting_key: targeting_key,
          tenant_key: tenant_key,
          session_id: session_id
        })

      expected_identity =
        case bucket_by do
          :subject -> targeting_key
          :tenant -> tenant_key
          :session -> session_id
          _ -> targeting_key
        end

      identity = Rulestead.Tenancy.compose_bucket_identity(context, bucket_by, expected_identity)
      assert identity == expected_identity
    end
  end
end
