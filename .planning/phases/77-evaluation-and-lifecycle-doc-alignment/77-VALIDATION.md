---
phase: 77
slug: evaluation-and-lifecycle-doc-alignment
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 77 — Validation Strategy

> Docs-only phase — grep and file-existence proofs; contract tests deferred to Phase 78.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — documentation edits |
| **Config file** | none |
| **Quick run command** | `grep -q 'Rulestead.Runtime' guides/flows/evaluation.md` |
| **Full suite command** | See plan 77-01 verify block |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `verify` automated command
- **After plan wave:** Run full grep trio from RESEARCH.md
- **Before `/gsd-verify-work`:** All acceptance criteria green

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 77-01-01 | 01 | 1 | DOC-01 | grep | `grep -q 'Rulestead.Runtime.enabled?' guides/flows/evaluation.md` | ⬜ pending |
| 77-01-02 | 01 | 1 | DOC-02 | grep | `grep -q expected_expiration guides/introduction/getting-started.md guides/introduction/installation.md` | ⬜ pending |
| 77-01-03 | 01 | 1 | DOC-03 | grep | `grep -q 'Rulestead.Runtime' rulestead/README.md` | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements (no new test files in Phase 77).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Payload-first still primary in evaluation.md | DOC-01 | Narrative order | "Core Calls" lists `Rulestead.evaluate/3` before Runtime subsection |
| README ordering matches footguns | DOC-03 | Table vs prose | Runtime block precedes payload-first list |
