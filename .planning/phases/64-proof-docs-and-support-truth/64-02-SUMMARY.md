---
phase: 64-proof-docs-and-support-truth
plan: 64-02
subsystem: testing
tags: [release-contract, docs, auto-advance, support-truth]

requires:
  - phase: 64-proof-docs-and-support-truth
    plan: 64-01
    provides: mix verify.phase64 merge gate
provides:
  - release_contract_test.exs auto-advance support-truth block
  - README and MAINTAINING v1.8 bounded auto-advance proof posture
affects:
  - 64-03
  - 64-04

tech-stack:
  added: []
  patterns:
    - "Forbidden-phrase negation avoids substring collisions with release_contract refutes"

key-files:
  created: []
  modified:
    - rulestead/test/rulestead/release_contract_test.exs
    - README.md
    - rulestead/README.md
    - rulestead_admin/README.md
    - MAINTAINING.md

key-decisions:
  - "Negation copy uses package-owned observability stack and fleet-wide operator dashboards to satisfy forbidden-phrase refutes while stating bounded non-claims"

requirements-completed:
  - VER-02
  - VER-03

duration: 12 min
completed: 2026-05-27
---

# Phase 64 Plan 02: Release Contract Drift Guards And Support Truth READMEs Summary

**v1.8 auto-advance support truth is enforced by release_contract_test.exs and reflected in root, package, and maintainer docs without removing verify.phase56 or verify.phase60 proof entries.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T00:00:00Z
- **Completed:** 2026-05-27T00:12:00Z
- **Tasks:** 2 completed
- **Files modified:** 5

## Accomplishments

- Added `guarded rollout auto-advance support truth stays bounded` test block asserting `mix verify.phase64`, observation-window vocabulary, `guardrail_automation`, host-owned signals, and CI scope across root, runtime, admin, and MAINTAINING docs.
- Removed stale `"auto-advance"` and `"auto-advance guarded rollouts"` forbidden phrases from guarded-rollout and blast-radius blocks.
- Extended Proof today, package READMEs, and MAINTAINING with v1.8 auto-advance bounded claims while preserving `mix verify.phase60` and `mix verify.phase56`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add auto-advance support truth test block and update forbidden phrases** - `c9f6154` (test)
2. **Task 2: Update README and MAINTAINING support truth** - `e787938` (docs)

## Files Created/Modified

- `rulestead/test/rulestead/release_contract_test.exs` - New support-truth block; forbidden phrase cleanup
- `README.md` - v1.8 Proof today entry + CI scope
- `rulestead/README.md` - Auto-advance contract section + `mix verify.phase64`
- `rulestead_admin/README.md` - Mounted auto-advance presentation section
- `MAINTAINING.md` - Guarded Rollout Auto-Advance Proof section

## Deviations from Plan

### Auto-fixed (1)

**1. [Rule 1 - Bug] Forbidden-phrase substring collisions in negation copy**
- **Found during:** Task 2 verification (`mix test release_contract_test.exs`)
- **Issue:** Plan template wording (`built-in observability product`, `fleet dashboards`, `self-healing rollouts`, `time-based percentage rollout`) matched forbidden-phrase refutes as substrings.
- **Fix:** Rephrased negation lines to `package-owned observability stack`, `fleet-wide operator dashboards`, `clock-driven percentage rollout semantics`, and `unattended rollout recovery`.
- **Files modified:** `README.md`, `rulestead/README.md`, `MAINTAINING.md`
- **Verification:** `mix test test/rulestead/release_contract_test.exs` — 18 tests, 0 failures
- **Commit:** `e787938`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Wording only; bounded support-truth intent unchanged.

## Verification Results

```bash
cd rulestead && mix test test/rulestead/release_contract_test.exs
# 18 tests, 0 failures

grep -q 'mix verify.phase64' README.md && echo PASS
grep -q 'mix verify.phase60' README.md && echo PASS
grep -q 'Guarded Rollout Auto-Advance Proof' MAINTAINING.md && echo PASS
```

- Guarded rollout forbidden list no longer contains bare `"auto-advance"` — PASS
- Blast-radius forbidden list no longer contains `"auto-advance guarded rollouts"` — PASS
- New test asserts `mix verify.phase64`, `mix verify.phase60`, and `mix verify.phase56` in root README — PASS

## Self-Check: PASSED

- Key files exist on disk
- Task commits present: `git log --oneline --grep="64-02"` returns 2 commits
- All acceptance criteria and plan verification commands pass

## Requirements Completed

- **VER-02** — Public docs describe bounded auto-advance scope, observation-window semantics, and host-owned metrics responsibilities
- **VER-03** — Release-contract allows bounded auto-advance claims; forbidden overclaim phrases retained

## Next

Ready for **64-03** (host seam subsection + in-place flow guide updates).
