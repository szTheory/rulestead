defmodule Rulestead.Admin.Lifecycle do
  @moduledoc false
  # Derives persisted admin lifecycle state from authored flag data.

  alias Rulestead.Admin.LifecycleDefaults

  @default_stale_after_seconds 30 * 24 * 60 * 60
  @default_secondary_limit 2
  @protected_flag_types [:kill_switch, :operational, :permission]

  @type state :: :active | :potentially_stale | :stale | :archived

  @spec classify(map() | struct(), map() | struct(), keyword()) :: %{
          state: state(),
          mode: :permanent | :expiring,
          owner: term(),
          owner_ref: term(),
          owner_kind: term(),
          owner_display: term(),
          ownership: map(),
          expected_expiration: Date.t() | nil,
          permanent: boolean(),
          review_by: Date.t() | nil,
          default_source: term(),
          default_overridden: boolean(),
          suggestion: map(),
          last_evaluated_at: DateTime.t() | nil
        }
  def classify(flag, flag_environment, opts \\ []) do
    flag = Map.new(flag)
    flag_environment = Map.new(flag_environment)
    ownership = normalize_nested_map(flag[:ownership])
    lifecycle = normalize_nested_map(flag[:lifecycle])

    permanent = truthy?(flag[:permanent])
    expected_expiration = flag[:expected_expiration]
    last_evaluated_at = flag_environment[:last_evaluated_at]
    mode = lifecycle[:mode] || if(permanent, do: :permanent, else: :expiring)

    suggestion =
      LifecycleDefaults.suggest(flag[:flag_type],
        authored_mode: mode,
        authored_review_by: lifecycle[:review_by] || expected_expiration
      )

    freshness =
      freshness(flag, flag_environment,
        now: Keyword.get(opts, :now, DateTime.utc_now()),
        warning_after_seconds: warning_after_seconds(opts),
        stale_after_seconds: stale_after_seconds(opts),
        code_reference_count: Keyword.get(opts, :code_reference_count),
        code_refs_scan: Keyword.get(opts, :code_refs_scan)
      )

    lifecycle_branch = %{
      state: freshness.state,
      mode: mode,
      ownership: ownership,
      review_by: lifecycle[:review_by] || expected_expiration,
      expected_expiration: expected_expiration,
      permanent: permanent,
      default_source: lifecycle[:default_source],
      default_overridden: lifecycle[:default_overridden] == true,
      last_evaluated_at: last_evaluated_at
    }

    archive_readiness =
      archive_readiness(flag, lifecycle_branch, freshness,
        now: Keyword.get(opts, :now, DateTime.utc_now()),
        secondary_limit: Keyword.get(opts, :secondary_limit, @default_secondary_limit)
      )

    %{
      state: freshness.state,
      mode: mode,
      owner: owner_label(ownership, flag[:owner]),
      owner_ref: ownership[:owner_ref],
      owner_kind: ownership[:owner_kind],
      owner_display: ownership[:owner_display],
      ownership: ownership,
      expected_expiration: expected_expiration,
      permanent: permanent,
      review_by: lifecycle[:review_by] || expected_expiration,
      default_source: lifecycle[:default_source],
      default_overridden: lifecycle[:default_overridden] == true,
      suggestion: suggestion,
      last_evaluated_at: last_evaluated_at,
      lifecycle: lifecycle_branch,
      freshness: freshness,
      archive_readiness: archive_readiness
    }
  end

  defp freshness(flag, flag_environment, opts) do
    state = state(flag, flag_environment, opts)
    evaluation = evaluation_freshness(flag_environment, state)
    code_references = code_reference_freshness(flag, opts)

    %{
      state: state,
      evaluation: evaluation,
      code_references: code_references,
      last_evaluated_at: flag_environment[:last_evaluated_at],
      code_refs_scan: scan_summary(Keyword.get(opts, :code_refs_scan))
    }
  end

  defp state(flag, flag_environment, opts) do
    if not is_nil(flag[:archived_at]) or flag_environment[:status] == :archived do
      :archived
    else
      state_from_freshness(flag_environment, opts)
    end
  end

  defp state_from_freshness(%{last_evaluated_at: nil}, _opts), do: :potentially_stale

  defp state_from_freshness(
         %{last_evaluated_at: %DateTime{} = last_evaluated_at} = flag_environment,
         opts
       ) do
    now = Keyword.fetch!(opts, :now)
    stale_after_seconds = Keyword.fetch!(opts, :stale_after_seconds)
    warning_after_seconds = Keyword.fetch!(opts, :warning_after_seconds)

    last_published_at = flag_environment[:last_published_at] || last_evaluated_at
    variants_served = flag_environment[:variants_served] || %{}

    eval_age_seconds = DateTime.diff(now, last_evaluated_at, :second)
    pub_age_seconds = DateTime.diff(now, last_published_at, :second)
    served_one_variant? = map_size(variants_served) <= 1

    terminal_stale? = pub_age_seconds >= stale_after_seconds and served_one_variant?
    terminal_warning? = pub_age_seconds >= warning_after_seconds and served_one_variant?

    cond do
      eval_age_seconds >= stale_after_seconds -> :stale
      terminal_stale? -> :stale
      eval_age_seconds >= warning_after_seconds -> :potentially_stale
      terminal_warning? -> :potentially_stale
      true -> :active
    end
  end

  defp evaluation_freshness(_flag_environment, :archived), do: :not_applicable
  defp evaluation_freshness(%{last_evaluated_at: nil}, _state), do: :never_evaluated
  defp evaluation_freshness(_flag_environment, :potentially_stale), do: :recently_evaluated
  defp evaluation_freshness(_flag_environment, :active), do: :recently_evaluated
  defp evaluation_freshness(_flag_environment, _state), do: :not_evaluated_recently

  defp code_reference_freshness(flag, opts) do
    reference_count = Keyword.get(opts, :code_reference_count)
    scan = scan_summary(Keyword.get(opts, :code_refs_scan))
    now = Keyword.fetch!(opts, :now)
    stale_after_seconds = Keyword.fetch!(opts, :stale_after_seconds)

    cond do
      reference_count_present?(reference_count) and reference_count > 0 ->
        :refs_present

      reference_count_present?(reference_count) and reference_count == 0 and
          fresh_scan?(scan, now, stale_after_seconds) ->
        :fresh_refs_absent

      stale_scan?(scan, now, stale_after_seconds) ->
        :scan_stale

      is_nil(scan) and archived?(flag) ->
        :not_applicable

      true ->
        :scan_unknown
    end
  end

  defp archive_readiness(flag, lifecycle, freshness, opts) do
    positive_reasons = positive_reasons(flag, lifecycle, freshness, opts)
    blockers = blockers(flag, lifecycle, freshness)
    unknowns = unknowns(freshness)
    evidence_quality = evidence_quality(positive_reasons, blockers, unknowns)
    readiness = readiness(flag, positive_reasons, blockers, unknowns, evidence_quality)
    primary_action = recommended_next_action(readiness, blockers, unknowns, evidence_quality)

    %{
      readiness: readiness,
      evidence_quality: evidence_quality,
      reasons: positive_reasons,
      unknowns: unknowns,
      blockers: blockers,
      recommended_next_action: primary_action,
      secondary_actions:
        secondary_actions(primary_action, blockers, unknowns)
        |> Enum.take(Keyword.fetch!(opts, :secondary_limit))
    }
  end

  defp positive_reasons(flag, lifecycle, freshness, opts) do
    now = Keyword.fetch!(opts, :now)
    review_by = lifecycle.review_by

    []
    |> maybe_add_reason(lifecycle.mode == :expiring, :expiring_posture)
    |> maybe_add_reason(review_due?(review_by, now), :review_horizon_passed)
    |> maybe_add_reason(freshness.evaluation == :not_evaluated_recently, :stale_evaluation)
    |> maybe_add_reason(freshness.evaluation == :never_evaluated, :never_evaluated)
    |> maybe_add_reason(freshness.code_references == :fresh_refs_absent, :no_code_refs)
    |> maybe_add_reason(archived?(flag), :already_archived)
  end

  defp blockers(flag, lifecycle, freshness) do
    []
    |> maybe_add_reason(protected_flag_type?(flag[:flag_type]), :protected_flag_type)
    |> maybe_add_reason(lifecycle.mode == :permanent, :permanent_posture)
    |> maybe_add_reason(flag[:flag_type] == :remote_config, :remote_config_requires_review)
    |> maybe_add_reason(freshness.code_references == :refs_present, :code_refs_present)
    |> maybe_add_reason(archived?(flag), :already_archived)
  end

  defp unknowns(freshness) do
    []
    |> maybe_add_reason(freshness.code_references == :scan_unknown, :code_refs_scan_missing)
    |> maybe_add_reason(freshness.code_references == :scan_stale, :code_refs_scan_stale)
    |> maybe_add_reason(freshness.evaluation == :never_evaluated, :evaluation_missing)
  end

  defp evidence_quality(reasons, blockers, unknowns) do
    cond do
      Enum.any?(unknowns, &(&1 in [:code_refs_scan_missing, :code_refs_scan_stale])) -> :weak
      reasons != [] and blockers == [] and unknowns == [] -> :strong
      reasons != [] and length(unknowns) <= 1 -> :partial
      blockers != [] and reasons != [] -> :partial
      true -> :weak
    end
  end

  defp readiness(flag, reasons, blockers, unknowns, evidence_quality) do
    cond do
      archived?(flag) -> :keep_active
      blockers != [] -> :keep_active
      evidence_quality == :strong and archive_candidate_reasons?(reasons) -> :archive_candidate
      unknowns != [] -> :needs_review
      evidence_quality == :partial and archive_positive?(reasons) -> :needs_review
      true -> :needs_review
    end
  end

  defp recommended_next_action(:archive_candidate, _blockers, _unknowns, :strong),
    do: :archive_ready

  defp recommended_next_action(:keep_active, _blockers, _unknowns, _quality), do: :keep_active
  defp recommended_next_action(_readiness, _blockers, _unknowns, :weak), do: nil
  defp recommended_next_action(_readiness, _blockers, _unknowns, _quality), do: :review_manually

  defp secondary_actions(primary_action, blockers, unknowns) do
    []
    |> maybe_add_reason(:code_refs_scan_missing in unknowns, :refresh_code_refs)
    |> maybe_add_reason(:code_refs_scan_stale in unknowns, :refresh_code_refs)
    |> maybe_add_reason(:evaluation_missing in unknowns, :collect_eval_evidence)
    |> maybe_add_reason(:code_refs_present in blockers, :remove_code_refs)
    |> maybe_add_reason(:permanent_posture in blockers, :mark_permanent)
    |> Enum.reject(&(&1 == primary_action))
    |> Enum.uniq()
  end

  defp scan_summary(nil), do: nil

  defp scan_summary(%_{} = scan),
    do: scan |> Map.from_struct() |> scan_summary()

  defp scan_summary(scan) when is_map(scan) do
    %{
      received_at: Map.get(scan, :received_at) || Map.get(scan, "received_at"),
      reference_count: Map.get(scan, :reference_count) || Map.get(scan, "reference_count") || 0
    }
  end

  defp scan_summary(_scan), do: nil

  defp fresh_scan?(nil, _now, _threshold), do: false

  defp fresh_scan?(%{received_at: %DateTime{} = received_at}, now, threshold) do
    DateTime.diff(now, received_at, :second) < threshold
  end

  defp fresh_scan?(_scan, _now, _threshold), do: false

  defp stale_scan?(nil, _now, _threshold), do: false

  defp stale_scan?(%{received_at: %DateTime{} = received_at}, now, threshold) do
    DateTime.diff(now, received_at, :second) >= threshold
  end

  defp stale_scan?(_scan, _now, _threshold), do: false

  defp protected_flag_type?(flag_type), do: flag_type in @protected_flag_types

  defp review_due?(nil, _now), do: false

  defp review_due?(%Date{} = review_by, %DateTime{} = now),
    do: Date.compare(review_by, DateTime.to_date(now)) != :gt

  defp review_due?(_review_by, _now), do: false

  defp archive_positive?(reasons) do
    Enum.any?(
      reasons,
      &(&1 in [:review_horizon_passed, :stale_evaluation, :no_code_refs, :never_evaluated])
    )
  end

  defp archive_candidate_reasons?(reasons) do
    :no_code_refs in reasons and
      Enum.any?(reasons, &(&1 in [:review_horizon_passed, :stale_evaluation, :never_evaluated]))
  end

  defp maybe_add_reason(list, true, reason), do: list ++ [reason]
  defp maybe_add_reason(list, false, _reason), do: list

  defp reference_count_present?(value), do: is_integer(value) and value >= 0
  defp archived?(flag), do: not is_nil(flag[:archived_at])

  defp stale_after_seconds(opts),
    do: Keyword.get(opts, :stale_after_seconds, @default_stale_after_seconds)

  defp warning_after_seconds(opts),
    do: Keyword.get(opts, :warning_after_seconds, div(stale_after_seconds(opts), 2))

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp normalize_nested_map(nil), do: %{}

  defp normalize_nested_map(%_{} = struct),
    do: struct |> Map.from_struct() |> normalize_nested_map()

  defp normalize_nested_map(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {normalize_key(key), value} end)

  defp normalize_nested_map(_value), do: %{}

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp owner_label(ownership, owner) do
    ownership[:owner_display] || ownership[:owner_ref] || owner
  end
end
