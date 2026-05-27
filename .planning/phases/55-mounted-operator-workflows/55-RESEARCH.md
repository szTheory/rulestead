# Phase 55 — Research: Mounted Operator Workflows

**Researched:** 2026-05-27  
**Phase:** 55 — Mounted Operator Workflows  
**Confidence:** HIGH (core contracts from Phases 53–54; admin patterns from Phases 46–54)

---

## Summary

Phase 55 mounts bounded operator workflows in `rulestead_admin` that **render core truth** from Phases 53–54 without duplicating validation or touching the runtime hot path. The implementation extends existing LiveView patterns (`FlagLive.CleanupPreview/Confirm`, `EnvironmentCompareLive`, `Session` scope helpers) with dedicated `/audiences` routes (registered before `/:key`), route-backed preview → confirm → audit for audience mutations, policy-aware dependency tables, flag explain/simulate/rules audience traces, and compare dependency findings presentation.

**Primary recommendation:** Ship four vertical plans (ADM-01 → ADM-04) with Wave 1 audience foundation, parallel Wave 2 mutation + flag surfaces, Wave 3 compare/verify/handoff. Treat substantial in-tree WIP as the starting scaffold — plans focus on UI-SPEC copy alignment, missing LiveView tests, `mix verify.phase55` admin coverage, and Phase 54 handoff boundary assertions.

---

## Standard Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Admin UI | Phoenix LiveView ~> 1.0 in `rulestead_admin` | Existing mountable admin; no new framework |
| Core APIs | `Rulestead.list_audiences/1`, `list_audience_dependencies/1`, `preview_audience_impact/3`, `apply_audience_mutation/1`, `explain_flag/2`, `simulate_flag/2` | Presentation-only boundary (D-03) |
| Policy | `Rulestead.Admin.Policy` + `Rulestead.Admin.DependencyVisibility` | Per-flag `:read_flags` before showing dependency rows (D-08–D-09) |
| Components | `AudienceComponents`, `AudienceTraceComponents`, `OperatorComponents`, `FlagComponents` | UI-SPEC inventory; `rs-*` + `data-tone` |
| Tests | `RulesteadAdmin.ConnCase` + `Rulestead.Fake.Control` | Same merge-gate pattern as Phases 46–54 |

**Do not use:** Repo access from LiveView, local fingerprint recomputation, modal-only mutations, graph visualizers, bulk automation, manifest wizards (deferred).

---

## Architecture Patterns

### Route-backed preview → confirm (mirror flag cleanup)

```
/audiences/:key/edit/preview  → Rulestead.preview_audience_impact(key, :update, ...)
/audiences/:key/edit/confirm  → requires preview_fingerprint + preview_schema_version query params
/audiences/:key/archive/preview|confirm → operation :archive
/audiences/:key/delete/preview → fail-closed copy only (no apply CTA)
```

Reference: `RulesteadAdmin.Live.FlagLive.CleanupPreview`, `CleanupConfirm`.

### Policy-aware dependency display

```
list_audience_dependencies(actor, audience_key, env, tenant)
  → core inventory + visibility_resolver(actor)
  → entries | redacted_entries | hidden_reference_count
```

`Rulestead.Admin.DependencyVisibility.visibility_resolver/1` gates `:read_flags` per referenced flag. Redacted rows use `Hidden reference` — never leak flag keys (D-09).

### Explain / simulate audience traces

Structured `audience_trace` on rule traces (from evaluation/explain payloads). Mounted UI uses `AudienceTraceComponents.audience_trace_steps/1`; CLI parity via optional `Rulestead.Explainer` sentences (D-13).

### Compare dependency findings (preview-only)

`compare.dependency_findings` rendered on `EnvironmentCompareLive` index/show with links to `/audiences/:key` and flag routes. No Apply/Publish on compare (D-16). Manifest slice = core APIs + compare UI + Phase 56 verify (D-15).

---

## Don't Hand-Roll

| Problem | Use instead | Reason |
|---------|-------------|--------|
| Dependency validation in LiveView | Core `DependencyValidator` + `apply_audience_mutation` | Authoritative fail-closed (54-HANDOFF) |
| Preview fingerprint signing | Core `preview_audience_impact` (`audprev_*`) | Stale-token rejection (D-06–D-07) |
| Trait/session PII in URLs | Allowed query keys only: `env`, `tenant`, `targeting_key`, `session_id`, `request_id` | UI-SPEC + security brief |
| Custom pagination framework | Offset for v1.6.0 fixture sizes; keyset later | CONTEXT discretion |

---

## Common Pitfalls

### Phase 55 pitfalls (from `.planning/research/PITFALLS.md`)

1. **Policy bypass on used-by tables** — Always route through `list_audience_dependencies` with `visibility_resolver`; never render raw store projection in LiveView.
2. **Bulk/automation shortcuts** — No one-click multi-audience mutations; preview → confirm → audit only.
3. **Tenant scope collapse** — Every row shows `environment_key` + `tenant_key`; URL state via `Session`.
4. **Compare Apply/Publish** — Tests already forbid; preserve preview-only handoff.
5. **Core/admin boundary drift** — No `rulestead_admin` imports in `rulestead` release contract.

---

## Codebase State (2026-05-27)

| Area | Status | Gap |
|------|--------|-----|
| Router `/audiences/*`, `/:key/explain` | Present | Assert order before `/:key` in router_test |
| `AudienceLive.*` (8 modules) | Present | UI-SPEC copy drift on index empty state, edit preview kickers |
| `AudienceComponents` | Present | Rollout indicators on detail (ADM-01) may need lifecycle hints from inventory |
| `FlagLive.Explain` | Present | Permalink + trace tests exist; align copy to UI-SPEC |
| `EnvironmentCompareLive` dependency_findings | Present | Show_test may need audience link assertions |
| `mix verify.phase55` | Core tests only | Must add `rulestead_admin` LiveView suite paths |
| `55-HANDOFF-CHECKLIST.md` | Missing | Create in plan 04 for Phase 56 |

---

## Validation Architecture

### Test infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit (both packages) |
| Admin quick | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live test/rulestead_admin/live/flag_live/explain_test.exs` |
| Core quick | `cd rulestead && mix test test/rulestead/admin/dependency_visibility_test.exs` |
| Phase gate | `cd rulestead && mix verify.phase55` (extend to admin paths in 55-04) |
| Full admin | `cd rulestead_admin && mix test` |

### Per-requirement proof strategy

| REQ | Automated proof |
|-----|-----------------|
| ADM-01 | LiveView tests: list, detail, hidden references, scope columns |
| ADM-02 | LiveView tests: preview fingerprint in confirm URL, drift redirect, archive apply, delete fail-closed |
| ADM-03 | explain_test, rules_test audience picker, simulate trace section |
| ADM-04 | environment_compare_live index/show tests, no Apply/Publish regression |

### Manual-only

- Host CSS mapping for new `rs-*` classes (host-owned styling)
- Visual 60/30/10 spot-check against UI-SPEC (optional; copy/a11y covered by tests)

---

## Phase Split Recommendation

**No split required.** Four plans map 1:1 to ADM-01–ADM-04 with ~4 waves total context — within executor budget when leveraging existing WIP.

---

## RESEARCH COMPLETE

**Phase directory:** `.planning/phases/55-mounted-operator-workflows/`  
**Ready for planning:** Yes
