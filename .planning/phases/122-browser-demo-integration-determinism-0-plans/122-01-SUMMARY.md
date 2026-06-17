---
phase: 122-browser-demo-integration-determinism
plan: 01
subsystem: ci, testing
tags: [playwright, github-actions, shell-scripts, ci-cd, browser-testing]

# Dependency graph
requires:
  - phase: 121-mix-exunit-performance-test-value-cleanup
    provides: corrected ExUnit suite with async/performance audit; 119-CI-CD-AUDIT.md root-cause findings
  - phase: 119-baseline-expert-audit
    provides: 119-CI-CD-AUDIT.md identifying playwright trace/retry mismatch and No-Go guardrails
provides:
  - Playwright config determinism: retain-on-failure trace/screenshot/video + html reporter (D-01)
  - verify.sh failure-output block printing URLs, artifact paths, rerun commands (D-04)
  - CI upload-artifact step on integration-placeholder job, SHA-pinned, if:failure() (D-05)
  - D-03 audit evidence: demo-script readiness confirmed sound, no rework needed
  - D-06 audit evidence: all 15 specs are KEEP, no CIDX-05 demotion evidence
affects:
  - 123-dx-closeout-proof (cites D-03/D-06 audit evidence for contributor-command closeout)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Playwright retain-on-failure for trace/screenshot/video: artifacts only on real failures, zero overhead on green"
    - "|| { ... ; exit 1 } failure-output idiom in shell scripts (house pattern from smoke.sh)"
    - "SHA-pinned upload-artifact step with if:failure() for debug artifact hygiene in CI"

key-files:
  created:
    - .planning/phases/122-browser-demo-integration-determinism-0-plans/122-01-SUMMARY.md
  modified:
    - examples/demo/frontend/playwright.config.ts
    - scripts/demo/verify.sh
    - .github/workflows/ci.yml

key-decisions:
  - "D-01: Fix trace/retry mismatch at root cause: retain-on-failure + html reporter; retries stays 0"
  - "D-02: No webServer block; external Compose stack remains the readiness authority"
  - "D-03: No rework of demo-script readiness; wait_for_health and retry_command are legitimate polling, not flake-hiding sleeps"
  - "D-04: verify.sh failure block prints exact URLs + artifact paths + rerun commands via || {} idiom"
  - "D-05: upload-artifact step SHA-pinned to ea165f8d (v4.6.2), if:failure(), paths scoped to playwright-report/ and test-results/ only"
  - "D-06: All 15 specs are KEEP; no CIDX-05 demotion evidence; 10 functional journeys + 5 visual-evidence matrices are role-distinct"

patterns-established:
  - "Playwright determinism config: retain-on-failure (not on-first-retry against retries:0)"
  - "Shell failure block: || { echo diagnostics; exit 1 } appended after subshell, never replaces trap"
  - "CI upload-artifact: scoped to playwright output dirs only, if:failure(), SHA-pinned per repo posture"

requirements-completed: [CIDX-05]

# Metrics
duration: 4min
completed: 2026-06-17
---

# Phase 122 Plan 01: Browser/Demo/Integration Determinism Summary

**Playwright trace/retry mismatch fixed at root cause — retain-on-failure config + verify.sh failure-output block + SHA-pinned CI upload-artifact step, with D-03/D-06 audit evidence confirming all 15 specs are KEEP and demo readiness is already sound**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-17T03:04:10Z
- **Completed:** 2026-06-17T03:08:00Z
- **Tasks:** 5 (Tasks 1, 2, 4 auto; Task 3 SHA resolved by orchestrator; Task 5 SUMMARY)
- **Files modified:** 3 (playwright.config.ts, verify.sh, ci.yml)

## Accomplishments

- Fixed the root-cause Playwright defect: `trace: "on-first-retry"` against `retries: 0` meant traces never fired and no HTML report directory was created for CI to upload. Changed to `retain-on-failure`, added `screenshot: "only-on-failure"` and `video: "retain-on-failure"`, and added `reporter: [["html", { open: "never" }], ["list"]]`. `retries: 0` untouched.
- Added failure-output ergonomics to `verify.sh`: the `|| { ... ; exit 1 }` block prints exact Frontend/Backend URLs, artifact paths (`playwright-report/` and `test-results/`), and local rerun commands when Playwright fails. Existing `trap cleanup EXIT INT TERM` is unmodified.
- Added SHA-pinned `upload-artifact` step to `integration-placeholder` job in `ci.yml`: `if: failure()`, paths scoped to exactly the two Playwright output directories, `if-no-files-found: ignore` prevents failure on cancelled runs. `release_gate` unaffected.
- Recorded D-03 audit evidence: demo-script readiness is sound (real Docker health polling, no free-standing sleeps, zero `waitForTimeout` in specs). No rework needed.
- Recorded D-06 audit evidence: 15 specs in 5 distinct concern areas. No two specs cover the same assertion surface. No CIDX-05 demotion bar is met for any spec.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix Playwright config (D-01/D-02)** - `0c2b021` (fix)
2. **Task 2: Add failure-output block to verify.sh (D-04)** - `542d048` (fix)
3. **Task 3: SHA verification** - resolved by orchestrator (no commit; SHA confirmed ea165f8d v4.6.2)
4. **Task 4: Add upload-artifact step to ci.yml (D-05)** - `cbdb7c1` (feat)
5. **Task 5: SUMMARY + state updates** - (docs, this commit)

## Files Created/Modified

- `examples/demo/frontend/playwright.config.ts` — trace/screenshot/video retain-on-failure + html+list reporter; retries:0 unchanged; no webServer
- `scripts/demo/verify.sh` — failure block via `|| {}` idiom: prints Frontend/Backend URL, artifact paths, local report + rerun commands; trap intact; success echo intact
- `.github/workflows/ci.yml` — upload-artifact step appended to integration-placeholder job; SHA-pinned v4.6.2; if:failure(); paths scoped; if-no-files-found:ignore

## Audit Evidence (D-03/D-06)

### D-03: Demo-Script Readiness — No Rework Needed

Evidence supporting the determination that `wait_for_health` polling and `retry_command` are legitimate health/eventual-consistency polling, not flake-hiding sleeps:

- **`smoke.sh:25-47` polls `docker inspect .State.Health.Status`** — real Docker health check, not a fixed sleep. The `wait_for_health` function queries the container's own health status, making it genuinely reactive to the Compose stack's readiness state.
- **`sleep 2` calls are inside bounded polling loops** — `smoke.sh:42` shows `sleep 2` is the inter-poll interval inside a loop with a maximum retry count. This is correct eventually-consistent polling, not a free-standing sleep masking a fixed delay.
- **`retry_command` (`smoke.sh:49-64`) retries curl probes** against an eventually-consistent seeded backend — the retry is scoped to network-layer readiness (curl returning non-error), not a blind wait.
- **Cleanup traps on every script** — `smoke.sh:23/89`, `verify.sh:14`, `proxy-smoke.sh:64/90` — all with `dump_failure_logs`, ensuring Docker teardown and log capture on any exit path.
- **Zero `waitForTimeout` or `setTimeout` in any spec** — confirmed by grep: `grep -rn "waitForTimeout\|setTimeout" examples/demo/frontend/tests/` returns no output. Specs use web-first `expect(...).toBeVisible({ timeout })` assertions (e.g., `adoption-journeys.spec.ts:18`, `00-demo-toggle.spec.ts:9,27`).

**Verdict:** Demo-script readiness is sound. D-03 no-rework determination is evidence-backed. Converting `wait_for_health` or `retry_command` to fixed sleeps would regress correctness. CIDX-05 criterion for "concrete evidence" is satisfied — the evidence record shows the existing approach is legitimate.

### D-06: Spec Inventory — All 15 Specs Are KEEP

**Total: 15 specs** (not 17+ as previously approximated; count verified by directory listing).

**Functional-journey specs (10) — live browser against real Compose stack:**

| Spec | Role |
|------|------|
| `00-demo-toggle.spec.ts` | Kill switch sign-in + toggle + frontend refresh loop |
| `adoption-journeys.spec.ts` | FleetDesk persona journeys (feature flag evaluation) |
| `rollout-advance.spec.ts` | Staged percentage rule surface for fleet-map-v2 flag |
| `guarded-rollout.spec.ts` | Guardrail copy in rollout panel |
| `flag-inventory.spec.ts` | Admin flag inventory lists adoption-lab seeds |
| `audit-timeline.spec.ts` | Audit timeline after kill switch activity |
| `explain-admin.spec.ts` | Admin explain permalink / support-safe trace |
| `theme-control.spec.ts` | Dark/light/system theme control on shell (11 tests) |
| `theme-cascade.spec.ts` | Token cascade without OS attr (5 tests) |
| `theme-scope.spec.ts` | Token scoping (`:root` isolation, 3 tests) |

**Visual-evidence matrix specs (5) — screenshot artifacts for human review:**

| Spec | Role |
|------|------|
| `ui-matrix.spec.ts` | Admin UI multi-viewport/theme matrix + self-enforcing anti-baseline guard |
| `brand-ui-evidence.spec.ts` | Brand-faithful UI evidence (logo, tokens, design fidelity) |
| `admin-flow-ia.spec.ts` | Admin route IA evidence (9 tests) |
| `design-system.spec.ts` | Color contrast (AA) + static token assertions (10 tests) |
| `brandbook.spec.ts` | Brandbook HTML landmarks + sections via `file://` (15 tests) |

**Redundancy verdict:** No two specs cover the same assertion surface. Functional journeys use distinct user-persona flows through distinct app surfaces. Visual-evidence specs write to `testInfo.outputPath(...)` (ignored `test-results/`) and cover non-overlapping UI components. `brandbook.spec.ts` uses `file://` against a static HTML file — a completely different target from the live Compose stack.

**Anti-baseline guard:** `ui-matrix.spec.ts:401-411` reads its own source at runtime and asserts that `toHaveScreenshot`, `matchSnapshot`, `pixelmatch`, `visual-diff`, `pixel-baseline`, `Storybook`, `PhoenixStorybook`, and `phoenix_storybook` are absent. This is self-enforcing — it would fail itself if a baseline term were introduced.

**Artifact hygiene:** `examples/demo/frontend/.gitignore` explicitly ignores `test-results/` and `playwright-report/`. `git ls-files -- 'examples/demo/frontend/test-results' 'examples/demo/frontend/playwright-report'` returns zero lines — confirmed clean.

**Verdict:** CIDX-05 demotion bar is not met for any of the 15 specs. All 15 are KEEP per D-06.

## Decisions Made

- **D-01:** `trace: "retain-on-failure"` (not `"on"` which bloats the 15-spec matrix, not `"on-first-retry"` which never fires against `retries: 0`). `retries: 0` unchanged — No-Go guardrail from `119-CI-CD-AUDIT.md` prohibits blind retries.
- **D-02:** No `webServer` block. External Compose stack started by `smoke.sh`/`verify.sh` is the readiness authority; `baseURL`/ports remain env-driven. A `webServer` block would duplicate the compose lifecycle and reintroduce fixed-port assumptions.
- **D-03:** No rework of demo-script readiness. Evidence confirms `wait_for_health` is real Docker health polling; `sleep 2` is inside bounded loops; zero `waitForTimeout` in specs. Recording the evidence satisfies CIDX-05 without churning working code.
- **D-04:** `|| { ... ; exit 1 }` idiom appended after the Playwright subshell — not a new trap. `exit 1` inside the block fires the existing `trap cleanup EXIT INT TERM`, preserving Docker teardown.
- **D-05:** `if: failure()` (not `if: always()`) — `retain-on-failure` means meaningful artifacts only exist on failure; uploading on green runs wastes storage. SHA pinned to `ea165f8d65b6e75b540449e92b4886f43607fa02` (v4.6.2) — verified by orchestrator as latest stable v4.x.
- **D-06:** All 15 specs KEEP. Default-to-keep is the correct posture when no concrete redundancy evidence exists per CIDX-05.

## ROADMAP Success Criteria Satisfaction

| Criterion | Status | Evidence |
|-----------|--------|----------|
| 1. Playwright, demo, UI matrix, FleetDesk, integration scripts audited for fixed ports, sleeps, shared state, artifact leakage, flaky readiness checks | SATISFIED | D-03 audit evidence: real Docker health polling, zero waitForTimeout in specs, cleanup traps on all scripts; D-06: 15 specs, distinct assertion surfaces, no pixel baselines |
| 2. Known transient browser/test behavior fixed at root cause | SATISFIED | D-01: trace "retain-on-failure" with retries:0 — no blind retries, artifacts fire on real failures |
| 3. Generated screenshots and browser artifacts remain ignored artifacts, not checked-in baselines | SATISFIED | D-06: gitignore covers both dirs; git ls-files returns empty; ui-matrix.spec.ts:401-411 anti-baseline guard intact |
| 4. Low-signal or redundant browser/demo checks rewritten/demoted/removed only with explicit evidence | SATISFIED | D-06 KEEP determination: no CIDX-05 demotion bar met for any of 15 specs |
| 5. Browser/demo failure output includes exact URLs, commands, and artifact paths for local reproduction | SATISFIED | D-04: verify.sh failure block; D-05: CI upload makes playwright-report/ accessible in GitHub Actions UI |

## Deviations from Plan

None — plan executed exactly as written. Task 3 SHA checkpoint was pre-resolved by the orchestrator (SHA `ea165f8d65b6e75b540449e92b4886f43607fa02` confirmed for v4.6.2). All three file edits match the exact target state specified in RESEARCH.md and PATTERNS.md.

## Issues Encountered

None. The plan's pre-research documented exact current state and precise diffs; all edits matched without drift.

## User Setup Required

None — no external service configuration required. The upload-artifact action uses the repo's default `GITHUB_TOKEN` permissions for artifact upload (no explicit token configuration needed).

## Next Phase Readiness

- Phase 122 is complete. All ROADMAP success criteria are satisfied.
- Phase 123 (DX + closeout proof) may cite D-03/D-06 audit evidence from this SUMMARY for contributor-command closeout metrics.
- `release_gate` is unaffected. The `integration-placeholder` job behavior is unchanged for green runs; failure runs now have accessible artifacts in the GitHub Actions UI.

## Self-Check: PASSED

- FOUND: examples/demo/frontend/playwright.config.ts
- FOUND: scripts/demo/verify.sh
- FOUND: .github/workflows/ci.yml
- FOUND: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-01-SUMMARY.md
- FOUND: commit 0c2b021 (Task 1 — playwright.config.ts)
- FOUND: commit 542d048 (Task 2 — verify.sh)
- FOUND: commit cbdb7c1 (Task 4 — ci.yml)
- All grep/YAML verification checks passed

---
*Phase: 122-browser-demo-integration-determinism*
*Completed: 2026-06-17*
