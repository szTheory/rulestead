---
phase: 43
slug: mounted-contract-verification-closure
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-25
---

# Phase 43 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| docs -> adopter expectations | Mounted companion docs can overstate the supported contract or imply standalone admin posture. | host-owned auth/session seams, supported lifecycle workflow, package-boundary claims |
| mounted router seam -> host integrations | Route or query drift can break mounted host links even when LiveViews still exist. | mount path, `?env=` normalization, `return_to` continuity |
| test fixtures -> public contract truth | Lifecycle/admin tests can silently prove an obsolete authored payload long after the product contract changes. | ownership embed, lifecycle embed, cleanup-flow expectations |
| permission assertions -> security posture | Weak preview/confirm proof could let docs claim safer destructive flows than the shipped gate actually enforces. | viewer versus execute/admin capability boundaries, redirect behavior |
| test commands -> support truth claims | If the scoped proof bar drifts or flakes, maintainers can overstate what is actually green. | CI wrapper commands, release/support wording, bounded verification posture |
| maintainer guidance -> future release posture | Support and release docs must stay tied to the same targeted proof bar instead of widening Phase 43 scope. | proof-bar command, bounded green claims, sibling-package release posture |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-43-01 | I | `rulestead_admin/README.md`, `guides/flows/admin-ui.md` | mitigate | Docs keep the host-owned auth/session seam explicit and frame `rulestead_admin` as a mounted companion rather than a standalone surface. | closed |
| T-43-02 | T | `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` | mitigate | Mounted integration proof asserts `?env=` normalization plus cleanup-route and `return_to` carry-through at the host seam. | closed |
| T-43-03 | E | docs and integration proof | mitigate | Cleanup remains viewer-readable while preview/confirm stay execute/admin-gated in both docs and tests. | closed |
| T-43-04 | T | lifecycle/admin-contract tests | mitigate | Queue and cleanup-family suites now seed the embed-based authored payload instead of legacy top-level fields. | closed |
| T-43-05 | E | cleanup preview/confirm proof | mitigate | Unauthorized preview/confirm access still resolves through mounted redirects rather than rendering destructive UI. | closed |
| T-43-06 | R | cleanup confirm drift checks | mitigate | Confirm flow still proves required reason, typed confirmation, and preview-signature drift revalidation. | closed |
| T-43-07 | R | `scripts/ci/test.sh`, `MAINTAINING.md` | mitigate | Phase 43 now uses one explicit `mounted_admin_contract` proof bar across the mounted admin suites and targeted core contract tests. | closed |
| T-43-08 | I | `README.md`, `rulestead_admin/README.md` | mitigate | Public claims stay bounded to the repaired mounted lifecycle/admin surface instead of implying repo-wide or standalone-admin closure. | closed |
| T-43-09 | T | maintainer release/support workflow | mitigate | Maintainer guidance points to the same scoped proof-bar command used to justify the bounded support claim. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

Evidence used for closure:
- No `## Threat Flags` sections were present in `43-01-SUMMARY.md`, `43-02-SUMMARY.md`, or `43-03-SUMMARY.md`.
- `rg -n "mounted companion|host owns|policy:|session|\\?env=|return_to|cleanup.*preview.*confirm.*audit|viewer|execute|admin|bounded|mounted_admin_contract|admin_contract_test|admin_lifecycle_test" README.md rulestead_admin/README.md MAINTAINING.md guides/flows/admin-ui.md guides/flows/flag-lifecycle.md scripts/ci/test.sh rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` -> passing on rerun 2026-05-25 (`20 tests, 0 failures` in `rulestead_admin`; `12 tests, 0 failures` in `rulestead`)
- Audit note: an earlier local run hit a non-reproducible `Rulestead.Fake.Control.reset!/1` failure during the combined `index_test.exs` setup; an immediate isolated rerun of `index_test.exs` and a full proof-bar rerun both passed, so the phase remained closed rather than accepted as risk.

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 9 | 9 | 0 | Codex (`$gsd-secure-phase 43`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
