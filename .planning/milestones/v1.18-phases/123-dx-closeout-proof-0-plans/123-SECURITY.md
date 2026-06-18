---
phase: 123
slug: dx-closeout-proof-0-plans
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-17
---

# Phase 123 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register origin: **authored at plan time** (`<threat_model>` blocks in 123-01/02/03-PLAN.md).
> Verification-only mode — mitigations confirmed present, no new STRIDE register built.

**Result:** SECURED — 12/12 declared threats CLOSED. One non-blocking unregistered flag (UF-123-A) logged for maintainer awareness. Phase is a documentation + ExUnit closeout (no new endpoints, auth paths, or runtime code); all `mitigate` controls located at cited locations, both `accept` dispositions verified genuinely low-risk.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Planning docs → repo | Edits to planning artifacts / 119-CI-CD-AUDIT.md do not touch Hex package code, workflow YAML, or release trust surfaces | Documentation text only |
| MAINTAINING.md triage microcopy → reader trust | Wrong command names could cause a maintainer to issue a mis-scoped CI rerun during an outage | Operator guidance |
| release_contract_test.exs → MAINTAINING.md | File-content assertions guard doc drift; loose assertions give false assurance | Test-enforced doc invariants |
| Verification gate → STATE flip | STATE.md must not flip to 100% before lint.sh + release_contract_test.exs exit 0 | Milestone completion signal |
| Planning docs → release trust | ROADMAP/REQUIREMENTS edits are declarative; they do not change workflow YAML or publish posture | Declarative roadmap state |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-123-01 | Tampering | 123-CI-CD-CLOSEOUT.md fabricated metrics | mitigate | 42 evidence tags `[VERIFIED/CITED/ASSUMED:]`; zero untagged metric rows; p95 honest-gap at :51; relocation framing `[CITED: 121-MEASUREMENT.md:154]` at :43 | closed |
| T-123-02 | Repudiation | 119-CI-CD-AUDIT.md:213 catalog edit | mitigate | Fast-loop row now `cd rulestead && mix ci (alias for bash scripts/ci/contributor.sh)`; single-line targeted edit, version-controlled (commit e14a1dd) | closed |
| T-123-03 | Info Disclosure | Rollback notes exposing secrets | accept | Only env-var names (`RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`), the `hex-publish` env, and commit handles printed — no secret values | closed |
| T-123-04 | Tampering | MAINTAINING.md triage commands rotting vs scripts/ci/test.sh | mitigate | MAINTAINING.md:133 matches scripts/ci/test.sh:74 verbatim; boundary text matches test.sh:73; D-14 guard asserts scope-wrapper (test.exs:300) | closed |
| T-123-05 | Tampering | Protected MAINTAINING.md sections edited | mitigate | Edits confined after :111; branch-protection (:32-61), cache (:63-78), release runbook unaltered; release_contract_test.exs passes (26/0) | closed |
| T-123-06 | Repudiation | D-14 guard too weak | mitigate | release_contract_test.exs:294-302 table-cell-anchored asserts (stronger than spec) for all 4 drift-prone tokens | closed |
| T-123-07 | Elevation of Privilege | Blind-rerun anti-pattern | mitigate | MAINTAINING.md:135-136 — `publish-hex` & `verify-published-release` both read "release-trust gate, not a speed target" | closed |
| T-123-08 | Repudiation | STATE.md flipped before verification gates pass | mitigate | STATE flip (ec46656) lands after gates-green (b9022d9); SUMMARY records GATE 1 (lint.sh) + GATE 2 (release_contract_test.exs) exit 0 first | closed |
| T-123-09 | Tampering | Irreversible publish steps during verification | mitigate | No `mix hex.publish` / `gh api` write additions; sole publish string is doc text labeled "NOT re-runnable / Irreversible" | closed |
| T-123-10 | Info Disclosure | STATE.md inaccuracy persists to next milestone | mitigate | STATE.md:10 `completed_phases: 5`, :13 `percent: 100`, :5 `status: milestone_complete`; no stale "Phase 122 final" language | closed |
| T-123-11 | Denial of Service | D-14 guard breaks on Wave 2 typo | mitigate | release_contract_test.exs runs as Gate 2 before flip; 26 tests / 0 failures recorded in 123-02 & 123-03 SUMMARYs | closed |
| T-123-SC | Tampering | npm/pip/cargo installs | accept | Zero `npm/pip/cargo/yarn install` additions in phase diff; doc authoring + one ExUnit extension only | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-123-01 | T-123-03 | Rollback/closeout notes could in principle leak a secret. Verified: only env-var names, the `hex-publish` environment identifier, and commit/PR handles appear — no secret values. Low residual risk. | gsd-security-auditor | 2026-06-17 |
| AR-123-02 | T-123-SC | Supply-chain risk from package installs. Verified: zero `npm/pip/cargo/yarn install` additions in the phase diff; no new dependencies introduced. | gsd-security-auditor | 2026-06-17 |

*Accepted risks do not resurface in future audit runs.*

---

## Unregistered Flags

**WARNING — UF-123-A (non-blocking, low/informational): CI guard script repointed + new trust-anchor file created, no threat mapping.**

Phase 123 modified `scripts/check_admin_foundations.py` and created `brandbook/admin-foundations-contract.md` (commit `d13e6a1`), discovered ad-hoc during D-15 verification (lint.sh had been red on `main` for the whole v1.18 milestone) and documented at 123-CI-CD-CLOSEOUT.md:160.

- **Why it is a flag:** All three plans declared `files_modified` covering only planning docs, MAINTAINING.md, and release_contract_test.exs, and each threat model affirmed "doc + ExUnit only." Repointing a CI guard script and creating the contract file it now trusts is new attack surface (the integrity anchor for live admin CSS-drift validation moved from an archived path to a new living file) that maps to no threat ID and appeared in no plan.
- **Severity:** Low / informational — **not a BLOCKER under `block_on: high`.** The relocated contract is content-faithful: enforced `REQUIRED_CONTRACT_SECTIONS` body preserved; diff vs the archived original (`b78bedd~1`) is provenance frontmatter plus two clarifying header lines. Guard remains operative — `bash scripts/ci/lint.sh` exits 0 with `ADMIN FOUNDATIONS OK`, CSS-drift protection intact.
- **Follow-up recommended (already logged as residual risk in the closeout ledger):** audit `scripts/ci/*` and `scripts/check_*.py` for other archival-fragile path constants under `.planning/phases/` that future milestone archival will break.

### Minor Observations (non-threat, no action required)

- **D-12 drift, adopter-contract row:** during code review (commit `cf8d48d`) the `adopter-contract` triage rerun changed from the plan's `cd rulestead && mix verify.adopter` to `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh` — a code-review correction toward the true CI invocation, not a mitigation gap. The D-14 guard does not assert this row, and no declared threat depends on it.
- **Plan-grep vs convention mismatch (T-123-01):** the plan's literal `grep -c "\[VERIFIED\]\|..."` matches bare tags, but the file (mirroring 119's convention) uses `[CITED: path]` form. The broader ERE check confirms 42 tagged lines — the file is correct; the plan's grep pattern was imprecise. No defect.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-17 | 12 | 12 | 0 | gsd-security-auditor (ASVS L1, block_on: high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-17
