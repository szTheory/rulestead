---
phase: 127
slug: adoption-guides
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 127 — Validation Strategy

> Per-phase validation contract. This is a DOCS-ONLY phase: the "tests" are the
> two repo guards that gate documentation truth, plus structural assertions on
> the two new guide files.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExDoc autolink gate + repo Python guards (no unit-test framework — docs phase) |
| **Config file** | `rulestead/mix.exs` (docs/extras), `scripts/ci/lint.sh` (guard chain) |
| **Quick run command** | `cd rulestead && mix docs --warnings-as-errors` |
| **Full suite command** | `cd rulestead && mix docs --warnings-as-errors && cd .. && python3 scripts/check_version_truth.py` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd rulestead && mix docs --warnings-as-errors` (catches broken autolinks / dangling refs in the new guides immediately).
- **After every plan wave:** Run the full suite (docs gate + version-truth guard).
- **Before `/gsd-verify-work`:** Full suite green AND `scripts/ci/lint.sh` docs lane green.
- **Max feedback latency:** 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 127-01-* | 01 | 1 | GUIDE-01 | structure | `grep -c '^## ' guides/recipes/troubleshooting.md` (== 7 patterns, Symptom→Cause→Fix→Verify) | ❌ W0 | ⬜ pending |
| 127-01-* | 01 | 1 | GUIDE-01 | autolink | `cd rulestead && mix docs --warnings-as-errors` | ✅ | ⬜ pending |
| 127-02-* | 02 | 1 | GUIDE-02 | structure | 4 recipes each carry Goal→For→Prerequisites→Steps→Verification→Gotchas→Related | ❌ W0 | ⬜ pending |
| 127-03-* | 03 | 2 | GUIDE-03 | wiring | `grep -n 'troubleshooting.md\|integrations-cookbook.md' rulestead/mix.exs` (cookbook early, troubleshooting last, no new group) + docs gate green | ✅ | ⬜ pending |
| seam-guard | all | 1 | GUIDE-01/02 | truth | `python3 scripts/check_version_truth.py` (no 0.1.x / ~> 0.1); seams limited to api_stability.md 1.x catalog | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `guides/recipes/troubleshooting.md` — new file (GUIDE-01)
- [ ] `guides/recipes/integrations-cookbook.md` — new file (GUIDE-02)

*No test framework to install — docs phase. The autolink + version-truth guards already exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Blame-free tone; footguns.md cross-linked not duplicated | GUIDE-01 | Tone/duplication is editorial judgment | Read troubleshooting.md; confirm each pattern links footguns anchors for the "why" and does not restate it |
| Persona/JTBD "For" lines map to real personas | GUIDE-02 | Semantic mapping to user-flows-and-jtbd.md | Confirm each recipe's "For" names a persona from guides/introduction/user-flows-and-jtbd.md |

*Editorial checks are inherently manual; the structural/truth checks above are automated.*

---

## Validation Sign-Off

- [ ] Both guide files exist with the required section structure
- [ ] `mix docs --warnings-as-errors` green (no broken autolinks)
- [ ] `scripts/check_version_truth.py` green (no 0.1.x drift)
- [ ] All recipe seams appear in api_stability.md 1.x catalog (no landmine seams headlined)
- [ ] GUIDE-03 wiring: cookbook early, troubleshooting last, getting-started.md untouched, no new extras group
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
