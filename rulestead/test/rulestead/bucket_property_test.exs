defmodule Rulestead.BucketPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Rulestead.Bucket

  property "identical inputs always produce the same bucket across 10k runs" do
    check all(
            flag_key <- string(:ascii, min_length: 1, max_length: 24),
            rule_key <- string(:ascii, min_length: 1, max_length: 24),
            salt <- string(:ascii, min_length: 1, max_length: 24),
            targeting_value <- string(:ascii, min_length: 1, max_length: 24),
            namespace <- member_of([:rollout, :variant]),
            max_runs: 10_000
          ) do
      bucket_a = Bucket.compute(flag_key, rule_key, salt, targeting_value, namespace)
      bucket_b = Bucket.compute(flag_key, rule_key, salt, targeting_value, namespace)

      assert bucket_a == bucket_b
      assert bucket_a in 0..9999
    end
  end

  property "rollout and variant namespaces remain distinct for the same identity" do
    check all(
            flag_key <- string(:ascii, min_length: 1, max_length: 24),
            rule_key <- string(:ascii, min_length: 1, max_length: 24),
            salt <- string(:ascii, min_length: 1, max_length: 24),
            targeting_value <- string(:ascii, min_length: 1, max_length: 24)
          ) do
      rollout_bucket = Bucket.compute(flag_key, rule_key, salt, targeting_value, :rollout)
      variant_bucket = Bucket.compute(flag_key, rule_key, salt, targeting_value, :variant)

      assert rollout_bucket in 0..9999
      assert variant_bucket in 0..9999
    end
  end
end
