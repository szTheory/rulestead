# Phase 119: Baseline + Expert Audit - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 1
**Analogs found:** 1 / 1

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` | documentation / audit artifact | batch + transform + static/live inventory | `.planning/phases/119-baseline-expert-audit-0-plans/119-RESEARCH.md` plus repo-local CI docs/scripts | exact for phase artifact, role-match for audit content |

## Pattern Assignments

### `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` (documentation / audit artifact, batch + transform + static/live inventory)

**Primary analogs:**
- `.planning/phases/119-baseline-expert-audit-0-plans/119-RESEARCH.md` for phase-local research/audit structure and source confidence language.
- `.planning/ROADMAP.md` for required Phase 119 success criteria.
- `.planning/REQUIREMENTS.md` for CIDX requirement mapping.
- `MAINTAINING.md` for branch protection, local commands, proof bars, and release posture.
- `.github/workflows/ci.yml`, `scripts/ci/test.sh`, `scripts/ci/lint.sh`, and `examples/demo/frontend/playwright.config.ts` for concrete inventory rows and diagnostic findings.

**Required output shape from context** (`119-CONTEXT.md`, decisions D-01 through D-03):
```markdown
Produce one integrated `119-CI-CD-AUDIT.md`, not split topical docs.

Structure the audit around:
- executive recommendation
- workflow/job inventory
- required-check semantics
- critical path and metrics baseline
- cache/PLT posture
- test/check classification matrix
- rerun command catalog
- failure categories with maintainer microcopy
- no-go/rollback guardrails
- handoff notes

Classification vocabulary: `keep`, `optimize`, `move`, `quarantine/fix`, `delete/rewrite`.
Every non-keep recommendation needs evidence.
```

**Phase success criteria pattern** (`.planning/ROADMAP.md` lines 35-47):
```markdown
### Phase 119: Baseline + Expert Audit

**Goal:** Produce a repo-specific CI/CD performance, reliability, security, and DX baseline before changing behavior.

**Requirements:** CIDX-01, CIDX-02, CIDX-03

**Success criteria:**
1. `119-CI-CD-AUDIT.md` inventories every workflow, trigger, job, matrix, service, cache, required-check role, command, and quality signal.
2. The audit records current critical path, duplicated work, likely bottlenecks, cache posture, runner CPU use, and missing metrics.
3. Mix/ExUnit diagnostics record slowest tests, require-time profile, compile profile, xref cycle/connected graphs, and scheduler count.
4. Major checks and test categories are classified as keep, optimize, move, quarantine/fix, or delete/rewrite with evidence.
5. Official docs and comparable Elixir OSS workflow patterns are summarized only where they apply to this repo.
```

**Requirement traceability pattern** (`.planning/REQUIREMENTS.md` lines 8-12):
```markdown
### Baseline and Audit

- [ ] **CIDX-01**: Maintainer can review a current workflow/job/step baseline covering PR, main, scheduled, release, dependency, and hygiene workflows.
- [ ] **CIDX-02**: Maintainer can see the CI critical path, duplicated work, cache behavior, runner CPU use, and likely bottlenecks with before/after targets.
- [ ] **CIDX-03**: Maintainer can classify each major test and check category as keep, optimize, move, quarantine/fix, or delete/rewrite based on quality signal and determinism.
```

**Documentation validation pattern** (`119-VALIDATION.md`):
```markdown
## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | CIDX-01, CIDX-02 | T-119-01 | Audit-only scaffold with evidence tags and no behavior edits | source assertion | Per-item loop asserts all 15 H2 sections, CIDX-01, CIDX-02, guardrail phrase, and evidence conventions. | task creates | planned |
| 119-02-02 | 02 | 2 | CIDX-02 | T-119-08 | Local diagnostics are recorded as evidence without behavior changes | source assertion + local diagnostics | Per-item loop asserts every D-11 Mix/xref command, CPU/scheduler commands, exit status, and profile labels. | yes | planned |
| 119-03-03 | 03 | 3 | CIDX-01, CIDX-02, CIDX-03 | T-119-10 | Source coverage blocks false completion claims and behavior-changing diffs | source assertion + diff gate | Per-item loop asserts source coverage, CIDX-01..03, deferred exclusions, D-01..D-21, and rejects behavior-changing paths. | yes | planned |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live branch protection state is interpreted correctly | CIDX-01, CIDX-02 | GitHub repository settings are external mutable state | Confirm the audit records the exact `gh api` result as documented-vs-live evidence and does not make a Phase 119 settings change. |
```

**Workflow inventory pattern** (`.github/workflows/ci.yml` lines 1-27):
```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and branch protection:
#   changes, lint, test, integration-placeholder, adopter-contract, openfeature-companion, mounted-proof, release_gate
# `name:` strings evolve freely; `id:` strings are immutable without coordinated docs + branch-protection updates.
name: ci

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  actions: read
  checks: read

jobs:
```

**Path selectivity and always-reporting gate pattern** (`.github/workflows/ci.yml` lines 28-88 and 294-332):
```yaml
changes:
  name: Detect docs-only changes
  runs-on: ubuntu-24.04
  outputs:
    docs-only: ${{ steps.docs-only.outputs.value }}
    openfeature-companion: ${{ steps.openfeature-companion.outputs.value }}
    mounted-proof: ${{ steps.mounted-proof.outputs.value }}

release_gate:
  name: release_gate
  needs:
    - changes
    - lint
    - test
    - integration-placeholder
    - adopter-contract
    - mounted-proof
  if: always()
  runs-on: ubuntu-24.04
  steps:
    - name: Evaluate gate
      run: |
        lint_result="${{ needs.lint.result }}"
        test_result="${{ needs.test.result }}"
        integration_result="${{ needs['integration-placeholder'].result }}"
        adopter_result="${{ needs['adopter-contract'].result }}"
        mounted_proof_result="${{ needs['mounted-proof'].result }}"

        scripts/ci/release_gate.sh \
          --skip-phase7 \
          "changes=${{ needs.changes.result }}" \
          "lint=${lint_result}" \
          "test=${test_result}" \
          "integration-placeholder=${integration_result}" \
          "adopter-contract=${adopter_result}" \
          "mounted-proof=${mounted_proof_result}"
```

**Cache and PLT posture pattern** (`.github/workflows/ci.yml` lines 103-124, 166-179):
```yaml
- name: Cache Mix deps and build
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
  with:
    path: |
      rulestead/deps
      rulestead/_build
    key: ${{ runner.os }}-lint-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}
    restore-keys: |
      ${{ runner.os }}-lint-mix-
- name: Restore Dialyzer PLT
  uses: actions/cache/restore@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
  with:
    path: rulestead/priv/plts
    key: ${{ runner.os }}-plt-${{ hashFiles('**/mix.lock', '.tool-versions') }}
- name: Save Dialyzer PLT
  if: always()
  uses: actions/cache/save@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5.0.5
```

**Branch protection and documented required-check semantics** (`MAINTAINING.md` lines 32-52):
```markdown
## Branch protection settings

Document these settings exactly on `main`:

- Required status checks:
  - `release_gate` (aggregates `lint`, `test`, `integration-placeholder`,
    `adopter contract (post-GA band)`, and the path-gated mounted companion proof
    result from `ci.yml`)
  - `Validate PR title`
  - `dependency-review`
- `actionlint` is not a required status check because it is path-filtered
  and would sit Pending on non-workflow pull requests.
```

**Scripts-first contributor rerun pattern** (`MAINTAINING.md` lines 65-91):
```text
## Shift-left contributor gate

Run the same checks CI runs before you push.

# Fast core gate (rulestead package)
cd rulestead && mix ci

# Full monorepo gate (lint + test scopes + adopter contract)
bash scripts/ci/local.sh

# Faster iteration (skips mounted + openfeature companion scopes)
bash scripts/ci/local.sh --fast

`mix ci` covers format, compile, credo, tests (excluding `install_integration`),
and docs. `scripts/ci/local.sh` adds sibling-package lint/test scopes and
`mix verify.adopter`.
```

**Release trust pattern** (`MAINTAINING.md` lines 16-24 and 132-148):
```markdown
The release machine is intentionally semi-automated:

- `release-please.yml` still owns release PRs and tags.
- `publish-hex.yml` owns the irreversible Hex publish step.
- One explicit maintainer approval in the protected `hex-publish`
  environment is required before `HEX_API_KEY` is exposed to a publish job.
- Publish order is fixed: `rulestead` first, then `rulestead_admin`.

The expected release path for the current shipped `0.1.x` line is:

1. Merge the Release Please PR for the intended version.
2. Let `release-please.yml` create the linked tags and dispatch
   `publish-hex.yml`.
3. Let `publish-hex` `preflight` and `gate-ci-green` complete.
4. Review the `preflight` and `gate-ci-green` job output and approve the
   protected `hex-publish` environment.
5. Let `publish-core` publish `rulestead`.
6. Let `publish-admin` publish `rulestead_admin`.
7. Hand off to the separate post-publish verification wave.
```

**Failure microcopy pattern** (`scripts/ci/test.sh` lines 53-90):
```bash
mounted_failure_category() {
  local log_file="$1"

  if grep -Eq \
    "Unchecked dependencies|Could not find Hex|Could not compile dependency|mix local\\.hex|mix deps\\.get|can't continue due to errors on dependencies|The database for" \
    "${log_file}"; then
    echo "setup/prerequisite failure"
  elif grep -Eq "test failed|failures|ExUnit\\.AssertionError|MatchError|FunctionClauseError|UndefinedFunctionError" "${log_file}"; then
    echo "mounted contract regression"
  else
    echo "unknown mounted-proof failure"
  fi
}

print_mounted_failure_guidance() {
  local category="$1"

  {
    echo
    echo "mounted_admin_contract failure category: ${category}"
    echo "Expected support boundary: mounted companion only; host app owns the router/session prerequisite contract."
    echo "Rerun: RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
    echo "Runbook: ${MOUNTED_PROOF_RUNBOOK}"
  } >&2
}
```

**Test-scope catalog pattern** (`scripts/ci/test.sh` lines 520-554):
```bash
case "${TEST_SCOPE}" in
  openfeature_companion)
    echo "Running OpenFeature companion provider proof bar"
    run_openfeature_companion
    ;;
  install_journey)
    echo "Running fresh-install adopter journey proof"
    bash "${RULESTEAD_REPO}/scripts/demo/install_journey.sh"
    ;;
  post_ga_band_closure)
    echo "Running post-GA band closure proof bar"
    run_post_ga_band_closure
    ;;
  *)
    echo "Unknown test scope: ${TEST_SCOPE}" >&2
    echo "Supported scopes: all, mounted_admin_contract, openfeature_companion, guarded_rollout_foundations, reusable_targeting_deepening, blast_radius_governance, guarded_rollout_auto_advance, host_preview_evidence, install_journey, post_ga_band_closure" >&2
    exit 64
    ;;
esac
```

**Lint/check inventory pattern** (`scripts/ci/lint.sh` lines 6-15 and 20-47):
```bash
cd "${RULESTEAD_REPO}/rulestead"
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix docs --warnings-as-errors
mix hex.audit
mix compile --no-optional-deps --warnings-as-errors
RULESTEAD_REPO="${RULESTEAD_REPO}" "${RULESTEAD_REPO}/scripts/ci/check_package_whitelist.sh"
mix dialyzer --format github

python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"
python3 "${RULESTEAD_REPO}/scripts/check_contrast.py"
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"
python3 "${RULESTEAD_REPO}/scripts/check_logo_assets.py"
python3 "${RULESTEAD_REPO}/scripts/check_admin_foundations.py"
python3 "${RULESTEAD_REPO}/scripts/check_design_system_evidence.py"
```

**Browser evidence mismatch pattern** (`examples/demo/frontend/playwright.config.ts` lines 6-16):
```typescript
export default defineConfig({
  testDir: "./tests",
  testMatch: ["**/*.spec.ts"],
  timeout: 30_000,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: false,
  use: {
    baseURL: frontendUrl,
    trace: "on-first-retry",
  },
});
```

## Shared Patterns

### Audit Sections

**Apply to:** `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md`

Use this section order unless the planner has a concrete readability reason to reorder:

```markdown
# Phase 119 CI/CD Audit

## Executive Recommendation
## Evidence Collection
## Workflow and Job Inventory
## Required-Check Semantics
## Critical Path and Metrics Baseline
## Cache and Dialyzer PLT Posture
## Mix, ExUnit, Dialyzer, and Xref Diagnostics
## Test and Check Classification Matrix
## Rerun Command Catalog
## Failure Categories and Maintainer Microcopy
## Release and Supply-Chain Trust
## Browser, Demo, and Integration Evidence
## No-Go and Rollback Guardrails
## Handoff Notes for Phases 120-123
## Sources
```

### Evidence Tags

**Source:** `119-RESEARCH.md`
**Apply to:** Every non-keep recommendation and every live/external-state claim.

```markdown
[VERIFIED: path-or-command]
[CITED: official-doc-url]
[ASSUMED: reason]
```

### Static Plus Live Inventory

**Source:** `119-RESEARCH.md`
**Apply to:** Workflow inventory, required-check semantics, critical-path baseline.

```bash
gh workflow list --repo szTheory/rulestead --all --json name,path,state,id
gh run list --repo szTheory/rulestead --workflow ci.yml --limit 10 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch
gh run view <run-id> --repo szTheory/rulestead --json jobs,createdAt,updatedAt,conclusion,event,workflowName
gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks
```

### Mix Diagnostic Baseline

**Source:** `119-CONTEXT.md` D-11 and `119-RESEARCH.md`
**Apply to:** Mix/ExUnit diagnostics section and classification evidence.

```bash
cd rulestead
mix test --warnings-as-errors --slowest 25
mix test --warnings-as-errors --slowest-modules 25
mix test --profile-require time
mix compile.elixir --force --profile time
mix xref graph --format cycles --label compile-connected
mix xref graph --format stats --label compile-connected
erl -noshell -eval 'io:format("~p~n", [erlang:system_info(schedulers_online)]), halt().'
```

### Classification Vocabulary

**Source:** `119-CONTEXT.md` D-03
**Apply to:** Major checks, workflows, proof bars, and test categories.

```markdown
| Surface | Current Role | Classification | Evidence | Later-Phase Action |
|---------|--------------|----------------|----------|--------------------|
| `release_gate` | Required aggregate gate | keep | Always reports and normalizes docs/path-gated jobs | Phase 120 may adjust dependencies only with evidence |
| `openfeature-companion` | Path-gated proof bar | optimize | Present in `ci.yml`; absent from `release_gate.needs` | Phase 120 decision point |
```

### No Behavior Change Guardrail

**Source:** `119-CONTEXT.md` phase boundary and deferred ideas
**Apply to:** Whole audit.

```markdown
Phase 119 records evidence and recommendations only. Do not edit workflow behavior, test behavior, release trust posture, product runtime APIs, schemas, `rulestead_admin` publish posture, browser baseline strategy, or test inclusion.
```

## No Analog Found

All target work is documentation/audit output. No source-code module analog is needed.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| N/A | N/A | N/A | Repo-local phase artifacts, maintenance docs, workflows, and scripts provide sufficient analogs. |

## Metadata

**Analog search scope:** `.planning/`, `.github/workflows/`, `scripts/ci/`, `scripts/demo/`, `examples/demo/frontend/`, `MAINTAINING.md`, `prompts/`
**Files scanned:** 34
**Project skill dirs:** no project-local `.codex/skills/` or `.agents/skills/` entries found in this workspace
**Pattern extraction date:** 2026-06-15
