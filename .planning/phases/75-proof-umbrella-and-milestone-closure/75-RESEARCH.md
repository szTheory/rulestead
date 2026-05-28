# Phase 75: Proof Umbrella And Milestone Closure — Research

**Researched:** 2026-05-28
**Status:** Complete

## Question

What do we need to know to plan Phase 75 (VER-01, VER-02, DOC-02, AUD-01, AUD-02) well?

## Findings

### VER-01 — `mix verify.phase73` flat union

**Pattern (locked):** Each phase verify task is a **flat union** of test paths — never delegates to older `verify.phaseNN` tasks (avoids duplicate runs). Phase 72 established the post-GA band union in `verify.phase72.ex` (~31 core paths + admin subprocess).

**v1.10.1 delta:** Phases 73–74 added contract coverage **inside files already in the phase72 union** (`release_contract_test.exs`, `post_ga_band_contract_test.exs`) plus **one net-new path**:

- `test/rulestead/context_test.exs` — CTX-01 traits→attributes promotion (not in `@phase72_core_tests`)

**Implementation:** New `Mix.Tasks.Verify.Phase73` copies `@phase72_core_tests` verbatim and appends `test/rulestead/context_test.exs`. Do **not** add `mix verify.phase74` (explicitly deferred in Phase 74 CONTEXT D-14).

**Registration:** Add `{:"verify.phase73", :test}` to `rulestead/mix.exs` `preferred_envs` (alongside phase72).

### VER-02 — `mix verify.adopter` delegate

**Current:** `verify.adopter.ex` delegates to `verify.phase72` with moduledoc citing v1.10 band.

**Target:** Delegate to `verify.phase73`; update `@moduledoc` / `@shortdoc` to v1.10.1 support-truth without duplicating test lists.

**CI alignment:** `scripts/ci/test.sh` `run_post_ga_band_closure` invokes `mix verify.phase72` directly — must switch to `verify.phase73` so CI proof spine matches adopter entrypoint.

### DOC-02 — Maintainer proof matrix and path-to-done

**Stale surfaces (pre-75):**

| File | Drift |
|------|-------|
| `MAINTAINING.md` | Post-GA section + proof matrix cite `mix verify.phase72` as current bar |
| `README.md` / `rulestead/README.md` | Post-GA bullet lists phase72 |
| `release_contract_test.exs` | `"post-GA band closure support truth"` block asserts `mix verify.phase72` in root README + MAINTAINING |
| `.planning/threads/2026-05-28-path-to-done-milestones.md` | Milestone 1 exit criteria still open wording |
| `guides/introduction/product-boundary.md` | Band closure gate cites phase72 |

**Required:** Bump primary adopter/band commands to **phase73** everywhere the **current** merge gate is named (keep historical phase68/72 entries in milestone history sections where they document shipped versions).

**Do not:** Remove phase72 task file — prior milestones remain reproducible.

### AUD-01 — Close investigations in STATE.md

| ID | Evidence to cite |
|----|------------------|
| INV-API-01 | Phase 74: bidirectional `release_contract_test.exs` guards + reconciled `guides/api_stability.md` |
| INV-MAINT-01 | Phase 73: MAINTAINING "Public surface contract (live)" + maintainer doc truth test |
| INV-CTX-01 | Phase 73: `context_test.exs` + quickstart guards (already closed in thread; confirm in STATE) |

**Proof commands for STATE table:**

- `cd rulestead && mix verify.phase73`
- `cd rulestead && mix test test/rulestead/release_contract_test.exs`
- `cd rulestead && mix test test/rulestead/context_test.exs`

### AUD-02 — `v1.10.1-MILESTONE-AUDIT.md`

Follow `v1.10.0-MILESTONE-AUDIT.md` frontmatter shape (`milestone`, `audited`, `status`, `scores`, `gaps`). Status: **`support_truth_complete`** (or `band_complete` variant — use distinct label from v1.10.0 to show patch milestone).

**Trust spine (post-75):**

- `mix verify.phase73` / `mix verify.adopter`
- `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- `scripts/demo/proof.sh`
- Phase evidence: `.planning/phases/73-*/73-VERIFICATION.md`, `74-*/74-VERIFICATION.md`, `75-*/75-VERIFICATION.md`

### Out of scope (confirmed)

- No new product APIs
- No `mix verify.phase74`
- No api_stability catalog edits (Phase 74 done)
- v1.11 integration spine (INV-INTRO-01) — separate milestone

## Validation Architecture

| Layer | Command | When |
|-------|---------|------|
| Unit (v1.10.1 guard) | `cd rulestead && mix test test/rulestead/context_test.exs` | After 75-01 |
| Contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | After 75-02 |
| Merge gate | `cd rulestead && mix verify.phase73` | After 75-01 |
| Adopter smoke | `cd rulestead && mix verify.adopter` | Phase exit |
| CI band | `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh` | Before milestone sign-off |

Sampling: run phase73 after 75-01; release_contract after 75-02 doc string updates; full adopter + CI before AUD-02.

## Recommended plan shape

| Plan | Wave | Requirements | Delivers |
|------|------|--------------|----------|
| 75-01 | 1 | VER-01, VER-02 | `verify.phase73.ex`, adopter delegate, `mix.exs` alias, CI `post_ga_band_closure` runner |
| 75-02 | 2 | DOC-02 | Doc/proof-matrix phase73 strings; release_contract post-GA block; path-to-done thread |
| 75-03 | 3 | AUD-01, AUD-02 | STATE investigations closed; `v1.10.1-MILESTONE-AUDIT.md`; phase VERIFICATION.md |

## RESEARCH COMPLETE
