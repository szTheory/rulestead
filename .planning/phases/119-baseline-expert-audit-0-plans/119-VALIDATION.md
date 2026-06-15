---
phase: 119
slug: baseline-expert-audit-0-plans
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Mix diagnostics, GitHub Actions/workflow inspection, Playwright config inspection |
| **Config file** | `mix.exs`, `.github/workflows/ci.yml`, `test/support/diagnostics.exs`, `assets/playwright.config.ts` |
| **Quick run command** | `mix test test/rulestead/*_test.exs` |
| **Full suite command** | `mix test && mix format --check-formatted && mix credo --strict` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rulestead/*_test.exs`
- **After every plan wave:** Run `mix test && mix format --check-formatted && mix credo --strict`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | Phase boundary | — | N/A | source assertion | `test -f .planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live branch protection state is recorded accurately | Audit GitHub required-check state | GitHub repository settings are external mutable state | Use `gh api repos/:owner/:repo/branches/main/protection` or equivalent documented in `119-RESEARCH.md`; record result in `119-CI-CD-AUDIT.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
