---
phase: 120
slug: workflow-topology-cache-hygiene-0-plans
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
validated: 2026-06-17
---

# Phase 120 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `120-RESEARCH.md` Validation Architecture. This phase edits CI
> workflow YAML, cache keys, CI shell output, and `MAINTAINING.md` — it is
> validated by **static workflow linting + shell-script behavior assertions +
> doc-vs-source reconciliation**, NOT by the ExUnit/`mix test` suite. All proof
> is offline: no live merge, no `gh api` write, no Hex publish.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None traditional — `actionlint` (static workflow lint) + `release_gate.sh` shell-behavior assertions + `git diff` non-regression checks + `grep` doc reconciliation |
| **Config file** | `.github/workflows/ci.yml` (artifact under test); `actionlint` uses defaults (no config file) |
| **Quick run command** | `actionlint .github/workflows/ci.yml` |
| **Full suite command** | `actionlint .github/workflows/*.yml && bash scripts/ci/release_gate.sh --skip-phase7 <pairs...>` |
| **Estimated runtime** | ~2 seconds (sub-second lint; instant arg-matrix) |

---

## Sampling Rate

- **After every task commit:** Run `actionlint .github/workflows/ci.yml` (sub-second)
- **After every plan wave:** Run `actionlint .github/workflows/*.yml` + `release_gate.sh` arg-matrix (success-all case and one-failure case)
- **Before `/gsd:verify-work`:** Full suite green + `git diff` confirms no protected-surface (D-09/D-10) regression + `MAINTAINING.md` required-check triad reconciled
- **Max feedback latency:** ~2 seconds

---

## Per-Task Verification Map

> Task IDs are assigned during planning. The rows below are requirement-level
> verification anchors the planner/nyquist-auditor will bind to concrete task
> IDs. Every task touching `ci.yml` MUST carry an `actionlint` acceptance check.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-T1 (D-03 wiring) | 01 | 0 | CIDX-04 | T-120-bypass | openfeature gate blocks only when companion-relevant; skipped→success otherwise | static lint + shell unit | `actionlint .github/workflows/ci.yml` ; `bash scripts/ci/release_gate.sh --skip-phase7 ...` (expect 0 all-success, 1 on one `=failure`) | ✅ | ✅ green |
| 120-02-T1 (D-05 fallback removal) | 02 | 0 | CIDX-07 | — | cross-lane `${{ runner.os }}-mix-` restore key removed from test matrix | static lint + diff | `actionlint .github/workflows/ci.yml` ; `grep -cE '\$\{\{ runner\.os \}\}-mix-'` → 0 | ✅ | ✅ green |
| 120-02-T1 (D-06 hash scoping) | 02 | 0 | CIDX-07 | — | lint/PLT keys scoped to `rulestead/mix.lock` + `.tool-versions`; multi-package lanes enumerate both built locks | static reasoning + lint | `grep -c "hashFiles('rulestead/mix.lock', '.tool-versions')"` → 3 (lint deps/build + PLT restore + PLT save) | ✅ | ✅ green |
| 120-03-T1 (D-07 busting docs) | 03 | 0 | CIDX-07 | — | per-cache busting rule documented | doc presence | `grep -A40 'CI caching' MAINTAINING.md` shows per-cache rule + `rulestead/mix.lock` | ✅ | ✅ green |
| 120-02-T2 (D-08 observability) | 02 | 0 | CIDX-07 | — | versions + cache posture + local rerun command emitted | run-step / summary inspection | `grep steps.mix-cache.outputs.cache-hit ci.yml` ; `grep GITHUB_STEP_SUMMARY {test,lint}.sh` | ✅ | ✅ green |
| 120-01-T2 (D-09/D-10 preserve) | 01 | 0 | CIDX-09 | T-120-supply | no regression in SHA pins, permissions, publish gating, secret boundaries | diff assertion | `git diff --name-only 1d9abaf~1 19873ea` excludes `publish-hex.yml`, `verify-published-release.yml`, `dependabot.yml`; `ci.yml` SHA pins unchanged | ✅ | ✅ green |
| 120-03-T2 (D-11 docs reconcile) | 03 | 0 | CIDX-04 | — | `MAINTAINING.md` states intended triad (`release_gate`, `Validate PR title`, `dependency-review`); no `gh api` writes | doc presence + diff | `grep` triad + `Branch not protected` + openfeature aggregation in `MAINTAINING.md`; `git diff` touches no live repo settings | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None requiring new test infrastructure. `actionlint 1.7.12` is installed; `scripts/ci/release_gate.sh` is directly executable with `--skip-phase7`.
- Optional: a plan may include a tiny inline shell step that runs the success-all and one-failure `release_gate.sh` invocations as an explicit verification gate (no new file strictly required).

*Existing infrastructure (actionlint + release_gate.sh + git/grep) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| openfeature skipped→success transform fires only when companion not relevant | CIDX-04 | Proving against a real skipped run needs a live PR (out of scope per no-live-merge posture) | Trace edited `ci.yml:307-323` block against the shipped mounted-proof precedent (`ci.yml:321-323`); accept script unit-behavior + actionlint + pattern-mirror as proof |
| Live branch-protection settings match documented triad | CIDX-04 | D-11 is docs-only; enabling/inspecting live protection is out of scope for v1.18 | Maintainer applies intended settings manually; `MAINTAINING.md` documents them |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (actionlint / release_gate.sh / git diff / grep) or are listed under Manual-Only
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none required)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-17 — all 7 requirement rows automated and green; 2 residual live-environment confirmations are documented Manual-Only and out of scope per the no-live-merge posture.

---

## Validation Audit 2026-06-17

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 (no new tests needed) |
| Escalated | 0 |

Every phase requirement (CIDX-04, CIDX-07, CIDX-09) was already covered by an
existing static check that exists and runs green. No test generation required.

**Re-run evidence (2026-06-17):**

| Check | Command | Result |
|-------|---------|--------|
| Workflow lint | `actionlint .github/workflows/*.yml` | exit 0 |
| Release gate (all-success) | `release_gate.sh --skip-phase7 changes=success mounted-proof=success openfeature-companion=success` | exit 0 — `release gate passed` |
| Release gate (one-failure) | `release_gate.sh --skip-phase7 … openfeature-companion=failure` | exit 1 — `openfeature-companion did not succeed: failure` |
| D-03 wiring | `grep needs['openfeature-companion'].result` + changes-transform | both present |
| D-05 fallback removed | `grep -cE '\$\{\{ runner\.os \}\}-mix-'` | 0 |
| D-06 hash scoping | `grep -c "hashFiles('rulestead/mix.lock', '.tool-versions')"` | 3 |
| D-08 observability | cache-hit output + `GITHUB_STEP_SUMMARY` in test.sh/lint.sh | present |
| D-07/D-11 docs | MAINTAINING.md busting rules + 404 note + triad + openfeature | present |
| D-09/D-10 supply chain | protected surfaces in phase diff | untouched |

Note: post-execution code-review fixes (IN-01 shared cache-hit script, IN-02
single `--version` capture, IN-04 mounted-proof `deps.get` doc) refined D-08
without altering the validation surface — `steps.mix-cache.outputs.cache-hit`
remains present and green.
