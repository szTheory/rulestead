# Phase 45: Companion Boot & Package-Boundary Truth - Research

**Researched:** 2026-05-25
**Domain:** Mounted companion boot contract, sibling-package boundary wiring, and fail-closed prerequisite proof
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions
- Preserve the linked-version, two-package release design centered on `rulestead` and `rulestead_admin`. [VERIFIED: AGENTS.md] [VERIFIED: roadmap]
- Do not widen `rulestead_admin` into a standalone product or publish-prep posture. [VERIFIED: AGENTS.md] [VERIFIED: README.md]
- Keep Phase 45 bounded to boot/runtime/config coherence and prerequisite truth; Phase 46 owns repo-root proof-bar restoration/CI wording, and Phase 47 owns broader docs closure. [VERIFIED: roadmap] [VERIFIED: requirements]
- Fail closed on unsupported mounted setup instead of letting repo-local proof or package docs imply broader support than the code can actually boot. [VERIFIED: roadmap] [VERIFIED: requirements]

### the agent's Discretion
- Exact helper and fixture shape used to encode the host-owned boot contract, provided it reuses existing install/release-publish patterns instead of inventing a third package model.
- Exact runtime guard location for optional Redis/notifier/pubsub behavior, provided `rulestead` remains the owner of runtime boot and `rulestead_admin` stays a mounted UI package.
- Exact negative-test split between core runtime startup tests and mounted-admin session/integration tests, provided missing prerequisites become explicit and bounded.

### No Phase Context
- No Phase 45 `CONTEXT.md` exists in the phase directory. This research therefore treats `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `AGENTS.md`, and repo-local code/test evidence as the active source of truth for planning.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | `rulestead_admin` starts through one deliberate, host-owned boot contract whose required runtime wiring, config shape, and package boundary are consistent from repo-root proof to mounted host usage. | The repo already has the pieces of that contract, but they are split across installer tests, release-publish fixtures, router/session tests, and runtime config code instead of one explicit boot contract. [VERIFIED: rulestead_install_test] [VERIFIED: verify_release_publish_test] [VERIFIED: admin_mount/session tests] |
| PKG-02 | Missing or unsupported mounted companion prerequisites fail with explicit, bounded behavior instead of silent drift, misleading proof output, or docs that imply broader support than the repo provides. | Current happy-path tests are stronger than the negative-path proof. The mounted proof bar passed on 2026-05-25, but prerequisite behavior still depends heavily on internal test setup rather than explicit contract fixtures. [VERIFIED: mounted proof rerun 2026-05-25] [VERIFIED: test helpers] |
</phase_requirements>

## Summary

The most important planning correction is temporal: in this workspace, on **2026-05-25**, the command `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` passed end to end. The stale thread that reported an `UndefinedFunctionError` for `Rulestead.Redis.enabled?/0` is useful historical context, but it is no longer the current repo state. Phase 45 should therefore not be planned as "turn the bar from red to green." It should be planned as "lock the real mounted boot contract so this proof cannot drift back into an ambiguous or internally patched state." [VERIFIED: repo-local rerun on 2026-05-25]

The actual contract spans both packages today. `rulestead_admin` is intentionally thin: its application starts only `Phoenix.PubSub`, and the public mount seam is `RulesteadAdmin.Router.rulestead_admin/2`, which requires `policy:` and injects `policy` plus `mount_path` into the LiveView session. The mounted UI then expects host-owned session keys such as `"current_actor"`, `"rulestead_admin_environments"`, and `"rulestead_admin_last_env"`, while `?env=` remains the canonical URL selector. This already matches the package-boundary story the repo wants to tell. [VERIFIED: rulestead_admin/application.ex] [VERIFIED: rulestead_admin/router.ex] [VERIFIED: rulestead_admin/README.md] [VERIFIED: session_test.exs]

The runtime ownership remains in `rulestead`. `Rulestead.Application` starts `Rulestead.Admin.StaleTracker`, `Rulestead.Analytics.Batcher`, and `Rulestead.Runtime.Supervisor`, while Redis children are added only when `Rulestead.Redis.enabled?/0` returns true. In `rulestead/config/test.exs`, Redis is explicitly disabled, which is why mounted proof in test does not require a live Redis dependency. That is a sound package boundary, but it also means the contract is easy to misunderstand unless tests encode the expected config shape directly. [VERIFIED: rulestead/application.ex] [VERIFIED: rulestead/redis.ex] [VERIFIED: rulestead/config/test.exs]

The weak point is not the happy path itself; it is where the repo proves that path. The mounted proof uses internal test setup to terminate `Rulestead.Analytics.Batcher`, inject `Rulestead.Fake` as the store, and install a permissive admin policy. Installer tests already assert that `mix rulestead.install` writes the expected runtime config (`api: Rulestead.Runtime`, `notifier: Rulestead.Runtime.Notifier.PhoenixPubSub`, `pubsub: MyApp.PubSub`, `pubsub_topic: "rulestead:runtime_snapshot"`), and release-publish fixtures already encode the mounted admin contract (`/flags`, session keys, `env` query). But those proof surfaces are not yet unified into one deliberate mounted boot contract. [VERIFIED: rulestead_admin/test_helper.exs] [VERIFIED: rulestead_install_test.exs] [VERIFIED: verify_release_publish_test.exs] [VERIFIED: release_publish_fixture.ex]

The best Phase 45 shape is therefore narrow and three-part. First, trace and encode the intended host-owned boot contract in reusable fixtures/tests so proof does not depend on tribal knowledge. Second, repair any runtime/config/package wiring gaps at the `rulestead` boundary, keeping optional infrastructure strictly config-gated and keeping `rulestead_admin` thin. Third, add explicit regression proof for missing or unsupported prerequisites so the mounted companion fails closed and predictably before Phase 46 re-centers the repo-root proof bar. [INFERENCE from verified evidence]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 45 | Why |
|---------|-----------------------------|-----|
| `rulestead/lib/rulestead/application.ex` | Own the mounted companion's runtime boot boundary and optional-child gating | Runtime ownership belongs in `rulestead`, not the admin package. [VERIFIED: application.ex] |
| `rulestead/lib/rulestead/redis.ex`, `rulestead/lib/rulestead/runtime/config.ex`, `rulestead/lib/rulestead/config.ex` | Keep Redis/notifier/pubsub behavior explicit and config-driven | This is where hidden optional prerequisites can reappear as boot drift. [VERIFIED: redis.ex] [VERIFIED: runtime/config.ex] [VERIFIED: config.ex] |
| `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs` | Prove the generated host config includes the runtime values the mounted companion depends on | Installer output is already the closest source of truth for host-owned boot wiring. [VERIFIED: rulestead_install_test.exs] |
| `rulestead/test/support/release_publish_fixture.ex`, `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` | Encode the package-boundary contract for a fresh host consumer | These fixtures already express mount path, session keys, and package versions. [VERIFIED: release_publish_fixture.ex] [VERIFIED: verify_release_publish_test.exs] |
| `rulestead_admin/lib/rulestead_admin/live/session.ex`, `rulestead_admin/test/rulestead_admin/live/session_test.exs`, `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` | Keep mounted prerequisite and fail-closed behavior explicit at the host seam | This is where missing actor/session/env behavior becomes user-visible. [VERIFIED: session.ex] [VERIFIED: session_test.exs] [VERIFIED: admin_mount_test.exs] |
| `rulestead/test/rulestead/runtime/startup_test.exs` | Prove degraded or optional runtime startup behavior instead of assuming full infra | Existing startup tests are the right analog for config-gated boot semantics. [VERIFIED: startup_test.exs] |

## Standard Stack

### Source-of-truth code and tests
- `rulestead/lib/rulestead/application.ex`
- `rulestead/lib/rulestead/redis.ex`
- `rulestead/lib/rulestead/runtime/config.ex`
- `rulestead/lib/rulestead/config.ex`
- `rulestead/test/rulestead/runtime/startup_test.exs`
- `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs`
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs`
- `rulestead/test/support/release_publish_fixture.ex`
- `rulestead_admin/lib/rulestead_admin/router.ex`
- `rulestead_admin/lib/rulestead_admin/live/session.ex`
- `rulestead_admin/test/rulestead_admin/live/session_test.exs`
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`

### Targeted proof commands
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/runtime/startup_test.exs test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/integration/admin_mount_test.exs`

These commands are the narrowest proof surfaces that exercise runtime boot, generated host config, package-boundary metadata, and the mounted host seam without widening into Phase 46 CI work or Phase 47 doc closure. [VERIFIED: repo-local rerun] [INFERENCE: scoped command set]

## Recommended Shape

### Pattern 1: Promote the generated-host contract over internal-only setup
The strongest analog already exists in `rulestead_install_test.exs` and `verify_release_publish_test.exs`: generate or mutate a fresh host app, then assert concrete config and mount values. Phase 45 should extend that pattern to the mounted companion boot contract instead of relying mainly on internal package test setup.

### Pattern 2: Keep optional infra strictly config-gated
Redis, notifier, and pubsub wiring should stay explicit and driven by `Rulestead.Config` / `Rulestead.Runtime.Config`. If a mounted proof path does not supply those prerequisites, the runtime should degrade or deny clearly rather than starting surprise children or crashing later.

### Pattern 3: Negative-path proof belongs at the host seam
`RulesteadAdmin.Live.Session` already treats invalid `env` and `tenant` inputs fail-closed. Phase 45 should add the same explicitness for missing or unsupported mounted prerequisites: either provide a documented fallback or surface a bounded failure, but do not leave support truth to inference.

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Planning against stale failure evidence leads to redundant fixes or broad cleanup | The plans should cite the 2026-05-25 passing proof command explicitly and focus on contract hardening, not generic "make tests green" work. |
| Runtime prerequisites remain encoded only in helper setup, not user-visible contract tests | Slice 1 should create or strengthen reusable host fixtures before Slice 2 changes core wiring. |
| Fixes accidentally move runtime responsibility into `rulestead_admin` | Slice 2 must preserve `rulestead_admin` as a thin mounted package and keep boot ownership in `rulestead`. |
| Negative-path behavior stays implicit and Phase 46 later re-breaks the repo-root proof | Slice 3 must add missing-prerequisite regression coverage before proof-bar tightening. |

## Validation Architecture

Phase 45 should use three waves:

1. **Boot contract tracing and fixture locking**: strengthen generated-host and package-boundary tests so the intended mounted boot path is explicit.
2. **Runtime/config/package wiring repair**: fix only the `rulestead`-owned boot/config seams needed to keep optional infra bounded and coherent.
3. **Prerequisite regression proof**: add negative-path mounted tests and rerun the bounded proof commands that Phase 46 will later wrap at the repo root.

## Recommended Slice Boundary

### Slice 1
Trace the mounted companion startup path and lock the intended host-owned boot contract in reusable fixtures and package-boundary tests.

### Slice 2
Repair sibling-package boot/runtime/config wiring at the `rulestead` boundary without widening `rulestead_admin` beyond a mounted companion.

### Slice 3
Add focused regression proof for missing-prerequisite and package-boundary behavior so unsupported setup fails closed and predictably.

## Confidence

- Architecture: HIGH - the desired package boundary already exists; the gap is that the contract is scattered across runtime code, installer output, and helper-heavy tests. [VERIFIED: application/router/config/tests]
- Verification: HIGH - the mounted proof bar passed locally on 2026-05-25, and the repo already has strong targeted analogs for runtime startup, installer config, release consumer fixtures, and mounted session behavior. [VERIFIED: rerun + targeted tests]
- Scope control: HIGH - roadmap, requirements, and AGENTS all support a narrow boot-contract closure without pulling in CI/doc work from later phases. [VERIFIED: roadmap] [VERIFIED: requirements] [VERIFIED: AGENTS.md]
