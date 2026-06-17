---
phase: "123"
plan: "02"
subsystem: maintaining-docs
tags: [ci-cd, closeout, dx, contributor-docs, triage, anti-drift]
dependency_graph:
  requires:
    - .planning/phases/123-dx-closeout-proof-0-plans/123-01-SUMMARY.md
    - scripts/ci/test.sh
    - .github/workflows/ci.yml
  provides:
    - MAINTAINING.md (## CI Failure Triage section + command ladder statement)
    - rulestead/test/rulestead/release_contract_test.exs (D-14 anti-drift guard)
  affects:
    - MAINTAINING.md
    - rulestead/test/rulestead/release_contract_test.exs
tech_stack:
  added: []
  patterns:
    - verbatim microcopy lift from scripts/ci/test.sh (D-12)
    - file-content assertions in existing ExUnit test (D-14 Option A)
    - release-trust gate boundary framing (D-13)
key_files:
  created: []
  modified:
    - MAINTAINING.md
    - rulestead/test/rulestead/release_contract_test.exs
decisions:
  - "Verbatim rerun commands lifted from scripts/ci/test.sh:67-90 (print_mounted_failure_guidance) and :124-129 (run_openfeature_companion) per D-12; no paraphrase"
  - "D-14 guard assertions added inside existing test function at lines 272-299; no new test functions, module attributes, or use/import statements"
  - "publish-hex and verify-published-release rows both labeled release-trust gate, not a speed target per D-13"
  - "Pre-existing lint.sh ADMIN FOUNDATION DRIFT failure (missing 115-FOUNDATIONS-CONTRACT.md) is out-of-scope and logged as deferred; does not affect the plan's mandatory D-15 verification"
metrics:
  duration: "15 minutes"
  completed: "2026-06-17"
  tasks: 2
  files: 2
---

# Phase 123 Plan 02: Command Ladder + CI Failure Triage Table Summary

**One-liner:** MAINTAINING.md shift-left gate section gains a command ladder paragraph and a new 9-row `## CI Failure Triage` table with verbatim microcopy from `scripts/ci/test.sh`; `release_contract_test.exs` gains 5 D-14 anti-drift guard assertions that all pass.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add command ladder statement + CI Failure Triage table to MAINTAINING.md (D-07/D-08/D-10..D-13) | e7c94b0 | `MAINTAINING.md` (+18 lines) |
| 2 | Add D-14 anti-drift guard to release_contract_test.exs | c281133 | `rulestead/test/rulestead/release_contract_test.exs` (+5 lines) |

## What Was Built

### MAINTAINING.md — Command Ladder Statement (ADDITION 1)

Inserted a `**Command ladder:**` prose paragraph inside the shift-left gate section, after the `scripts/demo/proof.sh` block and before the peer/integration dep bumps note. The paragraph:

- Names `cd rulestead && mix ci` as the canonical fast-loop alias for `bash scripts/ci/contributor.sh`
- Names `bash scripts/ci/local.sh` as the full monorepo gate (`--fast` skips mounted + OpenFeature companion scopes)
- Names `cd rulestead && mix verify.adopter` for the adopter-contract lane and `RULESTEAD_TEST_SCOPE=<scope> bash scripts/ci/test.sh` for proof scopes (with reference to the new CI Failure Triage section)
- Documents post-Phase 121 ~5s default suite posture and `@tag :published_hex_smoke` / `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` opt-in lane

Protected sections untouched: branch-protection (:32-61), cache table (:63-78), release runbook (:121+).

### MAINTAINING.md — `## CI Failure Triage` Section (ADDITION 2)

Inserted a new section between the shift-left gate section and `## Release Please flow`. The section contains a single 6-column markdown table with 9 rows in `release_gate` pipeline order:

| Lane | Immutable ci.yml job id |
|------|------------------------|
| Row 1 | `lint` |
| Row 2 | `test` |
| Row 3 | `integration-placeholder` |
| Row 4 | `adopter-contract` |
| Row 5 | `mounted-proof` |
| Row 6 | `openfeature-companion` |
| Row 7 | `publish-hex` |
| Row 8 | `verify-published-release` |
| Row 9 | `repo-hygiene` |

Columns: `Lane (ci.yml job id) | What failed | Boundary it protects | Exact rerun | Likely remediation | When to stop rather than bypass`

Verbatim microcopy per D-12:
- `mounted-proof` rerun: `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` (from `scripts/ci/test.sh:74`)
- `mounted-proof` boundary: `Mounted companion only; host app owns the router/session prerequisite contract.` (from `scripts/ci/test.sh:73`)
- `openfeature-companion` rerun: `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` (from `scripts/ci/test.sh` case switch)

`publish-hex` and `verify-published-release` "when to stop" cells: both state `release-trust gate, not a speed target` per D-13.

### release_contract_test.exs — D-14 Anti-Drift Guard (5 assertions)

Extended the existing test `"maintainer guidance matches the shipped release and support truth"` (lines 272-299) with 5 additional `assert maintaining =~` lines after the existing `integration-placeholder` assertion:

```elixir
assert maintaining =~ "## CI Failure Triage"
assert maintaining =~ "mounted-proof"
assert maintaining =~ "openfeature-companion"
assert maintaining =~ "RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh"
assert maintaining =~ "release-trust gate"
```

Guards: triage section heading (highest drift risk), both path-gated job ids (most likely to be renamed), scope-wrapper rerun command (single source of truth with `scripts/ci/test.sh`), and release-trust gate phrase (publish-hex and verify-published-release rows).

## Verification Results

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Triage section heading | `grep -A2 "CI Failure Triage" MAINTAINING.md` | Shows heading and table header | PASS |
| Exactly one triage table | `grep -c "Lane (ci.yml job id)" MAINTAINING.md` | 1 | PASS |
| Non-core job ids present | `grep "mounted-proof\|..." MAINTAINING.md \| wc -l` | 18 (>= 5) | PASS |
| mounted-proof verbatim rerun | `grep "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh" MAINTAINING.md` | match | PASS |
| openfeature-companion verbatim rerun | `grep "RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh" MAINTAINING.md` | match | PASS |
| Command ladder present | `grep "cd rulestead && mix ci" MAINTAINING.md` | match | PASS |
| D-14 guard assertions count | `grep "CI Failure Triage\|mounted-proof\|openfeature-companion\|release-trust gate" release_contract_test.exs \| wc -l` | 5 (>= 4) | PASS |
| D-15 mandatory test run | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | 26 tests, 0 failures | PASS |
| lint.sh | `bash scripts/ci/lint.sh` | FAIL (pre-existing) | N/A (see deferred) |

## Deviations from Plan

### Pre-existing Issue (Out of Scope)

**lint.sh ADMIN FOUNDATION DRIFT DETECTED** — `scripts/check_design_system_evidence.py` reports a missing `115-FOUNDATIONS-CONTRACT.md` file and multiple missing sections. This failure pre-dates this plan (the directory `.planning/phases/115-foundations-hardening/` does not exist). It is not caused by any change made in 123-02.

Per deviation rule scope boundary: only auto-fix issues DIRECTLY caused by the current task's changes. This pre-existing drift is logged to deferred items rather than fixed.

The plan's mandatory verification (`cd rulestead && mix test test/rulestead/release_contract_test.exs`) exits 0 and is fully satisfied.

## Known Stubs

None. All triage microcopy is sourced verbatim from committed `scripts/ci/test.sh` functions. No placeholder text.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes were introduced. All work is document editing and file-content assertion extension only. The triage table reinforces rather than weakens the release-trust boundary (T-123-04 mitigated: D-12 verbatim lift + D-14 scope-wrapper guard; T-123-07 mitigated: D-13 imperative boundary framing for publish-hex/verify-published-release rows).

## Self-Check: PASSED

- `MAINTAINING.md` — exists with `## CI Failure Triage` section (verified by grep)
- `rulestead/test/rulestead/release_contract_test.exs` — exists with 5 D-14 guard assertions (verified by grep count = 5)
- `e7c94b0` — commit exists (`git log --oneline -3` shows `e7c94b0 docs(123-02): add command ladder statement...`)
- `c281133` — commit exists (`git log --oneline -3` shows `c281133 test(123-02): add D-14 anti-drift guard assertions...`)
- `cd rulestead && mix test test/rulestead/release_contract_test.exs` — exits 0 (26 tests, 0 failures)
