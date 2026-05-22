# Phase 24: GitOps Manifests & CLI Surface - Pattern Map

**Mapped:** 2026-05-19
**Scope:** Only reusable implementation patterns for Phase 24 deterministic manifest export, validation/diff output, and dry-run import/promote CLI work.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead.ex` | facade | request-response | compare/apply facade verbs in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:69) | exact |
| `rulestead/lib/rulestead/store.ex` | behavior | request-response | compare/apply callbacks in [rulestead/lib/rulestead/store.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:15) | exact |
| `rulestead/lib/rulestead/store/command.ex` | command model | request-response | `CompareEnvironments` and `ApplyPromotion` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:177), [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:225) | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | store adapter | authored-read/write + transaction | compare projection and promotion apply path in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:55), [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:85) | exact |
| `rulestead/lib/rulestead/fake.ex` | fake adapter | request-response | compare/apply parity and snapshot regeneration in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:82), [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:3179), [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:3382) | exact |
| `rulestead/lib/rulestead/promotion/compare.ex` | domain projection | transform | canonical compare payload, sorting, tokening, and finding taxonomy in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:29) | exact |
| `rulestead/lib/rulestead/promotion/apply.ex` | domain validator | request-response | stale preview, fingerprint, and blocker revalidation in [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:7) | exact |
| `rulestead/lib/rulestead/environment_version.ex` | schema/model | transform | normalized authored snapshot persistence in [rulestead/lib/rulestead/environment_version.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/environment_version.ex:11) | role-match |
| `rulestead/lib/rulestead/runtime_snapshot.ex` | schema/model | file-I/O style artifact persistence | deterministic payload/checksum shape in [rulestead/lib/rulestead/runtime_snapshot.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime_snapshot.ex:15) | role-match |
| `rulestead/lib/rulestead/audit_event.ex` | utility/model | append-only audit | normalized metadata envelope in [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33) | role-match |
| `rulestead/lib/rulestead/manifest*.ex` or `rulestead/lib/rulestead/git_ops/*.ex` | domain transform | transform + file-I/O | compare canonicalization in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:64), snapshot/environment-version normalization in [rulestead/lib/rulestead/runtime_snapshot.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime_snapshot.ex:28), [rulestead/lib/rulestead/environment_version.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/environment_version.ex:29) | partial |
| `rulestead/lib/mix/tasks/rulestead.export.ex` | Mix task | file-I/O | task shell + `OptionParser` pattern in [rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:10), [rulestead/lib/mix/tasks/rulestead.code_refs.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.code_refs.ex:18) | exact |
| `rulestead/lib/mix/tasks/rulestead.validate.ex` | Mix task | file-I/O + transform | explicit exit-code task in [rulestead/lib/mix/tasks/verify.release_parity.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex:7) | role-match |
| `rulestead/lib/mix/tasks/rulestead.diff.ex` | Mix task | transform | compare-driven result and exit-code posture in [rulestead/lib/mix/tasks/verify.release_parity.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex:34), [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:118) | role-match |
| `rulestead/lib/mix/tasks/rulestead.import.ex` | Mix task | file-I/O + request-response | preview/apply split from promotion apply and task parsing in [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:15), [rulestead/lib/mix/tasks/verify.release_parity.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex:70) | role-match |
| `rulestead/lib/mix/tasks/rulestead.promote.ex` | Mix task | request-response | compare/apply bundle reuse in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:182), [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:67) | exact |
| `rulestead/test/rulestead/store/*manifest*_contract_test.exs` | contract test | transform + parity | compare/apply adapter parity in [rulestead/test/rulestead/store/compare_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/compare_contract_test.exs:184), [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:147) | exact |
| `rulestead/test/rulestead/mix/tasks/rulestead_*_test.exs` | task test | file-I/O | task-level unit tests in [rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs:6), [rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs:6), [rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:166) | exact |

## Pattern Assignments

### 1. Public facade -> command -> domain/store callback

**Copy from facade:**
- `compare_environments/3` and `compare_environments/1` in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:69)
- `apply_promotion/1` and `apply_promotion/2` in [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:88)

**Pattern to reuse**
- Public APIs expose both a command-first entrypoint and a convenience constructor form.
- Read/preview verbs delegate through a domain module (`Compare.compare/1`) or `run_store(...)`; mutating verbs delegate through a bounded validator (`Apply.apply/1`) before touching the adapter.
- Phase 24 export/validate/diff/import/promote library surfaces should look like first-class `Rulestead` APIs, not task-only helpers buried under `Mix.Tasks`.

**Copy behavior seam from:**
- store callbacks in [rulestead/lib/rulestead/store.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:15)

**What to copy**
- add new callbacks as first-class behavior functions when CLI flows need real adapter participation
- keep return contract `{:ok, map()} | {:error, %Rulestead.Error{}}`
- keep command structs on the adapter boundary rather than passing ad hoc maps

**Recommendation**
- If import preview/apply needs persisted state or parity across Ecto/Fake, model it as a real command + store callback, parallel to compare/apply.
- Keep export/validate/diff domain logic pure where possible, then let tasks only handle parsing, file I/O, rendering, and exit codes.

### 2. Command normalization and bounded input shapes

**Canonical command shapes**
- `CompareEnvironments.new/3` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:195)
- `ApplyPromotion.new/2` in [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:272)
- shared normalizers in `GovernanceSupport` at [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:12)

**What to copy**
- trim and normalize all strings up front
- normalize key lists through `Enum.uniq() |> Enum.sort()`
- normalize nested metadata maps to string-keyed deterministic maps
- keep required fields enforced by `@enforce_keys` and `fetch_required!/2`
- separate operator fields (`actor`, `reason`, `metadata`) from the semantic plan payload

**Recommendation**
- New manifest/export/import command structs should follow `ApplyPromotion`: one canonical semantic payload plus separately normalized operator metadata.
- Plan/apply artifacts should preserve the normalized command payload exactly, especially keys, fingerprints, and sorted dependency lists.

### 3. Canonical projection and deterministic semantic payloads

**Primary analog**
- `Rulestead.Promotion.Compare` in [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:64)

**Important spine**
- `new_result/1` establishes one canonical semantic result shape with stable status, top-level findings, fingerprints, and sorted flag entries
- `compare_projected/1` computes semantic payloads once, then derives token/fingerprint from that canonicalized basis
- `authored_state/1` strips payloads down to authored-semantic fields only

**What to copy**
- one canonical map shape first, multiple renderers second
- sort by key at every boundary that affects serialization or hashing
- derive fingerprints from normalized semantic payloads, not raw DB rows
- keep findings taxonomy semantic and stable so CLI human/json modes both consume the same payload

**Recommendation**
- Build manifest export from the same authored-state discipline as `Compare.authored_state/1`: semantic flag metadata, selected environment overlay, active published ruleset, and stable dependency keys only.
- Build `validate` and `diff` around one canonical result envelope analogous to `new_result/1`; text output should be a renderer over that envelope.
- If a new manifest module needs canonicalization helpers, copy `canonical_*` and sorting posture from `compare.ex`, not ad hoc JSON shaping inside tasks.

### 4. Preview/apply revalidation and stale-plan safety

**Canonical stale-protection flow**
- `validate/2`, `revalidate_compare/1`, and stale checks in [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:15)

**What to copy**
- schema/version check first
- re-fetch fresh compare basis before apply
- reject stale token, fingerprint drift, dependency drift, and blocker findings before mutation
- keep governed/protected-target allowance explicit and opt-in

**Recommendation**
- `mix rulestead.promote --plan` should reuse the compare payload and `ApplyPromotion` semantics directly.
- `mix rulestead.import --plan` should mint a manifest-scoped plan artifact with the same kind of freshness contract: schema version, target fingerprint, sorted flag keys, dependency closure, and normalized proposed bundle.
- `--apply` should consume only a saved plan artifact and rerun validation before mutation; do not apply raw manifest or raw compare output directly.

### 5. Transactional authored-write plus immutable artifact persistence

**Primary analog**
- `apply_promotion/1` and `run_promotion_apply/2` in [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:85)

**Important spine**
- target authored mutations, immutable environment version persistence, and runtime snapshot regeneration happen inside one `Ecto.Multi`
- success payload returns semantic linkage fields, not low-level transaction internals
- adapter translates changeset/internal failures into `StoreError`

**Artifact schema analogs**
- `EnvironmentVersion` normalization in [rulestead/lib/rulestead/environment_version.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/environment_version.ex:29)
- `RuntimeSnapshot` payload/checksum validation in [rulestead/lib/rulestead/runtime_snapshot.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/runtime_snapshot.ex:28)

**Recommendation**
- If import apply persists immutable plan/apply artifacts, copy the `EnvironmentVersion` normalization style: string trimming, list sorting, recursive map normalization, and bounded lengths.
- Deterministic manifest export must not dump raw runtime snapshots, but snapshot/environment-version code is the right analog for how artifact rows are normalized and persisted.
- Keep import/promote apply as one transaction that mutates authored state, records durable linkage, and regenerates runtime state once.

### 6. Fake adapter parity and deterministic in-memory artifacts

**Primary analogs**
- compare/apply entrypoints in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:82)
- environment-version update and result payload in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:3179)
- runtime snapshot rebuild in [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:3382)

**What to copy**
- fake mirrors real adapter semantics, not just success cases
- in-memory state updates preserve sorted deterministic payload generation
- apply code returns the same semantic result keys as Ecto

**Recommendation**
- Every new import/export/apply command that touches adapter behavior needs a fake implementation in the same phase.
- Use fake state as the fast path for CLI contract tests and machine-output snapshots, then prove Ecto parity with one shared contract case.

### 7. Mix task parsing, shell output, and exit-code discipline

**Thin task wrapper pattern**
- `Mix.Tasks.Rulestead.Install.run/1` in [rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:10)
- `Mix.Tasks.Rulestead.CodeRefs.run/1` in [rulestead/lib/mix/tasks/rulestead.code_refs.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.code_refs.ex:18)

**Exit-code task pattern**
- `Mix.Tasks.Verify.ReleaseParity.run/1`, `compute/2`, and `exit_code/1` in [rulestead/lib/mix/tasks/verify.release_parity.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex:7)
- strict arg parsing in [rulestead/lib/mix/tasks/verify.workspace_clean.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.workspace_clean.ex:51)

**What to copy**
- parse args with `OptionParser.parse(..., strict: @switches)`
- reject unknown flags explicitly
- keep tasks thin; pure `compute`/`render` helpers should be testable without invoking `run/1`
- use `Mix.shell().info/error` for human output
- use `System.halt(exit_code(result))` when commands need non-0/non-1 domain exit codes

**Recommendation**
- `validate`, `diff`, `import`, and `promote` should follow `verify.release_parity`: a pure result function plus `exit_code/1`.
- `export` can follow `rulestead.install`: do the work, write to stdout/file, raise on usage/system failures.
- For `--format json`, keep stdout pure JSON and move any warnings/errors to result status plus exit code, not mixed shell prose.

### 8. Task and integration test shapes

**Unit-style task tests**
- pure task helpers and exit-code assertions in [rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs:6)
- parsing and dirty-surface tests in [rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs:6)

**Output-capture task tests**
- deterministic shell output assertions in [rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:166)
- normalization helpers in [rulestead/test/support/install_fixture.ex](/Users/jon/projects/rulestead/rulestead/test/support/install_fixture.ex:80)

**Adapter parity contract tests**
- compare parity loop in [rulestead/test/rulestead/store/compare_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/compare_contract_test.exs:184)
- promotion apply parity loop in [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:147)

**Recommendation**
- Manifest/export/import contract tests should follow the parity-table style from compare/apply tests: run the same assertions against Ecto and Fake.
- CLI tests should isolate pure result/exit-code helpers first, then add a small number of `capture_io` end-to-end task tests for text and JSON modes.
- Normalize machine-output fixtures before comparing if timestamps or temp paths appear, following `InstallFixture.normalize_stdout/1`.

### 9. Append-only audit metadata for real mutations

**Primary analog**
- `AuditEvent.metadata/1` and `serialize/1` in [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33)

**What to copy**
- string-keyed normalized metadata
- explicit `before` / `after` / `diff` / `links` / `context` sections
- governance/schedule linkage fields merged into one append-only envelope

**Recommendation**
- Import/promote apply metadata should extend the existing audit envelope with manifest/plan linkage such as `environment_key`, `manifest_schema_version`, `plan_token` or `compare_token`, source artifact path or digest, and selected `flag_keys`.
- Keep preview-only commands side-effect free; only apply paths should emit audit events.

## Shared Patterns

### One canonical semantic payload, many renderers
- Source: [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:64)
- Apply to: manifest export payload, validate/diff result envelopes, import/promote plan artifacts, human/json renderers
- Rule: compute one normalized semantic map first, then render text or JSON from that same structure.

### Deterministic normalization and sorting
- Source: [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:12), [rulestead/lib/rulestead/environment_version.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/environment_version.ex:45)
- Apply to: manifest flags, dependency lists, finding lists, operator metadata, plan artifacts
- Rule: trim strings, stringify map keys, dedupe/sort lists, avoid source-order dependence.

### Freshness contract before mutation
- Source: [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:15)
- Apply to: `import --apply`, `promote --apply`
- Rule: validate schema version, revalidate preview basis, reject stale fingerprints/tokens/dependency drift before adapter mutation.

### Fake/Ecto parity
- Source: [rulestead/test/rulestead/store/compare_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/compare_contract_test.exs:326), [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:147)
- Apply to: any new store callback or persisted artifact used by Phase 24 CLI flows
- Rule: add the callback to both adapters and prove they emit the same canonical contract.

### Mix task exit-code contract
- Source: [rulestead/lib/mix/tasks/verify.release_parity.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/verify.release_parity.ex:70)
- Apply to: `validate`, `diff`, `import`, `promote`
- Rule: separate domain statuses from process failures and map them to explicit exit codes.

## Do Not Duplicate

- Do not invent a second diff/result model for CLI work. Reuse the compare vocabulary and canonical payload posture from [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:118).
- Do not serialize DB IDs, timestamps, runtime snapshots, audit history, governance state, or kill-switch overrides into exported manifests. Phase 24 context explicitly excludes them.
- Do not let `--apply` accept raw manifests or live ad hoc inputs. Copy the reviewed plan/apply split already implied by [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:67).
- Do not bypass the governed path for protected targets. Keep the same protected-target boundary enforced by [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:88) and [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:93).
- Do not build a bespoke `mix rulestead ...` shell. Phase 24 is explicitly separate Mix tasks, matching the existing task surface under [rulestead/lib/mix/tasks](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks).
- Do not turn `rulestead_admin` into a CLI review or release-orchestration product. Keep mounted-admin posture and linked-version package design from [AGENTS.md](/Users/jon/projects/rulestead/AGENTS.md:17), [CLAUDE.md](/Users/jon/projects/rulestead/CLAUDE.md:19), and [PROJECT.md](/Users/jon/projects/rulestead/.planning/PROJECT.md:34).
- Do not add Phase 25 tenancy semantics here. Phase 24 should stay environment-scoped only per [ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:39).

## No Close Analog Yet

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| canonical manifest module name/location | domain transform | file-I/O + transform | No existing manifest/export module exists yet; planner should choose the narrowest library-facing path that stays inside `rulestead/lib/rulestead/*` and reuse compare/environment-version normalization patterns. |
| shared CLI result renderer module | utility | transform | No current task family exposes both human and machine-readable output from one result envelope; planner should create a pure helper rather than embedding render logic in each Mix task. |
| import plan artifact model | command/model | file-I/O + request-response | Promotion has a compare/apply bundle, but manifest-scoped import preview artifacts are new in Phase 24. Reuse promotion-bundle semantics rather than creating a one-off shape. |

## Minimal Planner Notes

- Plan 24-01 should anchor on a pure manifest/export module plus the existing facade/command/store normalization seams. Keep exported JSON semantic, deterministic, and environment-bounded.
- Plan 24-02 should create one canonical result envelope and renderer layer before adding separate `validate` and `diff` tasks. Exit-code handling should mirror `verify.release_parity`.
- Plan 24-03 should treat `import` and `promote` as siblings: preview artifact first, `--apply` second, protected-target governance unchanged, Fake/Ecto parity required in the same slice.
