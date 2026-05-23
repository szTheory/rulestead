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
      owner: "growth"
    }

    assert %Ecto.Changeset{valid?: true} =
             Flag.changeset(%Flag{}, Map.put(valid_base, :expected_expiration, ~D[2026-05-01]))

    assert %Ecto.Changeset{valid?: true} =
             Flag.changeset(%Flag{}, Map.put(valid_base, :permanent, true))

    missing_mode =
      Flag.changeset(%Flag{}, Map.put(valid_base, :owner, "   "))

    refute missing_mode.valid?
    assert "can't be blank" in errors_on(missing_mode).owner
    assert "must be true when expected expiration is blank" in errors_on(missing_mode).permanent
    assert "must be set when permanent is false" in errors_on(missing_mode).expected_expiration

    contradictory =
      Flag.changeset(
        %Flag{},
        Map.merge(valid_base, %{expected_expiration: ~D[2026-05-01], permanent: true})
      )

    refute contradictory.valid?
    assert "must be false when expected expiration is set" in errors_on(contradictory).permanent
    assert "must be blank when permanent is true" in errors_on(contradictory).expected_expiration
  end

  test "lifecycle classifier derives active, potentially stale, stale, and archived from persisted data" do
    now = DateTime.from_naive!(~N[2026-04-23 14:00:00], "Etc/UTC")
    flag = %{owner: "growth", permanent: true, expected_expiration: nil}

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
      owner: "legacy-owner",
      permanent: true,
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
      owner: "growth",
      ownership: %{owner_ref: "team:growth", owner_kind: :team},
      lifecycle: %{
        mode: :expiring,
        default_source: :flag_type,
        default_overridden: false,
        review_by: ~D[2026-06-01]
      },
      expected_expiration: ~D[2026-05-01],
      permanent: false
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
