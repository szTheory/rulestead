---
phase: 96
slug: design-tokens-brandbook-scaffold
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | python3 stdlib scripts + bash CI (`scripts/ci/lint.sh`) — no test framework |
| **Config file** | none — drift checks are self-contained scripts |
| **Quick run command** | `python3 scripts/check_brand_tokens.py` |
| **Full suite command** | `bash scripts/ci/lint.sh` (or the appended brand-token + SVG-budget block) |
| **Estimated runtime** | ~2 seconds (token check); lint.sh full ~minutes (mix toolchain) |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/check_brand_tokens.py` (expect exit 1 until Phase 98)
- **After every plan wave:** Run `python3 scripts/check_synced_pair.py` + `python3 scripts/check_contrast.py`
- **Before `/gsd:verify-work`:** tokens.json parses as JSON; check script exits 1 with per-token diff (the intended pre-Phase-98 state)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | TOK-{XX} | T-96-01 / — | {expected secure behavior or "N/A"} | script-exit | `{command}` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Note: For this phase, success criterion 3 deliberately requires `check_brand_tokens.py` to exit NON-ZERO against the un-re-skinned admin CSS — a "red" token-check is the GREEN state for Phase 96. Verification asserts exit 1 + a per-token diff, not exit 0.*

---

## Wave 0 Requirements

- [ ] `scripts/check_brand_tokens.py` — the drift-check guard (mirrors `check_synced_pair.py`)
- [ ] `brandbook/tokens.json` — DTCG source consumed by the check

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| §12 brand-book hexes match AA-verified palette | TOK-01 (brand truth) | Prose reconciliation, not script-checkable | Diff §12 against `95-PALETTE-RECONCILIATION.md` §4/§8 |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
