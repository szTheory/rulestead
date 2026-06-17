# Phase 122: Browser/Demo/Integration Determinism - Context

**Gathered:** 2026-06-16 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 122 stabilizes the expensive browser, demo, integration, and generated-evidence
paths (`examples/demo/frontend/` Playwright, `scripts/demo/*.sh`, the `integration-placeholder`
FleetDesk adoption lab, generated screenshots/reports) while keeping every high-value
workflow proof intact. It turns the Phase 119 determinism findings
(`119-CI-CD-AUDIT.md`, esp. the Playwright trace/retry mismatch and the "audit by value and
determinism, not runtime alone" rule) into narrow, evidence-gated fixes: a root-cause
Playwright artifact-config fix, demo-script failure-output ergonomics, and a CI artifact-upload
step — without hiding flakes or deleting checks for being slow.

This phase does NOT: add blind retries to mask browser flakes; convert real health polling to
fixed sleeps; replace generated browser artifacts with checked-in pixel baselines; delete or
demote any check solely because it is slow; expand FleetDesk product UI/brand/design-system;
change product runtime APIs, schemas, or `rulestead_admin` publish posture; or touch workflow
topology/cache keys (Phase 120, done), core Mix/ExUnit async (Phase 121, done), or contributor
command + closeout docs (Phase 123). Demoting, rewriting, or removing any browser/demo check
requires concrete redundancy evidence (CIDX-05) — runtime alone is never deletion evidence.
</domain>

<decisions>
## Implementation Decisions

### Playwright Determinism Config (root-cause fix)
- **D-01 (Confident):** Fix the trace/retry mismatch at root cause in
  `examples/demo/frontend/playwright.config.ts`: set `trace: 'retain-on-failure'` (NOT `'on'`),
  add `screenshot: 'only-on-failure'` and `video: 'retain-on-failure'`, and add an explicit
  `reporter: [['html', { open: 'never' }], ['list']]`. **Keep `retries: 0` — do NOT add CI
  retries.** Evidence: `playwright.config.ts:10,15` pairs `retries: 0` with
  `trace: "on-first-retry"`, so traces are configured for a retry that never fires — the exact
  defect flagged in `119-CI-CD-AUDIT.md:~278`. `@playwright/test@^1.56.1`
  (`examples/demo/frontend/package.json:19`) supports `retain-on-failure`. `retain-on-failure`
  preserves determinism (artifacts only on real failures, zero overhead on green) vs `'on'`,
  which would bloat the 17-spec multi-viewport/theme matrix. No reporter is configured today
  (default `list`), so no HTML report dir exists for CI to upload — adding `html` is the
  load-bearing repro change. Keeping `retries: 0` honors the No-Go guardrail against hiding
  flakes (specs already use web-first `expect().toBeVisible({ timeout })`, e.g.
  `adoption-journeys.spec.ts:18`, `00-demo-toggle.spec.ts:9,27`). Success criteria #2, #3, #5.
- **D-02 (Confident):** Do NOT add a `webServer` block to the Playwright config. The external
  Compose stack started by `smoke.sh`/`verify.sh` remains the readiness authority, and
  `baseURL`/ports stay env-driven. Evidence: `playwright.config.ts:3-4,14` reads
  `DEMO_FRONTEND_URL`/`DEMO_BACKEND_URL` from env with `127.0.0.1` fallbacks;
  `verify.sh:17,41` starts the stack via `smoke.sh` (real Docker health polling,
  `smoke.sh:25-47`) before `npm run test:e2e`; ports are dynamically allocated by
  `compose-env.sh:236-264` (`demo_find_free_port`). A `webServer` block would duplicate the
  compose lifecycle and re-introduce a fixed-port assumption.

### Demo-Script Readiness, Cleanup, and Failure Ergonomics
- **D-03 (Confident):** Do NOT rework demo-script readiness. The existing `wait_for_health`
  polling and `retry_command` are legitimate health / eventual-consistency polling, not
  flake-hiding sleeps, and must NOT be converted to fixed sleeps. Evidence: `smoke.sh:25-47`
  and `proxy-smoke.sh:23-45` poll real Docker health
  (`docker inspect ... .State.Health.Status`); the `sleep 2` calls are inside bounded polling
  loops (`smoke.sh:42`); `retry_command` (`smoke.sh:49-64`) retries curl probes against an
  eventually-consistent seeded backend; cleanup traps exist on every script
  (`smoke.sh:23,89`, `verify.sh:14`, `proxy-smoke.sh:64,90`) with `dump_failure_logs`. Grep
  confirmed zero `waitForTimeout`/`setTimeout` in any spec. Success criterion #1 (audit
  confirms determinism is sound; record the evidence rather than churn it).
- **D-04 (Confident):** Fix failure-output ergonomics in `verify.sh`: when the Playwright step
  fails, print the exact frontend/backend URLs, the local rerun command
  (`npx playwright show-report` plus the `npm run test:e2e` invocation), and the artifact paths
  (`examples/demo/frontend/playwright-report/` and `test-results/`). Evidence: `verify.sh:38-42`
  wraps `npm run test:e2e` in a subshell with no failure handler, so a red run surfaces a raw
  non-zero exit with no URL, no report hint, and no artifact path. Success criterion #5.

### Artifact Hygiene and Low-Signal-Spec Evidence Posture
- **D-05 (Confident):** Artifact hygiene is sound at the source level — keep it that way and add
  the one missing piece: a CI `upload-artifact` step (`if: failure()` or `if: always()`) for
  `playwright-report/` and `test-results/` on the `integration-placeholder` job. Evidence:
  `examples/demo/frontend/.gitignore` ignores `test-results/` and `playwright-report/`;
  `git ls-files` shows zero committed `.png`/report/trace files; specs write screenshots only
  via `testInfo.outputPath(...)` (`ui-matrix.spec.ts:191`, `brand-ui-evidence.spec.ts:120`,
  `admin-flow-ia.spec.ts:185`) into ignored `test-results/`; `ui-matrix.spec.ts:401-410`
  actively asserts the source contains no `toHaveScreenshot`/`matchSnapshot`/`pixel-baseline`/
  `Storybook` terms (self-enforcing anti-baseline guard). The gap: `ci.yml:188-200`
  (`integration-placeholder` → `integration_placeholder.sh` → `verify.sh`) has NO
  artifact-upload step, so the D-01 trace/report is generated then discarded with the runner.
  Success criteria #3, #5.
- **D-06 (Confident):** Treat ALL current specs as KEEP. There is no concrete redundancy
  evidence to demote, rewrite, or remove any spec under CIDX-05. Specs are role-distinct —
  functional journeys (`adoption-journeys`, `00-demo-toggle`, `rollout-advance`,
  `guarded-rollout`, `flag-inventory`, `audit-timeline`, `explain-admin`, `theme-control`,
  `theme-cascade`, `theme-scope`) vs visual-evidence matrices (`ui-matrix`, `brand-ui-evidence`,
  `admin-flow-ia`, `design-system`, `brandbook`); no two cover the same assertion surface.
  Default to keep (success criterion #4; CIDX-05 evidence bar not met for any demotion).

### No Quarantine Needed
- The Playwright defect is a config mismatch with a clean root-cause fix (D-01), not transient
  browser flake — so no spec needs `test.fixme`/quarantine. If, during execution, a genuinely
  transient failure surfaces, quarantine it with a clear follow-up note (success criterion #2)
  rather than a blind retry.

### Planner Discretion
- The planner may choose the exact `upload-artifact` action pin/version (consistent with the
  repo's existing pinned-action posture), the precise wording of the `verify.sh` failure block,
  and whether to bundle D-01/D-04/D-05 into one or multiple plans — provided every decision
  above is honored and the `release_gate` aggregate (and the `integration-placeholder` job)
  stays green at each commit.
- The planner should record the determinism audit findings (D-03's "no rework needed" evidence)
  in the phase artifacts so Phase 123 closeout can cite them.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Ground Truth
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` — Browser/Demo/Integration
  Evidence section (~274-282), Playwright trace/retry mismatch (~278), classification matrix rows
  for `integration-placeholder`/`mounted-proof`/`scripts/demo/verify.sh`/Playwright specs/
  generated artifacts (~176-205), No-Go guardrails (~284-309), Phase 122 handoff (~21, 328-330).
- `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-CONTEXT.md` — prior
  conservatism patterns (correctness-first, scripts-first, no flake-hiding) and what 121 deferred to 122.
- `.planning/ROADMAP.md` — Phase 122 success criteria (5) + 120/121/123 scope boundary.
- `.planning/REQUIREMENTS.md` — CIDX-05 (evidence-gated demote/rewrite/remove) and out-of-scope constraints.
- `.planning/STATE.md` — strict 119→120→121→122→123 sequence and the v1.18 release-trust boundary.

### Prompt Grounding
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, proof-scope contracts, release-trust posture.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — browser/integration determinism baseline (where applicable).

### Code Surfaces (edit targets / cited)
- `examples/demo/frontend/playwright.config.ts` — trace/retry/reporter/baseURL/port config (D-01/D-02 target).
- `examples/demo/frontend/package.json` — pins `@playwright/test@^1.56.1` (confirms `retain-on-failure`/`html` availability).
- `examples/demo/frontend/tests/*.spec.ts` — 17+ role-distinct specs (D-06 keep set); `ui-matrix.spec.ts:401-410` anti-baseline guard; `*.spec.ts` screenshot writes via `testInfo.outputPath`.
- `examples/demo/frontend/.gitignore` — ignores `test-results/` + `playwright-report/` (D-05 hygiene evidence).
- `scripts/demo/verify.sh` — Playwright invocation + failure-ergonomics target (D-04); cleanup trap.
- `scripts/demo/smoke.sh`, `proxy-smoke.sh`, `compose-env.sh` — real health polling + dynamic-port allocation (D-03 evidence; do not regress).
- `scripts/ci/integration_placeholder.sh` — FleetDesk adoption-lab bridge (compose + Playwright) invoked by CI.
- `.github/workflows/ci.yml` — `integration-placeholder` job (~188-200) needs the D-05 artifact-upload step; `mounted-proof`/`openfeature-companion` proof jobs.
- `scripts/check_design_system_evidence.py` — generated-evidence/idempotence guardrail (Phase 118 lineage; do not regress).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Demo scripts already implement correct readiness: `wait_for_health` (Docker health polling) and
  `retry_command` in `smoke.sh`/`proxy-smoke.sh`, plus dynamic free-port allocation in
  `compose-env.sh` — no fixed-port races, no sleep-based readiness to fix.
- `ui-matrix.spec.ts:401-410` is a self-enforcing guard asserting no pixel-baseline/snapshot/
  Storybook terms enter the source — keep it; it already protects success criterion #3.
- Specs use web-first `expect(...).toBeVisible({ timeout })` assertions, so no `waitForTimeout`
  sleeps exist to remove (grep-confirmed zero).

### Established Patterns
- Scripts-first CI + Compose-backed demo: the external stack owns readiness; Playwright consumes
  env-supplied URLs. Do not let Playwright `webServer` duplicate the compose lifecycle.
- Correctness-first / no flake-hiding: `retries: 0` stays; artifacts are retained only on failure.
- Generated browser artifacts stay ignored, never checked-in baselines (No-Go guardrail).

### Integration Points
- The D-05 artifact-upload step must attach to the existing `integration-placeholder` job
  (`ci.yml`) without disturbing the `release_gate` aggregate Phase 120 stabilized.
- D-01's HTML reporter output is the artifact D-05 uploads and D-04 points operators to — the
  three decisions form one repro chain (config → script ergonomics → CI upload).
</code_context>

<specifics>
## Specific Ideas

- The single root cause (`trace: "on-first-retry"` + `retries: 0`) was pre-identified in the
  Phase 119 audit; Phase 122 is a small, surgical fix — config alignment, one script failure
  block, one CI upload step — plus an evidence record that demo readiness is already sound.
- Keep `retries: 0` everywhere. The whole milestone forbids hiding flakes behind blind retries;
  the artifact fix gives debuggability without sacrificing flake visibility.
</specifics>

<deferred>
## Deferred Ideas

- Any spec demotion/removal — rejected for this phase (D-06); no concrete redundancy evidence
  meets the CIDX-05 bar. Revisit only if overlap is later proven.
- Contributor-command docs, CI failure-triage table, and before/after closeout metrics — Phase 123.
- Workflow topology / cache keys (Phase 120, done) and core Mix/ExUnit async (Phase 121, done).
- FleetDesk product UI/brand/design-system expansion — out of scope; FleetDesk stays a
  host-branded example/adoption surface.

### Reviewed Todos (not folded)
- None — no pending todos matched Phase 122 scope.
</deferred>

---

*Phase: 122-browser-demo-integration-determinism-0-plans*
*Context gathered: 2026-06-16*
