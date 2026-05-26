---
phase: 45
slug: companion-boot-package-boundary-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 45 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/config/test.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/runtime/startup_test.exs test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs` |
| **Full suite command** | `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run the targeted package-local command set for the files touched in that task.
- **After every plan wave:** Run `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`
- **Before `$gsd-verify-work`:** Full mounted proof command must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | PKG-01 | T-45-01 | Generated host fixtures encode the mounted boot contract with explicit runtime config, mount path, session keys, and package versions | unit/integration | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs` | ✅ | ⬜ pending |
| 45-02-01 | 02 | 2 | PKG-01, PKG-02 | T-45-02 | Runtime boot starts only intended children and keeps optional infra config-gated instead of implicitly required | unit | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/runtime/startup_test.exs test/rulestead/mix/tasks/rulestead_install_test.exs` | ✅ | ⬜ pending |
| 45-03-01 | 03 | 3 | PKG-02 | T-45-03 | Mounted prerequisites fail closed through explicit session/mount behavior and the bounded proof bar remains green | integration | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs && RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All Phase 45 behaviors should have automated verification through ExUnit and the scoped `mounted_admin_contract` wrapper.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
