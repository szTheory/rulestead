---
phase: 73
slug: context-and-maintainer-doc-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 73 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `rulestead/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/context_test.exs` |
| **Contract command** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~15–45 seconds per command |

---

## Sampling Rate

- **After 73-01:** Run context unit tests
- **After 73-02:** Run full `release_contract_test.exs`
- **Before phase sign-off:** `cd rulestead && mix verify.adopter` (unchanged delegation)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 73-01-01 | 01 | 1 | CTX-01 | — | traits promoted; attributes win | unit | `mix test test/rulestead/context_test.exs` | ✅ | ⬜ pending |
| 73-01-02 | 01 | 1 | CTX-02 | — | quickstart uses attributes only | contract | `mix test test/rulestead/release_contract_test.exs --only line 594` | ✅ | ⬜ pending |
| 73-02-01 | 02 | 2 | DOC-01 | T-73-01 | MAINTAINING cannot defer live api_stability | contract | `mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 73-02-02 | 02 | 2 | DOC-01, CTX-02 | T-73-01 | live public surface section present | grep | `grep -q 'Public surface contract' MAINTAINING.md` | ⬜ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 stubs.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify
- [x] Sampling continuity: contract run after doc edits
- [x] Wave 0 N/A
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` in frontmatter

**Approval:** pending execution
