---
phase: 99
slug: specimens
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-05
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash assertions + `scripts/ci/lint.sh` (SVG size-budget loop) |
| **Config file** | `scripts/ci/lint.sh` (existing — no new framework) |
| **Quick run command** | `bash scripts/ci/lint.sh` |
| **Full suite command** | `bash scripts/ci/lint.sh` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** `wc -c < brandbook/assets/specimens/<file>.svg` (size spot-check ≤ 51200 bytes) + `grep -c base64 <file>.svg` (expect 0)
- **After every plan wave:** Size-budget loop over all specimens authored so far
- **Before `/gsd:verify-work`:** `bash scripts/ci/lint.sh` exits 0 with `SVG SIZE BUDGET OK`
- **Max feedback latency:** ~3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 0 | SPEC-01/02 | — | N/A (asset dir, no input handling) | smoke | `test -d brandbook/assets/specimens` | ❌ W0 | ⬜ pending |
| 99-02-01 | 02 | 1 | SPEC-01 | — | N/A | smoke | `test -f brandbook/assets/specimens/palette.svg` | ❌ W0 | ⬜ pending |
| 99-02-02 | 02 | 1 | SPEC-01 | — | N/A | unit | `grep -c '#3A6F8F\|#3a6f8f' brandbook/assets/specimens/palette.svg` (≥1) | ❌ W0 | ⬜ pending |
| 99-03-01 | 03 | 1 | SPEC-01 | — | N/A | smoke | `test -f brandbook/assets/specimens/typography.svg` | ❌ W0 | ⬜ pending |
| 99-03-02 | 03 | 1 | SPEC-01 | — | N/A | unit | `grep -c '<text' brandbook/assets/specimens/typography.svg` (≥1) | ❌ W0 | ⬜ pending |
| 99-04-01 | 04 | 2 | SPEC-02 | — | N/A | smoke | `ls brandbook/assets/specimens/{components,code-block,readme-header,social-card}.svg` | ❌ W0 | ⬜ pending |
| 99-04-02 | 04 | 2 | SPEC-01/02 | — | N/A (no embedded raster — repo policy) | unit | `grep -c base64 brandbook/assets/specimens/*.svg` (all 0) | ❌ W0 | ⬜ pending |
| 99-04-03 | 04 | 2 | SPEC-01/02 | — | N/A | integration | `bash scripts/ci/lint.sh 2>&1 \| grep 'SVG SIZE BUDGET OK'` | ✅ lint.sh | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs above are indicative; the planner finalizes exact plan/wave assignment. The verification commands are the contract.*

---

## Wave 0 Requirements

- [ ] `brandbook/assets/specimens/` — directory must be created before any SVG authoring (lint.sh size loop uses `nullglob` and silently passes on a missing dir → false-green risk)
- [ ] No new test files or test framework — all validation is file-existence + `grep` + the existing `scripts/ci/lint.sh` size-budget loop

*No framework install needed. Existing lint.sh infrastructure covers the phase gate.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Swatch hex/token labels render legibly and match `tokens.css` | SPEC-01 | Visual fidelity of annotations is not machine-checkable beyond presence | Open `palette.svg` in browser; confirm each swatch shows its hex + `--rs-*` token name matching `tokens.css` |
| Type ramp renders in Sora/Inter/IBM Plex Mono with correct fallbacks | SPEC-01 | Font rendering is visual; CDN unreachable in exec-env | Open `typography.svg`; confirm ramp rows labeled with token names; acceptable to verify via `font-family` stack presence |
| `components.svg` faithfully reflects re-skinned mineral admin buttons/cards/badges | SPEC-02 | Faithfulness to `rulestead_admin.css` is a visual judgment | Compare swatch colors/radius/borders against `rulestead_admin.css` Block 1 values |
| README header + social card read well at intended display size | SPEC-02 | Composition quality is subjective | Open both in browser at target dimensions |

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify or Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the specimens directory creation (MISSING reference)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter (set by planner once tasks carry verify commands)

**Approval:** pending
