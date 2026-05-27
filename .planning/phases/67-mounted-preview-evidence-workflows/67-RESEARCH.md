# Phase 67: Mounted Preview Evidence Workflows — Research

**Researched:** 2026-05-27
**Phase:** 67 — Mounted Preview Evidence Workflows
**Confidence:** HIGH

## Summary

Phase 67 is a **presentation + mounted-test** phase. Core already returns `ImpactPreview` v2 with `sample_evidence`, `impression_evidence`, `uncertainty`, and `preview_basis` through `Rulestead.preview_audience_impact/3`. Admin preview LiveViews already call that API; the gap is entirely in `AudienceComponents.impact_preview/1` and mounted ExUnit coverage.

**Primary recommendation:** Extend the single `impact_preview/1` render site (D-01), mirror `Rulestead.Fake.PreviewEvidenceResolver` setup from `audience_mutation_audit_test.exs`, and add four plans matching CONTEXT D-06 — no LiveView refactors beyond tests.

## Phase Requirements

| ID | Description | Research support |
|----|-------------|------------------|
| ADM-05 | Mounted edit/archive/delete preview resolve, render, fail-closed on host evidence | Component + tests; core path proven in Phases 65–66 |

## Standard Stack

### Core (unchanged this phase)

| Component | Location | Role |
|-----------|----------|------|
| `Rulestead.preview_audience_impact/3` | `rulestead/lib/rulestead.ex` | Preview API for all three LiveViews |
| `ImpactPreview.build/1` | `rulestead/lib/rulestead/targeting/impact_preview.ex` | v2 map with evidence + uncertainty |
| `PreviewEvidence` behaviour | `rulestead/lib/rulestead/targeting/preview_evidence.ex` | Host resolver seam |
| `Fake.PreviewEvidenceResolver` | `rulestead/lib/rulestead/fake/preview_evidence_resolver.ex` | Test resolver (samples + impression_summary) |

### Admin (change surface)

| Component | Location | Role |
|-----------|----------|------|
| `AudienceComponents.impact_preview/1` | `rulestead_admin/lib/rulestead_admin/components/audience_components.ex` | **Only UI code change** |
| `EditPreview` / `ArchivePreview` / `DeletePreview` | `rulestead_admin/lib/rulestead_admin/live/audience_live/*.ex` | Already call core; verify-only |
| Confirm LiveViews | `edit_confirm.ex`, `archive_confirm.ex` | Fingerprint query contract — test-only |

## Architecture Patterns

### Pattern 1: Single render site (Phase 63 precedent)

Extend existing mounted surfaces; no new routes. All three preview LiveViews render `<AudienceComponents.impact_preview preview={@preview} />`.

### Pattern 2: Resolver via Application env (Phase 65)

```elixir
Application.put_env(:rulestead, :preview_evidence_resolver, Rulestead.Fake.PreviewEvidenceResolver)
```

Restore on `on_exit` in each test describe that needs evidence. Unconfigured → `authored_state_and_explicit_samples` only (no sample/impression sections).

### Pattern 3: Uncertainty from core, not hardcoded admin copy

`ImpactPreview` sets:

| `preview_basis` | `uncertainty.message` (core) |
|-----------------|------------------------------|
| `authored_state_and_explicit_samples` | "authored-state and explicit-sample preview only" |
| `authored_state_with_host_evidence` | "authored state with bounded host-supplied evidence; not an authoritative population count" |
| `authored_state_host_evidence_unavailable` | "authored-state preview; host evidence unavailable or denied" |

Admin must render `@preview.uncertainty[:message]` (atom keys on LiveView assigns) and humanize basis strings for display labels.

### Pattern 4: Bounded display

- Core cap: `@max_sample_rows 25` in `PreviewEvidence.Limits`
- Admin display: show first **10** rows, then "+N more" if `length(samples) > 10`
- Impression: `window_label`, counts, optional `variant_breakdown` as simple list (variant + count)

## Evidence Field Shapes (from Fake resolver + ImpactPreview)

**Sample row (allowlist):** `actor_key`, `targeting_key`, `matched?`, `reason`

**Impression summary:** `window_label`, `sampled_impressions`, `matched_impressions`, optional `variant_breakdown` → `[%{variant: ..., count: ...}]` after normalization

## Don't Hand-Roll

| Problem | Use instead |
|---------|-------------|
| Admin-side resolver calls | `Rulestead.preview_audience_impact/3` only |
| Custom uncertainty strings | `preview.uncertainty[:message]` from core |
| Fleet/population language | Bounded sample/impression copy per CONTEXT D-05 |
| Full sample table when >10 rows | "+N more" truncation |

## Common Pitfalls

### Pitfall 1: Hardcoded uncertainty paragraph

**What goes wrong:** UI shows explicit-samples-only wording when host evidence is present.

**How to avoid:** Replace lines 70–72 in `audience_components.ex` with dynamic `uncertainty[:message]`.

### Pitfall 2: Missing atom vs string keys

**What goes wrong:** `Map.get(@preview, "uncertainty")` fails on LiveView assigns.

**How to avoid:** Use `fetch_preview/2` helper accepting atom or string keys (match existing `scope_key/2` style).

### Pitfall 3: Resolver leak in tests

**What goes wrong:** Flaky tests when resolver env bleeds between async tests.

**How to avoid:** `async: false` on evidence describes; save/restore env in setup; `on_exit` restore.

### Pitfall 4: Observability product copy

**What goes wrong:** "Fleet", "dashboard", "population analytics" in new section headings.

**How to avoid:** Section titles: "Sample cohort", "Impression summary" only.

## Code Examples

### Test resolver setup (from core audit tests)

```elixir
previous = Application.get_env(:rulestead, :preview_evidence_resolver)
Application.put_env(:rulestead, :preview_evidence_resolver, Rulestead.Fake.PreviewEvidenceResolver)
on_exit(fn ->
  if previous, do: Application.put_env(:rulestead, :preview_evidence_resolver, previous)
  else Application.delete_env(:rulestead, :preview_evidence_resolver)
end)
```

### Expected HTML assertions (edit preview with resolver)

```elixir
assert html =~ "Sample cohort"
assert html =~ "Impression summary"
assert html =~ "last_24h"
assert html =~ "fake-vip-users"
assert html =~ "authored state with bounded host-supplied evidence"
refute html =~ "fleet"
refute html =~ "dashboard"
```

## Validation Architecture

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (rulestead_admin ConnCase + LiveViewTest) |
| Config | `rulestead_admin/test/test_helper.exs` |
| Quick run | `cd rulestead_admin && mix test test/rulestead_admin/components/audience_components_test.exs` |
| Full phase | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs test/rulestead_admin/live/audience_live/archive_preview_test.exs test/rulestead_admin/live/audience_live/delete_preview_test.exs` |
| Estimated runtime | ~15–30s |

### Per-plan sampling

| Plan | After task commit | After wave |
|------|-------------------|------------|
| 67-01 | `mix test .../audience_components_test.exs` | same |
| 67-02 | edit + archive preview tests | both files |
| 67-03 | delete + governance preview tests | both files |
| 67-04 | full audience_live preview test glob | full file list in 67-04 |

### Critical paths (manual spot-check optional)

- Prod governance preview still shows blast-radius panel without impression-weighted scoring language
- Delete preview retains unsupported callout while showing evidence when resolver on

## Open Questions

None blocking — CONTEXT D-06 locks four-plan shape; display cap (10 rows) and variant_breakdown as inline list are planner discretion within plans.

## Sources

### Canonical (HIGH confidence)

- `.planning/phases/67-mounted-preview-evidence-workflows/67-CONTEXT.md`
- `rulestead_admin/lib/rulestead_admin/components/audience_components.ex`
- `rulestead/lib/rulestead/targeting/impact_preview.ex`
- `rulestead/test/rulestead/audience_mutation_audit_test.exs`

### Prior phases (HIGH confidence)

- Phases 65–66 CONTEXT + VERIFICATION — core/audit evidence carry-through complete

---

## RESEARCH COMPLETE
