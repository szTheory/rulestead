defmodule Rulestead.Analytics.StatsTest do
  use ExUnit.Case, async: true

  alias Rulestead.Analytics.Stats

  describe "evaluate/2" do
    test "computes conversion lift percentage between two variations" do
      control = %{exposures: 1000, conversions: 100} # 10%
      variant = %{exposures: 1000, conversions: 150} # 15%

      result = Stats.evaluate(control, variant)

      # Lift is (0.15 - 0.10) / 0.10 = 0.50 (50%)
      assert result.lift > 0.49
      assert result.lift < 0.51
    end

    test "computes a Z-score and p-value for the conversion difference" do
      control = %{exposures: 1000, conversions: 100} # 10%
      variant = %{exposures: 1000, conversions: 120} # 12%

      result = Stats.evaluate(control, variant)

      # Hand-calc expected:
      # p_pool = 220 / 2000 = 0.11
      # SE = sqrt(0.11 * 0.89 * (2/1000)) = sqrt(0.0979 * 0.002) = sqrt(0.0001958) = 0.01399
      # Z = 0.02 / 0.01399 = ~1.429
      
      assert result.z_score > 1.42
      assert result.z_score < 1.44

      # p-value for Z=1.429 (two-tailed) is around 0.153
      assert result.p_value > 0.15
      assert result.p_value < 0.16
    end

    test "determines if difference meets standard significance threshold (e.g. 95%)" do
      control = %{exposures: 1000, conversions: 100} # 10%
      
      # Not significant
      variant1 = %{exposures: 1000, conversions: 110} # 11%
      result1 = Stats.evaluate(control, variant1)
      refute result1.significant

      # Significant
      variant2 = %{exposures: 1000, conversions: 150} # 15%
      result2 = Stats.evaluate(control, variant2)
      assert result2.significant
    end

    test "handles zero exposures gracefully" do
      control = %{exposures: 0, conversions: 0}
      variant = %{exposures: 1000, conversions: 150}

      result = Stats.evaluate(control, variant)
      assert result.lift == 0.0
      assert result.z_score == 0.0
      assert result.p_value == 1.0
      refute result.significant
    end

    test "handles zero conversions gracefully" do
      control = %{exposures: 1000, conversions: 0}
      variant = %{exposures: 1000, conversions: 10}

      result = Stats.evaluate(control, variant)
      assert result.lift > 0.0 # Division by zero in lift calculation? Should handle it.
      assert result.z_score > 0.0
    end
  end
end
