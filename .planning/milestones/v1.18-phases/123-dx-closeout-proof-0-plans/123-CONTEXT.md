# Phase 123: DX + Closeout Proof - Context

**Gathered:** 2026-06-17 (assumptions mode + architect-default research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 123 closes the v1.18 CI/CD Reliability milestone with **contributor-command
clarity, measurable before/after impact, and rollback-ready documentation**. It is a
**documentation + measurement-reconciliation + verification** phase only. It delivers:
(1) narrow `MAINTAINING.md` reconciliation so contributor docs match the final fast loop,
full local gate, CI rerun commands, and release proof posture; (2) a concise CI
failure-triage table covering the eight release lanes; (3) `123-CI-CD-CLOSEOUT.md` — the
milestone counterpart to `119-CI-CD-AUDIT.md` — recording before/after PR wall-clock, p95
(if available), cache hit rate, top slow tests, flake notes, residual risks, and rollback
notes; (4) final verification of the changed lanes plus agreed local gates; and
(5) requirements-traceability + `STATE.md` closeout.

This phase does NOT: change product runtime APIs, schemas, or `rulestead_admin` publish
posture; change workflow topology or cache keys (Phase 120, done); change core Mix/ExUnit
async or test inclusion (Phase 121, done); change browser/demo/Playwright behavior
(Phase 122, done); execute irreversible release steps (`publish-hex`,
`verify-published-release`) or any `gh api` branch-protection writes; re-measure CI timing
with new commands; or fabricate metrics the tooling cannot produce. It satisfies
requirements **CIDX-08** (simple contributor commands) and **CIDX-10** (reviewable
before/after impact).
</domain>

<decisions>
## Implementation Decisions

### Closeout Document — `123-CI-CD-CLOSEOUT.md`
- **D-01:** Create `123-CI-CD-CLOSEOUT.md` in
  `.planning/phases/123-dx-closeout-proof-0-plans/` (standard `NNN-<slug>-0-plans/`
  convention). It is the **milestone counterpart to `119-CI-CD-AUDIT.md`**, not a
  replacement — a maintainer can diff baseline ledger against closeout ledger.
- **D-02:** Mirror the 119 audit's honesty convention: tag every metric
  `[VERIFIED]` / `[CITED]` / `[ASSUMED]`. Structure as a **field-by-field CIDX-10 ledger**
  with one row/section per required field (PR wall-clock, p95, cache hit rate, top slow
  tests, flake notes, residual risks, rollback notes), each citing its data source
  (file + line).
- **D-03:** **Cite prior-phase numbers; do NOT re-measure.** Phase 121 already re-ran the
  *exact* locked Phase 119 commands (`121-MEASUREMENT.md:12`,
  `119-CI-CD-AUDIT.md:153-154`) specifically to feed Phase 123, so the apples-to-apples
  before/after already exists and is committed. A fresh local re-measurement would
  introduce a third, un-baselined sample (different cache warmth, hex.pm latency variance —
  `121-MEASUREMENT.md:150`) and break comparability. Forward the committed deltas with
  their caveats.
- **D-04:** Use the **Oban-grade rigor** for every perf claim: state both endpoints + the
  measurement corpus + the factor delta + a methodology/caveat line — never a lone
  percentage. Frame the dominant-test result as **relocation-not-deletion**
  (`121-MEASUREMENT.md:154`); a bare "−88%" without that framing misleads a reader into
  thinking coverage was removed.
- **D-05 (honest gaps — load-bearing):** **p95** is recorded as
  `unavailable from current sample` with the reason verbatim from `119-CI-CD-AUDIT.md:109`
  (20-run sample spans mixed events/branch classes; insufficient for a defensible p95);
  show the verified representative critical-path wall-clocks (`119:103-107`) instead.
  **Cache hit rate** is recorded **qualitatively** (exact-hit vs miss/partial) as
  `scripts/ci/report_cache_hit.sh` emits it — GitHub Actions surfaces no numeric rate, so
  do NOT synthesize a percentage. Fabricating either is an audit defect against the
  honest-gap posture (`REQUIREMENTS.md:46`).
- **D-06 (rollback notes):** Model on the 119 No-Go/Rollback Guardrails
  (`119-CI-CD-AUDIT.md:284-309`) but make it **per-decision and git-revert-granular**: one
  row per Phase 120/121/122 change with (a) what changed, (b) exact revert handle
  (commit/PR; for cache changes the **cache-key bump** to invalidate poisoned entries),
  (c) the trust boundary that must not be silently weakened on rollback (release_gate,
  protected Hex publish, linked-version order). Cite the reversible-by-design exemplars:
  the `@tag :published_hex_smoke` relocation (`121:13`, revert = remove tag) and the
  FUT-01 partitioning rejection (`121:176`). Call out the footguns: a cache change reverted
  without a key bump leaves poisoned entries; a workflow path-filter rollback can leave a
  required check stuck pending (`119:88,302`).

### Contributor Command Surface (MAINTAINING.md reconciliation)
- **D-07:** Adopt the **canonical command ladder**: fast local loop = `cd rulestead &&
  mix ci`; full local gate = `bash scripts/ci/local.sh` (`--fast` skips companion scopes);
  CI reruns = `mix verify.adopter` + the named `RULESTEAD_TEST_SCOPE=… bash
  scripts/ci/test.sh` wrappers. This is **zero behavioral change** — `mix ci` is already a
  thin delegate (`rulestead/mix.exs:172` → `cmd bash ../scripts/ci/contributor.sh`) — so
  the fix is purely a naming/labeling reconciliation. `mix` is the least-surprising
  entrypoint for Elixir contributors; scripts-first remains correct for the multi-package
  full gate.
- **D-08:** Phase 123's MAINTAINING.md edits are **narrow**: in the shift-left contributor
  gate section (`MAINTAINING.md:80-106`), add one explicit ladder statement naming the
  canonical fast/full/rerun commands and stating that **`mix ci` is the named alias for
  `scripts/ci/contributor.sh`** (so the two refer to one job); add the CI failure-triage
  table (D-09/D-10); and reflect the post-121 ~5s default-suite / opt-in-tag posture where
  the fast loop is described. **Do NOT rewrite** the cache table (`:63-78`),
  branch-protection (`:32-61`), release runbook (`:121-228`), or proof-bar sections —
  those are already correct and several are test-enforced.
- **D-09 (catalog reconciliation):** Reconcile the rerun-catalog row at
  `119-CI-CD-AUDIT.md:213` to name `cd rulestead && mix ci` (alias for
  `scripts/ci/contributor.sh`) so the canonical name is recorded once and the catalog stops
  naming a competing entrypoint. (The audit doc is not in the Hex package and not
  test-pinned — safe to edit.)

### CI Failure-Triage Table
- **D-10:** Ship a **single 6-column table** in a new `## CI Failure Triage` section of
  `MAINTAINING.md`, columns:
  `Lane (ci.yml job id) | What failed | Boundary it protects | Exact rerun | Likely
  remediation | When to stop rather than bypass`. This mirrors the locked 5-slot D-20
  microcopy contract (`119-CI-CD-AUDIT.md:249-255`) 1:1.
- **D-11:** Lead each row with the **immutable `ci.yml` job id** (the string the reader sees
  red in the GitHub checks UI) and order rows in **`release_gate` pipeline order**:
  `lint → test → integration-placeholder → adopter-contract → mounted-proof →
  openfeature-companion → publish-hex → verify-published-release → repo-hygiene`
  (`ci.yml` `release_gate.needs:316-325`, plus `repo-hygiene.yml`). The two irreversible
  release lanes sit last where the "when to stop" microcopy lands hardest. (ROADMAP lists
  eight lanes; `adopter-contract` is included as the ninth real lane for completeness.)
- **D-12:** **Lift rerun commands and microcopy verbatim** from the existing
  `scripts/ci/test.sh` guidance functions (e.g. `print_mounted_failure_guidance:67-90`) so
  the doc table and runtime stderr say the same words (single source of truth). Use the
  scope **wrapper** (`RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`)
  not raw multi-file `mix test` lists, matching the rerun catalog and avoiding column
  overflow.
- **D-13 (tone):** Microcopy is **imperative, factual, boundary-anchored — not preachy**.
  Phrase "when to stop" as a release-trust *fact*, e.g. "`publish-hex` /
  `verify-published-release` are release-trust gates, not speed targets — a red here means
  published artifacts may not satisfy the install/mount contract; cut a corrected release
  rather than republishing from an untagged commit." This directly counters the documented
  blind-rerun anti-pattern.
- **D-14 (anti-drift guard — recommended):** Add a thin guard so the table can't silently
  rot — preferred form: extend an existing docs-drift assertion (e.g.
  `release_contract_test.exs`) or add a `scripts/check_*.py` to the `lint.sh` guard chain
  that asserts every `ci.yml` job id and every `RULESTEAD_TEST_SCOPE` rerun command in the
  triage section matches the rerun catalog. This matches the scripts-first / fail-closed
  posture (`119-CI-CD-AUDIT.md:257`). The planner may scope this minimally or defer the
  guard if it would expand the closeout beyond docs+measurement; if deferred, record it as
  a residual risk in `123-CI-CD-CLOSEOUT.md`.

### Final Verification Scope
- **D-15:** Run the **targeted changed lanes that actually guard a markdown/planning diff**:
  (1) `bash scripts/ci/lint.sh` — `mix docs --warnings-as-errors` plus brand/contrast/
  synced-pair/asset guards (`lint.sh:30-87`); (2) **explicitly**
  `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs` —
  the "support truth stays bounded" assertions are **test-enforced and live OUTSIDE
  `lint.sh`**, and editing `MAINTAINING.md`/`README.md` is exactly what breaks them
  (`release_contract_test.exs:272-604`); (3) `cd rulestead && mix verify.adopter` if any
  adopter-facing guide changed. This is the central footgun: a closeout that runs only
  `lint.sh` would claim "verified" while leaving the doc-drift guard unrun.
- **D-16:** Do **NOT** run for show: mounted/openfeature companion proofs
  (`local.sh:44-47`), DB-backed product suites, or the demo backend add no signal for a
  docs diff. Record them as **cited-as-skipped-by-design**, not silently omitted.
- **D-17 (cite-as-not-runnable, never silent skip):** Explicitly cite as not re-runnable in
  this environment: `publish-hex` / `mix hex.publish` (irreversible, gated, no version
  change); `verify-published-release` / `mix verify.release_publish` (live hex.pm network,
  no-publish phase; `published_hex_smoke` stays opt-in via
  `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`); live branch-protection / `gh api` reconciliation
  (docs-only, no gh-api writes — `119` handoff:316); and the CI matrix timing /
  `release_gate` aggregation (observable only in GitHub Actions, mirrored locally by
  lint+test). This honest-non-execution posture mirrors `122-VERIFICATION.md:89-91`.
- **D-18:** Note for the executor: the support-truth asserts are file-content asserts
  (`release_contract_test.exs:9-14`), so the module should pass **without** `ecto.create`;
  run `prepare_rulestead_test_db` only if a focused run reports a DB error, not pre-emptively.

### Traceability + STATE Closeout
- **D-19:** Flip **CIDX-08** and **CIDX-10** to `Complete` in BOTH the `REQUIREMENTS.md`
  traceability table (`:63,65`) and the `ROADMAP.md` traceability table (`:160,162`); mark
  Phase 123 `Complete` in the ROADMAP phase checklist (`:17`) and progress table (`:147`).
- **D-20:** Correct `STATE.md`: `completed_phases: 4→5`, `percent: 80→100`, and fix the
  inaccurate `stopped_at: "Phase 122 was final phase"` (`:14,37`) — Phase 123 is the actual
  final phase per `ROADMAP.md:5,17` and the dependency map (`STATE.md:43-50`). This is the
  step that makes the milestone done-state internally consistent for the next milestone
  kickoff.

### Claude's Discretion
- The planner may choose the exact table/section ordering inside `123-CI-CD-CLOSEOUT.md` if
  all seven CIDX-10 fields and their evidence tags remain present.
- The planner may bundle the MAINTAINING.md ladder edit, triage table, and catalog
  reconciliation into one plan or split them, and may decide the precise scope of the D-14
  anti-drift guard (including deferral with a recorded residual risk).
- The planner may add low-cost cross-references between `123-CI-CD-CLOSEOUT.md`,
  `119-CI-CD-AUDIT.md`, and `121-MEASUREMENT.md` to strengthen the audit trail.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Ground Truth
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` — baseline ledger;
  evidence convention (7-12), critical-path sample (103-107), p95-unavailable (109), cache
  posture (127-139), rerun catalog (211-224), failure microcopy contract D-20 (249-257),
  No-Go/rollback guardrails (284-309), Phase 123 handoff (332-336).
- `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-MEASUREMENT.md`
  — locked-command methodology (12-17), before/after table (136-154), relocation-not-deletion
  (154), reversible-by-design (13,176), "Phase 123 Feed" (222-229).
- `.planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md`
  — cite-as-optional / honest-non-execution precedent (89-91).
- `.planning/ROADMAP.md` — Phase 123 success criteria (5) + traceability tables.
- `.planning/REQUIREMENTS.md` — CIDX-08, CIDX-10, and out-of-scope/preserved-bar constraints.
- `.planning/STATE.md` — strict 119→123 sequence, release-trust boundary, milestone state.
- `.planning/METHODOLOGY.md` — recommendation-first / research-then-recommend / architect-default.

### Prompt Grounding
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, paths-ignore PR +
  always-runs push:main (78-85), release-trust posture, publish gating (304-324),
  post-publish proof (608-613).
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir OSS CI/CD baseline.
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — named `mix verify.*`/`mix ci.*`
  entrypoint preference (175).
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — contributor/support/SRE JTBD for the
  triage table audience; `mix ci.all` precedent (320,444).
- `prompts/rulestead-telemetry-observability-and-audit.md` — honest-gap / evidence posture.
- `prompts/rulestead-security-privacy-and-threat-model.md` — supply-chain / fail-closed posture.
- `prompts/rulestead-testing-and-e2e-strategy.md` — proof-bar / verification posture.

### Code & Doc Surfaces (edit targets / cited)
- `MAINTAINING.md` — shift-left gate (80-106; ladder + triage table edit target),
  release-trust language (181-185, 269); do NOT touch cache (63-78), branch-protection
  (32-61), release runbook (121-228).
- `rulestead/mix.exs:172` — `ci: ["cmd bash ../scripts/ci/contributor.sh"]` (proves D-07
  zero-behavioral-change).
- `scripts/ci/contributor.sh` (fast loop; `mix test` at :11), `scripts/ci/local.sh` (full
  gate; `--fast`, companion proofs 44-47, verify.adopter :55), `scripts/ci/lint.sh`
  (doc/brand/asset guards 30-87 — does NOT run the doc-drift test), `scripts/ci/test.sh`
  (microcopy functions e.g. 67-90; scope wrappers; `published_hex_smoke` opt-in :231).
- `scripts/ci/report_cache_hit.sh` — qualitative exact/partial hit reporting (cache-metric
  provenance for D-05).
- `.github/workflows/ci.yml` — job ids / `release_gate.needs` (316-325) for the triage lanes.
- `.github/workflows/publish-hex.yml`, `verify-published-release.yml`, `repo-hygiene.yml`
  — release/hygiene lanes (cited, not executed).
- `rulestead/test/rulestead/release_contract_test.exs` — test-enforced support-truth asserts
  (272-604; doc paths 9-14); the load-bearing verification target (D-15) and D-14 guard host.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — traceability +
  state closeout edit targets (D-19/D-20).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `119-CI-CD-AUDIT.md` already provides the ledger shape, evidence convention, rerun catalog,
  and No-Go/rollback guardrails — the closeout mirrors and updates these rather than inventing.
- `121-MEASUREMENT.md` already contains the committed before/after deltas (re-run with the
  exact locked 119 commands) and a "Phase 123 Feed" section — the closeout cites it directly.
- The failure microcopy already exists in shell (`scripts/ci/test.sh` guidance functions);
  the triage table lifts these verbatim, keeping doc and runtime in lockstep.
- `mix ci` already delegates to `scripts/ci/contributor.sh` — the command-naming fix is
  documentation, not plumbing.

### Established Patterns
- Scripts-first CI with named `mix` front doors; `mix` is the contributor entrypoint, shells
  own multi-package orchestration.
- Honest-gap evidence convention (`[VERIFIED]/[CITED]/[ASSUMED]`); no fabricated metrics.
- Docs are test-enforced: `release_contract_test.exs` asserts MAINTAINING/README support
  truth — editing those docs can break tests, so the doc-drift test is mandatory verification.
- Release trust preserved: pinned actions, minimal permissions, gated publish, post-publish
  proof; irreversible/live-network steps are cited, never executed in a closeout.

### Integration Points
- Closeout doc cross-references the 119 audit and 121 measurement to form one auditable chain.
- The triage table attaches to `ci.yml` job ids so the doc lookup key matches the failing
  check name a reader sees in GitHub.
- Traceability/STATE updates make the milestone done-state consistent for v1.19 kickoff.
</code_context>

<specifics>
## Specific Ideas

- User asked for one-shot expert recommendations with pros/cons/tradeoffs, ecosystem idioms,
  lessons from successful libs/apps (Elixir + broader), strong DX, and coherent architecture
  across the milestone — applied via four parallel research streams (closeout-report design,
  contributor-DX, failure-triage UX, verification posture).
- Idiom anchors confirmed: Oban changelog rigor (endpoints + corpus + factor + caveat),
  ex_check/`mix check` + Oban `mix test.ci` for the `mix`-front-door norm, Google SRE
  runbook structure + the blind-rerun anti-pattern for the triage table.
- Where prompts conflict with newer brandbook/design-system artifacts, prefer the newer repo
  artifact (no brand/UI work is in scope here regardless).
</specifics>

<deferred>
## Deferred Ideas

- Fresh local re-measurement of CI timing — rejected (D-03); would break apples-to-apples
  with the locked baseline. Cite committed prior-phase numbers instead.
- Numeric p95 / numeric cache-hit-rate — not computable from current tooling; recorded as
  honest gaps (D-05), not fabricated.
- A heavier anti-drift guard for the triage table (D-14) may be minimized or deferred to a
  recorded residual risk if it would expand the closeout beyond docs+measurement+verification.
- Larger runners, broad test partitioning, richer CI reports, browser-binary caching — remain
  future/later-milestone options (carried from 119); out of scope for closeout.
- Executing `publish-hex` / `verify-published-release` / `gh api` branch-protection — out of
  scope; cited as not re-runnable (D-17), release-trust boundary preserved.

### Reviewed Todos (not folded)
- None — no pending todos matched Phase 123 scope.
</deferred>

---

*Phase: 123-dx-closeout-proof-0-plans*
*Context gathered: 2026-06-17*
</content>
</invoke>
