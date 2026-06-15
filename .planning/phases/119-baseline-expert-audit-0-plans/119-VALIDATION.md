---
phase: 119
slug: baseline-expert-audit-0-plans
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-15
updated: 2026-06-15
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for audit-only execution. Phase 119 creates and fills `119-CI-CD-AUDIT.md`; it does not change workflows, scripts, product code, schemas, package metadata, or browser configuration.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Documentation/audit validation with shell source assertions, GitHub CLI metadata capture, static workflow/script inspection, and local Mix diagnostics |
| **Primary artifact** | `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` |
| **Config/source files inspected** | `.github/workflows/*.yml`, `.github/dependabot.yml`, `scripts/ci/*.sh`, `scripts/demo/*.sh`, `rulestead/mix.exs`, `rulestead_admin/mix.exs`, `examples/demo/frontend/playwright.config.ts`, `MAINTAINING.md` |
| **Quick run command** | `bash -lc 'f=.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md; test -f "$f"; rg -Fq "## Executive Recommendation" "$f"; rg -Fq "## Source Coverage" "$f"'` |
| **Full suite command** | Run the nine task-level `<automated>` assertions from `119-01-PLAN.md`, `119-02-PLAN.md`, and `119-03-PLAN.md`, then run `git diff --name-only` and confirm no behavior-changing paths are modified. |
| **Estimated runtime** | Source assertions < 10 seconds; live `gh` and Mix diagnostic collection duration is recorded in the audit when executed. |

---

## Sampling Rate

- **After every task commit:** Run that task's task-level `<automated>` assertion.
- **After every plan wave:** Re-run all completed plan assertions for `119-CI-CD-AUDIT.md` sections touched so far.
- **Before `$gsd-verify-work`:** Run the full suite command above and confirm `119-CI-CD-AUDIT.md` covers CIDX-01, CIDX-02, CIDX-03, D-01 through D-21, and deferred exclusions.
- **Max feedback latency:** Source assertions < 10 seconds; live/local diagnostic command duration must be recorded if slower.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | CIDX-01, CIDX-02 | T-119-01 | Audit-only scaffold with evidence tags and no behavior edits | source assertion | Per-item loop asserts all 15 H2 sections, CIDX-01, CIDX-02, guardrail phrase, and `[VERIFIED]`/`[CITED]`/`[ASSUMED]` conventions from `119-01-PLAN.md` Task 1. | task creates | planned |
| 119-01-02 | 01 | 1 | CIDX-01, CIDX-02 | T-119-02, T-119-03 | Required-check semantics distinguish documented intent, live state, advisory signals, and release posture | source assertion + live metadata evidence | Per-item loop asserts all 11 workflow files, all 8 `ci.yml` job IDs, `gh workflow list`, `required_status_checks`, documented-vs-live state, and `openfeature-companion` absent from `release_gate.needs`. | yes | planned |
| 119-01-03 | 01 | 1 | CIDX-01, CIDX-02 | T-119-01 | Script-first rerun catalog and failure microcopy avoid unsafe bypass advice | source assertion | Per-item loop asserts contributor/local/mix/proof/demo/post-publish rerun commands, lint quality signals, and microcopy slots. | yes | planned |
| 119-02-01 | 02 | 2 | CIDX-02 | T-119-05 | Timing claims are tied to run IDs or explicit fallback; p95 is not invented | source assertion + live metadata evidence | Per-item loop asserts `gh run list --repo szTheory/rulestead --workflow ci.yml --limit 20`, `gh run view`, events, wall-clock, longest job, critical path, duplicated work, runner/tool versions, Postgres, p95/fallback, and run ID or live-metadata failure. | yes | planned |
| 119-02-02 | 02 | 2 | CIDX-02 | T-119-08 | Local diagnostics are recorded as evidence without changing tests, async flags, sharding, or Dialyzer posture | source assertion + local diagnostics | Per-item loop asserts every D-11 Mix/xref command, CPU/scheduler commands, exit status, slowest/profile/compile/xref labels. | yes | planned |
| 119-02-03 | 02 | 2 | CIDX-02 | T-119-06, T-119-07 | Cache and release-trust surfaces are audited without exposing secrets or editing workflow keys | source assertion | Per-item loop asserts cache restore/save usage, cache paths, restore keys, PLT, `MIX_ENV`, `.tool-versions`, correctness-safe/Phase 120 attention, Dependabot, publish, protected Hex, secret-name boundary, and post-publish proof. | yes | planned |
| 119-03-01 | 03 | 3 | CIDX-03 | T-119-09 | Every non-keep classification has evidence and Phase 120-123 handoff | source assertion | Per-item loop asserts all five D-03 labels, named workflow/proof/check surfaces, every supported `RULESTEAD_TEST_SCOPE`, and Phase 120/121/122/123 handoff markers. | yes | planned |
| 119-03-02 | 03 | 3 | CIDX-01, CIDX-02, CIDX-03 | T-119-11, T-119-12 | Browser/release/security recommendations preserve audit-only no-go guardrails | source assertion | Per-item loop asserts primary recommendation, Playwright trace/retry mismatch, failure artifact/quarantine wording, official pattern notes, and every no-go guardrail. | yes | planned |
| 119-03-03 | 03 | 3 | CIDX-01, CIDX-02, CIDX-03 | T-119-10 | Source coverage prevents false completion claims and blocks behavior-changing diffs | source assertion + diff gate | Per-item loop asserts `## Source Coverage`, GOAL, CIDX-01..03, COVERED, deferred exclusion, D-01..D-21; diff gate rejects `.github/workflows/`, `scripts/`, `rulestead/`, `rulestead_admin/`, `examples/`, `mix.exs`, `mix.lock`, and `playwright.config.ts` changes. | yes | planned |

*Status: planned / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers Phase 119 validation. No missing test scaffold is required because this is an audit-only documentation phase and every task has an automated source assertion or live/local command evidence requirement.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live branch protection state is interpreted correctly | CIDX-01, CIDX-02 | GitHub repository settings are external mutable state, and Phase 119 must distinguish live evidence from a decision to change settings | Use the exact `gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks` result recorded in `119-CI-CD-AUDIT.md`; confirm the audit labels it as documented-vs-live evidence and does not make a Phase 119 settings change. |
| Representative CI timing sample is reasonable | CIDX-02 | Recent runs can be heterogeneous; a human may need to judge whether the sample supports p95 or only a baseline/fallback | Review the run IDs, events, branches, conclusions, and fallback notes in `119-CI-CD-AUDIT.md`; confirm p95 is either computed from a defensible sample or marked `p95 target unavailable from current sample`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands or concrete live/local command evidence.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 has no missing scaffold for this audit-only phase.
- [x] No watch-mode flags.
- [x] Feedback latency target is defined for source assertions; longer diagnostic commands are recorded as audit evidence.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** ready for execution
