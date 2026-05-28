# Phase 75: Proof Umbrella And Milestone Closure - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the adopter verify entrypoint to cover v1.10.1 support-truth guards, align maintainer/docs proof matrix with the new gate, close open investigations in `STATE.md`, and record v1.10.1 milestone audit evidence — **no new product APIs**.

**In scope:** VER-01, VER-02, DOC-02, AUD-01, AUD-02 — `mix verify.phase73`, adopter delegate, doc/proof-matrix strings, investigation closure, `v1.10.1-MILESTONE-AUDIT.md`.

**Out of scope:** New product APIs; `mix verify.phase74`; re-editing `guides/api_stability.md` catalog (Phase 74 done); removing `verify.phase72.ex`; v1.11 integration spine (INV-INTRO-01).

</domain>

<decisions>
## Implementation Decisions

### Proof umbrella — `mix verify.phase73` (VER-01)
- **D-01:** Add `Mix.Tasks.Verify.Phase73` as a **flat union**: copy `@phase72_core_tests` and `@admin_test_paths` from `verify.phase72.ex` **verbatim**, append **one** core path: `test/rulestead/context_test.exs`.
- **D-02:** `run/1` calls `Mix.Task.run("test", @phase73_core_tests)` then the same admin subprocess as phase72 — **never** `Mix.Task.run("verify.phase72", _)`.
- **D-03:** Register `{:"verify.phase73", :test}` in `rulestead/mix.exs` `preferred_envs`. **Do not** remove or edit `verify.phase72.ex` (v1.10.0 reproducibility).

### Adopter entrypoint and CI spine (VER-02)
- **D-04:** `Mix.Tasks.Verify.Adopter` delegates only to `verify.phase73`; update `@moduledoc` / `@shortdoc` for v1.10.1 support-truth.
- **D-05:** `scripts/ci/test.sh` — `run_post_ga_band_closure` and `print_post_ga_band_closure_failure_guidance` remediation use `mix verify.phase73`.
- **D-06:** Leave `scripts/demo/proof.sh` on `mix verify.adopter` (inherits delegate; no change required if already adopter-only).

### Maintainer and adopter doc proof matrix (DOC-02)
- **D-07:** Bump **current** merge-gate command from `mix verify.phase72` → `mix verify.phase73` in live adopter/maintainer surfaces:
  - `MAINTAINING.md` (Post-GA section + proof matrix)
  - root `README.md` and `rulestead/README.md` (post-GA bullets)
  - `guides/introduction/product-boundary.md` (band closure gate)
  - `rulestead/test/rulestead/release_contract_test.exs` post-GA band closure block
  - `.planning/threads/2026-05-28-path-to-done-milestones.md` (v1.10.1 exit criteria)
- **D-08:** Keep `mix verify.phase72` in **historical** milestone/archive sections (v1.10.0 shipped narrative). Optionally add proof-matrix row: phase72 = historical v1.10.0 gate, superseded by phase73 for v1.10.1+.
- **D-09:** Keep `mix verify.adopter` documented as integrator alias (delegates to phase73).

### Investigation closure (AUD-01)
- **D-10:** Run green proof **before** editing `STATE.md`:
  - `cd rulestead && mix verify.phase73`
  - `cd rulestead && mix test test/rulestead/release_contract_test.exs`
  - `cd rulestead && mix test test/rulestead/context_test.exs`
- **D-11:** Close investigations with proof pointers:

| ID | Status | Proof |
|----|--------|-------|
| INV-API-01 | Closed | Phase 74 catalog sync + `release_contract_test.exs`; adopter gate `mix verify.phase73` |
| INV-MAINT-01 | Closed | Phase 73 MAINTAINING live contract + maintainer doc truth test in `release_contract_test.exs` |
| INV-CTX-01 | Closed | Phase 73 `context_test.exs` + quickstart guards |

- **D-12:** Update `STATE.md` accumulated context and operator next steps: current adopter bar is `mix verify.phase73` / `mix verify.adopter` (replace phase72 wording). Mark v1.10.1 complete in `PROJECT.md` where still in-flight.

### Milestone audit (AUD-02)
- **D-13:** Publish `.planning/v1.10.1-MILESTONE-AUDIT.md` mirroring `v1.10.0-MILESTONE-AUDIT.md` frontmatter shape (`milestone`, `audited`, `status`, `scores`, `gaps`).
- **D-14:** Milestone status label: **`support_truth_complete`** (distinct from v1.10.0 `band_complete`).
- **D-15:** Trust spine lists: `mix verify.phase73`, `mix verify.adopter`, `RULESTEAD_TEST_SCOPE=post_ga_band_closure`, `scripts/demo/proof.sh`, `release_contract_test.exs`, `context_test.exs`, phase 73–75 verification artifacts.
- **D-16:** Write `75-VERIFICATION.md`; tick VER-01, VER-02, DOC-02, AUD-01, AUD-02 in `.planning/REQUIREMENTS.md`.

### Execution shape
- **D-17:** Three-wave plan (matches existing plans):
  - **75-01** — `verify.phase73.ex`, adopter delegate, `mix.exs`, CI `post_ga_band_closure` (VER-01, VER-02)
  - **75-02** — doc matrix + `release_contract_test.exs` asserts (DOC-02); depends on 75-01
  - **75-03** — STATE closure, milestone audit, REQUIREMENTS tick (AUD-01, AUD-02); depends on 75-01 + 75-02

### Claude's Discretion
- Exact wording of historical phase72 proof-matrix row
- `v1.10.1-MILESTONE-AUDIT.md` scores table detail (as long as trust spine and phase evidence paths are correct)
- Whether `rulestead/README.md` needs extra context beyond post-GA bullet bump

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 75 goal and success criteria
- `.planning/REQUIREMENTS.md` — VER-01, VER-02, DOC-02, AUD-01, AUD-02
- `.planning/STATE.md` — INV-API-01, INV-MAINT-01, INV-CTX-01 (closure targets)
- `.planning/MILESTONE-ARC.md` — v1.10.1 support-truth rationale
- `.planning/phases/75-proof-umbrella-and-milestone-closure/75-RESEARCH.md` — implementation research

### Prior phase context
- `.planning/phases/73-context-and-maintainer-doc-truth/73-CONTEXT.md` — CTX/DOC boundaries; deferred verify.phase73
- `.planning/phases/74-api-stability-catalog-sync/74-CONTEXT.md` — catalog sync; deferred STATE INV-API-01 closure

### Verify task patterns
- `rulestead/lib/mix/tasks/verify.phase72.ex` — union source to copy verbatim
- `rulestead/lib/mix/tasks/verify.adopter.ex` — delegate target to retarget
- `rulestead/mix.exs` — `preferred_envs` registration
- `prompts/rulestead-release-engineering-and-ci.md` — per-phase flat-union verify discipline

### Proof and contracts
- `rulestead/test/rulestead/context_test.exs` — v1.10.1 net-new verify path
- `rulestead/test/rulestead/release_contract_test.exs` — post-GA band closure doc asserts
- `scripts/ci/test.sh` — `post_ga_band_closure` scope
- `scripts/demo/proof.sh` — adopter smoke entrypoint

### Doc surfaces (DOC-02)
- `MAINTAINING.md` — proof matrix
- `README.md`, `rulestead/README.md` — post-GA bullets
- `guides/introduction/product-boundary.md` — band closure gate
- `.planning/threads/2026-05-28-path-to-done-milestones.md` — path-to-done exit criteria

### Audit templates
- `.planning/milestones/v1.10.0-MILESTONE-AUDIT.md` — frontmatter and trust-spine shape
- `.planning/phases/73-context-and-maintainer-doc-truth/73-VERIFICATION.md` — phase evidence (when present)
- `.planning/phases/74-api-stability-catalog-sync/74-VERIFICATION.md` — phase evidence (when present)

### Engineering DNA
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — scripts-first CI, per-phase verify tasks
- `prompts/rulestead-testing-and-e2e-strategy.md` — contract test discipline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `verify.phase72.ex` — complete `@phase72_core_tests` (31 paths) + `@admin_test_paths` (14 paths) to copy verbatim
- `context_test.exs` — traits→attributes promotion tests; only v1.10.1 net-new path outside phase72 union
- `verify.adopter.ex` — thin delegate; change one `Mix.Task.run` target + moduledoc
- `release_contract_test.exs` — post-GA band closure block asserts phase72 strings (update to phase73 in 75-02)

### Established Patterns
- Per-phase verify tasks are **flat unions** — never delegate to older `verify.phaseNN` (Phases 64, 68, 72, 74 CONTEXT)
- Adopter alias (`mix verify.adopter`) tracks latest phase verify for integrators
- Support-truth phases bump proof-matrix strings + release-contract asserts together (Phases 72, 73, 74)
- `scripts/demo/proof.sh` calls `mix verify.adopter` — inherits delegate without edit

### Integration Points
- CI: `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- Merge gate: `cd rulestead && mix verify.phase73` then `mix verify.adopter`
- Milestone sign-off: STATE investigations + `v1.10.1-MILESTONE-AUDIT.md` + REQUIREMENTS tick

### Pre-implementation state
- `verify.phase73.ex` does not exist yet; `mix.exs` has no `verify.phase73` preferred_env
- Live docs and `release_contract_test.exs` still cite `mix verify.phase72` as current bar

</code_context>

<specifics>
## Specific Ideas

- User confirmed all assumptions without correction — proceed with existing 75-01/02/03 plan wave shape.
- phase73 is strict superset of phase72: one additional test file only.
- Do not remove phase72 task — prior milestone reproducibility.

</specifics>

<deferred>
## Deferred Ideas

- **`mix verify.phase74`** — explicitly out of scope (Phase 74 CONTEXT D-14)
- **api_stability catalog edits** — Phase 74 complete
- **v1.11 integration spine (Plug, supervision, lifecycle)** — separate milestone (INV-INTRO-01)
- **generate-from-contract tooling** — deferred from Phase 74

None — analysis stayed within phase scope aside from explicit deferrals above.

</deferred>

---

*Phase: 75-proof-umbrella-and-milestone-closure*
*Context gathered: 2026-05-28*
