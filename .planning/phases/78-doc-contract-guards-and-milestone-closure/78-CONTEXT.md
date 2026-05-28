# Phase 78: Doc Contract Guards And Milestone Closure - Context

**Gathered:** 2026-05-28 (assumptions mode — Phases 76–77 deferrals + ROADMAP)
**Status:** Ready for planning

<domain>
## Phase Boundary

Guard the v1.11 integration spine with release-contract tests, extend the adopter verify entrypoint to `mix verify.phase76`, close **INV-INTRO-01** in `STATE.md`, and record **v1.11** milestone audit evidence — **no new product APIs**, no further doc authoring (Phases 76–77 shipped the spine and alignment).

**In scope:** VER-01, VER-02, AUD-01, AUD-02.

**Out of scope:** New spine or evaluation doc edits; admin/runtime `lib/` changes; `mix verify.phase74`; removing `verify.phase73.ex` (historical reproducibility).

</domain>

<decisions>
## Implementation Decisions

### Intro spine contract guards (VER-01)
- **D-01:** Add **`test/rulestead/intro_integration_spine_contract_test.exs`** as the v1.11 doc contract module (keeps `release_contract_test.exs` from growing further; still satisfies "or dedicated doc contract test").
- **D-02:** Contract asserts **file presence** and **grep-stable strings** for:
  - `guides/introduction/phoenix-integration-spine.md` — `Rulestead.Runtime`, `Rulestead.Plug`, `owner_ref`, `expected_expiration`, `flag-lifecycle`
  - `guides/introduction/getting-started.md` — spine link + `owner_ref` + `expected_expiration`
  - `guides/introduction/installation.md` — spine link + lifecycle fields
  - Root `README.md` — `phoenix-integration-spine` link
- **D-03:** Optionally add one **`release_contract_test.exs`** test block `"v1.11 integration spine support truth"` that asserts `mix verify.phase76` appears in root README + MAINTAINING (doc matrix — pairs with 78-02); intro file guards stay in dedicated test.

### Proof umbrella — `mix verify.phase76` (VER-02)
- **D-04:** Add `Mix.Tasks.Verify.Phase76` as **flat union**: copy `@phase73_core_tests` from `verify.phase73.ex` **verbatim**, append **`test/rulestead/intro_integration_spine_contract_test.exs`**.
- **D-05:** `run/1` calls `Mix.Task.run("test", @phase76_core_tests)` then same admin subprocess as phase73 — **never** `Mix.Task.run("verify.phase73", _)`.
- **D-06:** Register `{:"verify.phase76", :test}` in `rulestead/mix.exs` `preferred_envs`. **Do not** remove or edit `verify.phase73.ex`.

### Adopter entrypoint and CI spine (VER-02)
- **D-07:** `Mix.Tasks.Verify.Adopter` delegates only to `verify.phase76`; update `@moduledoc` / `@shortdoc` for **v1.11 integration spine**.
- **D-08:** `scripts/ci/test.sh` — `run_post_ga_band_closure` and `print_post_ga_band_closure_failure_guidance` use `mix verify.phase76`.
- **D-09:** Leave `scripts/demo/proof.sh` on `mix verify.adopter` (inherits delegate).

### Maintainer and adopter doc proof matrix (bundled in 78-02)
- **D-10:** Bump **current** merge-gate command from `mix verify.phase73` → `mix verify.phase76` in live surfaces:
  - `MAINTAINING.md` (Post-GA / proof matrix)
  - root `README.md` and `rulestead/README.md` (post-GA bullets)
  - `guides/introduction/product-boundary.md`
  - `release_contract_test.exs` post-GA band closure test
  - `.planning/threads/2026-05-28-path-to-done-milestones.md` (v1.11 exit)
  - `.planning/ROADMAP.md` active milestone proof spine
- **D-11:** Keep `mix verify.phase73` in **historical** milestone sections (v1.10.1 shipped narrative).
- **D-12:** Document `mix verify.adopter` as integrator alias (delegates to phase76).

### Investigation and milestone closure (AUD-01, AUD-02)
- **D-13:** Run green proof **before** editing `STATE.md`:
  - `cd rulestead && mix verify.phase76`
  - `cd rulestead && mix test test/rulestead/intro_integration_spine_contract_test.exs`
- **D-14:** Close **INV-INTRO-01** in `STATE.md` with proof pointers (`mix verify.phase76`, intro contract test path, spine doc path).
- **D-15:** Publish `.planning/v1.11-MILESTONE-AUDIT.md` mirroring `v1.10.1-MILESTONE-AUDIT.md` shape; status label **`integration_spine_complete`**.
- **D-16:** Trust spine: `mix verify.phase76`, `mix verify.adopter`, `intro_integration_spine_contract_test.exs`, `phoenix-integration-spine.md`, phase 76–78 verification artifacts.
- **D-17:** Write `78-VERIFICATION.md`; tick VER-01, VER-02, AUD-01, AUD-02 in `.planning/REQUIREMENTS.md`; update `PROJECT.md` / `ROADMAP.md` phase 78 status.

### Execution shape
- **D-18:** Three-wave plan (matches Phase 75):
  - **78-01** — intro contract test + `verify.phase76.ex` + adopter + `mix.exs` + CI (VER-01, VER-02 core)
  - **78-02** — doc proof matrix + `release_contract_test.exs` phase76 strings (VER-02 doc half)
  - **78-03** — STATE closure, v1.11 audit, REQUIREMENTS tick (AUD-01, AUD-02); depends on 78-01 + 78-02

### Claude's Discretion
- Exact `release_contract_test` test name for v1.11 block
- Whether `ROADMAP.md` marks Phase 78 complete in 78-03 only
- `v1.11-MILESTONE-AUDIT.md` scores table detail

</decisions>

<canonical_refs>
## Canonical References

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 78 goal and proof spine
- `.planning/REQUIREMENTS.md` — VER-01, VER-02, AUD-01, AUD-02
- `.planning/STATE.md` — INV-INTRO-01 closure target
- `.planning/phases/76-phoenix-integration-spine-doc/76-01-SUMMARY.md`
- `.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-01-SUMMARY.md`

### Verify task patterns
- `rulestead/lib/mix/tasks/verify.phase73.ex` — union source to copy verbatim
- `rulestead/lib/mix/tasks/verify.adopter.ex`
- `rulestead/mix.exs` — `preferred_envs`
- `.planning/phases/75-proof-umbrella-and-milestone-closure/75-01-PLAN.md` — phase73 pattern

### Docs under guard
- `guides/introduction/phoenix-integration-spine.md`
- `guides/introduction/getting-started.md`
- `guides/introduction/installation.md`
- `README.md`

### Audit templates
- `.planning/v1.10.1-MILESTONE-AUDIT.md`
- `.planning/phases/75-proof-umbrella-and-milestone-closure/75-03-PLAN.md`

</canonical_refs>

<deferred>
## Deferred Ideas

- Further intro doc expansion — out of v1.11 scope
- `mix verify.phase77` — not used; phase76 is v1.11 gate name per ROADMAP

</deferred>

---

*Phase: 78-doc-contract-guards-and-milestone-closure*
*Context gathered: 2026-05-28*
