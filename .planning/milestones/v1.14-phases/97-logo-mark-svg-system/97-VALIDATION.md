---
phase: 97
slug: logo-mark-svg-system
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-05
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase authors brand SVG assets — every validation is a grep-count,
> file-existence, or lint-exit assertion. No unit-test framework is involved.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash + grep + Python (no test framework — checks are grep-count / file-existence / lint-exit assertions) |
| **Config file** | none — checks are inline shell commands |
| **Quick run command** | `bash scripts/ci/lint.sh` (SVG size-budget loop — no-op until `brandbook/assets/logo/` exists) |
| **Full suite command** | `bash scripts/ci/lint.sh` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run the inline grep assertion(s) for that task's success criterion.
- **After every plan wave:** Run `bash scripts/ci/lint.sh`.
- **Before `/gsd:verify-work`:** `lint.sh` exits 0 with `SVG SIZE BUDGET OK`; all grep-count assertions below pass; demo backend still boots and serves the new logo.
- **Max feedback latency:** ~3 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists (pre) | Status |
|---------|------|------|-------------|-----------|-------------------|-------------------|--------|
| 97-01-* | 01 | 1 | LOGO-01 | smoke | `ls brandbook/assets/logo/concepts/rs-mark-concept-{a,b,c}.svg` (expect 3) | ❌ W1 creates | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-01/02 | smoke | `ls brandbook/assets/logo/rs-{wordmark,wordmark-dark,mark,mark-dark,mark-mono,favicon,social-card}.svg \| wc -l` (expect 7) | ❌ W2 creates | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-02 | grep | `grep -c '<text' brandbook/assets/logo/*.svg` (all 0 — glyphs outlined) | ❌ | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-03 | grep | `grep -c 'base64' brandbook/assets/logo/*.svg` (all 0) + `grep -rl 'http' brandbook/assets/logo/*.svg` (none external) | ❌ | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-03 | grep | `grep 'viewBox="0 0 1200 630"' brandbook/assets/logo/rs-social-card.svg` | ❌ | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-04 | grep | `for f in brandbook/assets/logo/*.svg; do grep -q '<title' "$f" \|\| echo "MISSING TITLE: $f"; done` (no output) | ❌ | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-04 | grep | `grep -c 'currentColor' brandbook/assets/logo/rs-mark-mono.svg` (> 0) | ❌ | ⬜ pending |
| 97-02-* | 02 | 2 | LOGO-04 | integration | `bash scripts/ci/lint.sh` → `SVG SIZE BUDGET OK` (all logo SVGs ≤20480 bytes) | ✅ lint.sh exists | ⬜ pending |
| 97-03-* | 03 | 3 | LOGO-04 | smoke | `ls rulestead_admin/priv/static/images/rs-mark.svg rulestead_admin/priv/static/images/rs-mark-dark.svg` | ❌ W3 creates | ⬜ pending |
| 97-03-* | 03 | 3 | LOGO-05 | grep | `grep -c 'FD4F00' examples/demo/backend/priv/static/images/logo.svg` (0 — phoenix-flame fill gone) | ✅ (old logo.svg) | ⬜ pending |
| 97-03-* | 03 | 3 | LOGO-05 | smoke | `ls examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg 2>/dev/null \| wc -l` (0 — old hash gone) | ✅ (currently 1) | ⬜ pending |
| 97-03-* | 03 | 3 | LOGO-05 | smoke | `ls examples/demo/backend/priv/static/images/logo-*.svg \| wc -l` (1 — new fingerprint) + `ls examples/demo/backend/priv/static/images/logo*.gz \| wc -l` (2 — regenerated sidecars) | ✅ | ⬜ pending |
| 97-04-* | 04 | 4 | LOGO-01..05 | integration | full phase SC sweep: all greps above pass + `bash scripts/ci/lint.sh` exits 0 + demo boots | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — no test files to create. All validation is grep-count / file-existence / lint-exit assertions runnable inline in plan tasks. `scripts/ci/lint.sh` SVG size-budget loop is already wired (Phase 96) and is a no-op until `brandbook/assets/logo/` exists.

*Existing infrastructure (lint.sh) covers all automatable phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Concept A/B/C selection | LOGO-01 | Brand/design decision — cannot be automated (ROADMAP human checkpoint) | Maintainer reviews `CONCEPT-REVIEW.md` (or rendered concepts) and selects A, B, or C before the full lockup is authored. Mid-phase gate; the selecting task is `autonomous: false`. |
| `rs-favicon.svg` legible at 16px | LOGO-03 | No automated 16px render-legibility check exists | Render `rs-favicon.svg` on a 16×16 canvas (browser `<img width="16">` or screenshot) and confirm the mark reads clearly. |
| Mark renders correctly in demo | LOGO-05 | Visual confirmation the new mark displays in place of phoenix-flame | Boot demo backend, load the layout, confirm `/images/logo.svg` shows the new mark at width=36. |

---

## Validation Sign-Off

- [x] All tasks have an automated grep/file-existence/lint verify OR a documented manual-only gate
- [x] Sampling continuity: every wave has at least one automated assertion; no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — no test infra needed)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-05
