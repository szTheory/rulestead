---
phase: 96
slug: design-tokens-brandbook-scaffold
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
validated: 2026-06-04
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | python3 stdlib drift-check scripts + bash CI (`scripts/ci/lint.sh`) — no unit-test framework (correct for a static-config scaffold phase) |
| **Config file** | none — each check is a self-contained stdlib script (`sys`, `re`, `json`) |
| **Quick run command** | `python3 scripts/check_tokens_css.py` (exit 0) · `python3 scripts/check_brand_tokens.py` (exit 1 by design) |
| **Full suite command** | `bash scripts/ci/lint.sh` |
| **Estimated runtime** | ~2 seconds (token checks); lint.sh full ~minutes (mix toolchain) |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/check_tokens_css.py` (expect exit 0) + `python3 scripts/check_brand_tokens.py` (expect exit 1 until Phase 98)
- **After every plan wave:** Run `python3 scripts/check_synced_pair.py` + `python3 scripts/check_contrast.py` (both exit 0 — Phase 95 regression guards)
- **Before `/gsd:verify-work`:** tokens.json parses as JSON; tokens.css mirror exits 0; brand-token check exits 1 with per-token diff (the intended pre-Phase-98 state)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 96-01-01 | 01 | 1 | TOK-01, TOK-03 | — | tokens.json parses as valid DTCG; admin_css_mapping has 37 light / 31 dark `--rs-*` hex tokens | script-exit | `python3 scripts/check_brand_tokens.py` (loads + reads admin_css_mapping; intentional exit 1) + `python3 -c "import json; json.load(open('brandbook/tokens.json'))"` | ✅ | ✅ green |
| 96-01-02 | 01 | 1 | TOK-02, TOK-04 | — | tokens.css `--rs-*` light/dark blocks mirror tokens.json admin_css_mapping verbatim (Tailwind excerpt present in trailing comment) | script-exit | `python3 scripts/check_tokens_css.py` (**new this audit** — exits 0, 68 tokens synced) | ✅ | ✅ green |
| 96-02-01 | 02 | 1 | TOK-01 | — | brand-book §12 hexes reconciled to AA-verified canonicals; relocated via git mv (history preserved) | manual | see Manual-Only table | ✅ | 🔵 manual |
| 96-02-02 | 02 | 1 | — (docs) | — | README.md + docs/brand-usage.md exist, cross-link check script + intentional-failure + synced-pair rule | file-exists | `test -f brandbook/README.md && test -f brandbook/docs/brand-usage.md` | ✅ | ✅ green |
| 96-03-01 | 03 | 2 | TOK-03 | — | check_brand_tokens.py exits 1 with ≥7-token per-token diff against un-re-skinned admin CSS (gate-zero PASS) | script-exit | `python3 scripts/check_brand_tokens.py; [ $? -eq 1 ]` | ✅ | ✅ green |
| 96-03-02 | 03 | 2 | TOK-03 | — | lint.sh additively extended (synced-pair + brand-token + tokens.css + SVG-budget); all original lines preserved | script-exit | `bash -n scripts/ci/lint.sh` + `grep -c 'check_tokens_css.py\|check_brand_tokens.py\|SVG SIZE BUDGET OK' scripts/ci/lint.sh` | ✅ | ✅ green |
| 96-04-01 | 04 | 3 | TOK-01..04 | — | SC-1..SC-5 assertions pass; regression guards (synced-pair, contrast) exit 0 | script-exit | `python3 scripts/check_synced_pair.py && python3 scripts/check_contrast.py` | ✅ | ✅ green |
| 96-04-02 | 04 | 3 | — (tracking) | — | STATE.md / ROADMAP.md reflect Phase 96 complete | n/a | tracking-doc update (no runtime behavior) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · 🔵 manual*
*Note: For this phase, success criterion 3 deliberately requires `check_brand_tokens.py` to exit NON-ZERO against the un-re-skinned admin CSS — a "red" brand-token check is the GREEN state for Phase 96. Verification asserts exit 1 + a per-token diff, not exit 0. By contrast, the new `check_tokens_css.py` mirror guard exits 0 now and stays green (it compares the hand-authored mirror against its own JSON source of truth, not against the admin cascade).*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Both drift-check inputs were produced in-phase (no separate Wave-0 bootstrap needed):

- ✅ `brandbook/tokens.json` — DTCG source consumed by both checks (Plan 01)
- ✅ `scripts/check_brand_tokens.py` — json→admin-css drift guard (Plan 03)
- ✅ `scripts/check_tokens_css.py` — json→tokens.css mirror guard (added this validation audit)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| §12 brand-book hexes match AA-verified palette | TOK-01 (brand truth) | Prose reconciliation, not script-checkable | Diff §12 against `95-PALETTE-RECONCILIATION.md` §4/§8 |
| 'border' token-group interpretation (TOK-03) | TOK-03 | Spec-wording interpretation: the `border` group is realized as border-COLOR tokens (`--rs-*-border`), with no literal border-width scalar in the shipped CSS to mirror | Resolved in `96-VERIFICATION.md` frontmatter (architect decision, accepted interpretation (a)) — no automated check applicable |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are explicitly manual-only (2 manual: §12 prose reconciliation, TOK-03 border interpretation)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none outstanding — both check inputs in-phase)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-04

---

## Validation Audit 2026-06-04

State A audit of the draft VALIDATION.md skeleton against the executed phase (4 plans, 8 tasks). Filled the placeholder Per-Task Map with the real verified commands, and closed the single automated-coverage gap.

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap resolved:** `brandbook/tokens.css` (the hand-authored reference mirror, TOK-02/TOK-04) had no standing automated drift guard — `check_brand_tokens.py` compares tokens.json against `rulestead_admin.css` (exits 1 by design), but nothing verified tokens.css against its own JSON source of truth. Added `scripts/check_tokens_css.py` (mirrors the comment-strip + brace-walk algorithm of `check_brand_tokens.py`; compares light `.rs-shell,` and dark `.rs-shell[data-theme="dark"],` blocks against `admin_css_mapping.light`/`.dark`; case-insensitive; skips DTCG `$description` metadata). Verified exit 0 — `TOKENS.CSS MIRROR SYNCED (68 tokens)` — and wired additively into `scripts/ci/lint.sh`. Adversarial negative-control confirmed the guard fails on injected drift (not a trivial always-pass).
