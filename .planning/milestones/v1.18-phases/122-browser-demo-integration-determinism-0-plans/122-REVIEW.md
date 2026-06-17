---
phase: 122-browser-demo-integration-determinism
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - examples/demo/frontend/playwright.config.ts
  - scripts/demo/verify.sh
  - .github/workflows/ci.yml
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: clean
---

# Phase 122: Code Review Report

**Reviewed:** 2026-06-16T00:00:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** clean

## Summary

Reviewed the three Phase 122 determinism changes: the Playwright config trace/reporter
hardening, the `verify.sh` failure-output block, and the SHA-pinned `upload-artifact`
step added to the `integration-placeholder` job in `ci.yml`. All focus-area requirements
hold. No correctness, security, or robustness defects were found. Two Info-level
observations are recorded below; neither blocks shipping.

Adversarial verification performed:

- **ci.yml `upload-artifact` step.** SHA-pinned to
  `@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2` (no floating tag). Scoped with
  `if: failure()`. `path:` is limited to `examples/demo/frontend/playwright-report/` and
  `examples/demo/frontend/test-results/` — no secrets, env dumps, or extra paths.
  `if-no-files-found: ignore` is present so an early-stage failure (before any report is
  produced) does not itself fail the upload step. Indentation (6 spaces for the step key,
  8 for `with`, 10 for list items) matches the sibling `checkout`/`setup-node`/`run`
  steps and is valid YAML inside `integration-placeholder.steps`.
- **release_gate isolation (the load-bearing concern).** Confirmed the added step cannot
  flip the job conclusion. GitHub Actions sets a job's conclusion to `failure` whenever any
  non-`continue-on-error` step fails; a later step gated on `if: failure()` runs *because*
  of that failure, and its own success does not override the conclusion. `release_gate`
  reads `needs['integration-placeholder'].result` (line 334), which remains `failure` after
  a failing `integration_placeholder.sh` run regardless of the upload step's outcome. The
  step has no `continue-on-error` and no `id`/output that the gate consults. Safe.
- **verify.sh failure block.** Uses the `) || { …; exit 1; }` idiom (lines 42–53), so the
  non-zero exit of the `npm run test:e2e` subshell is caught and re-propagated via explicit
  `exit 1`. The pre-existing `trap cleanup EXIT INT TERM` (line 14) is untouched and still
  fires on the `exit 1`, so compose teardown still runs on failure. The success path
  (`echo "[verify] compose smoke and browser proof passed"`) is unchanged. All interpolated
  variables in the failure block are quoted (`${DEMO_FRONTEND_URL}`, `${DEMO_BACKEND_URL}`).
  `shellcheck` reports nothing on the changed lines (the two pre-existing SC1007/SC1091
  notices are out of scope and benign).
- **playwright.config.ts.** `retries: 0` retained (no flake-hiding). No `webServer` block
  introduced. Valid `defineConfig({...})` shape. `reporter: [["html", { open: "never" }],
  ["list"]]`, `trace: "retain-on-failure"`, `screenshot: "only-on-failure"`, and
  `video: "retain-on-failure"` are all valid values for `@playwright/test ^1.56.1`
  (confirmed against the declared dependency in `examples/demo/frontend/package.json`).

## Info

### IN-01: Artifact paths are config-implicit, not explicitly pinned

**File:** `examples/demo/frontend/playwright.config.ts:13` / `.github/workflows/ci.yml:206-208`
**Issue:** The upload step and the `verify.sh` failure message both reference
`playwright-report/` and `test-results/`, but the Playwright config does not explicitly set
`outputDir` (it relies on the framework default `test-results/`) and the HTML reporter does
not set `outputFolder` (defaulting to `playwright-report/`). The paths happen to match the
defaults, so this works today, but the coupling between the CI upload paths and Playwright's
implicit defaults is undocumented. A future Playwright major that changes a default, or a
config edit that sets a custom `outputDir`, would silently produce empty artifacts (masked
by `if-no-files-found: ignore`).
**Fix:** Optionally make the contract explicit to harden against drift:
```ts
// playwright.config.ts
reporter: [["html", { open: "never", outputFolder: "playwright-report" }], ["list"]],
outputDir: "test-results",
```
No change required for correctness; this is a future-proofing note.

### IN-02: `if-no-files-found: ignore` can mask a "no artifacts produced" failure

**File:** `.github/workflows/ci.yml:210`
**Issue:** `ignore` is the correct choice to keep the upload step from failing when the run
crashes before any report is written. The trade-off is that a misconfiguration where reports
are *never* emitted (wrong path, disabled reporter) would surface as a silently empty/absent
artifact rather than a `warn`. Given the goal is failure-diagnostics-only and the run step
already failed, this is an acceptable trade-off — recorded only so the choice is intentional
and visible.
**Fix:** No change needed. If stronger signal is later desired, `warn` annotates the run log
without failing the step.

---

_Reviewed: 2026-06-16T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
