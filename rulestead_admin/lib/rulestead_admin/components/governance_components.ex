defmodule RulesteadAdmin.Components.GovernanceComponents do
  @moduledoc false

  use Phoenix.Component

  alias RulesteadAdmin.Components.FlagComponents

  @update_limit 2
  @archive_limit 0
  @max_visible_breaches 5

  attr(:assessment, :map, required: true)
  attr(:variant, :atom, default: :operator, values: [:operator, :reviewer])
  attr(:visibility, :atom, default: :full, values: [:full, :redacted])
  attr(:environment_label, :string, default: nil)
  attr(:frozen?, :boolean, default: false)
  slot(:impact_preview)

  def blast_radius_panel(assigns) do
    reasons = breach_reasons(assigns.assessment)

    assigns =
      assigns
      |> assign(:verdict, verdict(assigns.assessment))
      |> assign(:breach_reasons, reasons)
      |> assign(:visible_breaches, Enum.take(reasons, @max_visible_breaches))
      |> assign(:overflow_breaches, Enum.drop(reasons, @max_visible_breaches))

    ~H"""
    <section class="rs-card rs-governance-panel" data-verdict={@verdict} aria-label="Blast radius governance">
      <FlagComponents.callout title={verdict_title(@verdict)} tone={verdict_tone(@verdict)}>
        <p :if={@environment_label}>
          Environment: <strong>{@environment_label}</strong>
        </p>
        <p :if={@frozen?}>
          Evidence frozen at submission
          <span :if={fingerprint(@assessment)}>
            · fingerprint <code>{fingerprint(@assessment)}</code>
          </span>
        </p>
      </FlagComponents.callout>

      <p class="rs-governance-panel__severity">
        <strong>Governance severity:</strong>
        {severity_line(@verdict)}
      </p>

      <p :if={threshold_summary(@assessment, @verdict)}>
        {threshold_summary(@assessment, @verdict)}
      </p>

      <p :if={show_basis_line?(@assessment)}>
        Population impact is estimated from authored references and explicit samples only.
      </p>

      <ul :if={@visible_breaches != []} class="rs-governance-breaches">
        <li :for={reason <- @visible_breaches}>
          {breach_line(reason, @visibility)}
        </li>
      </ul>

      <details :if={@variant == :reviewer and @overflow_breaches != []}>
        <summary>{length(@overflow_breaches)} more breach reasons</summary>
        <ul>
          <li :for={reason <- @overflow_breaches}>
            {breach_line(reason, @visibility)}
          </li>
        </ul>
      </details>

      <div :if={render_slot(@impact_preview)} class="rs-governance-impact-preview">
        {render_slot(@impact_preview)}
      </div>
    </section>
    """
  end

  defp verdict(assessment) do
    assessment
    |> Map.get(:verdict, Map.get(assessment, "verdict"))
    |> normalize_verdict()
  end

  defp normalize_verdict(verdict) when is_atom(verdict), do: verdict

  defp normalize_verdict(verdict) when is_binary(verdict) do
    case verdict do
      "above_threshold" -> :above_threshold
      "below_threshold" -> :below_threshold
      "indeterminate" -> :indeterminate
      _ -> :indeterminate
    end
  end

  defp normalize_verdict(_), do: :indeterminate

  defp breach_reasons(assessment) do
    assessment
    |> Map.get(:breach_reasons, Map.get(assessment, "breach_reasons", []))
    |> List.wrap()
  end

  defp verdict_title(:above_threshold), do: "Governance required"
  defp verdict_title(:below_threshold), do: "Direct apply allowed"
  defp verdict_title(:indeterminate), do: "Cannot evaluate safely"
  defp verdict_title(_), do: "Cannot evaluate safely"

  defp verdict_tone(:above_threshold), do: "warning"
  defp verdict_tone(:below_threshold), do: "neutral"
  defp verdict_tone(:indeterminate), do: "critical"
  defp verdict_tone(_), do: "critical"

  defp severity_line(:above_threshold), do: "Change request required before execution."
  defp severity_line(:below_threshold), do: "Direct apply remains available."
  defp severity_line(:indeterminate), do: "Blocked until preview evidence is safe to evaluate."
  defp severity_line(_), do: "Blocked until preview evidence is safe to evaluate."

  defp threshold_summary(assessment, :above_threshold) do
    operation =
      normalize_operation(Map.get(assessment, :operation) || Map.get(assessment, "operation"))

    count = reference_count(assessment)
    limit = limit_for_operation(operation)

    "Exceeds direct-apply limit (#{operation} limit: #{limit}, found: #{count} references)."
  end

  defp threshold_summary(_assessment, _), do: nil

  defp show_basis_line?(assessment) do
    authoritative? =
      Map.get(assessment, :authoritative_population_count?) ||
        Map.get(assessment, "authoritative_population_count?")

    authoritative? == false
  end

  defp fingerprint(assessment) do
    Map.get(assessment, :preview_fingerprint) || Map.get(assessment, "preview_fingerprint")
  end

  defp reference_count(assessment) do
    Map.get(assessment, :reference_count) || Map.get(assessment, "reference_count") || 0
  end

  defp normalize_operation("archive"), do: "archive"
  defp normalize_operation("update"), do: "update"
  defp normalize_operation(:archive), do: "archive"
  defp normalize_operation(:update), do: "update"
  defp normalize_operation(_), do: "update"

  defp limit_for_operation("archive"), do: @archive_limit
  defp limit_for_operation(_), do: @update_limit

  defp breach_line(reason, visibility) do
    code = Map.get(reason, :code) || Map.get(reason, "code") || "breach"
    remediation = Map.get(reason, :remediation) || Map.get(reason, "remediation")
    observed = Map.get(reason, :observed) || Map.get(reason, "observed")
    limit = Map.get(reason, :limit) || Map.get(reason, "limit")

    detail =
      if visibility == :redacted do
        redacted_observed_summary(observed)
      else
        observed_detail(observed)
      end

    [code, detail, remediation, limit_detail(observed, limit)]
    |> Enum.reject(fn item -> is_nil(item) or item == "" end)
    |> Enum.join(" — ")
  end

  defp redacted_observed_summary(observed) when is_map(observed) do
    keys = Map.get(observed, :reference_keys) || Map.get(observed, "reference_keys")

    if is_list(keys) and keys != [] do
      "#{length(keys)} references (keys hidden by permissions)"
    else
      observed_detail(observed)
    end
  end

  defp redacted_observed_summary(observed), do: observed_detail(observed)

  defp observed_detail(observed) when is_integer(observed), do: "observed #{observed}"
  defp observed_detail(observed) when is_binary(observed), do: "observed #{observed}"
  defp observed_detail(observed) when is_atom(observed), do: "observed #{observed}"

  defp observed_detail(observed) when is_map(observed) do
    keys = Map.get(observed, :reference_keys) || Map.get(observed, "reference_keys")

    if is_list(keys) and keys != [] do
      Enum.join(keys, ", ")
    end
  end

  defp observed_detail(_), do: nil

  defp limit_detail(_observed, nil), do: nil
  defp limit_detail(observed, limit) when is_map(observed), do: "limit #{inspect(limit)}"
  defp limit_detail(_observed, limit), do: "limit #{limit}"
end
