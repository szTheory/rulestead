defmodule RulesteadAdmin.Components.GovernanceComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Components.GovernanceComponents

  @base_assessment %{
    operation: "update",
    reference_count: 5,
    preview_fingerprint: "audprev_frozen123",
    authoritative_population_count?: false,
    breach_reasons: [
      %{
        code: "blast_radius_above_threshold",
        observed: 5,
        limit: 2,
        remediation: "Submit a change request for governed approval."
      }
    ]
  }

  test "above_threshold verdict shows governance required copy" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{verdict: :above_threshold})
      )

    assert html =~ "Governance required"
    assert html =~ "Exceeds direct-apply limit (update limit: 2, found: 5 references)."
  end

  test "below_threshold verdict shows direct apply allowed copy" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{verdict: :below_threshold, reference_count: 1, breach_reasons: []})
      )

    assert html =~ "Direct apply allowed"
    refute html =~ "Exceeds direct-apply limit"
  end

  test "indeterminate verdict shows cannot evaluate safely copy" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{
          verdict: :indeterminate,
          breach_reasons: [
            %{
              code: "blast_radius_indeterminate",
              observed: "dependency_blockers",
              limit: "clear_dependency_blockers",
              remediation: "Re-run preview after resolving dependency visibility."
            }
          ]
        })
      )

    assert html =~ "Cannot evaluate safely"
    refute html =~ "Governance required"
  end

  test "panel does not leak audience predicate or conditions fields" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{
          verdict: :above_threshold,
          audience_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
          predicate: "segment_match(vip)"
        })
      )

    refute html =~ "conditions"
    refute html =~ "predicate"
    refute html =~ "segment_match"
  end

  test "redacted visibility omits reference keys from breach observed maps" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{
          verdict: :indeterminate,
          breach_reasons: [
            %{
              code: "blast_radius_indeterminate",
              observed: %{reference_keys: ["flag-a", "flag-b"]},
              limit: 0,
              remediation: "Resolve visibility."
            }
          ]
        }),
        visibility: :redacted
      )

    refute html =~ "flag-a"
    refute html =~ "flag-b"
    assert html =~ "2 references (keys hidden by permissions)"
  end

  test "frozen panel shows submission evidence copy" do
    html =
      render_blast_radius_panel(
        Map.merge(@base_assessment, %{verdict: :above_threshold}),
        frozen?: true
      )

    assert html =~ "Evidence frozen at submission"
    assert html =~ "audprev_frozen123"
  end

  defp render_blast_radius_panel(assessment, opts \\ []) do
    assigns = [assessment: assessment, frozen?: Keyword.get(opts, :frozen?, false), visibility: Keyword.get(opts, :visibility, :full)]

    render_component(&GovernanceComponents.blast_radius_panel/1, assigns)
  end
end
