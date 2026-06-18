---
phase: 125
slug: version-truth-sweep-release-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 125 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + bash/grep CI guards + Python guard scripts |
| **Config file** | `rulestead/mix.exs`; `scripts/ci/lint.sh`; `scripts/ci/test.sh` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Full suite command** | `bash scripts/ci/lint.sh && cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~30–60 seconds (contract test fast; lint.sh includes `mix compile/docs --warnings-as-errors`) |

---

## Sampling Rate

- **After every task commit:** Run the criterion-1 grep (must return zero hits) + `mix test ...release_contract_test.exs`
- **After every plan wave:** Run `bash scripts/ci/lint.sh` (proves the new `check_version_truth.py` guard wired in and the existing release gate stays green)
- **Before `/gsd-verify-work`:** Full suite green — criterion-1 grep zero hits, contract test green, lint.sh exit 0
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | 01 | 1 | REL-02 | — | Sweep 13 files + delete callout; criterion-1 grep returns zero hits in shipped surface | integration | `grep -rn '0\.1\.x\|~> 0\.1\|0\.1\.7\|future.*1\.0\|1\.0 API freeze' README.md rulestead/README.md rulestead_admin/README.md open_feature_rulestead/README.md guides/ MAINTAINING.md CONTRIBUTING.md` (expect zero) | ✅ | ⬜ pending |
| 125-01-02 | 01 | 1 | REL-02 | — | `release_contract_test.exs` re-anchored in lockstep (6 flips L233/234/249/254/262/285; L265 demo survivor unchanged) | unit | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 125-02-01 | 02 | 2 | REL-02 | — | `scripts/check_version_truth.py` fail-closed guard with `~> 0\.1(?![.\d])` lookahead; wired into `lint.sh`; does NOT flag `~> 0.1.3` | integration | `python3 scripts/check_version_truth.py && bash scripts/ci/lint.sh` (exit 0) | ❌ W0 | ⬜ pending |
| 125-03-01 | 03 | 2 | REL-03 | — | `upgrading.md` "Upgrading 0.1.x → 1.0" section (zero code changes, dep-pin bump, promotion-not-rewrite) | grep | `grep -q 'Upgrading 0.1.x' guides/introduction/upgrading.md` | ✅ | ⬜ pending |
| 125-03-02 | 03 | 2 | REL-03 | — | `MAINTAINING.md` "Cutting a major (X.0.0)" runbook (Release-As, package sequence, deprecation-window, post-cut removal) | grep | `grep -q 'Cutting a major' MAINTAINING.md` | ✅ | ⬜ pending |
| 125-03-03 | 03 | 2 | REL-03 | — | `brandbook/CHANGELOG-PREAMBLE-1.0.md` staged two-package "promotion, not rewrite" preamble artifact exists | file-exists | `test -f brandbook/CHANGELOG-PREAMBLE-1.0.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: plan/task IDs above are an estimate for validation sampling; the planner finalizes the actual plan/wave decomposition.*

---

## Wave 0 Requirements

- [ ] `scripts/check_version_truth.py` — new fail-closed drift guard (does not exist yet; created in Plan 02)
- [ ] `brandbook/CHANGELOG-PREAMBLE-1.0.md` — new staged release artifact (does not exist yet; created in Plan 03)

*Existing infrastructure (ExUnit, lint.sh guard chain, the 8 `check_*.py` precedents) covers everything else.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The README "Two version lines" callout is deleted *entirely* (criterion 2) — not merely reworded | REL-02 | Grep proves absence of the phrase, but a human should confirm the surrounding hero/install prose still reads coherently after removal | Read root `README.md` + 3 package READMEs after the sweep; confirm no orphaned admonition syntax and the install snippets show `~> 1.0` |
| "Promotion, not rewrite" framing is genuinely clear (not just keyword-present) in upgrading.md + CHANGELOG preamble | REL-03 | Semantic quality of adopter-facing copy is not grep-checkable | Read the new sections; confirm they state explicit zero breaking changes + dep-pin-only bump |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`check_version_truth.py`, CHANGELOG preamble artifact)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
