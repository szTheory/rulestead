---
phase: 52
slug: proof-docs-milestone-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest for mounted admin tests |
| **Config file** | `rulestead/test/test_helper.exs` and `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` |
| **Full suite command** | `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh && cd rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs` |
| **Estimated runtime** | ~90 seconds after dependencies are compiled |

---

## Sampling Rate

- **After every task commit:** Run `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` once the scope exists, or the explicit targeted command bundle until it exists.
- **After every plan wave:** Run `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh && cd rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs`.
- **Before `$gsd-verify-work`:** Named guarded rollout proof, docs drift checks, and `52-VERIFICATION.md` artifact checks must be green.
- **Max feedback latency:** 180 seconds after dependency compilation.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | VER-01 | T-52-01 | Guarded rollout proof scope stays bounded to host-owned fail-closed foundations. | script/docs | `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` | ❌ W0 | ⬜ pending |
| 52-01-02 | 01 | 1 | VER-01 | T-52-02 | Weak or missing guardrail facts hold/fail closed and never imply healthy rollout state. | ExUnit | `cd rulestead && mix test test/rulestead/guarded_rollout_test.exs test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/decision_test.exs` | ✅ | ⬜ pending |
| 52-01-03 | 01 | 1 | VER-01 | T-52-03 | Docs state host-owned metrics and bounded support limits without observability or auto-advance claims. | docs contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs` | ✅ | ⬜ pending |
| 52-02-01 | 02 | 2 | VER-01 | T-52-04 | Verification artifact records rerunnable proof and planning truth updates only after evidence lands. | artifact/planning | `test -f .planning/phases/52-proof-docs-milestone-closure/52-VERIFICATION.md && rg -n "guarded_rollout_foundations|VER-01|ready_for_closeout" .planning/phases/52-proof-docs-milestone-closure/52-VERIFICATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/test.sh` — add `guarded_rollout_foundations` scope.
- [ ] `rulestead/test/rulestead/guarded_rollout_test.exs` — add focused gap tests if the VER-01 matrix confirms missing adapter-path behavior.
- [ ] `rulestead/test/rulestead/release_contract_test.exs` — add guarded rollout support-truth assertions and forbidden-phrase checks.
- [ ] `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` — mirror package docs support-truth assertions for publish verification planning.
- [ ] `.planning/phases/52-proof-docs-milestone-closure/52-VERIFICATION.md` — write after proof passes.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Milestone archive workflow remains separate from Phase 52 execution | VER-01 | Archive/closeout is a GSD workflow decision, not runtime behavior | Confirm `52-VERIFICATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` say ready-for-closeout or satisfied, not archived/shipped, unless the milestone closeout workflow has run. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter after validation is proven

**Approval:** pending
