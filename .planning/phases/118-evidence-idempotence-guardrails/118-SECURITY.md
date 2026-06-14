---
phase: 118
slug: evidence-idempotence-guardrails
status: verified
threats_open: 0
threats_total: 14
asvs_level: 1
created: 2026-06-14
register_authored_at_plan_time: true
---

# Phase 118 - Security

Per-phase security contract: threat register, accepted risks, and audit trail for Phase 118 evidence and idempotence guardrails.

The plan-time threat model contained 16 threat rows across `118-01-PLAN.md`, `118-02-PLAN.md`, and `118-03-PLAN.md`. The repeated supply-chain row `T-118-SC` appeared in all three plans and is consolidated below into one unique threat with all three source plans covered.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| source tree to CI guard | Guard script turns repository text into pass/fail trust for design-system evidence posture. | Source file text and manifest text already in the repo. |
| CI guard to planning evidence | Later plans rely on guard output as part of VER-03 proof. | Deterministic command output and failure strings. |
| test-mode backend to Playwright | Browser proof depends on a local Phoenix backend serving mounted admin and matrix routes. | Local test-mode browser traffic to `DEMO_BACKEND_URL`. |
| generated screenshots to evidence docs | Test artifacts are referenced as proof but must not become committed baselines. | Ignored local Playwright output paths, artifact globs, and counts. |
| guard output to planning truth | Closeout docs use command outputs from `118-EVIDENCE.md` to mark requirements complete. | PASS rows, command output summaries, and residual-risk notes. |
| evidence artifact to planning truth | Requirements, roadmap, validation, and state are updated based on recorded proof. | VER-01 through VER-04 completion status and traceability. |
| planning docs to future executors | Future phases trust Phase 118 exceptions and guardrail claims. | Planning summaries, milestone boundaries, and decision coverage. |

## Threat Register

| Threat ID | Category | Component | Source Plans | Disposition | Mitigation | Status |
|-----------|----------|-----------|--------------|-------------|------------|--------|
| T-118-01 | Tampering | `scripts/check_design_system_evidence.py` | 118-01 | mitigate | Closed by explicit source assertions for matrix sections, workflow routes, rare states, selected contrast labels, artifact naming, and forbidden visual-baseline strings in `scripts/check_design_system_evidence.py:38`, `scripts/check_design_system_evidence.py:54`, `scripts/check_design_system_evidence.py:76`, `scripts/check_design_system_evidence.py:86`, and `scripts/check_design_system_evidence.py:238`; current run printed `DESIGN SYSTEM EVIDENCE OK`. | closed |
| T-118-02 | Repudiation | `scripts/ci/lint.sh` guard output | 118-01 | mitigate | Closed by deterministic success/failure strings in `scripts/check_design_system_evidence.py:263` and `scripts/check_design_system_evidence.py:268`, plus lint-spine wiring at `scripts/ci/lint.sh:45`; `118-EVIDENCE.md:107` and `118-EVIDENCE.md:130` record `DESIGN SYSTEM EVIDENCE OK`. | closed |
| T-118-03 | Denial of Service | CI lint guard | 118-01 | mitigate | Closed by stdlib-only imports in `scripts/check_design_system_evidence.py:13`, fixed source scan paths in `scripts/check_design_system_evidence.py:27`, read-only `Path.read_text()` behavior in `scripts/check_design_system_evidence.py:115`, and lint wiring that runs only the source guard, not browser tests, at `scripts/ci/lint.sh:45`. | closed |
| T-118-04 | Information Disclosure | source guard | 118-01 | accept | Closed as accepted risk `A-118-01`: the guard reads repo source already under version control and does not write screenshots, secrets, environment values, or browser artifacts. | closed |
| T-118-05 | Spoofing | `DEMO_BACKEND_URL` | 118-02 | mitigate | Closed by recorded backend environment in `118-EVIDENCE.md:20` and `118-EVIDENCE.md:21`, sign-in through `/demo/sign-in` in `examples/demo/frontend/tests/ui-matrix.spec.ts:137` and `examples/demo/frontend/tests/admin-flow-ia.spec.ts:120`, and `.rs-shell` assertions in `examples/demo/frontend/tests/ui-matrix.spec.ts:148` and `examples/demo/frontend/tests/admin-flow-ia.spec.ts:131`. | closed |
| T-118-06 | Tampering | screenshot evidence | 118-02 | mitigate | Closed by `testInfo.outputPath(...)` generated-artifact writes in `examples/demo/frontend/tests/ui-matrix.spec.ts:191` and `examples/demo/frontend/tests/admin-flow-ia.spec.ts:185`, artifact counts and globs in `118-EVIDENCE.md:30` and `118-EVIDENCE.md:31`, and `git ls-files examples/demo/frontend/test-results` returning `0` tracked files. | closed |
| T-118-07 | Repudiation | `118-EVIDENCE.md` | 118-02 | mitigate | Closed by exact command/result rows and residual-risk notes in `118-EVIDENCE.md:30` through `118-EVIDENCE.md:36`, requirement coverage in `118-EVIDENCE.md:38`, and guard output rows in `118-EVIDENCE.md:104` through `118-EVIDENCE.md:131`. | closed |
| T-118-08 | Information Disclosure | Playwright screenshots | 118-02 | mitigate | Closed by generated-artifact posture in `118-EVIDENCE.md:30`, `118-EVIDENCE.md:31`, and `118-EVIDENCE.md:135`; screenshots are referenced by globs/counts only, and `git ls-files examples/demo/frontend/test-results` returned `0` tracked files. | closed |
| T-118-09 | Denial of Service | browser evidence suite | 118-02 | mitigate | Closed by curated recorded browser/static proof only: 70/70 matrix/workflow tests in `118-EVIDENCE.md:30` through `118-EVIDENCE.md:32`, 29/29 static fixture/theme tests in `118-EVIDENCE.md:34`, and targeted reduced-motion scope in `118-EVIDENCE.md:32`. | closed |
| T-118-10 | Tampering | `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` | 118-03 | mitigate | Closed by post-evidence completion rows in `.planning/REQUIREMENTS.md:40` through `.planning/REQUIREMENTS.md:43`, Complete traceability in `.planning/REQUIREMENTS.md:89` through `.planning/REQUIREMENTS.md:92`, and Phase 118 3/3 complete roadmap rows in `.planning/ROADMAP.md:120` and `.planning/ROADMAP.md:144`. | closed |
| T-118-11 | Repudiation | `118-EVIDENCE.md` closeout | 118-03 | mitigate | Closed by requirement coverage in `118-EVIDENCE.md:38`, decision coverage in `118-EVIDENCE.md:47`, D-01 through D-20 coverage including endpoints at `118-EVIDENCE.md:51` and `118-EVIDENCE.md:70`, planning closeout in `118-EVIDENCE.md:72`, and milestone boundary exceptions in `118-EVIDENCE.md:78`. | closed |
| T-118-12 | Information Disclosure | planning docs | 118-03 | mitigate | Closed by artifact globs/counts rather than image contents in `118-EVIDENCE.md:30` through `118-EVIDENCE.md:32`, generated-artifact exception in `118-EVIDENCE.md:135`, and `git ls-files examples/demo/frontend/test-results` returning `0` tracked files. | closed |
| T-118-13 | Denial of Service | closeout docs | 118-03 | accept | Closed as accepted risk `A-118-02`: the closeout risk is limited to documentation verification; Plan 03 summary reports planning/evidence documents only and no new endpoint, auth path, file access pattern, schema, migration, release workflow, package metadata, or publish boundary. | closed |
| T-118-SC | Tampering | npm/pip/cargo installs | 118-01, 118-02, 118-03 | mitigate | Closed by Phase 118 commit file review: guard commits changed `scripts/check_design_system_evidence.py` and `scripts/ci/lint.sh`; evidence/closeout commits changed planning artifacts only; no package manifests or lockfiles were changed. `118-EVIDENCE.md:35` also records guard additions as deterministic source checks only with no package installs. | closed |

Status: `open` or `closed`.

Disposition: `mitigate` means implementation evidence required; `accept` means risk documented in this file; `transfer` means third-party transfer documentation required.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| A-118-01 | T-118-04 | Source guard reads a fixed set of repository files already under version control and does not write screenshots, secrets, environment values, or browser artifacts. Residual risk is limited to normal repo-source visibility. | Phase 118 plan-time threat model | 2026-06-14 |
| A-118-02 | T-118-13 | Closeout documentation verification can consume local command time, but Phase 118 closeout changed planning/evidence docs only and uses bounded source assertions plus `git diff --check`; no heavy runtime loop is part of the closeout docs. | Phase 118 plan-time threat model | 2026-06-14 |

Accepted risks do not resurface in future audit runs unless the referenced component or disposition changes.

## Unregistered Flags

None.

- `118-01-SUMMARY.md:103` through `118-01-SUMMARY.md:105` reports no threat flags.
- `118-02-SUMMARY.md:108` through `118-02-SUMMARY.md:110` reports no threat flags.
- `118-03-SUMMARY.md:111` through `118-03-SUMMARY.md:113` reports no threat flags.

## Security Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Plan-time threat rows parsed | 16 |
| Unique threats found | 14 |
| Closed | 14 |
| Open | 0 |
| Accepted risks documented | 2 |
| Unregistered flags | 0 |

Verification performed:

- `python3 scripts/check_design_system_evidence.py` -> `DESIGN SYSTEM EVIDENCE OK`
- `git ls-files examples/demo/frontend/test-results | wc -l` -> `0`
- `git status --short` -> clean before this SECURITY artifact was added
- Phase 118 commit file review found no package manifest or lockfile changes

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-14 | 14 | 14 | 0 | Codex `$gsd-secure-phase 118` |

## Sign-Off

- [x] All threats have a disposition (`mitigate` or `accept`; no `transfer` threats in Phase 118)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-06-14
