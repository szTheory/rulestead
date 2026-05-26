# Phase 46: Mounted Proof Bar Restoration - Research

**Researched:** 2026-05-25
**Domain:** Repo-root mounted proof restoration, mounted lifecycle route/permission contract drift, and CI/remediation alignment
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions
- Preserve the linked-version, two-package release design centered on `rulestead` and `rulestead_admin`. [VERIFIED: AGENTS.md] [VERIFIED: roadmap]
- Keep `rulestead_admin` mounted-companion only; do not widen it into a standalone product or publish-prep surface. [VERIFIED: AGENTS.md] [VERIFIED: requirements]
- Keep Phase 46 bounded to restoring the named mounted proof bar, the mounted lifecycle/permission contract it is supposed to prove, and the CI/remediation wiring around that bar. Docs reclosure belongs to Phase 47. [VERIFIED: roadmap] [VERIFIED: requirements]
- Verification must stay scripts-first, rerunnable from the repo root, and explicit about setup-versus-regression failure modes. [VERIFIED: context] [VERIFIED: prompts/rulestead-release-engineering-and-ci.md]

### the agent's Discretion
- Exact helper structure inside `scripts/ci/test.sh`, provided the public verifier remains `RULESTEAD_TEST_SCOPE=mounted_admin_contract`.
- Exact split between route/permission fixes in code versus test-fixture/session fixes, provided the final bar proves the supported mounted lifecycle workflow rather than a test-only shortcut.
- Exact CI job key and `changes` output name, provided the mounted proof becomes a named, path-gated, merge-blocking lane.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | The named `mounted_admin_contract` proof bar passes from the repo root against the supported mounted companion startup path and covers the repaired lifecycle, route, and permission contract. | The current repo-root command still passes, but only because Phase 45 narrowed it to session + mount + core contract suites. The broader mounted lifecycle suites are still red and must be brought back under the named verifier intentionally. [VERIFIED: `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` on 2026-05-25] [VERIFIED: `mix test ...index_test.exs ...cleanup*_test.exs` on 2026-05-25] |
| VER-01 | Shared verification scripts and CI distinguish the merge-blocking mounted companion proof from advisory smoke paths and report actionable remediation when the proof surface fails. | `scripts/ci/test.sh` currently prints only a generic mounted-proof banner and runs the narrow scope without failure classification. `.github/workflows/ci.yml` has no dedicated mounted-proof job and does not thread that proof into `release_gate`. [VERIFIED: `scripts/ci/test.sh`] [VERIFIED: `.github/workflows/ci.yml`] |
</phase_requirements>

## Summary

The key temporal fact for Phase 46 is current and concrete: on **2026-05-25**, the repo-root command `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` is green, but it is green only because Phase 45 intentionally narrowed the bar to `session_test.exs`, `admin_mount_test.exs`, `admin_contract_test.exs`, and `admin_lifecycle_test.exs`. That means the named proof bar is no longer proving the broader mounted lifecycle workflow that Phase 46 is supposed to restore. [VERIFIED: `scripts/ci/test.sh`] [VERIFIED: Phase 45 summary]

The broader candidate suites identified in Phase 46 context are still materially red. Running `mix test` for `index_test.exs`, `cleanup_test.exs`, `cleanup_preview_test.exs`, and `cleanup_confirm_test.exs` in `rulestead_admin` produced **16 tests, 9 failures** on 2026-05-25. The recurring symptom is immediate redirects back to `/admin/flags` instead of rendering the cleanup/preview/confirm surfaces, including both happy-path and unauthorized-path assertions. [VERIFIED: repo-local rerun on 2026-05-25]

The drift is centered on the mounted route/policy seam, not on the core lifecycle engine. `index_test.exs` continues to pass, proving the route-backed queue, `env` query handling, cleanup links, archive-return messaging, and mounted host-path conventions are still broadly intact. The failing cluster is specific to the cleanup review, preview, and confirm routes. [VERIFIED: repo-local rerun on 2026-05-25]

One concrete hotspot is the policy/session contract boundary. The mounted router macro injects `"policy"` and `"mount_path"` into the LiveView session, and `RulesteadAdmin.Live.Session.on_mount/4` resolves policy from `session["policy"]`, not from ambient application config. Several failing cleanup suites still mutate `Application.put_env(:rulestead, :admin_policy, AllowPolicy/ReadOnlyPolicy)` while mounting through the router-backed host seam. Planning should therefore treat policy-source alignment between test fixtures, router session, and capability checks as first-class repair work instead of assuming the failing redirects are only UI copy drift. [VERIFIED: `rulestead_admin/lib/rulestead_admin/router.ex`] [VERIFIED: `rulestead_admin/lib/rulestead_admin/live/session.ex`] [VERIFIED: cleanup suite setup]

The CI gap is straightforward. The workflow already has a reusable pattern for bounded optional/companion proof lanes via `openfeature-companion`: path-gated in `changes`, given a stable job name, and left out of the main `test` matrix. Phase 46 should reuse that pattern for the mounted proof rather than hiding the contract inside the full matrix or relying on workflow-level path filters. It then needs to thread the mounted lane into `release_gate` so branch protection can cite one stable merge-blocking result. [VERIFIED: `.github/workflows/ci.yml`] [INFERENCE from existing CI structure]

The best Phase 46 shape remains the roadmap’s three-part split. First, restore the repo-root verifier path so `mounted_admin_contract` once again runs the intended mounted suite list rather than the temporary seam-only slice. Second, repair the mounted cleanup/preview/confirm route and permission proof so the broader bar is actually green. Third, add structured remediation output in the script and a dedicated named CI job wired into `release_gate`. [INFERENCE from verified evidence]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 46 | Why |
|---------|-----------------------------|-----|
| `scripts/ci/test.sh` | Own the curated repo-root mounted verifier scope and failure classification | This is the public proof entrypoint adopters and CI both call. [VERIFIED: script] |
| `rulestead_admin/lib/rulestead_admin/live/session.ex` | Keep mounted policy/session/mount-path resolution explicit and compatible with the host-owned seam | The failing cleanup routes all depend on the mounted session contract. [VERIFIED: session.ex] |
| `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup*.ex` | Enforce the lifecycle review, preview, confirm, and permission semantics that the restored proof bar must cover | These are the red route-backed surfaces. [VERIFIED: cleanup LiveViews] |
| `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` | Anchor the passing queue/readiness/return-to contract that cleanup flows must preserve | It is the strongest passing proof of the current mounted queue semantics. [VERIFIED: index_test.exs + rerun] |
| `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup*.exs` | Prove the repaired cleanup/preview/confirm contract against the mounted host seam | These suites currently expose the real gap. [VERIFIED: rerun] |
| `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` | Keep host-mounted env/query/route semantics stable while broader cleanup coverage is restored | It already proves the host seam and should remain in the named bar. [VERIFIED: admin_mount_test.exs] |
| `.github/workflows/ci.yml` | Surface a stable named mounted-proof lane and thread it into `release_gate` | This is the branch-protection contract for the proof bar. [VERIFIED: workflow] |

## Standard Stack

### Source-of-truth code and tests
- `scripts/ci/test.sh`
- `.github/workflows/ci.yml`
- `rulestead_admin/lib/rulestead_admin/router.ex`
- `rulestead_admin/lib/rulestead_admin/live/session.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_preview.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_confirm.ex`
- `rulestead_admin/test/support/conn_case.ex`
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `rulestead/test/rulestead/admin_contract_test.exs`
- `rulestead/test/rulestead/admin_lifecycle_test.exs`

### Targeted proof commands
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_contract_test.exs test/rulestead/admin_lifecycle_test.exs`

These commands keep Phase 46 focused on the mounted proof contract itself: repo-root verifier, mounted host seam, route-backed cleanup workflow, and core lifecycle/admin truth. [VERIFIED: context + reruns]

## Recommended Shape

### Pattern 1: Restore one named bounded verifier, not a hidden matrix branch
Keep `mounted_admin_contract` as the public repo-root command, but make it run the curated lifecycle suite list Phase 46 context already locked: session, host seam, index, cleanup, cleanup preview, cleanup confirm, and the two core `rulestead` contract tests.

### Pattern 2: Treat policy/session source alignment as contract work
The mounted router injects policy into the LiveView session. Cleanup tests that try to steer authorization only through app env are vulnerable to drift against the real host seam. Phase 46 should repair that mismatch explicitly, either by aligning fixtures to the router contract or by making the capability path consume the same source consistently.

### Pattern 3: Keep cleanup semantics split by capability
`cleanup` remains the read/review surface; `cleanup/preview` and `cleanup/confirm` remain execute/admin-gated mutation paths. The restored proof must show both the happy path and the deny path for those roles.

### Pattern 4: Categorize proof failures without hiding raw ExUnit output
The script wrapper should print whether the failure looks like setup/prerequisite drift or a mounted-contract regression, plus the exact rerun/setup commands, but it must leave the underlying Mix/ExUnit output visible.

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Re-expanding the named bar before the cleanup routes are repaired makes the public verifier immediately red without clarifying the cause | Slice 1 should codify the intended suite list and mounted contract target deliberately, then Slice 2 should make that restored scope green. |
| Fixing tests only at the fixture layer can hide a real policy-source inconsistency in the mounted seam | Slice 2 must read both `session.ex` and router/test-support code before deciding whether the repair belongs in LiveView capability logic, host-session fixtures, or both. |
| CI path filters that are too narrow will let contract-breaking changes skip the mounted proof lane | Slice 3 should include all mounted-proof-touching paths, not only `rulestead_admin/**`. |
| Failure output that only says “tests failed” recreates support-truth ambiguity | Slice 3 must add setup-vs-regression categorization and exact rerun guidance. |

## Validation Architecture

Phase 46 should use three waves:

1. **Verifier restoration**: codify the intended repo-root mounted suite, keep the named command stable, and anchor the passing queue/core tests that belong in the restored bar.
2. **Lifecycle route and permission repair**: make cleanup, preview, and confirm pass through the mounted host seam with the intended read-only versus execute/admin behavior.
3. **CI and remediation closure**: add structured script output, named workflow job, path gating, and `release_gate` aggregation.

## Recommended Slice Boundary

### Slice 1
Restore the repo-root `mounted_admin_contract` verifier path around the intended mounted lifecycle contract instead of the temporary Phase 45 seam-only bar.

### Slice 2
Align mounted cleanup, preview, confirm, and permission proof with the supported companion route/session contract.

### Slice 3
Tighten script remediation output and GitHub Actions wiring so mounted proof failures are named, actionable, and merge-blocking through `release_gate`.

## Confidence

- Verification: HIGH - current repo-local reruns clearly separate the passing narrow proof bar from the failing broader mounted lifecycle suites. [VERIFIED: 2026-05-25 reruns]
- Architecture: HIGH - the mounted host seam, route-backed workflow, and CI lane patterns already exist; Phase 46 is a bounded restoration problem, not a new architecture problem. [VERIFIED: router/session/index/CI files]
- Scope control: HIGH - roadmap, requirements, AGENTS, and phase context all point to the same narrow objective: restore the named mounted proof surface without broadening product posture or dragging docs work forward from Phase 47. [VERIFIED: roadmap] [VERIFIED: requirements] [VERIFIED: AGENTS.md] [VERIFIED: 46-CONTEXT.md]
