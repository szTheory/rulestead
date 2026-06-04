---
phase: 95
slug: brand-audit-palette-reconciliation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 95 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | python3 stdlib (no test runner — colorimetry by hand, no third-party deps) |
| **Config file** | none |
| **Quick run command** | `python3 scripts/check_contrast.py` |
| **Full suite command** | `python3 scripts/check_contrast.py` (same — single self-validating script) |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/check_contrast.py`
- **After every plan wave:** Run `python3 scripts/check_contrast.py`
- **Before `/gsd:verify-work`:** Script must exit 0 with all built-in anchors green and every reconciliation-table normal-weight text pairing ≥4.5:1
- **Max feedback latency:** ~1 second

---

## Validation Anchors (self-test on script startup)

The contrast/OKLCH script is the only automated surface in Phase 95. It MUST self-test against known-good values on startup and exit non-zero if any anchor fails — this guards against silent formula errors.

| Anchor | Expected | Rationale |
|--------|----------|-----------|
| Black `#000000` on white `#FFFFFF` | 21.00:1 exactly | WCAG 2.1 §1.4.3 definition |
| White on white | 1.00:1 exactly | Same color = 1:1 |
| Stead Blue `#3A6F8F` on white | ~5.45:1 | Confirmed pass; non-trivial value |
| Ember Copper `#B96A3A` on white | ~4.05:1 | Confirmed fail; anchors remediation direction |
| OKLCH hue-drift round-trip | <3° on remediated pairs | Ottosson sRGB→linear→OKLab matrices; preserves brand hue |

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | Status |
|--------|----------|-----------|-------------------|--------|
| PAL-01 | Every text/button pairing across all 4 surfaces has a computed WCAG 2.x ratio | Automated | `python3 scripts/check_contrast.py` | ⬜ pending |
| PAL-02 | Every AA-failing pairing has an AA-verified hex ≥4.5:1, remediated via uniform-RGB-scale (OKLCH hue drift <3° for Ember Copper + Warning) | Automated (script asserts ≥4.5 + hue drift <3°) | `python3 scripts/check_contrast.py` | ⬜ pending |
| PAL-03 | Dark ramp anchored on shipped v1.13 (`#10161f` kept, elevation by luminance, no `--rs-surface-base` swap) | Manual review | slot mapping in `95-PALETTE-RECONCILIATION.md` | ⬜ pending |
| PAL-04 | Signal Gold `#D2A94E` decorative-only policy documented | Manual review | policy text in `95-PALETTE-RECONCILIATION.md` | ⬜ pending |
| BRD-01 | Pressure-test audit (KEEP/TIGHTEN/REWORK/ADD/REMOVE) + scorecard written for all brand-book sections | Manual review | `95-BRAND-AUDIT.md` exists with ratings | ⬜ pending |
| BRD-02 | Canonical brand-book relocation decision (→ `brandbook/brand-book.md` in Phase 96) confirmed in writing | Manual review | D-04 statement in `95-PALETTE-RECONCILIATION.md` | ⬜ pending |
| BRD-03 | szTheory suite brand-architecture note captured / scoped | Manual review | note or ADD-item in `95-BRAND-AUDIT.md` | ⬜ pending |
| D-11 | Maintainer accepts each AA-adjusted hex as brand-compatible | Human checkpoint | phase-close gate; not automated | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/check_contrast.py` — dependency-free python3 stdlib script computing WCAG 2.x relative-luminance contrast ratios and OKLCH hue angles (Ottosson matrices), with built-in anchor self-test.

*This script IS the Wave 0 / validation infrastructure for the phase — there is no pre-existing contrast harness (D-05).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dark-ramp slot mapping is faithful to v1.13 | PAL-03 | Design-intent judgement, not a numeric assertion | Compare slot table in `95-PALETTE-RECONCILIATION.md` against v1.13 dark blocks in `rulestead_admin.css` |
| Brand-book pressure-test ratings are sound | BRD-01 | Editorial judgement | Read `95-BRAND-AUDIT.md` scorecard |
| Each AA-adjusted hex is brand-compatible | D-11 / PAL-02 | Brand-acceptance is a maintainer design call | Maintainer reviews reconciliation table at phase close |

---

## Validation Sign-Off

- [ ] All automated tasks (PAL-01, PAL-02) have a `<automated>` verify command or Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (decision-record phase — manual reviews are inherent and acceptable here)
- [ ] Wave 0 covers the MISSING `scripts/check_contrast.py` reference
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
