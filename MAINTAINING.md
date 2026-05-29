# Maintaining Rulestead

## Release posture

Rulestead ships as a linked-version sibling-package monorepo:

- `rulestead`
- `rulestead_admin`

Repo GA shipped in `v1.0.0` on 2026-05-21. The current installable
sibling-package line on Hex is **`0.1.3`**, so maintainer release work should treat
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
  - `release_gate` (aggregates `lint`, `test`, `integration-placeholder`,
    `adopter contract (post-GA band)`, and the path-gated mounted companion proof
    result from `ci.yml`)
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

## CI caching

`ci.yml` restores and saves bounded Mix caches to keep lint and test lanes fast:

- **Mix deps/build** — `rulestead/` (and sibling packages where the job needs them)
  keyed by `mix.lock` plus OTP/Elixir when matrixed.
- **Dialyzer PLTs** — `rulestead/priv/plts/` uses restore → build-if-miss → save in
  the lint job (PLTs are gitignored locally; CI owns the warm cache).

Cache keys intentionally exclude `.planning/`, `prompts/`, and guide-only edits.

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

The expected release path for the current shipped `0.1.x` line (currently `0.1.3`) is:

1. Merge the Release Please PR for the intended version.
2. Let `release-please.yml` create the linked tags and dispatch
   `publish-hex.yml`.
3. Let `publish-hex` `preflight` and `gate-ci-green` complete — preflight runs
   package guards and the Phase 7 admin slice; `gate-ci-green` requires a
   successful `ci.yml` run on the tagged SHA (dispatch `ci.yml` on the release
   PR ref when release-please bot pushes do not trigger checks).
4. Review the `preflight` and `gate-ci-green` job output and approve the
   protected `hex-publish` environment.
5. Let `publish-core` publish `rulestead`.
6. Let `publish-admin` publish `rulestead_admin`.
7. Hand off to the separate post-publish verification wave. Do not claim
   live artifact proof before that follow-on verification completes.

Publish no longer fakes merge CI success in preflight. `gate-ci-green` polls for up
to ~15 minutes for a green `ci.yml` run on the release tag SHA (handles the
release-please race where publish dispatches before merge CI finishes), including the
`adopter contract (post-GA band)` job (`mix verify.phase82` via
`post_ga_band_closure` scope).

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

- `rulestead_admin/test/rulestead_admin/components/audience_components_test.exs`
- `rulestead_admin/test/rulestead_admin/live/audience_live/edit_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/audience_live/archive_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/audience_live/delete_preview_test.exs`
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

Audience preview evidence tests configure
`Application.put_env(:rulestead, :preview_evidence_resolver, Rulestead.Fake.PreviewEvidenceResolver)`
in the edit, archive, and delete preview LiveView tests above. They prove mounted
surfaces render bounded sample/impression evidence without observability-product
copy regressions.

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

## Host Preview Evidence Proof

Use the host preview evidence proof when work touches opt-in resolver wiring,
sample cohort and impression summary on audience previews, redaction and
fingerprint/stale rejection, governance boundary (GOV-05), mounted rendering, or
the root/package docs that describe v1.9 support truth (VER-01).

Run the primary maintainer command:

```bash
cd rulestead && mix verify.phase68
```

Or rerun through the CI wrapper:

```bash
RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh
```

That scope is intentionally bounded. It proves:

- resolver wiring, redaction, and fingerprint determinism on impact previews
- fail-closed rejection of invalid, oversized, or policy-denied evidence
- governance boundary: impression evidence does not change blast-radius assess
- mounted admin rendering of sample cohort and impression summary with
  `audience_components_test.exs` and audience_live preview tests

Core delta paths (union with phase64 regression):

- `test/rulestead/targeting/preview_evidence_contract_test.exs`
- `test/rulestead/targeting/preview_evidence_test.exs`
- `test/rulestead/governance/preview_evidence_governance_contract_test.exs`
- `test/rulestead_admin/components/audience_components_test.exs`

It does **not** prove warehouse ingestion, fleet-wide operator views,
authoritative population analytics, or Rulestead-owned impression pipelines.
Hosts supply bounded summaries; Rulestead evaluates and presents them — not a
metrics product.

Upstream boundary contracts for this milestone:

- `.planning/milestones/v1.9.0-phases/65-host-preview-evidence-contract/`
- `.planning/milestones/v1.9.0-phases/66-evidence-carry-through-and-governance-boundary/`
- `.planning/milestones/v1.9.0-phases/67-mounted-preview-evidence-workflows/`

## Post-GA Band Closure Proof

Use this proof when closing v1.10 support truth or validating that docs, release
contract, and the v1.9 proof superset still align.

```bash
cd rulestead && mix verify.phase82
```

Integrator-facing alias (delegates to phase82):

> Historical v1.10.1 gate: `mix verify.phase73` (unchanged task; superseded by phase82 for current merges).
> Historical v1.11 gate: `mix verify.phase76` (unchanged task; superseded by phase82 for current merges).

```bash
cd rulestead && mix verify.adopter
```

CI wrapper:

```bash
RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh
```

Adopter 15-minute path (demo smoke + band verify):

```bash
scripts/demo/proof.sh
```

Proves:

- v1.11 intro integration spine doc contract (`phoenix-integration-spine.md` routing)
- v1.9 proof union (phase68 core + mounted admin audience/governance paths)
- `post_ga_band_contract_test.exs` — band docs exist; no stale “unbuilt” claims
- quickstart/runtime doc honesty (`Rulestead.Runtime`, not `enabled?(key, conn)`)
- `context_test.exs` — traits→attributes promotion (v1.10.1)
- bidirectional `api_stability` catalog guards via `release_contract_test.exs` (v1.10.1 / Phase 74)

Does **not** prove: new v2 features (ADM-06, ROL-08, GOV-02-ext); full browser
e2e (use `scripts/demo/verify.sh` for Playwright).

## Proof Matrix (maintainer)

| Command | Proves | Does not prove |
|---------|--------|----------------|
| `mix test` (both packages) | Full regression + `release_contract_test` | Faster milestone-only subset |
| `mix verify.phase82` / `mix verify.adopter` | Post-GA band + v1.10.1 context + v1.11 intro-spine + v1.12 adoption-lab contract guards | Historical phase56-only regressions in isolation |
| `mix verify.phase76` | Historical v1.11 gate (reproducibility) | Superseded by phase82 for current merges |
| `mix verify.phase73` | Historical v1.10.1 gate (reproducibility) | Superseded by phase82 for current merges |
| `mix verify.phase72` | Historical v1.10.0 gate | Superseded by phase73 for v1.10.1+ |
| `mix verify.phase68` | v1.9 host preview evidence focus | Band-closure doc contracts only in phase82 |
| `RULESTEAD_TEST_SCOPE=post_ga_band_closure` | Same as phase82 via CI script | Default merge gate (use `all`) |
| `RULESTEAD_TEST_SCOPE=install_journey` | Fresh-install golden-diff journey | FleetDesk compose/Playwright |
| `scripts/demo/proof.sh` | Demo smoke + phase82 (via adopter) | Playwright frontend |
| `scripts/demo/verify.sh` | Compose + Playwright e2e | Entire ExUnit suite |

### When you change FleetDesk

1. Update seeds, compose, or Playwright → sync [examples/demo/README.md](../examples/demo/README.md).
2. Update persona paths and connect URLs in [guides/introduction/adoption-lab.md](../guides/introduction/adoption-lab.md).
3. Run `cd rulestead && mix test test/rulestead/adoption_lab_contract_test.exs`.

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

## Public surface contract (live)

These guides ship in the Hex package and define the locked public surface. They are **not** deferred artifacts:

- `guides/api_stability.md` — primary semver public-surface contract (telemetry events, modules, breaking-change policy)
- `guides/flows/extending-rulestead.md` — documented extension seams for host apps
- `guides/cheatsheet.cheatmd` — operator quick reference

**Catalog completeness:** reconciling post-GA modules/events with `api_stability.md` and generate-from-contract discipline is **Phase 74** (INV-API-01), not this phase.

Internal modules should still prefer `@moduledoc false` until promoted into the public contract.

## Required references for maintainers and agents

When working in this repo, read:

- `.planning/` for roadmap, requirements, and active phase context
- `prompts/` for anchor docs and implementation guardrails
- `rulestead/` and `rulestead_admin/` as sibling packages, not nested apps
