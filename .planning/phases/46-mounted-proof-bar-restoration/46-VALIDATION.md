---
phase: 46
slug: mounted-proof-bar-restoration
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 46 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + repo-root shell verifier |
| **Config file** | `rulestead/config/test.exs`, `rulestead_admin/test/test_helper.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs && cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_contract_test.exs test/rulestead/admin_lifecycle_test.exs` |
| **Full suite command** | `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` |
| **Estimated runtime** | ~30 seconds after deps are warm |

---

## Sampling Rate

- **After every task commit:** Run the narrowest package-local command set for the touched files.
- **After every plan wave:** Run `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`.
- **Before `$gsd-verify-work`:** The repo-root mounted verifier must be green and CI wiring changes must still leave the command green locally.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | ADM-01 | T-46-01 | The named repo-root verifier runs the intended bounded mounted lifecycle contract instead of the temporary seam-only subset | integration | `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` | ✅ | ⬜ pending |
| 46-02-01 | 02 | 2 | ADM-01 | T-46-11 | Cleanup is readable, preview/confirm remain execute/admin-gated, and route-backed env/return_to behavior stays intact through the mounted host seam | integration | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs && RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` | ✅ | ⬜ pending |
| 46-03-01 | 03 | 3 | VER-01 | T-46-21 | Mounted proof failures are categorized, CI runs a named mounted lane, and release-gate wiring preserves the local verifier path | shell/integration | `bash -n /Users/jon/projects/rulestead/scripts/ci/test.sh && RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.
- No new test framework or external browser harness is required for Phase 46.

---

## Manual-Only Verifications

- Review the final `.github/workflows/ci.yml` diff to ensure the mounted-proof job key and `release_gate` needs list remain stable and readable.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
