# Phase 65: Host Preview Evidence Contract — Research

**Researched:** 2026-05-27
**Status:** Complete (plan-phase inline research; CONTEXT assumptions mode)

## Summary

Phase 65 adds an opt-in host resolver seam for bounded sample cohorts and impression summaries on audience impact previews. The codebase already has schema v1 `ImpactPreview` with explicit `command.samples`, `preview_basis`, redacted `sample_evidence`, and fingerprint tokens that hash `sample_fingerprint` only. Store adapters (`Fake`, `Ecto`) build previews in `audience_preview_payload/4` then gate apply via `ensure_fresh_audience_preview/2` and `ImpactPreview.schema_version()`.

The implementation mirrors `Rulestead.Guardrails.Provider` + `Rulestead.Guardrails` config resolution. Resolver I/O stays at the store boundary; `ImpactPreview` remains pure. GOV-05 blast-radius scoring must not consume impression or cohort evidence.

## Key Findings

### Existing seam template
- `Rulestead.Guardrails.Provider` — `@callback fetch_signal/1`, flexible return shapes
- `Rulestead.Guardrails` — `Application.get_env(:rulestead, :guardrails_provider)` + `Keyword.get(opts, :provider)`
- Contract tests use `Application.put_env/3` in setup/on_exit

### Integration point (both adapters identical today)
- `audience_preview_payload/4` calls `ImpactPreview.build/1` with `samples: Map.get(command, :samples, [])` only
- No resolver hook exists; `preview_basis` passes through from command when set
- `ensure_fresh_audience_preview/2` compares `command.preview_fingerprint` to `current_preview.preview_fingerprint`

### ImpactPreview v1 gaps for IMP-05/06
- `@schema_version 1` — must bump to **2** for apply gate
- Fingerprint token lacks `impression_fingerprint`
- No `impression_evidence` on built preview
- Single default basis `authored_state_and_explicit_samples`
- `BlastRadiusThreshold.assess/2` already ignores samples/impressions (reference keys only) — no scoring change needed

### Command structs
- `Command.PreviewAudienceImpact` and `Command.ApplyAudienceMutation` already carry `samples`, `preview_basis`
- Apply requires `preview_schema_version == ImpactPreview.schema_version()` in facade + store

### Test patterns
- `audience_impact_contract_test.exs` — `@adapters [Rulestead.Fake, StoreEcto]`
- `impact_preview_test.exs` — fingerprint/redaction unit tests
- Guardrails tests demonstrate env-based provider stub pattern

## Recommended Module Layout

| Module | Responsibility |
|--------|----------------|
| `Rulestead.Targeting.PreviewEvidence` | Behaviour `@callback resolve/1` |
| `Rulestead.Targeting.PreviewEvidence` (facade functions) | `resolve/2`, `resolver_module/1` |
| `Rulestead.Targeting.PreviewEvidence.Limits` | Merge, cap 25, 16 KiB bound, allowlists, fail-closed errors |
| `Rulestead.Targeting.PreviewEvidence.Query` | Normalize query map from store context |
| `Rulestead.Fake.PreviewEvidenceResolver` (or inline in Fake) | Test double for contract tests |

Config key: `:preview_evidence_resolver` (parallel `:guardrails_provider`).

## Risk Notes

- **Fingerprint drift:** Any host evidence change must alter `preview_fingerprint`; extend token before `ImpactPreview.build/1` final fingerprint call.
- **PII:** Reuse `Rulestead.Admin.Redaction` + dedicated impression allowlist; never log raw resolver blobs.
- **Error types:** Use existing `%Rulestead.Error{type: :invalid_command}` with stable finding codes — no new public `:type` without `api_stability.md` update.
- **Opt-in:** `resolver_module/1` returning `nil` must preserve pre-v1.9 preview semantics.

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17+) |
| Config | `rulestead/test/test_helper.exs`, `Rulestead.RepoCase` |
| Quick run | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` |
| Contract run | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/targeting/preview_evidence_contract_test.exs` |
| Full phase slice | `cd rulestead && mix test test/rulestead/targeting/ test/rulestead/store/audience_impact_contract_test.exs` |
| Estimated runtime | ~30–90 seconds |

### Automated coverage map

| Behavior | Test type | Command |
|----------|-----------|---------|
| Resolver opt-in / missing | unit + contract | `mix test test/rulestead/targeting/preview_evidence_test.exs` |
| Limits fail-closed | unit | same |
| ImpactPreview v2 fingerprint | unit | `mix test test/rulestead/targeting/impact_preview_test.exs` |
| Fake/Ecto parity | contract | `mix test test/rulestead/store/audience_impact_contract_test.exs` |
| Stale evidence bypass | contract | `preview_evidence_contract_test.exs` |
| GOV unchanged | unit | `mix test test/rulestead/governance/blast_radius_threshold_test.exs` |

### Wave 0

Existing infrastructure covers phase requirements. No new framework install. Add `preview_evidence_contract_test.exs` in plan 65-04.

## RESEARCH COMPLETE
