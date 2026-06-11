---
phase: 101
slug: html-brand-book
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-05
---

# Phase 101 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase is a generated static artifact, so the source of truth is proven by
> deterministic generation, drift checks, static HTML/SVG assertions, lint wiring,
> and targeted browser evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python 3 stdlib guard scripts + `scripts/ci/lint.sh`; optional Playwright browser evidence under existing `examples/demo/frontend` infrastructure |
| **Config file** | `scripts/ci/lint.sh` (existing scripts-first CI lane; Phase 101 adds generated-HTML drift check) |
| **Quick run command** | `python3 scripts/check_brandbook_html.py` |
| **Full suite command** | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_brandbook_html.py && bash scripts/ci/lint.sh` |
| **Estimated runtime** | ~5 seconds for guard/lint checks; browser evidence runtime depends on the existing Playwright fixture if used |

---

## Sampling Rate

- **After every generator/rendering task commit:** Run `python3 scripts/gen_brandbook_html.py && python3 scripts/check_brandbook_html.py`
- **After every guard/CI task commit:** Run `python3 scripts/check_brandbook_html.py && bash scripts/ci/lint.sh`
- **After every plan wave:** Run the full guard suite listed above
- **Before `/gsd:verify-work`:** Full guard suite must be green and browser/static evidence must cover light, dark, system/no-JS, required sections, and inline assets
- **Max feedback latency:** ~5 seconds for non-browser guard feedback

---

## Per-Task Verification Map

> Plan/task IDs are indicative; the planner finalizes exact plan/wave assignment.
> The verification commands are the contract.

| Requirement | Wave | Validation Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|------|---------------------|-----------|-------------------|-------------|--------|
| BOOK-01 / D-04-D-10 | 1 | Generated `brandbook/index.html` contains the required section IDs in order and uses `[data-rulestead-brandbook]` scoped theme CSS | automated static | `python3 scripts/check_brandbook_html.py` | missing W0 | pending |
| BOOK-01 / D-07-D-08 | 1 | Final logo/specimen previews are embedded inline, have unique SVG IDs, and expose accessible names when non-decorative | automated static | `python3 scripts/check_brandbook_html.py` | missing W0 | pending |
| BOOK-01 / UI-SPEC | 1 | Browser-opened `brandbook/index.html` shows required sections, nav, inline assets, and theme controls at desktop and mobile widths | browser evidence | optional existing Playwright file:// check or manual browser checklist | optional | pending |
| BOOK-02 / D-01-D-03 | 1 | `scripts/gen_brandbook_html.py` renders deterministic HTML from canonical sources without external build dependencies | automated generation | `python3 scripts/gen_brandbook_html.py && python3 scripts/check_brandbook_html.py` | missing W0 | pending |
| BOOK-02 / D-11-D-13 | 2 | Drift checker byte-compares generated output against committed `brandbook/index.html`, emits concise diff on drift, and enforces HTML size budget | automated guard | `python3 scripts/check_brandbook_html.py` | missing W0 | pending |
| BOOK-02 / D-12 | 2 | CI lint lane runs the generated-HTML guard after token checks and before SVG budget checks | automated integration | `bash scripts/ci/lint.sh` | existing | pending |
| BOOK-01/02 / D-14-D-15 | 3 | Milestone closeout updates happen only after generator, drift, budget, lint, and browser/static verification pass | source review + guards | `rg -n "v1.14|BOOK-01|BOOK-02|Phase 101" .planning/PROJECT.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md` | existing | pending |

*Status: pending / green / red / flaky.*

---

## Wave 0 Requirements

- [ ] `scripts/check_brandbook_html.py` - generated-HTML drift and static assertion guard for `brandbook/index.html`
- [ ] `scripts/gen_brandbook_html.py` - deterministic stdlib generator with importable render function
- [ ] `brandbook/index.html` - generated review artifact committed after the generator is in place
- [ ] `brandbook/BUDGET.md` - documents generated HTML byte budget without relaxing existing SVG budgets

No new runtime framework is required. Browser evidence may reuse the existing Playwright stack if the planner chooses to add a narrow file:// fixture, but CI lint should remain scripts-first unless the plan explicitly accepts the cost.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual composition reads as the approved brand book, not a marketing landing page | BOOK-01 / UI-SPEC | Static assertions cannot judge information hierarchy and visual polish | Open `brandbook/index.html` in a browser; confirm first viewport shows mark/wordmark, tagline, theme state, and direct section navigation |
| Light and dark rendered palettes preserve Phase 95 contrast decisions | BOOK-01 | Automated checks can assert tokens and contrast, but final composition still needs visual review | Toggle Light/Dark/System; inspect normal-weight text, token swatches, code blocks, and callouts for legibility |
| Motion is restrained and reduced-motion behavior is acceptable | BOOK-01 / UI-SPEC | Motion quality and reduced-motion comfort need human review unless a browser spec is added | With normal and reduced-motion preferences, confirm no bouncing, looping glow, jitter, or exaggerated motion appears |
| Milestone closeout timing is correct | BOOK-02 / D-14 | The "ship v1.14 only after verification" sequence is a process judgment | Review final commits and summaries; ensure `.planning/PROJECT.md` and `.planning/STATE.md` say v1.14 shipped only after checks pass |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify command or an explicit browser/manual verification note
- [ ] Sampling continuity: no 3 consecutive tasks without automated guard feedback
- [ ] Wave 0 covers the generator, drift checker, generated artifact, and budget doc before milestone closeout
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s for non-browser checks
- [ ] `nyquist_compliant: true` set in frontmatter once plans bind task IDs and verify commands

**Approval:** pending
