defmodule Rulestead.Analytics.Stats do
  @moduledoc """
  Calculates statistical significance for A/B test results without external dependencies.
  """

  @doc """
  Evaluates control and variant counts to compute conversion lift, z-score, p-value, and significance.
  Expects maps with `:exposures` and `:conversions` keys.

  Returns a map containing:
  - `:lift` - percentage lift (0.50 means 50%)
  - `:z_score` - standard score
  - `:p_value` - probability value
  - `:significant` - boolean (true if p-value < 0.05, 95% confidence)
  """
  def evaluate(%{exposures: c_exp, conversions: c_conv}, %{exposures: v_exp, conversions: v_conv}) do
    # Handle edge cases
    if c_exp == 0 or v_exp == 0 do
      %{
        lift: 0.0,
        z_score: 0.0,
        p_value: 1.0,
        significant: false
      }
    else
      cr_control = c_conv / c_exp
      cr_variant = v_conv / v_exp

      lift = if cr_control == 0.0 do
        if cr_variant > 0.0, do: 1.0, else: 0.0
      else
        (cr_variant - cr_control) / cr_control
      end

      # Z-score computation
      p_pool = (c_conv + v_conv) / (c_exp + v_exp)

      se = if p_pool == 0.0 or p_pool == 1.0 do
        0.0
      else
        :math.sqrt(p_pool * (1.0 - p_pool) * (1.0 / c_exp + 1.0 / v_exp))
      end

      z_score = if se == 0.0 do
        if cr_variant > cr_control, do: 99.0, else: 0.0
      else
        (cr_variant - cr_control) / se
      end

      p_value = normal_cdf_two_tailed(z_score)
      significant = p_value < 0.05

      %{
        lift: lift,
        z_score: z_score,
        p_value: p_value,
        significant: significant
      }
    end
  end

  # Abramowitz & Stegun approximation for standard normal CDF (Hastings approximation)
  # Computes two-tailed p-value: 2 * (1 - CDF(|z|))
  defp normal_cdf_two_tailed(z) do
    z_float = z * 1.0
    abs_z = abs(z_float)

    # If z is extremely large, p-value is effectively 0
    if abs_z > 8.0 do
      0.0
    else
      t = 1.0 / (1.0 + 0.2316419 * abs_z)
      d = 0.3989423 * :math.exp(-z_float * z_float / 2.0)

      # Polynomial approximation
      prob = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))))
      
      # Since we want 2 * (1 - CDF(|z|)), and `prob` is approximately (1 - CDF(|z|)) for positive z
      # wait, the formula above gives the upper tail probability directly for positive z
      # CDF(z) = 1 - prob (for z > 0)
      # Upper tail = prob
      # Two tailed = 2 * prob
      p_val = 2.0 * prob
      
      # ensure within bounds [0.0, 1.0]
      min(max(p_val, 0.0), 1.0)
    end
  end
end
