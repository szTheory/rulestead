---
phase: 98
slug: admin-re-skin-css-cascade
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-05
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> The python3 guard scripts ARE the validation oracle for this colors-only re-skin —
> the CSS edits have no Elixir unit tests; correctness is proven by guards exiting 0
> plus a final diff review (zero non-color lines changed).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python 3 stdlib guard scripts (project scripts-first CI pattern) |
| **Config file** | `scripts/ci/lint.sh` (wires guards at `:18,22,27`; exit-code-only parsing) |
| **Quick run command** | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py` |
| **Full suite command** | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py` (phase gate: `bash scripts/ci/lint.sh` from repo root) |
| **Estimated runtime** | ~2 seconds (guards only; no Elixir env needed) |

---

## Sampling Rate

- **After every task commit:** Run `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py`
- **After every plan wave:** Run all four guards (synced_pair + brand_tokens + tokens_css + contrast)
- **Before `/gsd:verify-work`:** Full `bash scripts/ci/lint.sh` from repo root must be green
- **Max feedback latency:** ~2 seconds (guards-only quick run)

---

## Per-Task Verification Map

> Plan/task IDs are filled by the planner; this map binds each requirement to its
> automated oracle. The two guard-script extensions (D-05a, D-05b) are Wave 0 work —
> they are the test infrastructure, created as part of this phase.

| Requirement | Wave | Validation Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|------|---------------------|-----------|-------------------|-------------|--------|
| SKIN-02 / D-05a | 0 | `check_synced_pair.py` also asserts Block 1≡4 (light pair) | automated (post-extension) | `python3 scripts/check_synced_pair.py` | ❌ W0 extend | ⬜ pending |
| SKIN-03 / D-05b | 0 | `check_brand_tokens.py` also diffs Block 3 vs `admin_css_mapping.dark` | automated (post-extension) | `python3 scripts/check_brand_tokens.py` | ❌ W0 extend | ⬜ pending |
| SKIN-01 | 1+ | Blocks 1–4 use mineral hex; zero non-color diff | source diff review + guards | `git diff rulestead_admin/priv/static/css/rulestead_admin.css` | ✅ | ⬜ pending |
| SKIN-02 | 1+ | Synced pairs 2≡3 AND 1≡4 byte-identical; WCAG-AA both themes | automated | `python3 scripts/check_synced_pair.py && python3 scripts/check_contrast.py` | ✅ (+W0) | ⬜ pending |
| SKIN-03 | 1+ | Block 1 light + Block 3 dark `--rs-*` match `tokens.json admin_css_mapping` | automated | `python3 scripts/check_brand_tokens.py` | ✅ (+W0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The two guard-script extensions are the only test-infrastructure gaps — and they ARE
part of the phase work (additive, stdlib-only, must preserve existing output/exit
semantics and `lint.sh` parse points):

- [ ] `scripts/check_synced_pair.py` — extend to also assert Block 1≡4 (light pair) — D-05a
- [ ] `scripts/check_brand_tokens.py` — extend to also diff Block 3 vs `admin_css_mapping.dark` — D-05b

*Already-passing infrastructure (no Wave 0 work): `check_contrast.py` (18 AA checks green), `check_tokens_css.py`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zero non-color property changes in the CSS diff (SC-1) | SKIN-01 | No guard inspects "only color lines changed" — the synced/brand guards check values, not the property-set delta | `git diff rulestead_admin/priv/static/css/rulestead_admin.css` — confirm every changed line is a `--rs-*` color declaration; no spacing/typography/radius/layout/structural line appears |

*All value-correctness and synced-pair behaviors have automated verification; only the "colors-only" diff-shape gate (SC-1) is human-reviewed.*

---

## Validation Sign-Off

- [ ] All tasks have automated guard verification or are the Wave 0 guard extensions themselves
- [ ] Sampling continuity: guard quick-run after every task commit
- [ ] Wave 0 covers both guard extensions (D-05a, D-05b) before value edits are gated
- [ ] No watch-mode flags (guards are one-shot, exit-coded)
- [ ] Feedback latency < ~2s
- [ ] `nyquist_compliant: true` set in frontmatter once map is bound to plan/task IDs

**Approval:** pending
