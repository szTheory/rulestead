# Phase 123: DX + Closeout Proof — Research

**Researched:** 2026-06-17
**Domain:** Documentation reconciliation, CI failure-triage authoring, measurement closeout, verification posture
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Create `123-CI-CD-CLOSEOUT.md` in `.planning/phases/123-dx-closeout-proof-0-plans/` (standard NNN convention). Milestone counterpart to `119-CI-CD-AUDIT.md`.
- **D-02:** Mirror the 119 audit's honesty convention (`[VERIFIED]` / `[CITED]` / `[ASSUMED]`). Field-by-field CIDX-10 ledger with one row/section per required field, each citing file+line.
- **D-03:** Cite prior-phase numbers; do NOT re-measure. Phase 121 already ran the exact locked Phase 119 commands; a fresh local re-measurement would introduce a third un-baselined sample.
- **D-04:** Oban-grade rigor for perf claims: state both endpoints + measurement corpus + factor delta + methodology/caveat line. Never a lone percentage. Frame the dominant-test result as relocation-not-deletion.
- **D-05 (honest gaps):** p95 = `unavailable from current sample` with verbatim reason from `119:109`. Cache hit rate = qualitative only (`scripts/ci/report_cache_hit.sh` emits it). Do NOT synthesize a percentage for either.
- **D-06 (rollback notes):** Per-decision, git-revert-granular rows for Phase 120/121/122 changes. Model on `119:284-309`. Call out footguns (cache key bump required; path-filter rollback can leave pending check).
- **D-07:** Canonical command ladder: fast = `cd rulestead && mix ci`; full gate = `bash scripts/ci/local.sh`; CI reruns = `mix verify.adopter` + `RULESTEAD_TEST_SCOPE=… bash scripts/ci/test.sh`. Zero behavioral change — `mix ci` already delegates to `scripts/ci/contributor.sh`.
- **D-08:** MAINTAINING.md edits are narrow: shift-left gate section (:80-106) only. Add ladder statement + triage table. Do NOT touch cache (:63-78), branch-protection (:32-61), or release runbook (:121-228).
- **D-09:** Reconcile the rerun-catalog row at `119:213` to name `cd rulestead && mix ci` (alias for `scripts/ci/contributor.sh`).
- **D-10:** Single 6-column triage table in a new `## CI Failure Triage` section of MAINTAINING.md.
- **D-11:** Lead each row with the immutable `ci.yml` job id, in `release_gate` pipeline order: `lint → test → integration-placeholder → adopter-contract → mounted-proof → openfeature-companion → publish-hex → verify-published-release → repo-hygiene`.
- **D-12:** Lift rerun commands and microcopy verbatim from `scripts/ci/test.sh` guidance functions. Use scope wrappers, not raw multi-file mix test lists.
- **D-13:** Microcopy is imperative, factual, boundary-anchored — not preachy.
- **D-14:** Add a thin anti-drift guard (extend `release_contract_test.exs` or add `scripts/check_*.py` to `lint.sh`). Planner may scope minimally or defer with recorded residual risk.
- **D-15:** Final verification runs: (1) `bash scripts/ci/lint.sh`, (2) `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs`, (3) `cd rulestead && mix verify.adopter` if any adopter-facing guide changed.
- **D-16:** Do NOT run for show: mounted/openfeature companion proofs, DB-backed product suites, demo backend. Cite as skipped-by-design.
- **D-17:** Cite as not re-runnable: `publish-hex`, `verify-published-release`, `mix verify.release_publish`, `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`, live `gh api` branch-protection writes. Mirror `122-VERIFICATION.md:89-91` honest-non-execution posture.
- **D-18:** The support-truth asserts are file-content asserts (`release_contract_test.exs:9-14`); the module passes without `ecto.create`. Run `prepare_rulestead_test_db` only if a focused run reports a DB error.
- **D-19:** Flip CIDX-08 and CIDX-10 to `Complete` in REQUIREMENTS.md (:63,65) and ROADMAP.md (:160,162). Mark Phase 123 Complete in ROADMAP phase checklist (:17) and progress table (:147).
- **D-20:** Correct STATE.md: `completed_phases: 4→5`, `percent: 80→100`, fix `stopped_at: "Phase 122 was final phase"` (:14,37). Phase 123 is the actual final phase per ROADMAP (:5,17) and dependency map (STATE.md:43-50).

### Claude's Discretion

- Exact table/section ordering inside `123-CI-CD-CLOSEOUT.md` (all seven CIDX-10 fields and evidence tags must remain present).
- Bundle or split MAINTAINING.md ladder edit, triage table, and catalog reconciliation across one or multiple plans.
- Determine the precise scope of the D-14 anti-drift guard (include minimally or defer with recorded residual risk).
- Add low-cost cross-references between `123-CI-CD-CLOSEOUT.md`, `119-CI-CD-AUDIT.md`, and `121-MEASUREMENT.md`.

### Deferred Ideas (OUT OF SCOPE)

- Fresh local re-measurement of CI timing.
- Numeric p95 or numeric cache-hit-rate (not computable from current tooling).
- Heavier anti-drift guard for the triage table (D-14 is minimal-or-defer).
- Larger runners, broad test partitioning, richer CI reports, browser-binary caching.
- Executing `publish-hex`, `verify-published-release`, `gh api` branch-protection.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CIDX-08 | Contributor commands remain simple: fast local loop, full local gate, and clear rerun commands for failed CI jobs | Command ladder fully verified in `rulestead/mix.exs:172`, `scripts/ci/contributor.sh`, `scripts/ci/local.sh`, `scripts/ci/test.sh`. MAINTAINING.md :80-106 is the edit target. Verified `mix ci` already delegates correctly. |
| CIDX-10 | Maintainer can review final before/after impact, including PR wall-clock, p95 target if available, cache hit rate, top slow tests, flake notes, residual risks, and rollback notes | All data points sourced from `119-CI-CD-AUDIT.md` and `121-MEASUREMENT.md`. The "Phase 123 Feed" section (`121-MEASUREMENT.md:222-229`) explicitly provides the before/after numbers for the closeout ledger. |
</phase_requirements>

---

## Summary

Phase 123 is a documentation, measurement-reconciliation, and verification closeout. No product runtime code, schema, workflow topology, or test-behavior changes are in scope. The phase has three primary work surfaces: (1) narrowly updating MAINTAINING.md to add a command-ladder statement and CI failure-triage table; (2) creating `123-CI-CD-CLOSEOUT.md` as the milestone counterpart to `119-CI-CD-AUDIT.md`; and (3) running the mandatory verification gates and updating traceability/STATE.

All before/after measurement data is pre-committed in `121-MEASUREMENT.md`. The Phase 123 closeout cites that ledger directly rather than re-running measurements. The key verification footgun is running only `bash scripts/ci/lint.sh` and claiming "verified" — `lint.sh` does NOT run `release_contract_test.exs`, which is the doc-drift guard that would catch any MAINTAINING.md edits that break the support-truth assertions. The planner must include the explicit `cd rulestead && mix test test/rulestead/release_contract_test.exs` step in verification.

**Primary recommendation:** Three-wave plan structure — Wave 1: closeout ledger + catalog reconciliation; Wave 2: MAINTAINING.md reconciliation (ladder + triage table + optional D-14 guard); Wave 3: verification + traceability/STATE closeout. This keeps the ledger and docs independently reviewable before the STATE flip.

---

## Citation Verification Report

This section documents whether each load-bearing CONTEXT.md citation resolves to the expected content at the cited file:line.

### 119-CI-CD-AUDIT.md Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:103-107` — critical-path wall-clock table | Representative CI run table (5m18s, 5m04s, 4m46s samples) | [VERIFIED] | Lines 102-107 | Table is at :103-107 exactly as cited. Three sample rows with run IDs, events, wall-clock, longest job. |
| `:109` — p95-unavailable line | "p95 target unavailable from current sample" + reason (mixed events/branch classes) | [VERIFIED] | Line 109 | Exact line: "The sample is enough to identify the current critical path, but not enough to claim a defensible p95…" |
| `:153-154` — locked Phase 119 commands | `mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25` commands | [VERIFIED] | Lines 153-154 | Both commands in the D-11 table with exit status, elapsed, key output. |
| `:211-224` — rerun catalog | Table of surface / exact rerun / boundary protected | [VERIFIED] | Lines 211-224 | Table is exactly at these lines. `Fast contributor loop` row cites `bash scripts/ci/contributor.sh` (not `mix ci`). |
| `:213` — catalog row naming `bash scripts/ci/contributor.sh` | Fast contributor loop row | [VERIFIED] | Line 213 | Row reads: `Fast contributor loop | \`bash scripts/ci/contributor.sh\``. D-09 reconciliation target confirmed. |
| `:249-257` — D-20 microcopy contract | 5-slot failure microcopy table | [VERIFIED] | Lines 249-257 | Table at lines 249-256, posture note at line 257. Slot columns: what failed / boundary / rerun / remediation / when to stop. |
| `:284-309` — No-Go/Rollback Guardrails | List of what Phase 119 must NOT do | [VERIFIED] | Lines 284-309 | Block starts at 284, ends at 309. Contains the applicable official/OSS notes subsection. |
| `:332-336` — Phase 123 handoff | "Turn the rerun catalog and failure microcopy into closeout docs." | [VERIFIED] | Lines 332-336 | Handoff note for Phase 123 is at lines 332-336 exactly. |

### 121-MEASUREMENT.md Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:12` — locked-command methodology reference | "Measurements use the EXACT locked Phase 119 commands from `119-CI-CD-AUDIT.md:153-154`" | [VERIFIED] | Line 12 | Exact sentence at line 12. |
| `:13` — reversible-by-design reference | `@tag :published_hex_smoke` + `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` | [VERIFIED] | Line 13 | Lines 13-15 cover the env var confirmation. `:13` is referenced by D-06 for the reversible-by-design exemplar. |
| `:136-154` — before/after table | Comparison table with wall-clock, test count, deltas, notes | [VERIFIED] | Lines 136-154 | Table at :136-148, notes at :149-154. Delta: default ~42s → ~4.6s (-37s / -88%). |
| `:154` — relocation-not-deletion statement | "The speedup is relocation (proof still runs on `guarded_rollout_foundations` scope)…" | [VERIFIED] | Line 154 | Line 154 is the delta assessment sentence with the relocation framing. |
| `:176` — FUT-01 partitioning rejection | Partitioning REJECTED, FUT-01 deferred | [VERIFIED] | Line 176 | "Deferred to FUT-01; revisit only if the suite grows materially…" |
| `:222-229` — "Phase 123 Feed" section | Summary table with Phase 123 Feed column | [VERIFIED] | Lines 222-229 | Summary table at :222-229 with `Phase 123 Feed` column providing the exact before/after numbers. |

### MAINTAINING.md Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:80-106` — shift-left gate section (edit target) | Fast loop / full gate / repo hygiene commands block | [VERIFIED] | Lines 80-106 | The `## Shift-left contributor gate` section spans lines 80-106. Contains `mix ci`, `scripts/ci/local.sh`, `--fast` flag, and repo_hygiene_check.sh. |
| `:63-78` — cache table (do NOT touch) | CI caching table with lane/key/busting-rule | [VERIFIED] | Lines 63-78 | Cache table at :64-77, header at :63. Do not edit. |
| `:32-61` — branch-protection section (do NOT touch) | Branch protection settings | [VERIFIED] | Lines 32-61 | "Branch protection settings" section at :32-61. Do not edit. |
| `:121-228` — release runbook (do NOT touch) | Release Please flow through post-publish verification handoff | [VERIFIED] | Lines 121-228 | Spans `## Release Please flow` through `## Post-publish verification handoff`. Do not edit. |

### rulestead/mix.exs Citation

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:172` — `ci:` alias | `ci: ["cmd bash ../scripts/ci/contributor.sh"]` | [VERIFIED] | Line 172 | Exact match. Inside `defp aliases do` block. |

### scripts/ci/test.sh Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:67-90` — `print_mounted_failure_guidance` function | Function body with microcopy: category, boundary, rerun command, suites list | [VERIFIED] | Lines 67-90 | Function starts at line 67, ends at line 90. Contains all five microcopy slots: category echo, boundary statement, exact rerun command `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`, suites list, remediation conditional. |

### ci.yml Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:316-325` — `release_gate.needs` job ids | `needs:` block listing `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `mounted-proof`, `openfeature-companion` | [VERIFIED] | Lines 316-325 | `release_gate:` job starts at 316; `needs:` block at 318-325 lists exactly 7 items: `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `mounted-proof`, `openfeature-companion`. |

### release_contract_test.exs Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:9-14` — doc paths (`@api_stability_path` through `@maintaining_path` etc.) | Module attributes pointing to docs under test | [VERIFIED] | Lines 8-19 | Path attributes span lines 8-19 (broader than cited; the `:9-14` window covers the six core paths including `@maintaining_path`). All are `Path.expand(…, __DIR__)` — no DB deps. |
| `:272-604` — support-truth asserts on MAINTAINING.md | File-content asserts: `maintaining =~` string matching | [VERIFIED] | Lines 272-299 start range | Test `"maintainer guidance matches the shipped release and support truth"` starts at line 272. The test range extends well past line 299; the total file is 1003 lines, so :272-604 is a fair capture of the doc-assertion block. |

### 122-VERIFICATION.md Citations

| Citation | Expected Content | Verified? | Actual Line | Notes |
|----------|-----------------|-----------|-------------|-------|
| `:89-91` — cite-as-optional / honest-non-execution precedent | Human verification section noting all behaviors have deterministic static verification; manual-optional item explicitly marked optional | [VERIFIED] | Lines 89-91 | "None. All phase behaviors have deterministic static verification. The one manual-optional item noted in VALIDATION.md (confirming artifacts appear in the GitHub Actions UI after a real failure) is explicitly marked optional…" |

**Summary:** All load-bearing CONTEXT.md citations are verified. No drift found. The planner can trust every file:line reference in CONTEXT.md D-01 through D-20.

---

## Triage Lane Inventory

### ci.yml Job IDs (Actual, from Release Gate Pipeline Order)

The `release_gate.needs` block at ci.yml:318-325 lists these job ids:

1. `changes` (path-filter detection job — not a user-visible failure lane)
2. `lint` (lines 90-130)
3. `test` (lines 131-187, matrix job)
4. `integration-placeholder` (lines 188-211, FleetDesk Playwright)
5. `adopter-contract` (lines 212-254)
6. `mounted-proof` (lines 280-315)
7. `openfeature-companion` (lines 255-279)
8. `release_gate` (lines 316-370, aggregate)

Additional lanes from separate workflows (not in `release_gate.needs`, separate workflows):
- `publish-hex` (`.github/workflows/publish-hex.yml`)
- `verify-published-release` (`.github/workflows/verify-published-release.yml`)
- `repo-hygiene` (`.github/workflows/repo-hygiene.yml` — weekly scheduled; job name: `repo-hygiene`)

**D-11 row ordering confirmed:** `lint → test → integration-placeholder → adopter-contract → mounted-proof → openfeature-companion → publish-hex → verify-published-release → repo-hygiene`. (`adopter-contract` is included as D-11 specifies; `changes` is internal bookkeeping, not a user-facing failure lane.)

Note: CONTEXT.md D-11 says `:316-325` for `release_gate.needs`; the actual `needs:` block is at lines 318-325 within the `release_gate:` job that begins at 316. Effective citation window is 316-325 (matches). [VERIFIED: .github/workflows/ci.yml]

### Microcopy Guidance Functions in scripts/ci/test.sh

The planner can lift these verbatim for the D-12 triage table:

- `print_mounted_failure_guidance` at lines 67-90 — provides: category (from `mounted_failure_category`), boundary statement, exact rerun command, suites list, setup guidance, remediation focus.
- Rerun command extracted verbatim: `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`
- `run_openfeature_companion` at lines 124-129 — the OpenFeature scope rerun command: `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh`
- Additional `print_reusable_targeting_failure_guidance` function begins at line 131+ — not in scope for Phase 123 triage lanes.

The D-12 "lift verbatim" instruction is achievable for the `mounted_admin_contract` lane. For other lanes, the rerun catalog at `119-CI-CD-AUDIT.md:211-224` provides the exact commands.

### RULESTEAD_TEST_SCOPE Wrappers for Triage Table Rerun Column

[VERIFIED: scripts/ci/test.sh, 119-CI-CD-AUDIT.md:211-224]

| Lane (ci.yml job id) | Exact Rerun Command |
|----------------------|---------------------|
| `lint` | `bash scripts/ci/lint.sh` |
| `test` | `bash scripts/ci/contributor.sh` (fast) or `bash scripts/ci/local.sh` (full) |
| `integration-placeholder` | `bash scripts/demo/verify.sh` |
| `adopter-contract` | `cd rulestead && mix verify.adopter` |
| `mounted-proof` | `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` |
| `openfeature-companion` | `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` |
| `publish-hex` | NOT re-runnable (cite as irreversible gate) |
| `verify-published-release` | `bash scripts/ci/verify_published_release.sh <version>` (post-publish, live network) |
| `repo-hygiene` | `./scripts/maintainer/repo_hygiene_check.sh` |

---

## Architecture Patterns

### Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Command-ladder docs (MAINTAINING.md) | Documentation | — | Pure text edit in shift-left gate section :80-106 |
| CI failure-triage table | Documentation | CI scripts (single source of truth) | Table content lifted from shell microcopy functions |
| Closeout ledger (123-CI-CD-CLOSEOUT.md) | Documentation | Prior-phase measurement artifacts | Cites 119/121 files; does not re-measure |
| Final verification (lint.sh + release_contract_test) | CI scripts + ExUnit | — | Lint.sh is the lint gate; release_contract_test.exs is the doc-drift guard |
| Traceability + STATE updates | Planning docs | — | REQUIREMENTS.md, ROADMAP.md, STATE.md edits only |
| Anti-drift guard (D-14, optional) | ExUnit or Python lint guard | lint.sh | Either extend release_contract_test.exs or add scripts/check_*.py |

### Recommended Phase Structure

```
.planning/phases/123-dx-closeout-proof-0-plans/
├── 123-CONTEXT.md          (exists — locked)
├── 123-RESEARCH.md         (this file)
├── 123-CI-CD-CLOSEOUT.md   (to create — Wave 1)
├── 123-01-PLAN.md          (Wave 1: closeout ledger + catalog reconciliation)
├── 123-02-PLAN.md          (Wave 2: MAINTAINING.md — ladder + triage + D-14 guard)
├── 123-03-PLAN.md          (Wave 3: verification + traceability/STATE closeout)
└── 123-VALIDATION.md       (to create — per Nyquist workflow)
```

Edit targets by wave:
- Wave 1: `.planning/phases/123-dx-closeout-proof-0-plans/123-CI-CD-CLOSEOUT.md` (new), `119-CI-CD-AUDIT.md:213` (D-09 catalog reconciliation)
- Wave 2: `MAINTAINING.md:80-106` (ladder + triage table addition), optionally `release_contract_test.exs` or a new `scripts/check_*.py`
- Wave 3: `REQUIREMENTS.md:63,65`, `ROADMAP.md:17,147,160,162`, `STATE.md:14,37` (+ frontmatter fields)

---

## Verification Target Reality

### lint.sh Does NOT Run release_contract_test.exs

[VERIFIED: scripts/ci/lint.sh]

`scripts/ci/lint.sh` runs (in order): `mix deps.get`, `mix format`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix docs --warnings-as-errors`, `mix hex.audit`, `mix compile --no-optional-deps --warnings-as-errors`, `check_package_whitelist.sh`, `mix dialyzer`, then Python guard chain (synced_pair, brand_tokens, tokens_css, contrast, brandbook_html, logo_assets, admin_foundations, design_system_evidence), then SVG size budget.

There is no `mix test` call anywhere in `lint.sh`. The doc-drift guard (`release_contract_test.exs`) is NOT run by lint. [VERIFIED: scripts/ci/lint.sh full file]

**D-15 footgun confirmed:** A closeout that only runs `bash scripts/ci/lint.sh` would claim "verified" while leaving the doc-drift guard unrun. The mandatory second step is `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs`.

### release_contract_test.exs Passes Without ecto.create

[VERIFIED: rulestead/test/rulestead/release_contract_test.exs:1-19]

The module uses `use ExUnit.Case, async: true` and reads only file paths (all `Path.expand(…, __DIR__)` module attributes). No `use DataCase`, no `use RepoCase`, no `Ecto` or DB module references anywhere in the file. Grep for `ecto.create`, `Ecto`, `DataCase`, `RepoCase` returns zero matches.

D-18 confirmed: run `prepare_rulestead_test_db` only if a focused run reports a DB error, not pre-emptively.

### Exact Final Verification Commands

1. `bash scripts/ci/lint.sh` — doc/brand/asset guards
2. `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs` — support-truth doc-drift guard (MANDATORY for any MAINTAINING.md/README edit)
3. `cd rulestead && mix verify.adopter` — if any adopter-facing guide changed (optional if only MAINTAINING.md shift-left section and closeout ledger changed)

Do NOT run: mounted companion proof, DB-backed product suites, demo backend, publish-hex, verify-published-release, live `gh api` writes. Cite as skipped-by-design per D-16/D-17.

---

## D-14 Anti-Drift Guard Feasibility Assessment

### Option A: Extend release_contract_test.exs

**Feasibility:** HIGH. The file already asserts MAINTAINING.md content via file-content string matching. Adding assertions like `assert maintaining =~ "## CI Failure Triage"` and spot-checks on job ids or rerun commands follows the exact same pattern at lines 272-604. No new infrastructure, no new dependencies.

**Cost:** Minimal — 2-5 additional `assert maintaining =~ "…"` lines.

**Risk if deferred:** Triage table silently rots as ci.yml job ids or rerun commands change over time. Recorded in `123-CI-CD-CLOSEOUT.md` as a residual risk.

**Recommendation:** Include minimally. Add 3-5 assertions: one for the `## CI Failure Triage` section heading, one for each of the two highest-drift job ids (`mounted-proof` and `openfeature-companion`) since those are path-gated and most likely to be renamed, and one for the scope-wrapper pattern. Cost is 5 lines; benefit is permanent drift protection.

### Option B: New scripts/check_triage_table.py

**Feasibility:** MEDIUM. Possible using stdlib (no external dependencies), but requires parsing MAINTAINING.md and ci.yml together. Higher authoring cost than Option A.

**Recommendation:** Skip in favor of Option A for this closeout. A Python guard is appropriate if the triage table grows to cover many more lanes or becomes structured data.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Before/after measurements | New CI timing runs | Cite `121-MEASUREMENT.md:136-154` | Re-measurement breaks apples-to-apples comparability (D-03) |
| p95 metric | Synthesized percentile | Record as "unavailable" with verbatim reason from `119:109` | 20-run sample spans mixed events/branch classes — not defensible |
| Cache hit rate number | Derived percentage | Cite `scripts/ci/report_cache_hit.sh` qualitative output (exact-hit vs miss/partial) | GitHub Actions surfaces no numeric rate |
| Failure microcopy | Custom triage guidance text | Lift verbatim from `scripts/ci/test.sh` guidance functions | Single source of truth; doc and runtime stderr stay in lockstep |
| Rollback section structure | Free-form prose | Model on `119-CI-CD-AUDIT.md:284-309` per-decision rows | Established pattern; maintainers expect the same shape |

---

## Common Pitfalls

### Pitfall 1: Running Only lint.sh for Verification

**What goes wrong:** Executor runs `bash scripts/ci/lint.sh`, sees it pass, writes "verified" in the closeout. The MAINTAINING.md triage table edit (or any doc change) breaks `release_contract_test.exs` assertions, which only surfaces on the next `mix test` run.

**Why it happens:** lint.sh looks comprehensive (it runs Dialyzer + 9 Python guards) but does NOT run `mix test`. The doc-drift guard lives outside the lint lane.

**How to avoid:** Always include explicit `cd rulestead && mix test test/rulestead/release_contract_test.exs` as a second mandatory step.

**Warning signs:** Verification section that doesn't mention `release_contract_test.exs` by name.

### Pitfall 2: Fabricating Metrics Not in the Committed Record

**What goes wrong:** Executor synthesizes a p95 claim or a cache-hit percentage from available data.

**Why it happens:** It feels like a better closeout to have concrete numbers.

**How to avoid:** D-05 is explicit: use `unavailable from current sample` (verbatim from `119:109`) for p95; use qualitative (exact-hit / miss-or-partial) for cache rate. The honest-gap posture is a feature, not a deficiency.

**Warning signs:** Any percentage in the closeout that isn't directly cited to `121-MEASUREMENT.md`.

### Pitfall 3: Touching Protected MAINTAINING.md Sections

**What goes wrong:** Planner adds the triage table to the wrong location or reformats adjacent sections. Cache table (:63-78), branch-protection (:32-61), and release runbook (:121-228) are already correct and several are test-enforced.

**How to avoid:** D-08 is explicit. Add content only inside the shift-left gate section (:80-106). Add the `## CI Failure Triage` section adjacent to that section.

**Warning signs:** Any MAINTAINING.md diff touching lines outside :80-106 (except inserting a new section immediately after :106).

### Pitfall 4: Rerun Catalog Row Naming the Wrong Entrypoint

**What goes wrong:** `119-CI-CD-AUDIT.md:213` currently names `bash scripts/ci/contributor.sh` as the "Fast contributor loop" command. D-09 requires reconciling it to `cd rulestead && mix ci`. If not reconciled, contributors seeing the audit see a different name than what MAINTAINING.md will say.

**How to avoid:** D-09 reconciliation is a Wave 1 task alongside the closeout ledger (audit doc is not in the Hex package and not test-pinned — safe to edit).

### Pitfall 5: Triage Table Row Order Not Matching Pipeline Order

**What goes wrong:** Triage table rows are ordered arbitrarily rather than in pipeline order. Maintainers scanning during a CI failure compare what they see (pipeline order in the GitHub UI) against the doc.

**How to avoid:** D-11 specifies the exact order. `changes` is internal; start with `lint`, end with `repo-hygiene`.

### Pitfall 6: STATE.md Consistency Trap

**What goes wrong:** `STATE.md` frontmatter says `completed_phases: 4`, `percent: 80`, and text at line 37 says `"Phase 122 was final phase"`. These fields are intentionally left incorrect until Phase 123 is complete. Flipping them before verification is complete creates a false "done" signal.

**How to avoid:** D-20 STATE update is the last task in Wave 3, after lint + release_contract_test pass.

---

## Code Examples

### Pattern: release_contract_test.exs Assertion Style

[VERIFIED: rulestead/test/rulestead/release_contract_test.exs:272-299]

```elixir
# File-content assertion pattern (passes without ecto.create):
test "maintainer guidance matches the shipped release and support truth" do
  maintaining = File.read!(@maintaining_path)

  assert maintaining =~ "v1.0.0"
  assert maintaining =~ "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
  assert maintaining =~ "integration-placeholder"

  # Banned phrases (multi-fragment):
  for fragments <- banned_phrases do
    phrase = Enum.join(fragments, " ")
    refute maintaining =~ phrase
  end
end
```

D-14 guard additions follow this exact pattern. E.g.:
```elixir
assert maintaining =~ "## CI Failure Triage"
assert maintaining =~ "mounted-proof"
assert maintaining =~ "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
```

### Pattern: Rerun Catalog Reconciliation (D-09)

Current line 213 in `119-CI-CD-AUDIT.md`:
```
| Fast contributor loop | `bash scripts/ci/contributor.sh` | Common pre-push checks without slow proof scopes |
```

After D-09 reconciliation:
```
| Fast contributor loop | `cd rulestead && mix ci` (alias for `bash scripts/ci/contributor.sh`) | Common pre-push checks without slow proof scopes |
```

### Pattern: Closeout Ledger Field (D-02/D-04)

```markdown
### PR Wall-Clock (Before/After)

| Metric | Phase 119 Baseline | After Phase 121 | Delta |
|--------|--------------------|-----------------|-------|
| Default suite wall-clock (real) | ~42s | ~4.6s | -37s (-88%) |
| With dominant test (opted-in) | ~42s | ~22s | -20s (faster network on measure day) |
| Measurement corpus | 18 schedulers, local machine, 4 runs | 18 schedulers, local machine, 4 runs | Same baseline |

**Methodology:** Phase 121 re-ran the exact locked Phase 119 commands (`119-CI-CD-AUDIT.md:153-154`)
for direct comparability. [CITED: 121-MEASUREMENT.md:12-17]

**Caveat:** The "with dominant" run (22s) is faster than the Phase 119 ~42s baseline because hex.pm
network latency was lower on measurement day (17s vs ~28s). The dominant test cost is variable
(20-28s depending on hex.pm). [CITED: 121-MEASUREMENT.md:150]

**Framing:** The default-lane improvement is **relocation, not deletion** — the proof still runs
on the `guarded_rollout_foundations` scope via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`.
[CITED: 121-MEASUREMENT.md:154]
```

---

## Environment Availability

Step 2.6: No external service dependencies introduced by this phase. All work is doc edits, a new planning file, and running existing local commands.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / Elixir | `release_contract_test.exs`, `mix verify.adopter` | Assumed available (project is Elixir) | Project standard | — |
| `bash scripts/ci/lint.sh` | D-15 verification | Available (file verified) | — | — |
| Python3 | lint.sh guard chain | Assumed available (guards already run in CI) | stdlib only | — |

**Missing dependencies with no fallback:** None.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact on Phase 123 |
|--------------|------------------|--------------|---------------------|
| `bash scripts/ci/contributor.sh` named as fast loop | `cd rulestead && mix ci` is the named alias | Phase 123 (D-09 reconciliation) | Catalog row at `119:213` must be updated |
| Phase 122 was "final phase" in STATE.md | Phase 123 is the actual final phase | Phase 123 (D-20) | STATE frontmatter and line :37 must be corrected |
| CIDX-08 / CIDX-10 `Pending` in REQUIREMENTS.md and ROADMAP.md | Flip to `Complete` | Phase 123 (D-19) | Two tables require updates |
| `completed_phases: 4, percent: 80` in STATE.md | `5, 100` | Phase 123 (D-20) | Frontmatter correction |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Python3 is available locally for lint.sh guard chain execution | Environment Availability | lint.sh would fail before the release_contract_test step; executor would need to install Python3 |
| A2 | `mix verify.adopter` is not needed if only MAINTAINING.md shift-left section and closeout ledger change (no adopter-facing guide changed) | Verification Target Reality | If wrong, run `cd rulestead && mix verify.adopter` as D-15 specifies |

---

## Open Questions

1. **D-14 scope decision**
   - What we know: Both options (extend `release_contract_test.exs` vs new Python guard) are feasible. Option A is lower cost.
   - What's unclear: Whether the planner should include it in Wave 2 or defer to a residual risk note.
   - Recommendation: Include minimally in Wave 2 (3-5 assertions in `release_contract_test.exs`). Deferral is acceptable if the planner judges the closeout scope is already full.

2. **Wave 1 vs Wave 2 sequencing for catalog reconciliation (D-09)**
   - What we know: D-09 edits `119-CI-CD-AUDIT.md:213`, which is a planning artifact. The closeout ledger also lives in planning.
   - What's unclear: Whether to bundle D-09 into Wave 1 (closeout ledger + catalog) or Wave 2 (MAINTAINING.md).
   - Recommendation: Bundle D-09 into Wave 1. The audit doc reconciliation and the closeout ledger both live in planning artifacts and form a coherent "source-of-truth correction" wave.

---

## Validation Architecture

> Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) + bash lint.sh |
| Config file | `rulestead/test/test_helper.exs` |
| Quick run command | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| Full suite command | `bash scripts/ci/lint.sh && cd rulestead && mix test test/rulestead/release_contract_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| CIDX-08 | Command-ladder statement exists in MAINTAINING.md (fast loop, full gate, CI reruns all named) | Source assertion | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | `release_contract_test.exs` already asserts `mix ci`-adjacent content; D-14 guard additions extend this |
| CIDX-08 | `mix ci` alias delegates to `scripts/ci/contributor.sh` | Source assertion | `grep 'ci:.*contributor.sh' rulestead/mix.exs` | Confirmed at mix.exs:172 |
| CIDX-10 | `123-CI-CD-CLOSEOUT.md` exists with all seven CIDX-10 fields (PR wall-clock, p95, cache hit rate, top slow tests, flake notes, residual risks, rollback notes) | Structure check | `grep -E 'wall.clock|p95|cache hit|slow test|flake|residual risk|rollback' .planning/phases/123-dx-closeout-proof-0-plans/123-CI-CD-CLOSEOUT.md` | Manual/grep verification in VALIDATION.md |
| CIDX-10 | Every metric in closeout is tagged `[VERIFIED]`, `[CITED]`, or `[ASSUMED]` | Source assertion | `grep -c '\[VERIFIED\]\|\[CITED\]\|\[ASSUMED\]' .planning/phases/123-dx-closeout-proof-0-plans/123-CI-CD-CLOSEOUT.md` | Zero untagged metrics = audit posture intact |
| CIDX-08/CIDX-10 | MAINTAINING.md shift-left section contains CI failure triage table | Source assertion | `grep -A2 'CI Failure Triage' MAINTAINING.md` | Grep check in VALIDATION.md |
| CIDX-08/CIDX-10 | `release_contract_test.exs` passes (no doc-drift breakage from MAINTAINING.md edit) | unit | `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs` | MUST run — not covered by lint.sh |
| CIDX-08/CIDX-10 | lint.sh passes (doc/brand/asset guards green) | lint | `bash scripts/ci/lint.sh` | Standard CI lane verification |
| D-19 | CIDX-08 and CIDX-10 are `Complete` in REQUIREMENTS.md and ROADMAP.md | Source assertion | `grep -A1 'CIDX-08\|CIDX-10' .planning/REQUIREMENTS.md .planning/ROADMAP.md` | Grep check in VALIDATION.md |
| D-20 | STATE.md frontmatter has `completed_phases: 5`, `percent: 100` | Source assertion | `grep 'completed_phases\|percent:' .planning/STATE.md` | Grep check in VALIDATION.md |

### Sampling Rate

- **Per task commit:** Quick run: `cd rulestead && mix test test/rulestead/release_contract_test.exs`
- **Per wave merge:** `bash scripts/ci/lint.sh && cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs`
- **Phase gate:** Full suite green (`bash scripts/ci/lint.sh` + `release_contract_test.exs`) before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. `release_contract_test.exs` exists and is the load-bearing verification target. D-14 guard additions extend it rather than replace it.

*(If D-14 is deferred: record gap as "D-14 triage table anti-drift guard deferred — residual risk recorded in 123-CI-CD-CLOSEOUT.md.")*

---

## Security Domain

Security enforcement applies; this phase has no new attack surface. Applicable ASVS categories for documentation/CI changes:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No | — |
| V6 Cryptography | No | — |

**Supply-chain posture:** No new packages, no workflow topology changes, no action pin changes. Release-trust boundary preserved per D-16/D-17 (irreversible/live-network steps cited, never executed). [VERIFIED: CONTEXT.md domain block; VERIFIED: scripts/ci/lint.sh]

---

## Sources

### Primary (HIGH confidence — VERIFIED in this session)

- `.planning/phases/123-dx-closeout-proof-0-plans/123-CONTEXT.md` — decisions D-01 through D-20; all canonical reference citations
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` — lines :103-107 (critical-path), :109 (p95-unavailable), :153-154 (locked commands), :211-224 (rerun catalog), :213 (catalog row), :249-257 (microcopy contract), :284-309 (rollback guardrails), :332-336 (Phase 123 handoff)
- `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-MEASUREMENT.md` — lines :12-17 (methodology), :136-154 (before/after table), :154 (relocation framing), :176 (FUT-01 rejection), :222-229 (Phase 123 Feed)
- `.planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md` — lines :89-91 (honest-non-execution precedent)
- `MAINTAINING.md` — lines :32-61 (branch-protection), :63-78 (cache table), :80-106 (shift-left gate, edit target), :121-228 (release runbook)
- `rulestead/mix.exs:172` — `ci:` alias delegation confirmed
- `scripts/ci/lint.sh` — full file; confirmed does NOT run mix test
- `scripts/ci/contributor.sh` — fast loop implementation
- `scripts/ci/local.sh` — full gate implementation (companion proofs at :44-47)
- `scripts/ci/test.sh:67-90` — `print_mounted_failure_guidance` function with verbatim microcopy
- `scripts/ci/report_cache_hit.sh` — qualitative exact/partial hit reporting
- `.github/workflows/ci.yml:316-325` — `release_gate.needs` job id list (7 jobs)
- `.github/workflows/repo-hygiene.yml` — repo-hygiene job exists; job name: `repo-hygiene`
- `rulestead/test/rulestead/release_contract_test.exs:1-19` — file-content asserts, `async: true`, no DB deps; total 1003 lines
- `.planning/REQUIREMENTS.md:63,65` — CIDX-08/CIDX-10 rows (Pending → Complete targets)
- `.planning/ROADMAP.md:17,147,160,162` — Phase 123 checklist and traceability targets
- `.planning/STATE.md` — `completed_phases: 4`, `percent: 80`, line :37 drift confirmed
- `.planning/config.json` — `workflow.nyquist_validation: true`

### Tertiary (LOW confidence — training knowledge, not verified)

None — all claims in this research are backed by direct file inspection.

---

## Metadata

**Confidence breakdown:**
- Citation verification: HIGH — every load-bearing CONTEXT.md citation verified against actual file:line in this session; no drift found
- Architecture: HIGH — edit targets, do-not-touch ranges, and verification commands all confirmed
- Pitfalls: HIGH — lint.sh non-execution of release_contract_test.exs directly verified (grep returns 0 matches for `mix test` in lint.sh)
- D-14 feasibility: HIGH — release_contract_test.exs pattern confirmed; option A is unambiguously lower cost

**Research date:** 2026-06-17
**Valid until:** 60 days — this is a verification/docs phase; the underlying code is stable
