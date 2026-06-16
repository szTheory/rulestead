---
phase: 120
slug: workflow-topology-cache-hygiene-0-plans
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
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
| TBD (D-03 wiring) | — | — | CIDX-04 | T-120-bypass | openfeature gate blocks only when companion-relevant; skipped→success otherwise | static lint + shell unit | `actionlint .github/workflows/ci.yml` ; `bash scripts/ci/release_gate.sh --skip-phase7 ...` (expect 0 all-success, 1 on one `=failure`) | ✅ | ⬜ pending |
| TBD (D-05 fallback removal) | — | — | CIDX-07 | — | cross-lane `${{ runner.os }}-mix-` restore key removed from test matrix | static lint + diff | `actionlint .github/workflows/ci.yml` ; `git diff ci.yml` shows line 177 removed | ✅ | ⬜ pending |
| TBD (D-06 hash scoping) | — | — | CIDX-07 | — | lint/PLT keys scoped to `rulestead/mix.lock` + `.tool-versions`; multi-package lanes enumerate both built locks | static reasoning + lint | review each `key:`/`restore-keys:` against the lane's built `path:` | ✅ | ⬜ pending |
| TBD (D-07 busting docs) | — | — | CIDX-07 | — | per-cache busting rule documented | doc presence | `grep -A30 'CI caching' MAINTAINING.md` shows per-cache rule | ✅ | ⬜ pending |
| TBD (D-08 observability) | — | — | CIDX-07 | — | versions + cache posture + local rerun command emitted | run-step / summary inspection | review added `$GITHUB_STEP_SUMMARY` lines in diff | ✅ | ⬜ pending |
| TBD (D-09/D-10 preserve) | — | — | CIDX-09 | T-120-supply | no regression in SHA pins, permissions, publish gating, secret boundaries | diff assertion | `git diff --name-only` excludes `publish-hex.yml`, `verify-published-release.yml`, `dependabot.yml`; `ci.yml` SHA pins unchanged | ✅ | ⬜ pending |
| TBD (D-11 docs reconcile) | — | — | CIDX-04 | — | `MAINTAINING.md` states intended triad (`release_gate`, `Validate PR title`, `dependency-review`); no `gh api` writes | doc presence + diff | `grep` triad in `MAINTAINING.md`; `git diff` touches no live repo settings | ✅ | ⬜ pending |

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

- [ ] All tasks have `<automated>` verify (actionlint / release_gate.sh / git diff / grep) or are listed under Manual-Only
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none required)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
