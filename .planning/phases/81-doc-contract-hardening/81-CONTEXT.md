# Phase 81: Doc Contract Hardening - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close optional v1.11 audit hardening gaps: extend the intro doc contract test to guard `evaluation.md` Runtime strings (DOC-01 regression guard beyond grep), and backfill Phase 76 Nyquist validation artifact (`76-VALIDATION.md`).

**In scope:**
- New test in `intro_integration_spine_contract_test.exs` asserting `evaluation.md` Runtime API strings
- `76-VALIDATION.md` with Nyquist-compliant per-task verification map (2 tasks from 76-01)
- `mix verify.phase76` green including new contract assertions

**Out of scope:**
- Guide or README edits (`evaluation.md` content already correct from Phase 77)
- `verify.phase76.ex` union changes (test file already listed)
- Anchor re-fixes (Phase 79)
- `76-VERIFICATION.md` / `77-VERIFICATION.md` rewrites (Phase 80)
- `v1.11-MILESTONE-AUDIT.md` gap table updates (optional hygiene; not in ROADMAP success criteria)

**Proof spine (unchanged):** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

</domain>

<decisions>
## Implementation Decisions

### Contract test extension (DOC-01)
- **D-01:** Extend **`rulestead/test/rulestead/intro_integration_spine_contract_test.exs`** — same module Phase 78 established; no new test file, no `release_contract_test.exs` changes.
- **D-02:** Add `@evaluation_path` module attribute pointing to `guides/flows/evaluation.md` (same path-expand pattern as spine/hub paths).
- **D-03:** New test (name along lines of `"evaluation.md documents Runtime keyed lookup APIs (DOC-01)"`) asserts grep-stable strings from `77-01-PLAN.md` verify block:
  - `Rulestead.Runtime.enabled?/3`
  - `Rulestead.Runtime.evaluate/3`
  - `Rulestead.evaluate/3` (payload-first Core Calls contract preserved)
- **D-04:** Do **not** edit `verify.phase76.ex` — file already in `@phase76_core_tests` union; extending the test module auto-includes new assertions in merge gate.

### 76-VALIDATION.md backfill
- **D-05:** Create `.planning/phases/76-phoenix-integration-spine-doc/76-VALIDATION.md` mirroring 77/79 VALIDATION shape (frontmatter, Test Infrastructure, Sampling Rate, Per-Task Verification Map, Validation Sign-Off).
- **D-06:** Map **2 tasks only** from `76-01-PLAN.md`:
  - **76-01-01** (INT-01, INT-02): grep spine content — `test -f guides/introduction/phoenix-integration-spine.md && grep -q 'Rulestead.Runtime' guides/introduction/phoenix-integration-spine.md && grep -q 'owner_ref' guides/introduction/phoenix-integration-spine.md && grep -q 'expected_expiration' guides/introduction/phoenix-integration-spine.md`
  - **76-01-02** (INT-03): hub cross-links — `grep -q 'phoenix-integration-spine' guides/introduction/getting-started.md guides/introduction/installation.md README.md`
- **D-07:** All task rows marked `✅ done`; frontmatter `status: complete`, `nyquist_compliant: true`; sign-off dated 2026-05-28 (Phase 81 backfill — tasks shipped in Phase 76).
- **D-08:** Quick run command: spine existence grep; full suite: `cd rulestead && mix verify.phase76`.

### Execution shape
- **D-09:** Single plan **81-01**, two tasks: (1) contract test extension, (2) `76-VALIDATION.md` creation.
- **D-10:** Plan verification runs `cd rulestead && mix verify.phase76` and confirms new contract test passes.

### Claude's Discretion
- Exact test name string in contract module
- Whether to add optional assertion for Runtime subsection heading (`### Runtime keyed lookup`)
- Payload-first narrative ordering guard (77-VALIDATION lists as manual-only — likely skip automated position check)
- Minor 77-VERIFICATION.md DOC-01 deferral note cleanup (not in ROADMAP success criteria)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and audit context
- `.planning/ROADMAP.md` — Phase 81 goal and success criteria
- `.planning/milestones/v1.11-REQUIREMENTS.md` — DOC-01 traceability
- `.planning/milestones/v1.11-MILESTONE-AUDIT.md` — optional hardening items #3 (evaluation.md contract guard) and #4 (76-VALIDATION.md)

### Prior phase deferrals (now in scope)
- `.planning/phases/80-phase-76-77-verification-backfill/80-CONTEXT.md` — D-08 DOC-01 guard deferred to Phase 81; D-19 76-VALIDATION deferred
- `.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-VERIFICATION.md` — DOC-01 grep proof + deferral note
- `.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-01-PLAN.md` — authoritative Runtime string verify block

### Contract test and verify patterns
- `rulestead/test/rulestead/intro_integration_spine_contract_test.exs` — existing 4-test module to extend
- `rulestead/lib/mix/tasks/verify.phase76.ex` — merge gate union (read-only; no edits expected)
- `.planning/phases/78-doc-contract-guards-and-milestone-closure/78-CONTEXT.md` — D-01 established dedicated intro contract test module

### VALIDATION.md templates
- `.planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-VALIDATION.md` — docs-only phase backfill pattern
- `.planning/phases/79-lifecycle-deep-link-anchor-fix/79-VALIDATION.md` — contract-test phase pattern

### Phase 76 source tasks
- `.planning/phases/76-phoenix-integration-spine-doc/76-01-PLAN.md` — 2 tasks with verify commands
- `.planning/phases/76-phoenix-integration-spine-doc/76-01-SUMMARY.md` — shipped deliverables
- `.planning/phases/76-phoenix-integration-spine-doc/76-VERIFICATION.md` — existing verification (Phase 80)

### Doc under guard
- `guides/flows/evaluation.md` — Runtime subsection strings to assert (read-only)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`intro_integration_spine_contract_test.exs`** — 4 tests with `@*_path` module attributes and `File.read!/1` + `=~` pattern; add `@evaluation_path` and fifth test following same shape
- **Phase 79 anchor test** — precedent for targeted regression test in same module (`getting-started deep-links spine section 6...`)
- **77-VALIDATION.md / 79-VALIDATION.md** — frontmatter + per-task table + sign-off template for 76-VALIDATION backfill

### Established Patterns
- **Doc contract guards in dedicated test module** — Phase 78 D-01; keeps `release_contract_test.exs` from growing
- **verify.phase76 flat union** — single test file entry covers all tests in module; no per-test registration
- **Nyquist backfill for shipped phases** — Phase 80 refreshed 77-VALIDATION without re-running work; Phase 81 same for 76

### Integration Points
- Edit: `rulestead/test/rulestead/intro_integration_spine_contract_test.exs` (add test + path attribute)
- Write: `.planning/phases/76-phoenix-integration-spine-doc/76-VALIDATION.md` (new)
- Read-only proof: `guides/flows/evaluation.md`, `mix verify.phase76`
- Do not edit: guides, `verify.phase76.ex`, planning VERIFICATION files (unless optional deferral note cleanup)

</code_context>

<specifics>
## Specific Ideas

- Close v1.11 audit optional hardening: "evaluation.md Runtime subsection not in intro contract test union" and "Phase 76 missing VALIDATION.md".
- Contract assertions must match `77-01-PLAN.md` verify block exactly — same strings Phase 80 grep-proved manually.

</specifics>

<deferred>
## Deferred Ideas

- **`v1.11-MILESTONE-AUDIT.md` gap table update** — optional post-Phase-81 hygiene; not in ROADMAP success criteria
- **Automated payload-first narrative ordering guard** — 77-VALIDATION manual-only; low ROI for contract test
- **77-VERIFICATION deferral note cleanup** — nice-to-have after guard ships; not blocking

</deferred>

---

*Phase: 81-doc-contract-hardening*
*Context gathered: 2026-05-28*
