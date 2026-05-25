---
phase: 41
slug: release-truth-alignment
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 41 - Validation Strategy

> Per-phase validation contract for release-truth alignment across README surfaces, onboarding/support docs, companion proof language, and release-facing doc contracts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit doc-contract tests in `rulestead` plus file-integrity checks across root/package/onboarding docs |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `rg -n 'v1\\.0\\.0|2026-05-21|0\\.1\\.0|mounted companion|verify\\.release_publish|verify\\.release_parity' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/guides/introduction/installation.md /Users/jon/projects/rulestead/guides/introduction/getting-started.md /Users/jon/projects/rulestead/guides/introduction/upgrading.md /Users/jon/projects/rulestead/open_feature_rulestead/README.md /Users/jon/projects/rulestead/examples/demo/README.md /Users/jon/projects/rulestead/MAINTAINING.md` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs && rg -n 'v1\\.0\\.0|2026-05-21|0\\.1\\.0|runtime|mounted companion|Proof today|verify\\.release_publish|verify\\.release_parity' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/guides/introduction/installation.md /Users/jon/projects/rulestead/guides/introduction/getting-started.md /Users/jon/projects/rulestead/guides/introduction/upgrading.md /Users/jon/projects/rulestead/open_feature_rulestead/README.md /Users/jon/projects/rulestead/examples/demo/README.md /Users/jon/projects/rulestead/MAINTAINING.md` |
| **Estimated runtime** | ~10-20 seconds after compile warm-up |

---

## Sampling Rate

- **After the README task:** Run the README/package `rg` checks to confirm the new release story lands consistently.
- **After the onboarding/support task:** Run the guide/demo/companion `rg` checks so the bounded proof posture and runtime-first path stay aligned.
- **After the verification-guardrail task:** Run `mix test test/rulestead/release_contract_test.exs` plus the full doc grep set.
- **Before `$gsd-verify-work`:** Re-run the full suite command and confirm no stale “first public Hex release is planned for after `v0.6.0`” language remains in touched surfaces.
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | DOC-01 | T-41-01 | Root and sibling READMEs tell one explicit post-`v1.0.0` truth without standalone-admin drift | doc-integrity | `rg -n 'v1\\.0\\.0|2026-05-21|0\\.1\\.0|mounted companion|runtime' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md && ! rg -n 'planned for after `v0\\.6\\.0`|planned for after' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md` | ✅ | ⬜ pending |
| 41-01-02 | 01 | 1 | DOC-02 | T-41-02 | Installation, onboarding, demo, bridge, and upgrade docs all stay within the bounded proof posture | doc-integrity | `rg -n '0\\.1\\.0|runtime|admin|demo|verify\\.release_publish|verify\\.release_parity|OpenFeature|companion' /Users/jon/projects/rulestead/guides/introduction/installation.md /Users/jon/projects/rulestead/guides/introduction/getting-started.md /Users/jon/projects/rulestead/guides/introduction/upgrading.md /Users/jon/projects/rulestead/open_feature_rulestead/README.md /Users/jon/projects/rulestead/examples/demo/README.md` | ✅ | ⬜ pending |
| 41-01-03 | 01 | 1 | DOC-01, DOC-02 | T-41-03 | Release-facing tests and maintainer guidance enforce the new release/support truth and reject stale pre-GA claims | targeted-test + doc-integrity | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs && rg -n 'verify\\.release_publish|verify\\.release_parity|documented install or mount contract|0\\.1\\.0|v1\\.0\\.0' /Users/jon/projects/rulestead/MAINTAINING.md /Users/jon/projects/rulestead/rulestead/test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `41-01` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs && rg -n 'v1\\.0\\.0|2026-05-21|0\\.1\\.0|runtime|mounted companion|Proof today|verify\\.release_publish|verify\\.release_parity' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/guides/introduction/installation.md /Users/jon/projects/rulestead/guides/introduction/getting-started.md /Users/jon/projects/rulestead/guides/introduction/upgrading.md /Users/jon/projects/rulestead/open_feature_rulestead/README.md /Users/jon/projects/rulestead/examples/demo/README.md /Users/jon/projects/rulestead/MAINTAINING.md && ! rg -n 'planned for after `v0\\.6\\.0`|planned for after' /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Root and sibling release story matches the shipped posture | `41-01-01`, `41-01-03` | README rewrites plus release-contract enforcement |
| Installation and onboarding docs point to the real current package and proof posture | `41-01-02`, `41-01-03` | Guides and companion docs stay aligned |
| Support-facing language stays bounded where proof is incomplete | `41-01-02`, `41-01-03` | Demo and bridge surfaces stay discoverable but secondary |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| DOC-01 | `41-01-01`, `41-01-03` | README alignment plus test enforcement |
| DOC-02 | `41-01-02`, `41-01-03` | Guide/support alignment plus guardrails |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| One explicit root release note | `41-01-01` | Avoids competing narratives |
| Runtime-first onboarding and optional admin | `41-01-01`, `41-01-02` | Preserves the linked sibling-package model |
| Bounded proof posture | `41-01-02`, `41-01-03` | Keeps support truth honest |
| Tests for wording that changes support expectations | `41-01-03` | Prevents drift |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Keep the sibling-package model explicit | all tasks | No standalone-admin drift |
| Do not overstate demo/OpenFeature proof | `41-01-02`, `41-01-03` | Companion surfaces remain bounded |
| Do not widen into version-line realignment | all tasks | Docs reconcile truth without changing package versions |

Audit result: the single-plan set covers the full Phase 41 boundary without widening into new runtime features, version strategy changes, or future proof-closure work.

---

## Wave 0 Requirements

Existing docs, package metadata, maintainer guidance, and release-contract tests provide all required inputs. No additional scaffold is required.

---

## Manual-Only Verifications

No manual-only verification is required if the targeted release-contract test and doc grep checks pass.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-24
