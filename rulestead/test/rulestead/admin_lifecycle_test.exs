defmodule Rulestead.AdminLifecycleTest do
  use ExUnit.Case, async: true

  alias Rulestead.Admin.{Lifecycle, LifecycleDefaults}
  alias Rulestead.{Flag, FlagEnvironment}

  test "flag changeset requires owner and exactly one lifecycle mode" do
    valid_base = %{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "growth", owner_kind: :team},
      lifecycle: %{mode: :expiring, review_by: ~D[2026-05-01], default_source: :flag_type, default_overridden: false}
    }

    assert %Ecto.Changeset{valid?: true} =
             Flag.changeset(%Flag{}, valid_base)

    missing_mode =
      Flag.changeset(%Flag{}, %{valid_base | ownership: %{owner_ref: "   ", owner_kind: :team}})

    refute missing_mode.valid?
    assert "can't be blank" in errors_on(missing_mode).ownership.owner_ref

    contradictory =
      Flag.changeset(
        %Flag{},
        %{
          valid_base
          | lifecycle: %{mode: :expiring, review_by: nil, default_source: :flag_type, default_overridden: false}
        }
      )

    refute contradictory.valid?
    assert "reviewed expiring flags must set an expected expiration" in errors_on(contradictory).lifecycle.review_by
  end

  test "lifecycle classifier derives active, potentially stale, stale, and archived from persisted data" do
    now = DateTime.from_naive!(~N[2026-04-23 14:00:00], "Etc/UTC")
    flag = %{
      ownership: %{owner_ref: "growth", owner_kind: :team},
      lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false}
    }

    assert %{state: :active, mode: :permanent} =
             Lifecycle.classify(flag, %{status: :active, last_evaluated_at: DateTime.add(now, -900, :second)},
               now: now,
               warning_after_seconds: 1_800,
               stale_after_seconds: 3_600
             )

    assert %{state: :potentially_stale} =
             Lifecycle.classify(flag, %{status: :active, last_evaluated_at: DateTime.add(now, -2_400, :second)},
               now: now,
               warning_after_seconds: 1_800,
               stale_after_seconds: 3_600
             )

    assert %{state: :stale} =
             Lifecycle.classify(flag, %{status: :active, last_evaluated_at: DateTime.add(now, -7_200, :second)},
               now: now,
               warning_after_seconds: 1_800,
               stale_after_seconds: 3_600
             )

    assert %{state: :potentially_stale} =
             Lifecycle.classify(flag, %{status: :active, last_evaluated_at: nil}, now: now)

    assert %{state: :archived} =
             Lifecycle.classify(Map.put(flag, :archived_at, now), %{status: :active, last_evaluated_at: now},
               now: now
             )

    assert %{state: :archived} =
             Lifecycle.classify(flag, %{status: :archived, last_evaluated_at: now}, now: now)
  end

  test "lifecycle classifier separates authored posture freshness and archive readiness guidance" do
    now = ~U[2026-04-23 16:00:00Z]

    result =
      Lifecycle.classify(
        %{
          ownership: %{owner_ref: "growth", owner_kind: :team},
          flag_type: :release,
          lifecycle: %{mode: :expiring, review_by: ~D[2026-04-20]}
        },
        %{status: :active, last_evaluated_at: DateTime.add(now, -7_200, :second)},
        now: now,
        warning_after_seconds: 1_800,
        stale_after_seconds: 3_600,
        code_reference_count: 0,
        code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
      )

    assert result.state == :stale
    assert result.lifecycle.mode == :expiring
    assert result.lifecycle.review_by == ~D[2026-04-20]
    assert result.freshness.state == :stale
    assert result.freshness.evaluation == :not_evaluated_recently
    assert result.freshness.code_references == :fresh_refs_absent
    assert result.archive_readiness.readiness == :archive_candidate
    assert result.archive_readiness.evidence_quality == :strong
    assert :no_code_refs in result.archive_readiness.reasons
    assert :stale_evaluation in result.archive_readiness.reasons
    assert result.archive_readiness.recommended_next_action == :archive_ready
  end

  test "protected and permanent flags resist archive candidate guidance without explicit retirement evidence" do
    now = ~U[2026-04-23 16:00:00Z]

    result =
      Lifecycle.classify(
        %{
          ownership: %{owner_ref: "ops", owner_kind: :team},
          flag_type: :kill_switch,
          lifecycle: %{mode: :permanent}
        },
        %{status: :active, last_evaluated_at: DateTime.add(now, -7_200, :second)},
        now: now,
        warning_after_seconds: 1_800,
        stale_after_seconds: 3_600,
        code_reference_count: 0,
        code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
      )

    assert result.archive_readiness.readiness == :keep_active
    assert result.archive_readiness.evidence_quality == :partial
    assert :protected_flag_type in result.archive_readiness.blockers
    assert :permanent_posture in result.archive_readiness.blockers
    assert result.archive_readiness.recommended_next_action == :keep_active
  end

  test "missing or stale scan evidence stays uncertain and withholds a primary archive recommendation" do
    now = ~U[2026-04-23 16:00:00Z]

    result =
      Lifecycle.classify(
        %{
          ownership: %{owner_ref: "growth", owner_kind: :team},
          flag_type: :release,
          lifecycle: %{mode: :expiring, review_by: ~D[2026-04-20]}
        },
        %{status: :active, last_evaluated_at: DateTime.add(now, -7_200, :second)},
        now: now,
        warning_after_seconds: 1_800,
        stale_after_seconds: 3_600,
        code_reference_count: 0
      )

    assert result.freshness.code_references == :scan_unknown
    assert result.archive_readiness.readiness == :needs_review
    assert result.archive_readiness.evidence_quality == :weak
    assert :code_refs_scan_missing in result.archive_readiness.unknowns
    assert is_nil(result.archive_readiness.recommended_next_action)
    assert :refresh_code_refs in result.archive_readiness.secondary_actions
  end

  test "flag environment changeset persists last_evaluated_at" do
    evaluated_at = DateTime.from_naive!(~N[2026-04-23 14:00:00], "Etc/UTC")

    changeset =
      FlagEnvironment.changeset(%FlagEnvironment{}, %{
        flag_id: Ecto.UUID.generate(),
        environment_id: Ecto.UUID.generate(),
        status: :active,
        last_evaluated_at: evaluated_at
      })

    assert changeset.valid?
    assert DateTime.to_unix(get_change(changeset, :last_evaluated_at)) == DateTime.to_unix(evaluated_at)
  end

  test "flag changeset accepts authored ownership metadata and rejects blank refs or invalid kinds" do
    valid_base = %{
      key: "pricing-rollout",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{
        owner_ref: "team:pricing",
        owner_kind: :team,
        owner_display: "Pricing Team"
      },
      lifecycle: %{
        mode: :permanent,
        default_source: :flag_type,
        default_overridden: false
      }
    }

    assert %Ecto.Changeset{valid?: true} = Flag.changeset(%Flag{}, valid_base)

    blank_ref =
      Flag.changeset(%Flag{}, put_in(valid_base, [:ownership, :owner_ref], "   "))

    refute blank_ref.valid?
    assert "can't be blank" in errors_on(blank_ref).ownership.owner_ref

    invalid_kind =
      Flag.changeset(%Flag{}, put_in(valid_base, [:ownership, :owner_kind], :vendor))

    refute invalid_kind.valid?
    assert "is invalid" in errors_on(invalid_kind).ownership.owner_kind
  end

  test "flag changeset stores authored lifecycle metadata and requires explicit remote config posture" do
    base = %{
      key: "checkout-copy",
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "team:growth", owner_kind: :team},
      lifecycle: %{
        mode: :expiring,
        default_source: :flag_type,
        default_overridden: false,
        review_by: ~D[2026-06-01]
      }
    }

    assert %Ecto.Changeset{valid?: true} =
             Flag.changeset(%Flag{}, Map.put(base, :flag_type, :release))

    remote_config =
      Flag.changeset(
        %Flag{},
        Map.merge(base, %{
          flag_type: :remote_config,
          lifecycle: %{mode: nil, default_source: :operator_required, default_overridden: false}
        })
      )

    refute remote_config.valid?
    assert "must choose permanent or expected expiration for remote config" in errors_on(remote_config).lifecycle.mode
  end

  test "lifecycle defaults stay advisory and never persist computed stale or archive-ready states" do
    assert %{
             mode: :expiring,
             rationale: rationale,
             default_source: :flag_type,
             default_overridden: false
           } = LifecycleDefaults.suggest(:release)

    assert rationale =~ "release"

    assert %{
             mode: nil,
             rationale: remote_config_rationale,
             default_source: :operator_required,
             default_overridden: false
           } = LifecycleDefaults.suggest(:remote_config)

    assert remote_config_rationale =~ "explicit"

    overridden =
      LifecycleDefaults.suggest(:permission,
        authored_mode: :expiring,
        authored_review_by: ~D[2026-06-10]
      )

    assert overridden.default_overridden
    refute Map.has_key?(overridden, :state)
    refute Map.has_key?(overridden, :archive_ready)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end

  defp get_change(changeset, field), do: Ecto.Changeset.get_change(changeset, field)
end
