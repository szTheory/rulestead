# Maintaining Rulestead

## Release posture

Rulestead ships as a linked-version sibling-package monorepo:

- `rulestead`
- `rulestead_admin`

Repo GA shipped in `v1.0.0` on 2026-05-21. The current installable
sibling-package line remains `0.1.0`, so maintainer release work should treat
the `0.1.x` packages as the live consumer surface while keeping
`rulestead_admin` documented as the mounted companion rather than a standalone
product.

The release machine is intentionally semi-automated:

- `release-please.yml` still owns release PRs and tags.
- `publish-hex.yml` owns the irreversible Hex publish step.
- One explicit maintainer approval in the protected `hex-publish`
  environment is required before `HEX_API_KEY` is exposed to a publish job.
- Publish order is fixed: `rulestead` first, then `rulestead_admin`.
- Support proof remains intentionally bounded to the current runnable and
  release-verification seams.

The sibling-package publish decision is intentional:

- `rulestead_admin` is published on Hex alongside `rulestead`
- `rulestead_admin` remains the mounted admin companion, not a standalone
  control-plane product

## Branch protection settings

Document these settings exactly on `main`:

- Required status checks:
  - `release_gate` (aggregates `lint`, `test`, `integration-placeholder`, and
    the path-gated mounted companion proof result from `ci.yml`)
  - `Validate PR title`
  - `dependency-review`
- `actionlint` is not a required status check because it is path-filtered
  and would sit Pending on non-workflow pull requests.
- Require branches to be up to date before merging: off
- Require a pull request before merging: on
- Required approvals: 0
- Require linear history: on
- Require signed commits: off
- Do not allow bypassing the above settings: on
- Allow force pushes: off
- Allow deletions: off
- Require conversation resolution before merging: off

## Release Please flow

The repository uses a linked-version sibling-package setup:

- `rulestead`
- `rulestead_admin`

The release metadata is seeded so the linked tags stay predictable:

- `rulestead-vX.Y.Z`
- `rulestead_admin-vX.Y.Z`

When Release Please cuts a real release, it dispatches `publish-hex.yml`
with both tags and the shared release version.

## Manual reruns and GitHub token caveat

The default `GITHUB_TOKEN` used by Release Please does not trigger all
follow-on workflows in the same way a normal user action does. If the
dispatch from `release-please.yml` to `publish-hex.yml` fails, use the
manual recovery path below instead of trying to publish ad hoc from a
workstation.

If that becomes painful at release time, move to a dedicated release token
with the minimum write scope needed for the workflow.

## Gated publish choreography

The expected release path for the current shipped `0.1.0` line is:

1. Merge the Release Please PR for the intended version.
2. Let `release-please.yml` create the linked tags and dispatch
   `publish-hex.yml`.
3. Let the publish preflight re-run the release gate and the fresh
   sibling-package admin slice from `rulestead_admin`.
4. Review the `preflight` job output and approve the protected
   `hex-publish` environment.
5. Let `publish-core` publish `rulestead`.
6. Let `publish-admin` publish `rulestead_admin`.
7. Hand off to the separate post-publish verification wave. Do not claim
   live artifact proof before that follow-on verification completes.

The preflight rerun matters because publish readiness must re-run the
sibling-package release slice instead of trusting stale reports from earlier
milestones.

## Manual recovery path

`publish-hex.yml` is also the manual recovery path if the automated handoff
fails after the release PR or tags are already correct.

When using the workflow manually:

1. Supply `core_tag`, `admin_tag`, and `release_version` from the linked
   release (`rulestead-vX.Y.Z` and `rulestead_admin-vX.Y.Z`).
2. Let `preflight` finish before approving `hex-publish`.
3. If `publish-core` succeeds and `publish-admin` fails, rerun
   `publish-hex.yml` with the same inputs and monitor the admin guard
   closely.
4. If a tag is wrong, stop and cut a corrected release rather than trying to
   publish from an untagged commit.

The admin guard is structural. It prevents empty-package squatting by
blocking publication while `rulestead_admin/lib/rulestead_admin/router.ex`
still contains the earlier guarded stub text. It is not a substitute for
human review of the publish run.

## Post-publish verification handoff

Hex publish completion is not the end of the release checklist.

After `publish-hex.yml` completes and both sibling packages are visible on Hex,
transition immediately into the live post-publish verification wave:

```bash
bash scripts/ci/verify_published_release.sh <version>
```

That wrapper is the canonical REL-03 / REL-04 entrypoint. It first confirms
that `rulestead` and `rulestead_admin` expose the requested version on Hex,
then runs the required trio in order:

1. `mix verify.workspace_clean`
2. `mix verify.release_publish <version>`
3. `mix verify.release_parity <version>`

Capture durable evidence from the live run:

- the full command output from `bash scripts/ci/verify_published_release.sh <version>`
- the live package URLs for `rulestead` and `rulestead_admin`
- the versioned HexDocs URL for `rulestead`
- confirmation that the fresh `mix new` consumer proof passed
- confirmation that the fresh `mix phx.new` admin mount/boot proof passed

Treat any failure here as a release blocker, not informational drift. A failed
`verify.release_publish` run means the published artifacts do not satisfy the
documented install or mount contract yet. A failed `verify.release_parity` run
means the Hex tarball differs from the tagged source and must be investigated
before the release can be considered verified.

This is the same bounded proof posture described in the public docs: the local
demo under `examples/demo/` is the primary runnable proof path, while
`verify.release_publish` and `verify.release_parity` are the release-facing
proof seams for published artifacts.

## Mounted Companion Contract Proof

Use this narrow mounted companion proof bar when the work changes the mounted
cleanup flow, host-facing route conventions, or the authored ownership and
lifecycle contract that the companion surfaces.

Run the same wrapper locally or in CI:

```bash
RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh
```

That scope is intentionally bounded to:

- `rulestead_admin/test/rulestead_admin/live/session_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
- `rulestead/test/rulestead/admin_contract_test.exs`
- `rulestead/test/rulestead/admin_lifecycle_test.exs`

CI exposes the same command through the path-gated `mounted companion proof`
job in `.github/workflows/ci.yml`. It is visible by name so maintainers can
cite it directly, and `release_gate` treats that job as required whenever
mounted-proof-relevant paths change.

Treat this proof bar as merge-blocking for mounted lifecycle and
admin-contract changes. It is sufficient to claim the mounted lifecycle/admin
surface is green again. It is not sufficient to claim the entire admin package,
every repo verification surface, or future companion proof paths are closed.

## OpenFeature Companion Proof

Phase 44 adds a separate proof bar for the optional `open_feature_rulestead`
provider package. Use it when the work changes the package README, provider
contract, context mapping, or the repo-level support truth around the
OpenFeature companion surface.

Run the same wrapper locally or in CI:

```bash
RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh
```

That scope is intentionally bounded to:

- `open_feature_rulestead/test/open_feature_rulestead/context_mapper_test.exs`
- `open_feature_rulestead/test/open_feature_rulestead/provider_test.exs`

CI exposes the same command through the path-gated `openfeature companion
proof` job in `.github/workflows/ci.yml`. It is visible by name so maintainers
can cite it directly, but it is not threaded into the default sibling-package
release gate and does not redefine the repo as a three-package publish machine.

Treat this proof bar as merge-blocking for the OpenFeature companion contract
it actually covers. It is sufficient to claim the Elixir provider package is
runnable and documented. It is not sufficient to claim browser/demo glue,
publish choreography, or unrelated repo surfaces are now part of the same
contract.

## Guarded Rollout Foundations Proof

Use the guarded rollout foundations proof when work touches VER-01 support
truth, guardrail decision semantics, mounted rollout status explanation, or the
root/package docs that describe guarded rollout support.

Run the same wrapper locally:

```bash
RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh
```

That scope is intentionally bounded to stale signals, insufficient samples,
automatic hold, automatic rollback, mounted explanation, and support-truth
drift guards. It proves VER-01 only across the current host-owned fact seam and
mounted companion explanation path.

It does not prove metrics pipelines, dashboards, provider adapters, browser
demo flows, or automated rollout advancement. Keep those as separate future
support claims unless a later phase adds explicit code, docs, and proof.

## Reusable Targeting Deepening Proof

Use the reusable targeting deepening proof when work touches reusable
**Audience** workflows, dependency inventory, impact preview, compare/promotion
dependency findings, explain trace carry-through, or the root/package docs
that describe v1.6 support truth (VER-01 for this milestone).

Run the primary maintainer command:

```bash
cd rulestead && mix verify.phase56
```

Or rerun through the CI wrapper:

```bash
RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh
```

That scope is intentionally bounded. It proves:

- dependency inventory and visibility contracts
- preview determinism and stale preview fingerprint rejection
- fail-closed blockers for missing, archived, incompatible, or stale references
- audit evidence for audience mutations
- explain trace carry-through for audience resolution
- promotion and manifest dependency blockers

It does **not** prove exact affected-user counts, dependency graph UIs,
batch mutation automation, package-owned metrics pipelines, or observability
dashboards inside Rulestead. Keep those as separate future support claims.

Upstream boundary contracts for this milestone:

- `.planning/phases/54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md`
- `.planning/phases/55-mounted-operator-workflows/55-HANDOFF-CHECKLIST.md`

## Blast Radius Governance Proof

Use the blast radius governance proof when work touches protected-environment
audience mutations, threshold evaluation, change-request proposal/execute, or
the root/package docs that describe v1.7 support truth (VER-01 for this
milestone).

Run the primary maintainer command:

```bash
cd rulestead && mix verify.phase60
```

Or rerun through the CI wrapper:

```bash
RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh
```

That scope is intentionally bounded. It proves:

- threshold evaluation and breach reasons in protected environments
- change-request proposal and execute for high-blast-radius audience mutations
- stale-preview rejection and fail-closed behavior on missing inputs
- audit evidence for governed mutations
- mounted admin governance UX and route contract (no standalone governance app)

It does **not** prove observability-backed population counts, parallel governance
workflows, standalone admin products, or automatic progressive delivery beyond
deferred roadmap items. Previews use **preview basis** (authored references and
**explicit samples** only).

Upstream boundary contracts for this milestone:

- `.planning/phases/57-blast-radius-threshold-contract/`
- `.planning/phases/58-change-request-integration/`
- `.planning/phases/59-mounted-governance-workflows/`

## Guarded Rollout Auto-Advance Proof

Use the guarded rollout auto-advance proof when work touches opt-in
auto-advance policy, observation-window eligibility, scheduled-tick
orchestration, mounted auto-advance panel presentation, or the root/package
docs that describe v1.8 support truth (VER-01 for this milestone).

Run the primary maintainer command:

```bash
cd rulestead && mix verify.phase64
```

Or rerun through the CI wrapper:

```bash
RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh
```

That scope is intentionally bounded. It proves:

- opt-in per-rollout auto-advance policy with observation window and authored
  next-stage plan
- healthy scheduled-tick advance and fail-closed non-advance on weak or stale
  signals
- protected-environment change-request routing at tick execute
- idempotency under concurrent manual advance
- mounted admin auto-advance panel and timeline labeling with
  **`guardrail_automation`**
- v1.5 hold and rollback behavior preserved when auto-advance is enabled

It does **not** prove metrics pipelines, fleet-wide operator dashboards,
clock-driven percentage rollout semantics, unattended rollout recovery, or
Rulestead-owned progressive delivery automation. Signal facts and metrics
normalization remain host-owned; Rulestead evaluates normalized facts only.

Upstream boundary contracts for this milestone:

- `.planning/phases/61-auto-advance-authored-contract/`
- `.planning/phases/62-orchestration-and-governed-execution/`
- `.planning/phases/63-mounted-auto-advance-workflows/`

## Lifecycle Release Surface

Phase 38 adds a lifecycle release surface that maintainers must verify
explicitly when closing the milestone or preparing later lifecycle-sensitive
releases.

The machine-backed lifecycle release surface is:

- root and sibling README lifecycle discoverability
- the shared `guides/flows/flag-lifecycle.md` narrative
- `mix rulestead.lifecycle` contract coverage
- mounted host-seam verification through `admin_mount_test.exs`

Do not treat this as a prose-only checklist. The lifecycle closeout requires a
machine-backed evidence artifact at
`.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md`.

That artifact should point to the exact `mix test` commands, `rg` checks, and
pass outputs used to verify the lifecycle release surface.

## Timing expectations

Do not use the existence of the release workflows alone as the signal to ship.

Ship or document support only when these conditions are true:

1. The current `0.1.x` package line is aligned with the root and sibling docs.
2. The multi-environment compare/promote and import/export seams are documented
   well enough for early adopters to use honestly.
3. The mounted companion posture is clear in `README.md`, `rulestead/README.md`,
   and `rulestead_admin/README.md`.
4. The post-publish verification wave is ready to prove both sibling packages
   from live Hex artifacts.

The recurring drift monitor lives in `.github/workflows/verify-published-release.yml`.
It reuses the same shell entrypoint on a daily cron and on manual dispatch,
resolves the latest shared stable sibling release from Hex, and opens or updates
one rolling GitHub issue only when published verification actually fails or the
sibling versions drift out of lockstep.

## Deferred Phase 8 artifacts

Do not create these early:

- `guides/api_stability.md`
- `guides/cheatsheet.cheatmd`
- `guides/flows/extending-rulestead.md`

These files describe the locked public surface and extension points. They
belong to Phase 8, not bootstrap.

Until that surface is real, internal modules should prefer `@moduledoc false`.

## Required references for maintainers and agents

When working in this repo, read:

- `.planning/` for roadmap, requirements, and active phase context
- `prompts/` for anchor docs and implementation guardrails
- `rulestead/` and `rulestead_admin/` as sibling packages, not nested apps
