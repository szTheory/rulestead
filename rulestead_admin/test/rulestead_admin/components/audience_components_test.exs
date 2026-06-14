defmodule RulesteadAdmin.Components.AudienceComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias RulesteadAdmin.Components.AudienceComponents

  @full_preview %{
    preview_basis: "authored_state_with_host_evidence",
    preview_fingerprint: "audprev_test123",
    environment_scope: %{environment_key: "test"},
    tenant_scope: %{tenant_key: "tenant-a"},
    affected_references: [%{reference_key: "flag:example:ruleset:1:rule:vip"}],
    uncertainty: %{
      message:
        "authored state with bounded host-supplied evidence; not an authoritative population count",
      authoritative_population_count?: false
    },
    sample_evidence: [
      %{
        actor_key: "actor-1",
        targeting_key: "t-1",
        matched?: true,
        reason: "segment_match"
      }
    ],
    impression_evidence: %{
      window_label: "last_24h",
      sampled_impressions: 100,
      matched_impressions: 12,
      variant_breakdown: [
        %{variant: "control", count: 8},
        %{"variant" => "treatment", "count" => 4}
      ]
    }
  }

  test "renders sample cohort, impression summary, basis, and uncertainty from core" do
    html = render_impact_preview(@full_preview)

    assert html =~ "Sample cohort"
    assert html =~ "Impression summary"
    assert html =~ "Preview uncertainty"
    assert html =~ "Authored state with host-supplied evidence"
    assert html =~ "bounded host-supplied evidence"
    assert html =~ "actor-1"
    assert html =~ "last_24h"
    assert html =~ "control"
    refute html =~ "fleet"
    refute html =~ "dashboard"
  end

  test "omits sample and impression sections when evidence empty" do
    preview =
      Map.merge(@full_preview, %{
        sample_evidence: [],
        impression_evidence: %{},
        preview_basis: "authored_state_and_explicit_samples"
      })

    html = render_impact_preview(preview)

    refute html =~ "Sample cohort"
    refute html =~ "Impression summary"
    assert html =~ "Authored state and explicit samples"
    assert html =~ "No explicit sample evidence supplied"
    assert html =~ "No impression evidence supplied"
  end

  test "shows +N more when sample list exceeds display limit" do
    samples =
      for i <- 1..11 do
        %{actor_key: "actor-#{i}", targeting_key: "t-#{i}", matched?: true, reason: "ok"}
      end

    html = render_impact_preview(Map.put(@full_preview, :sample_evidence, samples))

    assert html =~ "actor-1"
    assert html =~ "actor-10"
    refute html =~ "actor-11"
    assert html =~ "+1 more"
  end

  test "humanizes host evidence unavailable basis" do
    html =
      render_impact_preview(
        Map.merge(@full_preview, %{
          preview_basis: "authored_state_host_evidence_unavailable",
          uncertainty: %{
            message: "authored-state preview; host evidence unavailable or denied",
            authoritative_population_count?: false
          }
        })
      )

    assert html =~ "Authored state (host evidence unavailable)"
    assert html =~ "host evidence unavailable or denied"
  end

  test "used-by table exposes hidden and denied dependency states" do
    hidden_html =
      render_used_by_table(%{
        summary: "Audience is used by production flags.",
        denied?: false,
        hidden_count: 2,
        entries: [],
        redacted_entries: [%{visibility: %{reason: "policy_denied"}}]
      })

    assert hidden_html =~ "Hidden references"
    assert hidden_html =~ "At least 2 references are hidden by your permissions."
    assert hidden_html =~ "policy denied"

    denied_html =
      render_used_by_table(%{
        summary: "Audience dependencies are policy scoped.",
        denied?: true,
        hidden_count: 0,
        entries: [],
        redacted_entries: []
      })

    assert denied_html =~ "Dependency visibility denied"
    assert denied_html =~ "you do not have permission"
  end

  defp render_impact_preview(preview) do
    render_component(&AudienceComponents.impact_preview/1, preview: preview)
  end

  defp render_used_by_table(dependencies) do
    render_component(&AudienceComponents.used_by_table/1,
      dependencies: dependencies,
      mount_path: "/admin/flags",
      environment_key: "test",
      tenant_key: "tenant-a"
    )
  end
end
