---
phase: 122
slug: browser-demo-integration-determinism-0-plans
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
validated: 2026-06-17
---

# Phase 122 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase changes config + shell + CI YAML only (no product runtime code).
> Verification is **static/structural** (grep + YAML parse), not test-suite execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Static assertions (grep / `git ls-files` / Python YAML parse); existing Playwright `@playwright/test ^1.56.1` for the e2e suite |
| **Config file** | `examples/demo/frontend/playwright.config.ts` (edited by D-01); `.github/workflows/ci.yml` (edited by D-05) |
| **Quick run command** | The per-change greps in the verification map below (~5s total) |
| **Full suite command** | `bash scripts/demo/verify.sh` (Compose + Playwright integration); CI `integration-placeholder` job |
| **Estimated runtime** | Static checks ~5s; full demo/Playwright integration several minutes (CI-bound) |

---

## Sampling Rate

- **After every task commit:** Run the change's static grep/assert checks (see map). All under 5s.
- **After every plan wave:** Re-run the full static suite for changed files + `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`.
- **Before `/gsd:verify-work`:** All static checks green; `integration-placeholder` parses and (if run) fails only on genuine browser behavior, never YAML/config error.
- **Max feedback latency:** < 5 seconds for static checks.

---

## Per-Task Verification Map

| Task ID | Decision | Requirement | Verify Type | Automated Command | Status |
|---------|----------|-------------|-------------|-------------------|--------|
| D-01a | trace/video/screenshot modes | CIDX-05 | grep | `grep -c "retain-on-failure" examples/demo/frontend/playwright.config.ts` → ≥2; `grep -c "only-on-failure" …` → 1; `grep -c "on-first-retry" …` → 0 | ✅ green |
| D-01b | explicit html+list reporter | CIDX-05 | grep | `grep "reporter" examples/demo/frontend/playwright.config.ts` shows `html` + `{ open: 'never' }` + `list` | ✅ green |
| D-01c | retries unchanged (no flake-hiding) | CIDX-05 | grep | `grep "retries: 0" examples/demo/frontend/playwright.config.ts` → present | ✅ green |
| D-02 | no webServer block added | CIDX-05 | grep | `grep -c "webServer" examples/demo/frontend/playwright.config.ts` → 0 | ✅ green |
| D-03 | demo readiness unchanged (evidence recorded) | CIDX-05 | grep | `grep "wait_for_health" scripts/demo/smoke.sh` present; no diff to readiness logic | ✅ green |
| D-04a | verify.sh prints URLs + rerun + paths on failure | CIDX-05 | grep | `grep "playwright show-report" scripts/demo/verify.sh`; `grep -c "DEMO_FRONTEND_URL" scripts/demo/verify.sh` ≥2 | ✅ green |
| D-04b | cleanup trap intact | CIDX-05 | grep | `grep "trap cleanup" scripts/demo/verify.sh` → present | ✅ green |
| D-05a | upload-artifact step on integration-placeholder | CIDX-05 | grep + YAML parse | `grep "upload-artifact" .github/workflows/ci.yml`; `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` no error | ✅ green |
| D-05b | scoped to failure | CIDX-05 | grep | upload step block contains `if: failure()` | ✅ green |
| D-05c | correct paths | CIDX-05 | grep | `grep "examples/demo/frontend/playwright-report" .github/workflows/ci.yml` → present | ✅ green |
| D-05d | action SHA-pinned (repo posture) | CIDX-05, CIDX-09 | grep | `grep "upload-artifact@" .github/workflows/ci.yml` references a full 40-char SHA + version comment, never a bare `@v4` tag | ✅ green |
| D-06 | all specs KEEP; hygiene preserved | CIDX-05 | git + grep | `git ls-files -- 'examples/demo/frontend/test-results' 'examples/demo/frontend/playwright-report'` → empty; `grep "forbiddenSourceTerms" examples/demo/frontend/tests/ui-matrix.spec.ts` present | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no new test files needed. All verification is grep/static assertions on the three changed files (`playwright.config.ts`, `scripts/demo/verify.sh`, `.github/workflows/ci.yml`). The `ui-matrix.spec.ts:401-411` anti-baseline guard runs inside the existing `npm run test:e2e` suite (unchanged).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Trace/report artifacts actually appear in the GitHub Actions UI after a real `integration-placeholder` failure | CIDX-05 | Requires a genuinely failing browser run in CI; cannot be forced deterministically without breaking a test | On a branch, introduce a temporary failing assertion in one spec, push, confirm the `integration-placeholder` job uploads `playwright-report/`, then revert. (Optional — not required for phase pass.) |
| `upload-artifact` SHA is the current stable v4.x | CIDX-09 | SHA freshness check against GitHub | `curl -s https://api.github.com/repos/actions/upload-artifact/releases/latest \| jq '.tag_name,.target_commitish'` before commit |

*All other phase behaviors have automated static verification.*

---

## Validation Sign-Off

- [x] All decisions D-01..D-06 have an automated static verify command
- [x] Sampling continuity: every changed file has a grep/parse check
- [x] Wave 0 covers all MISSING references (none required)
- [x] No watch-mode flags
- [x] Feedback latency < 5s for static checks
- [x] `nyquist_compliant: true` set in frontmatter (set by planner/executor when map is complete)

**Approval:** validated 2026-06-17 — all 12 static checks green, no gaps

---

## Validation Audit 2026-06-17

State A audit: re-ran every command in the Per-Task Verification Map against the live files. All 12 rows pass; phase is Nyquist-compliant. No test generation needed (Wave 0 requires none — verification is grep/YAML-parse only).

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Static check results:** retain-on-failure=2, only-on-failure=1, on-first-retry=0, reporter=html+list, retries:0 present, webServer=0, wait_for_health present, `playwright show-report` present, DEMO_FRONTEND_URL=2, `trap cleanup` present, `bash -n` clean, upload-artifact present + YAML parses, `if: failure()` present, both artifact paths present, `if-no-files-found: ignore` present, SHA pin 40-char (`ea165f8d…` v4.6.2, zero bare tags), committed-artifacts list empty, `forbiddenSourceTerms` guard present.
