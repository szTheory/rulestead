# Phase 73: Context And Maintainer Doc Truth — Research

**Researched:** 2026-05-28
**Status:** Complete

## Question

What do we need to know to plan Phase 73 (CTX-01, CTX-02, DOC-01) well?

## Findings

### CTX-01 — Context traits promotion (largely landed)

`Rulestead.Context.new/1` already implements `promote_traits_to_attributes/1`:

- Reads `:traits` or `"traits"`, normalizes to a map, merges with `:attributes` via `Map.merge(from_traits, from_attributes)` so **attributes win**.
- Strips `:traits` / `"traits"` from attrs before struct build — no `traits` field on `%Rulestead.Context{}`.
- `context_test.exs` has traits-only and conflict-resolution tests.

**Gap:** Plan 73-01 should **verify green** and treat any uncommitted diff as the deliverable (fold, do not re-implement).

### CTX-02 — Quickstart honesty (largely landed)

- Root `README.md` and `guides/introduction/getting-started.md` use `attributes:` (no `traits: %{` in quickstart paths).
- `release_contract_test.exs` already has `"quickstart Context.new examples use attributes not traits for evaluation inputs"` asserting `attributes:` and refuting `traits: %{` in both docs.

**Gap:** None for quickstart guard if working tree lands. Do **not** extend guard to admin simulate `traits` form field or telemetry `%{traits: ...}` fixtures (per D-06).

### DOC-01 — MAINTAINING truth (primary remaining work)

`MAINTAINING.md` still contains **"## Deferred Phase 8 artifacts"** listing `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md` as "do not create early" — all three files **ship today**. This is the active INV-MAINT-01 leak.

Working tree added **Post-GA Band Closure Proof** and **Proof Matrix** but did **not** remove the Phase 8 deferral block.

**Required:**

1. Delete entire "Deferred Phase 8 artifacts" section (D-09).
2. Add **"Public surface contract (live)"** section listing live guides + note Phase 74 owns catalog completeness (D-10).
3. Add `release_contract_test.exs` **maintainer doc truth** block (D-08):
   - `refute maintaining =~ "Deferred Phase 8"` or equivalent
   - `refute maintaining =~ ~r/Do not create these early/`
   - `assert maintaining =~ "api_stability.md"` as live contract language
   - `refute maintaining =~ ~r/Phase 8, not bootstrap/` for api_stability

### Out of scope (confirmed)

- No edits to `guides/api_stability.md` catalog (API-01, Phase 74).
- No `mix verify.phase73` (Phase 75).
- No `product-boundary.md` Runtime semver posture (Phase 74).

## Validation Architecture

| Layer | Command | When |
|-------|---------|------|
| Unit | `cd rulestead && mix test test/rulestead/context_test.exs` | After 73-01 |
| Contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | After 73-02 |
| Adopter bar (unchanged) | `cd rulestead && mix verify.adopter` | Phase exit smoke |

Sampling: run context tests after 73-01; full release_contract after 73-02. No new verify.phase task in this phase.

## Recommended plan shape

| Plan | Wave | Delivers |
|------|------|----------|
| 73-01 | 1 | Land/fold CTX-01 + confirm CTX-02 quickstart guard green |
| 73-02 | 2 | DOC-01 MAINTAINING rewrite + maintainer doc truth release_contract block |

## RESEARCH COMPLETE
