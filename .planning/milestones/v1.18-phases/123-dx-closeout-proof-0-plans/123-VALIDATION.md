---
phase: 123
slug: dx-closeout-proof-0-plans
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-17
validated: 2026-06-17
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a **documentation + measurement-reconciliation + verification** phase — no product
> runtime code. Acceptance is proven by source/structure assertions on doc content plus the
> test-enforced doc-drift guard, not subjective review.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) + bash `scripts/ci/lint.sh` guard chain |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Full suite command** | `bash scripts/ci/lint.sh && cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~10–20 seconds (lint guards + focused doc-drift module; `async: true`, no DB) |

---

## Sampling Rate

- **After every task commit:** Run `cd rulestead && mix test test/rulestead/release_contract_test.exs`
  (the load-bearing doc-drift guard — editing `MAINTAINING.md` is exactly what breaks it; **lives OUTSIDE `lint.sh`**, D-15).
- **After every plan wave:** Run `bash scripts/ci/lint.sh && cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs`
- **Before `/gsd:verify-work`:** Full suite must be green.
- **Max feedback latency:** ~20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-CLOSEOUT | closeout | 1 | CIDX-10 | — / — | N/A (no attack surface) | structure | `grep -Ec 'wall.clock\|p95\|cache hit\|slow test\|flake\|residual risk\|rollback' .planning/phases/123-dx-closeout-proof-0-plans/123-CI-CD-CLOSEOUT.md` (=18, ≥7) | ✅ | ✅ green |
| 123-CLOSEOUT-TAGS | closeout | 1 | CIDX-10 | — / — | N/A | source | `grep -cE '\[(VERIFIED\|CITED\|ASSUMED):' .planning/phases/123-dx-closeout-proof-0-plans/123-CI-CD-CLOSEOUT.md` (=42, ≥10) | ✅ | ✅ green |
| 123-LADDER | maintaining | 2 | CIDX-08 | — / — | N/A | source | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ✅ green |
| 123-CI-ALIAS | maintaining | 2 | CIDX-08 | — / — | N/A | source | `grep 'ci:.*contributor.sh' rulestead/mix.exs` | ✅ | ✅ green |
| 123-TRIAGE | maintaining | 2 | CIDX-08/CIDX-10 | — / — | N/A | source | `grep -A2 'CI Failure Triage' MAINTAINING.md` | ✅ | ✅ green |
| 123-D14-GUARD | maintaining | 2 | CIDX-08/CIDX-10 | — / — | N/A (anti-drift; deferable w/ recorded residual risk) | unit | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ✅ green |
| 123-LINT | verify | 3 | CIDX-08/CIDX-10 | — / — | N/A | lint | `bash scripts/ci/lint.sh` (exit 0) | ✅ | ✅ green |
| 123-DOCDRIFT | verify | 3 | CIDX-08/CIDX-10 | — / — | N/A | unit | `cd rulestead && mix deps.get && mix test test/rulestead/release_contract_test.exs` (26 tests, 0 failures) | ✅ | ✅ green |
| 123-TRACE | verify | 3 | CIDX-08/CIDX-10 (D-19) | — / — | N/A | source | `grep -A1 'CIDX-08\|CIDX-10' .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ✅ green |
| 123-STATE | verify | 3 | D-20 | — / — | N/A | source | `grep 'completed_phases\|percent:' .planning/STATE.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs are illustrative — the planner assigns final `{N}-{plan}-{task}` ids. Mapping shows every CIDX-08/CIDX-10 claim has an automated source/structure/unit assertion.*

> **Audit correction (2026-06-17):** The `123-CLOSEOUT-TAGS` command was originally written with
> bare tag syntax (`\[VERIFIED\]\|\[CITED\]\|\[ASSUMED\]`), which returned 0 — the closeout
> ledger's evidence convention always carries content (`[CITED: path:lines]`), matching the
> `119-CI-CD-AUDIT.md` style (flagged in `123-01-SUMMARY.md:102`). Corrected to the ERE form
> `grep -cE '\[(VERIFIED\|CITED\|ASSUMED):'` (=42, ≥10). Coverage was never absent — only the
> recorded command was wrong.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* `release_contract_test.exs` already exists
(`async: true`, file-content asserts, no DB — D-18) and is the load-bearing verification target. The
optional D-14 anti-drift guard **extends** that module (3–5 `assert maintaining =~` lines, Option A per
research) rather than introducing new infrastructure.

*If D-14 is deferred:* record the gap as "D-14 triage-table anti-drift guard deferred — residual risk
recorded in `123-CI-CD-CLOSEOUT.md`."

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Closeout ledger reads as a coherent CIDX-10 audit trail (evidence tags, Oban-grade perf framing, relocation-not-deletion) | CIDX-10 | Narrative coherence is a review judgment, but every *metric* is independently grep-assertable above | Read `123-CI-CD-CLOSEOUT.md`; confirm all seven fields present, each metric tagged, perf claims state endpoints+corpus+factor+caveat |
| Triage microcopy matches `scripts/ci/test.sh` guidance verbatim (single source of truth) | CIDX-08 | Verbatim-match is partly assertable but tone/column-fit is review | Diff triage rows against `print_*_failure_guidance` functions in `scripts/ci/test.sh` |

*All structural/source claims have automated verification above; only narrative coherence and verbatim-microcopy fit are manual.*

---

## Cited-as-Not-Runnable (honest non-execution — D-16/D-17)

These are **recorded as skipped-by-design**, never silently omitted (mirrors `122-VERIFICATION.md:89-91`):

- Mounted-admin / OpenFeature companion proofs, DB-backed product suites, demo backend — no signal for a docs diff (D-16).
- `publish-hex` / `mix hex.publish` — irreversible, gated, no version change (D-17).
- `verify-published-release` / `mix verify.release_publish` — live hex.pm network; `published_hex_smoke` stays opt-in via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` (D-17).
- Live branch-protection / `gh api` reconciliation — docs-only, no gh-api writes (D-17).
- CI matrix timing / `release_gate` aggregation — observable only in GitHub Actions; mirrored locally by lint+test (D-17).

---

## Validation Audit 2026-06-17

| Metric | Count |
|--------|-------|
| Requirements audited (rows) | 10 |
| COVERED (green) | 10 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 1 (buggy command, not a coverage gap) |
| Resolved | 1 (corrected `123-CLOSEOUT-TAGS` grep to ERE form) |
| Escalated | 0 |
| Tests generated | 0 (existing infra suffices — no new tests needed) |

All 10 CIDX-08/CIDX-10 automated verifies re-run green against the executed phase:
lint.sh exit 0, `release_contract_test.exs` 26 tests / 0 failures (incl. D-14 guard),
all source/structure greps match. No `gsd-nyquist-auditor` spawn required — no MISSING/PARTIAL
coverage to fill. The single finding was a non-runnable command string in the map (now fixed),
never an absence of verification.

---

## Validation Sign-Off

- [x] All tasks have an `<automated>` verify (source/structure/unit) or are listed under Manual-Only with rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra suffices)
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter (confirmed by re-running all 10 verifies green)

**Approval:** validated 2026-06-17 — Phase 123 is Nyquist-compliant.
