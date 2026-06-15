# Phase 119 CI/CD Audit

Phase 119 records evidence and recommendations only. It does not edit workflow behavior, test behavior, release trust posture, product runtime APIs, schemas, `rulestead_admin` publish posture, browser baseline strategy, or test inclusion. It also does not introduce workflow-level path filters for required PR checks, tag-only publish trust, local publish shortcuts, weaker workflow permissions, weaker action pinning, unchecked Hex secret exposure, ExUnit async/sharding changes, checked-in pixel baselines, FleetDesk product rebranding, or Phase 8-only docs.

Requirements covered by this audit: CIDX-01, CIDX-02, and CIDX-03.

Evidence conventions:

- `[VERIFIED: path-or-command]` means the claim is backed by a repo file, local command, or live CLI/API command named in the tag.
- `[CITED: official-doc-url]` means the claim relies on official external documentation.
- `[ASSUMED: reason]` means the claim is an explicit assumption because live evidence was unavailable or not defensible from the current sample.

## Executive Recommendation

Pending final classification. The current working recommendation is to preserve the always-triggered `ci.yml` plus aggregate `release_gate` baseline while Phase 119 records static workflow inventory, live GitHub state, local Mix diagnostics, cache/PLT posture, and test/check classification before Phases 120-123 change behavior. [VERIFIED: .planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md]

## Evidence Collection

| Evidence Type | Source | Status |
|---------------|--------|--------|
| Phase scope and decisions | `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` | collected |
| Roadmap and requirements | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` | collected |
| Workflow definitions | `.github/workflows/*.yml` | collected |
| Script-first CI surfaces | `scripts/ci/*.sh`, `scripts/demo/*.sh` | collected |
| Live GitHub workflow list | `gh workflow list --repo szTheory/rulestead --all --json name,path,state,id` | collected |
| Live branch protection | `gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks` | collected |
| Live CI run timing | `gh run list --repo szTheory/rulestead --workflow ci.yml --limit 20 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch` | pending detailed analysis |
| Local Mix diagnostics | D-11 command set | pending |

## Workflow and Job Inventory

Live workflow state was collected with:

```bash
gh workflow list --repo szTheory/rulestead --all --json name,path,state,id
```

Result summary: all checked-in workflow files are active; GitHub also reports the dynamic `Dependabot Updates` workflow. [VERIFIED: gh workflow list --repo szTheory/rulestead --all --json name,path,state,id]

| File | Workflow name | Live ID | Triggers | Permissions | Concurrency | Jobs | Role |
|------|---------------|---------|----------|-------------|-------------|------|------|
| `.github/workflows/actionlint.yml` | `actionlint` | `265354684` | `pull_request` | `contents: read`, `pull-requests: write` | none | `actionlint` | advisory workflow syntax signal; not documented as required because path-filtered checks can sit pending |
| `.github/workflows/ci.yml` | `ci` | `265354303` | `push`, `pull_request`, `workflow_dispatch` | `contents: read`, `actions: read`, `checks: read` | `ci-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `openfeature-companion`, `mounted-proof`, `release_gate` | merge-blocking aggregate baseline through `release_gate` |
| `.github/workflows/dependency-review.yml` | `dependency-review` | `265354683` | `pull_request` | `contents: read` | none | `dependency-review` | documented required dependency supply-chain check |
| `.github/workflows/dependabot-automerge.yml` | `dependabot-automerge` | `265354685` | `pull_request` | `pull-requests: write`, `contents: write` | none | `auto-merge` | dependency automation |
| `.github/workflows/pr-title.yml` | `Validate PR title` | `265354686` | `pull_request` | `contents: read`, `pull-requests: read` | none | `validate-pr-title` | documented required release-note hygiene check |
| `.github/workflows/release-please.yml` | `release-please` | `265354302` | `push`, `workflow_dispatch` | `contents: write`, `pull-requests: write`, `issues: write`, `actions: write` | `release-please-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `release-please`, `dispatch-release-pr-ci`, `dispatch-publish` | release intent automation |
| `.github/workflows/release-pr-ci.yml` | `release-pr-ci` | `284980013` | `push`, `workflow_dispatch` | `contents: read`, `actions: write` | `release-pr-ci-${{ github.ref }}`, cancel in progress | `dispatch-ci` | release PR CI dispatch |
| `.github/workflows/release-pr-automerge.yml` | `release-pr-automerge` | `286030394` | `workflow_run`, `workflow_dispatch` | `contents: write`, `pull-requests: write`, `actions: write` | none | `automerge` | release PR automation |
| `.github/workflows/publish-hex.yml` | `publish-hex` | `274861464` | `workflow_dispatch` | `contents: read`, `actions: read`; handoff job adds `issues: write` | none | `preflight`, `gate-ci-green`, `approval`, `publish-core`, `publish-admin`, `handoff-post-publish` | protected release-only Hex publish |
| `.github/workflows/verify-published-release.yml` | `verify-published-release` | `274861466` | `schedule`, `workflow_dispatch` | `contents: read`, `issues: write` | `verify-published-release-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `verify-published-release` | post-publish proof and scheduled release hygiene |
| `.github/workflows/repo-hygiene.yml` | `repo-hygiene` | `286030395` | `schedule`, `workflow_dispatch` | `contents: read`, `issues: write` | none | `hygiene-check` | scheduled hygiene |

`ci.yml` stable job IDs are explicitly documented in the file comment and present in YAML: `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `openfeature-companion`, `mounted-proof`, and `release_gate`. [VERIFIED: .github/workflows/ci.yml]

`ci.yml` runner and service baseline:

- All jobs use `ubuntu-24.04`.
- `test` matrix axes are Elixir `1.17.3` / OTP `26.2.5` and Elixir `1.19.2` / OTP `28.4.3`.
- `test` and `adopter-contract` use a Postgres 15 service with `MIX_ENV=test`.
- `lint`, `test`, `adopter-contract`, `openfeature-companion`, and `mounted-proof` use Mix dependency/build caches.
- `lint` restores and saves `rulestead/priv/plts` with `actions/cache/restore` and `actions/cache/save`. [VERIFIED: .github/workflows/ci.yml]

## Required-Check Semantics

Live branch-protection state was collected with:

```bash
gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks
```

Exact output on 2026-06-15:

```json
{"message":"Branch not protected","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection","status":"404"}
gh: Branch not protected (HTTP 404)
```

documented-vs-live finding: `MAINTAINING.md` documents required checks (`release_gate`, `Validate PR title`, and `dependency-review`) and explicitly excludes path-filtered `actionlint`; the live GitHub API currently returns `Branch not protected`. This is external mutable repository state, not YAML source truth, so Phase 119 records it and makes no settings change. [VERIFIED: MAINTAINING.md; VERIFIED: gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks]

Required-check pending trap: workflow-level path filters must not be recommended for required PR checks. Path selectivity belongs inside always-reporting workflows or behind an aggregate required check. [VERIFIED: .planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md; CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

Aggregate gate baseline: `release_gate.needs` currently includes `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, and `mounted-proof`. The `openfeature-companion` job exists as a path-gated proof job, and openfeature-companion is absent from current release_gate.needs. Do not change `ci.yml` in Phase 119; carry this as a Phase 120 required-check semantics finding. [VERIFIED: .github/workflows/ci.yml]

## Critical Path and Metrics Baseline

Pending live timing and local diagnostic evidence.

## Cache and Dialyzer PLT Posture

Pending cache/PLT inventory.

## Mix, ExUnit, Dialyzer, and Xref Diagnostics

Pending D-11 diagnostics.

## Test and Check Classification Matrix

Pending D-03 classification.

## Rerun Command Catalog

Pending script-first rerun catalog.

## Failure Categories and Maintainer Microcopy

Pending maintainer microcopy catalog.

## Release and Supply-Chain Trust

Pending release and supply-chain trust inventory.

## Browser, Demo, and Integration Evidence

Pending browser/demo/integration evidence findings.

## No-Go and Rollback Guardrails

No Phase 119 recommendation may:

- Reduce release-gate trust without equivalent evidence.
- Break the linked-version sibling-package release design.
- Prepare `rulestead_admin` for standalone publishing.
- Replace generated browser artifacts with checked-in pixel baselines.
- Hide browser flakes behind blind retries.
- Delete or demote slow checks solely because they are slow.
- Move path selectivity to workflow-level filters for required PR checks.
- Change product runtime APIs, schemas, product UI, brand, or the design system.

## Handoff Notes for Phases 120-123

Pending evidence-backed handoff bullets.

## Sources

| Source | Role |
|--------|------|
| `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` | Phase decisions D-01 through D-21 |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-RESEARCH.md` | Research baseline and official/comparable pattern notes |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-PATTERNS.md` | Required audit pattern map |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-VALIDATION.md` | Validation strategy |
| `.planning/ROADMAP.md` | Phase sequence and success criteria |
| `.planning/REQUIREMENTS.md` | CIDX-01, CIDX-02, CIDX-03 |
| `.github/workflows/*.yml` | Workflow definitions |
| `scripts/ci/*.sh`, `scripts/demo/*.sh` | Script-first CI and proof commands |
| `MAINTAINING.md` | Documented branch-protection and release posture |
