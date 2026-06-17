# Phase 122: Browser/Demo/Integration Determinism - Research

**Researched:** 2026-06-16
**Domain:** Playwright config, shell-script ergonomics, GitHub Actions CI YAML
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Fix `playwright.config.ts`: `trace: 'retain-on-failure'`, add `screenshot: 'only-on-failure'`, add `video: 'retain-on-failure'`, add `reporter: [['html', { open: 'never' }], ['list']]`. Keep `retries: 0`. No CI retries.
- **D-02:** Do NOT add a Playwright `webServer` block. `baseURL`/ports stay env-driven (`DEMO_FRONTEND_URL`/`DEMO_BACKEND_URL`, dynamic from `compose-env.sh`).
- **D-03:** Do NOT rework demo-script readiness. `wait_for_health` polling and `retry_command` are legitimate, not flake-hiding sleeps. Record audit evidence, don't churn.
- **D-04:** Fix `scripts/demo/verify.sh` failure ergonomics — on Playwright failure print exact frontend/backend URL values, local rerun command (`npx playwright show-report` + `npm run test:e2e`), artifact paths (`examples/demo/frontend/playwright-report/` and `test-results/`).
- **D-05:** Add CI `upload-artifact` step (`if: failure()`) for `playwright-report/` and `test-results/` on `integration-placeholder` job in `.github/workflows/ci.yml`. Use a pinned action SHA matching repo's existing posture.
- **D-06:** ALL specs are KEEP. No CIDX-05 demotion evidence exists.

### Claude's Discretion

- Exact `upload-artifact` action pin/version (consistent with repo's pinned-action posture)
- Precise wording of the `verify.sh` failure block
- Whether to bundle D-01/D-04/D-05 into one or multiple plans — provided every decision above is honored and `release_gate` stays green at each commit

### Deferred Ideas (OUT OF SCOPE)

- Any spec demotion/removal — no concrete redundancy evidence meets the CIDX-05 bar
- Contributor-command docs, CI failure-triage table, before/after closeout metrics — Phase 123
- Workflow topology / cache keys (Phase 120, done), core Mix/ExUnit async (Phase 121, done)
- FleetDesk product UI/brand/design-system expansion
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CIDX-05 | Maintainer can fix, demote, rewrite, or remove the lowest-signal redundant or flaky checks only when the audit records concrete evidence. | D-01 fixes the root-cause trace/retry mismatch; D-03 records audit evidence of sound readiness; D-06 records that all 15 specs are role-distinct with no redundancy evidence. No spec is demoted. |
</phase_requirements>

---

## Summary

Phase 122 is a small, surgical CI/CD reliability fix — three narrow changes plus an audit evidence record — with no product runtime impact. The Phase 119 audit pre-identified the root cause: `playwright.config.ts` configures `trace: "on-first-retry"` against `retries: 0`, so traces are configured for a retry that never fires and no HTML report directory is created for CI to upload. The fix is D-01 (align the config), D-04 (print actionable failure output in `verify.sh`), and D-05 (upload the now-existing report in CI). D-03 records that demo-script readiness is already sound and needs no change. D-06 records that all 15 specs are role-distinct and no CIDX-05 demotion bar is met.

All changes touch exactly three files: `examples/demo/frontend/playwright.config.ts`, `scripts/demo/verify.sh`, and `.github/workflows/ci.yml`. No product code, no spec changes, no schema migrations. The `release_gate` aggregate job must stay green after each commit.

**Primary recommendation:** Apply D-01 config patch + D-04 verify.sh failure block + D-05 CI artifact upload as a single tightly-scoped commit (or up to three sequential commits, each CI-green). Record D-03 audit evidence in phase artifacts for Phase 123 closeout.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Playwright artifact config (trace/video/screenshot/reporter) | Frontend test config | — | `playwright.config.ts` controls all artifact behavior; no runtime tier involved |
| Demo stack readiness (health polling, port allocation) | Shell scripts (`smoke.sh`, `compose-env.sh`) | Docker Compose | External Compose stack owns readiness; Playwright consumes env-supplied URLs — do not duplicate |
| Browser test invocation and failure output | Shell scripts (`verify.sh`) | CI YAML | `verify.sh` is the single invocation point; CI calls it via `integration_placeholder.sh` |
| CI artifact upload / retention | CI YAML (`ci.yml`) | GitHub Actions runtime | Upload step belongs on the `integration-placeholder` job that owns the browser run |
| Artifact hygiene (no committed baselines) | Frontend `.gitignore` + spec guard | Root `.gitignore` | `.gitignore` ignores dirs; `ui-matrix.spec.ts` self-enforcing guard prevents source-level regression |

---

## Standard Stack

No external packages are installed in this phase. Changes are limited to config/shell/CI YAML. The relevant tooling is already installed:

| Tool | Version | Role | Source |
|------|---------|------|--------|
| `@playwright/test` | `^1.56.1` (resolved: `1.56.1`) | Playwright test runner | `examples/demo/frontend/package.json:19` |
| `actions/upload-artifact` | v4.6.2 (SHA `ea165f8d65b6e75b540449e92b4886f43607fa02`) | CI artifact upload | actions/upload-artifact GitHub releases [CITED: github.com/actions/upload-artifact/releases] |

### No Package Installs

This phase installs zero new packages. The Package Legitimacy Audit section is omitted accordingly.

---

## Package Legitimacy Audit

Omitted — no new packages are installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
[CI: integration-placeholder job]
         |
         v
[scripts/ci/integration_placeholder.sh]   (thin wrapper)
         |
         v
[scripts/demo/verify.sh]
  ├── smoke.sh  (Compose start + Docker health polling)
  ├── compose-env.sh  (dynamic free-port allocation)
  ├── demo_export_urls_from_compose  (sets DEMO_FRONTEND_URL / DEMO_BACKEND_URL)
  ├── npm ci  (install frontend deps)
  ├── npx playwright install chromium
  └── npm run test:e2e  (→ playwright test, reads env URLs)
         |                              |
         v (success)                   v (failure — D-04 adds this)
[echo "passed"]              [print DEMO_FRONTEND_URL, DEMO_BACKEND_URL]
                             [print: npx playwright show-report]
                             [print: npm run test:e2e]
                             [print: artifact paths playwright-report/ test-results/]
                             [exit non-zero → CI job fails]
         |
         v (D-05: always/failure)
[actions/upload-artifact]
  ├── examples/demo/frontend/playwright-report/
  └── examples/demo/frontend/test-results/
```

### Recommended Project Structure

No structural changes to directories. Edits target three existing files:

```
examples/demo/frontend/
└── playwright.config.ts        # D-01: trace/video/screenshot/reporter changes

scripts/demo/
└── verify.sh                   # D-04: failure-output ergonomics

.github/workflows/
└── ci.yml                      # D-05: upload-artifact step on integration-placeholder
```

---

## D-01: Playwright Config — Exact Current State and Precise Diff

### Current `playwright.config.ts` (all 21 lines)

```typescript
import { defineConfig } from "@playwright/test";

const frontendUrl = process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000";
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: false,
  use: {
    baseURL: frontendUrl,
    trace: "on-first-retry",
  },
  metadata: {
    frontendUrl,
    backendUrl,
  },
});
```

**Key line numbers (current):**
- Line 3: `DEMO_FRONTEND_URL` env read (D-02 evidence — do not change)
- Line 4: `DEMO_BACKEND_URL` env read (D-02 evidence — do not change)
- Line 10: `retries: 0` — KEEP (D-01, D-02, D-06)
- Line 15: `trace: "on-first-retry"` — CHANGE to `"retain-on-failure"` (D-01)
- No `reporter:` key — ADD (D-01)
- No `screenshot:` key — ADD inside `use:` (D-01)
- No `video:` key — ADD inside `use:` (D-01)
- No `webServer:` key — intentionally absent (D-02)

**CIDX line-number drift note:** CONTEXT.md cites `playwright.config.ts:10,15` for `retries` and `trace`. Confirmed: `retries: 0` is line 10, `trace: "on-first-retry"` is line 15. No drift.

### Target `playwright.config.ts` (post-D-01)

```typescript
import { defineConfig } from "@playwright/test";

const frontendUrl = process.env.DEMO_FRONTEND_URL ?? "http://127.0.0.1:3000";
const backendUrl = process.env.DEMO_BACKEND_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: false,
  reporter: [["html", { open: "never" }], ["list"]],
  use: {
    baseURL: frontendUrl,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  metadata: {
    frontendUrl,
    backendUrl,
  },
});
```

**Diff summary:**
- Line 13: INSERT `reporter: [["html", { open: "never" }], ["list"]],`
- Line 15: `trace: "on-first-retry"` → `trace: "retain-on-failure"`
- Lines 16-17: INSERT `screenshot: "only-on-failure",` and `video: "retain-on-failure",`

### Version confirmation for `@playwright/test@^1.56.1`

`npm view @playwright/test@1.56.1 version` returns `1.56.1` — package exists on registry. [VERIFIED: npm registry]

Playwright `retain-on-failure` for `trace` was introduced in Playwright v1.15 (June 2021). `retain-on-failure` for `video` and `only-on-failure` for `screenshot` have been stable since v1.12 (May 2021). All three modes are fully supported in v1.56.1. [CITED: https://playwright.dev/docs/test-configuration#use-options]

`html` reporter with `{ open: 'never' }` is the standard reporter config for headless/CI environments and has been stable since v1.10+. [CITED: https://playwright.dev/docs/test-reporters#html-reporter]

### Default artifact output directories

Playwright HTML reporter writes to `playwright-report/` by default (relative to config file location). `test-results/` is the default `outputDir` for test artifacts (screenshots, traces, videos). Both are relative to `examples/demo/frontend/` (where `playwright.config.ts` lives).

From the repo root, the paths are:
- `examples/demo/frontend/playwright-report/`
- `examples/demo/frontend/test-results/`

Both are confirmed ignored in `examples/demo/frontend/.gitignore` (lines 4-5).

---

## D-04: verify.sh — Exact Current State and Minimal Change

### Current `verify.sh` (all 44 lines)

The Playwright invocation is lines 38-42:

```bash
echo "[verify] running FleetDesk adoption lab browser proof (kill switch + journeys)"
(
  cd examples/demo/frontend
  CI=true DEMO_BACKEND_URL="$DEMO_BACKEND_URL" DEMO_FRONTEND_URL="$DEMO_FRONTEND_URL" npm run test:e2e
)
```

**Current problem:** The subshell exits non-zero on Playwright failure. `set -euo pipefail` at line 2 propagates the exit, but no failure handler prints any contextual information before propagation. The operator sees a raw exit code, nothing else.

**Existing cleanup trap (line 14):** `trap cleanup EXIT INT TERM` where `cleanup` (lines 10-12) calls `docker compose down --remove-orphans`. This trap fires on any exit. The D-04 fix must NOT replace or disable this trap.

**Env vars in scope at line 41:** `DEMO_BACKEND_URL` and `DEMO_FRONTEND_URL` are set by `demo_export_urls_from_compose` (line 18), which reads actual allocated ports from the running Compose stack. They contain the real URLs at test time (e.g., `http://127.0.0.1:PORT`).

**`test:e2e` script:** `package.json` line 10: `"test:e2e": "playwright test"` — this is the command that runs all specs via `playwright.config.ts`.

### Minimal change for D-04 (failure output, success path untouched)

Replace lines 38-42 with:

```bash
echo "[verify] running FleetDesk adoption lab browser proof (kill switch + journeys)"
(
  cd examples/demo/frontend
  CI=true DEMO_BACKEND_URL="$DEMO_BACKEND_URL" DEMO_FRONTEND_URL="$DEMO_FRONTEND_URL" npm run test:e2e
) || {
  echo ""
  echo "[verify] Playwright failed."
  echo "  Frontend URL : ${DEMO_FRONTEND_URL}"
  echo "  Backend URL  : ${DEMO_BACKEND_URL}"
  echo "  Artifacts    : examples/demo/frontend/playwright-report/"
  echo "                 examples/demo/frontend/test-results/"
  echo "  Local report : cd examples/demo/frontend && npx playwright show-report"
  echo "  Local rerun  : cd examples/demo/frontend && npm run test:e2e"
  echo ""
  exit 1
}
```

**Why this approach:**
- The subshell `( ... )` runs exactly as before; `|| { ... }` only fires on non-zero exit.
- `exit 1` inside the `|| {}` block propagates to the outer shell, which triggers the existing `trap cleanup EXIT` — Docker cleanup still runs.
- The success path (`echo "[verify] compose smoke and browser proof passed"` at line 44) is completely unaffected.
- `DEMO_FRONTEND_URL` and `DEMO_BACKEND_URL` are guaranteed to be set (they were exported at line 18); even if empty the print is informative.
- The artifact paths are relative to repo root — matching what D-05 uploads and what CI would display.

---

## D-05: CI Artifact Upload — Exact Current State and Required Change

### Current `integration-placeholder` job (ci.yml lines 188-200)

```yaml
integration-placeholder:
  name: integration (FleetDesk adoption lab)
  needs: changes
  if: needs.changes.outputs.docs-only != 'true'
  runs-on: ubuntu-24.04
  timeout-minutes: 45
  steps:
    - uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
    - uses: actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e # v6.4.0
      with:
        node-version: "22"
    - name: Run FleetDesk adoption lab (compose + Playwright)
      run: scripts/ci/integration_placeholder.sh
```

**No artifact upload step exists currently.** When the Playwright run fails, `playwright-report/` and `test-results/` are created inside the runner's workspace then discarded at job end.

### `actions/upload-artifact` pin to use (D-05)

The repo's existing pinned-action convention: `uses: org/action@<full-40-char-sha> # vX.Y.Z`

No `upload-artifact` usage exists anywhere in `.github/workflows/`. The planner must introduce the first pin.

**Current latest stable v4:** `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2`
[CITED: https://github.com/actions/upload-artifact/releases — v4.6.2, released 2025-03-19]

**`if:` condition:** Use `if: failure()` — upload artifacts only when the job has a failing step. This is appropriate because:
- On green runs, no `playwright-report/` HTML content is generated (only `test-results/` dir exists but is empty of interesting content).
- D-01 configures `trace: 'retain-on-failure'` — traces only appear on failure.
- Using `if: failure()` rather than `if: always()` avoids uploading empty/trivial artifacts on green runs and prevents unnecessary storage consumption.
- The `integration-placeholder` job has `timeout-minutes: 45` — on success the 45-min window is used; uploading empty artifacts on every green run wastes storage.

**Upload paths (relative to repo root, i.e., `$GITHUB_WORKSPACE`):**

```
examples/demo/frontend/playwright-report/
examples/demo/frontend/test-results/
```

These are the exact paths where Playwright emits output when run from the repo root via `verify.sh` (which `cd`s to `examples/demo/frontend` for the npm commands, but the reporter resolves paths relative to `playwright.config.ts` location).

### Required step to add

Append after line 200 (after the `Run FleetDesk adoption lab` step):

```yaml
    - name: Upload Playwright report and test artifacts
      if: failure()
      uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2
      with:
        name: playwright-report-${{ github.run_id }}
        path: |
          examples/demo/frontend/playwright-report/
          examples/demo/frontend/test-results/
        retention-days: 7
        if-no-files-found: ignore
```

**Rationale for each field:**
- `name: playwright-report-${{ github.run_id }}` — unique per run, avoids collisions across retries/reruns; human-readable in the Actions UI.
- `path:` — two paths matching the D-01 reporter and artifact defaults.
- `retention-days: 7` — short retention for debug artifacts (no compliance retention needed); consistent with ephemeral CI debug posture.
- `if-no-files-found: ignore` — prevents the step from failing if the reporter didn't create the directory (e.g., job was cancelled before Playwright ran).

**`release_gate` safety:** The upload step is conditional (`if: failure()`), so it runs only when the job is already failing. It cannot cause a previously-green `integration-placeholder` job to fail. The `release_gate` job reads `needs['integration-placeholder'].result`, which reflects the job's overall outcome. A passing `upload-artifact` step after a failed main step does NOT change the job result from `failure` to `success` — the job result is determined by the failing `Run FleetDesk adoption lab` step. [ASSUMED — based on standard GitHub Actions behavior; the job result is set by the first failing step, not subsequent `if: failure()` steps]

### `integration_placeholder.sh` structure (confirmed)

```bash
#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
cd "${RULESTEAD_REPO}"
scripts/demo/verify.sh
```

This is a thin wrapper — three meaningful lines. No changes needed here for D-04 or D-05.

---

## D-03 Audit Evidence (Record, Do Not Change)

### Demo script readiness — confirmed sound

`smoke.sh` implements real Docker health polling (not fixed sleeps):
- `wait_for_health` polls `docker inspect ... .State.Health.Status` (grep-confirmed in CONTEXT.md citing `smoke.sh:25-47`)
- `sleep 2` calls inside bounded polling loops — not free-standing sleeps
- `retry_command` retries curl probes against an eventually-consistent seeded backend (`smoke.sh:49-64`)
- Cleanup traps on every script with `dump_failure_logs`

**Zero `waitForTimeout`/`setTimeout` in any spec** — confirmed by grep: `grep -rn "waitForTimeout\|setTimeout" examples/demo/frontend/tests/` → no output.

This evidence record satisfies CIDX-05's "audit records concrete evidence" requirement for D-03's "no rework needed" conclusion.

---

## D-06: Spec Inventory — All 15 Specs Are KEEP

### Actual count

**15 specs** — CONTEXT.md's "17+" was an approximation. The correct count is 15 (confirmed by `ls examples/demo/frontend/tests/*.spec.ts`).

### Inventory

**Functional journeys (live browser, real Compose stack):**

| Spec | Tests | Role |
|------|-------|------|
| `00-demo-toggle.spec.ts` | 1 | Kill switch sign-in + toggle + frontend refresh loop |
| `adoption-journeys.spec.ts` | 5 | FleetDesk persona journeys (feature flag evaluation) |
| `rollout-advance.spec.ts` | 1 | Staged percentage rule surface for fleet-map-v2 flag |
| `guarded-rollout.spec.ts` | 1 | Guardrail copy in rollout panel |
| `flag-inventory.spec.ts` | 1 | Admin flag inventory lists adoption-lab seeds |
| `audit-timeline.spec.ts` | 1 | Audit timeline after kill switch activity |
| `explain-admin.spec.ts` | 1 | Admin explain permalink / support-safe trace |
| `theme-control.spec.ts` | 11 | Dark/light/system theme control on shell |
| `theme-cascade.spec.ts` | 5 | Token cascade without OS attr |
| `theme-scope.spec.ts` | 3 | Token scoping (`:root` isolation) |

**Visual-evidence matrices (screenshot artifacts for human review):**

| Spec | Tests | Role |
|------|-------|------|
| `ui-matrix.spec.ts` | 10 | Admin UI multi-viewport/theme matrix + anti-baseline guard |
| `brand-ui-evidence.spec.ts` | 5 | Brand-faithful UI evidence (logo, tokens, design fidelity) |
| `admin-flow-ia.spec.ts` | 9 | Admin route IA evidence |
| `design-system.spec.ts` | 10 | Color contrast (AA) + static token assertions |
| `brandbook.spec.ts` | 15 | Brandbook HTML landmarks + sections via `file://` |

**Total: 15 specs, 79 test cases across 5 distinct concern areas.**

### Redundancy verdict (CIDX-05)

No two specs cover the same assertion surface. Functional journeys use distinct user-persona flows through distinct app surfaces. Visual-evidence specs write to `testInfo.outputPath(...)` (ignored `test-results/`) and cover non-overlapping UI components. `brandbook.spec.ts` uses `file://` against a static HTML file — a completely different target from the live Compose stack. **No CIDX-05 demotion evidence exists. D-06 KEEP posture confirmed.**

---

## Artifact Hygiene Proof (D-05 Evidence)

### `.gitignore` coverage

`examples/demo/frontend/.gitignore` (5 lines total):
```
.next
node_modules
coverage
test-results/
playwright-report/
```

Both artifact directories are explicitly ignored. [VERIFIED: file read]

Root `.gitignore` does not ignore test-results/playwright-report by path (browser artifacts are scoped to the frontend package; root ignores cover planning-phase scratch renders). No gap.

### Committed artifact check

`git ls-files -- 'examples/demo/frontend/test-results' 'examples/demo/frontend/playwright-report'` → no output (zero committed files in those paths). [VERIFIED: git ls-files]

`git ls-files -- '*.png' ...` returns only `.planning/milestones/` logo tournament specimens — no browser test artifacts from Playwright. [VERIFIED: git ls-files]

### Anti-baseline guard (ui-matrix.spec.ts:401-411)

```typescript
test("matrix spec keeps screenshots as artifacts without source baselines", () => {
  const source = fs.readFileSync(
    path.resolve(__dirname, "ui-matrix.spec.ts"),
    "utf8",
  );
  for (const term of forbiddenSourceTerms) {
    expect(source.includes(term)).toBe(false);
  }
});
```

`forbiddenSourceTerms` (lines 72-81) contains: `"toHaveScreenshot"`, `"matchSnapshot"`, `"pixelmatch"`, `"visual-diff"`, `"pixel-baseline"`, `"Storybook"`, `"PhoenixStorybook"`, `"phoenix_storybook"`. The test reads `ui-matrix.spec.ts` at runtime and asserts none of these terms appear in the source. Self-enforcing: it would fail itself if a baseline term were introduced. [VERIFIED: file read, lines 72-81, 401-411]

---

## Common Pitfalls

### Pitfall 1: Overwriting the cleanup trap in verify.sh

**What goes wrong:** Replacing `trap cleanup EXIT INT TERM` with a new trap to print failure output removes Docker cleanup on exit.
**Why it happens:** Bash traps are replaced, not stacked, by default.
**How to avoid:** Use `|| { ... ; exit 1 }` on the subshell as described in D-04 — the existing trap remains untouched, fires on `exit 1`, and handles Docker teardown.
**Warning signs:** If `docker compose ps` shows containers still running after a test failure.

### Pitfall 2: Wrong upload paths in CI (relative vs absolute)

**What goes wrong:** Specifying `playwright-report/` without the `examples/demo/frontend/` prefix causes `upload-artifact` to look in the repo root, finds nothing, and warns/fails.
**Why it happens:** `verify.sh` `cd`s into `examples/demo/frontend` for the npm commands, but the CI step runs from `$GITHUB_WORKSPACE` (repo root). Playwright resolves output dirs relative to `playwright.config.ts` — so from the repo root the paths are `examples/demo/frontend/playwright-report/` and `examples/demo/frontend/test-results/`.
**How to avoid:** Use repo-root-relative paths in the `path:` field of `upload-artifact`. Include `if-no-files-found: ignore` as a safety net.
**Warning signs:** `upload-artifact` step logs "No files were found with the provided path" even after a failed Playwright run.

### Pitfall 3: `if: always()` instead of `if: failure()` causes storage bloat

**What goes wrong:** Uploading artifacts on every run creates large artifact packages for the majority of green runs where `playwright-report/` contains only an empty HTML shell.
**Why it happens:** D-01 sets `trace: 'retain-on-failure'` — no trace files on green. With `if: always()`, the upload fires on green and uploads an empty/trivial report.
**How to avoid:** Use `if: failure()`. On failure, the D-01 config ensures traces, screenshots, and video are present. On success, skip the upload entirely.

### Pitfall 4: `retries` creep — do not add retries to mask CI failures

**What goes wrong:** Adding `retries: 1` to get `trace: 'on-first-retry'` working masks genuine browser flake with a blind retry, obscuring signal.
**Why it happens:** It seems like "fixing" the mismatch differently. It violates the phase's No-Go guardrail from `119-CI-CD-AUDIT.md:~284-309`.
**How to avoid:** Keep `retries: 0` and change `trace` to `'retain-on-failure'`. The artifact fix gives debuggability; retries hide flakes.
**Warning signs:** Any PR that changes `retries:` to a non-zero value must be rejected.

### Pitfall 5: spec count discrepancy in CONTEXT.md

**What goes wrong:** CONTEXT.md cites "17+ role-distinct specs." The actual count is 15.
**Why it happens:** An earlier draft counted an approximation. The planner should use the verified count of 15.
**How to avoid:** The D-06 inventory above lists all 15 specs. The planner's task descriptions should use 15, not 17+.

---

## Validation Architecture

Changes in this phase are config, shell, and CI YAML — no product runtime code. Verification is static/structural rather than test-suite execution.

### Per-Change Verification

| Change (Decision) | Verification Method | Command / Check |
|-------------------|--------------------|---------------------------------|
| D-01: `playwright.config.ts` trace/video/screenshot/reporter | Grep assert correct values present, old value absent | `grep "retain-on-failure" examples/demo/frontend/playwright.config.ts` (3 hits); `grep -v "on-first-retry" examples/demo/frontend/playwright.config.ts` (zero hits) |
| D-01: reporter key added | Grep assert `reporter` present with `html`/`list` | `grep 'reporter.*html.*never' examples/demo/frontend/playwright.config.ts` |
| D-01: `retries: 0` unchanged | Grep assert retries still zero | `grep 'retries: 0' examples/demo/frontend/playwright.config.ts` |
| D-02: no `webServer` added | Grep assert no `webServer` key | `grep -c "webServer" examples/demo/frontend/playwright.config.ts` → `0` |
| D-04: verify.sh failure block | Grep assert failure-output lines present | `grep "playwright show-report" scripts/demo/verify.sh`; `grep "DEMO_FRONTEND_URL" scripts/demo/verify.sh` (2 hits — env read + failure print) |
| D-04: cleanup trap intact | Grep assert `trap cleanup` still present | `grep "trap cleanup" scripts/demo/verify.sh` |
| D-05: upload-artifact step added | YAML parse + grep | `grep "upload-artifact" .github/workflows/ci.yml`; `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` → no parse error |
| D-05: upload step scoped to failure | Grep assert `if: failure()` on the step | `grep -A1 "Upload Playwright" .github/workflows/ci.yml | grep "failure()"` |
| D-05: paths correct | Grep assert `examples/demo/frontend/playwright-report` | `grep "examples/demo/frontend/playwright-report" .github/workflows/ci.yml` |
| D-05: SHA pinned | Grep assert full SHA used (not `@v4` tag alone) | `grep "upload-artifact@" .github/workflows/ci.yml | grep -v "@ea165f8"` → zero hits |
| Artifact hygiene preserved | git ls-files check | `git ls-files -- 'examples/demo/frontend/test-results' 'examples/demo/frontend/playwright-report'` → zero output |
| Anti-baseline guard intact | Spec itself will assert at runtime | `grep "forbiddenSourceTerms" examples/demo/frontend/tests/ui-matrix.spec.ts` — present |

### Sampling Rate

- **Per-task commit:** Run the grep/assert static checks listed above — all take under 5 seconds total.
- **Full CI gate:** The `integration-placeholder` CI job (`ci.yml`) is the integration validation; it must stay green (or fail only due to a genuine browser test failure, not a YAML/config error).
- **Phase gate:** All static checks pass + `release_gate` green before Phase 123.

### Wave 0 Gaps

None — no new test files are needed. All verification is via grep/static assertions on the changed files. The `ui-matrix.spec.ts:401-411` anti-baseline guard runs as part of the existing `npm run test:e2e` suite.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@playwright/test` | D-01 config validation, D-04 invocation | Already in `package.json:19` | `^1.56.1` | — |
| Docker / Compose | D-03 audit evidence (smoke.sh runs in CI) | Available on `ubuntu-24.04` GitHub runners | — | — |
| Node.js 22 | `npm ci`, Playwright install | Installed by `setup-node` in CI job | 22 (setup-node step) | — |
| `actions/upload-artifact` | D-05 CI artifact upload | Available as GitHub Action (no install needed) | v4.6.2 | — |
| `actionlint` (optional) | CI YAML linting | Not confirmed installed locally | — | `python3 -c "import yaml; yaml.safe_load(...)"` for parse check |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** `actionlint` not confirmed locally — use Python YAML parse as fallback for CI YAML structural check.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `trace: 'on-first-retry'` with `retries: 0` | `trace: 'retain-on-failure'` | This phase (D-01) | Traces fire on real failures instead of never |
| No HTML reporter (default `list`) | `reporter: [['html', { open: 'never' }], ['list']]` | This phase (D-01) | `playwright-report/` dir created on failure; uploadable by CI |
| No failure output in `verify.sh` | Print URLs + artifact paths + rerun commands on failure | This phase (D-04) | Operators can reproduce failures without grepping CI logs |
| No CI artifact upload | `upload-artifact` step on `integration-placeholder` | This phase (D-05) | Playwright report is accessible in GitHub Actions UI after failure |

**Deprecated/outdated:**
- `trace: 'on-first-retry'` in this config: produces no traces (zero retries configured). Replaced by `retain-on-failure`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub Actions job result is set by the first failing step; a passing `if: failure()` upload step after a failed run step does NOT change the job result from `failure` to `success` | D-05 CI Artifact Upload | If wrong, the release_gate would receive `success` for a genuinely failing integration job — HIGH risk, but this is standard GitHub Actions behavior; extremely unlikely to be wrong |
| A2 | `actions/upload-artifact` v4.6.2 SHA `ea165f8d65b6e75b540449e92b4886f43607fa02` is correct | D-05 | If wrong, the `uses:` line references a non-existent commit; CI would fail at job setup with a clear error (detectable immediately) |

**Note on A2:** The SHA was sourced from the releases page via WebFetch. The planner should verify this SHA against `https://github.com/actions/upload-artifact/releases/tag/v4.6.2` before committing to avoid a stale-SHA situation. [ASSUMED for exact SHA correctness — authoritative source checked but WebFetch can be stale]

---

## Open Questions

1. **`upload-artifact` SHA final verification**
   - What we know: WebFetch returned `ea165f8d65b6e75b540449e92b4886f43607fa02` for v4.6.2 (March 2025)
   - What's unclear: Whether a newer v4.x point release exists (v4.6.3+) that the planner should prefer
   - Recommendation: Implementer should run `curl -s https://api.github.com/repos/actions/upload-artifact/releases/latest | jq '.tag_name,.target_commitish'` to confirm the latest v4 SHA before writing the YAML step. Any v4.x SHA is acceptable; use the latest stable.

2. **`if: failure()` vs `if: always()` final call**
   - What we know: D-05 says "`if: failure()` or `if: always()`"; the research recommends `if: failure()` for the reasons above
   - What's unclear: The CONTEXT.md deliberately left both as acceptable
   - Recommendation: Use `if: failure()` — avoids storage waste on green runs and is semantically correct for debug artifacts

---

## Sources

### Primary (HIGH confidence)
- `examples/demo/frontend/playwright.config.ts` — read in full; all line numbers verified [VERIFIED: file read]
- `examples/demo/frontend/package.json` — `@playwright/test@^1.56.1` confirmed at line 19 [VERIFIED: file read]
- `scripts/demo/verify.sh` — read in full; all lines 1-44 verified [VERIFIED: file read]
- `.github/workflows/ci.yml` — read in full; `integration-placeholder` job lines 188-200 verified [VERIFIED: file read]
- `scripts/ci/integration_placeholder.sh` — read in full [VERIFIED: file read]
- `examples/demo/frontend/.gitignore` — 5 lines, `test-results/` and `playwright-report/` confirmed [VERIFIED: file read]
- `.gitignore` — root ignore file read; no frontend artifact entries [VERIFIED: file read]
- `examples/demo/frontend/tests/ui-matrix.spec.ts` — anti-baseline guard at lines 401-411 confirmed [VERIFIED: file read + grep]
- `git ls-files` output — zero committed browser artifacts in `examples/demo/frontend/` paths [VERIFIED: shell command]
- `npm view @playwright/test@1.56.1 version` → `1.56.1` [VERIFIED: npm registry]

### Secondary (MEDIUM confidence)
- `actions/upload-artifact` v4.6.2 SHA `ea165f8d65b6e75b540449e92b4886f43607fa02` [CITED: github.com/actions/upload-artifact/releases via WebFetch]
- Playwright `retain-on-failure` trace mode availability since v1.15 [CITED: playwright.dev/docs/test-configuration]
- Playwright `html` reporter `{ open: 'never' }` CI pattern [CITED: playwright.dev/docs/test-reporters#html-reporter]

### Tertiary (LOW confidence)
- None — all critical claims verified via file read or official source.

---

## Metadata

**Confidence breakdown:**
- Playwright config changes (D-01): HIGH — exact current file read, version confirmed on npm registry, options are well-established Playwright stable APIs
- verify.sh ergonomics (D-04): HIGH — full file read, exact bash semantics of `|| { ... }` well-established
- CI artifact upload (D-05): HIGH for YAML structure; MEDIUM for exact SHA (sourced from WebFetch, planner should re-verify before commit)
- Spec inventory (D-06): HIGH — directory listing + test count confirmed by file system
- `release_gate` safety (D-05): HIGH (assumption A1) — standard GitHub Actions behavior

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (stable tooling; Playwright and GitHub Actions APIs change slowly)
