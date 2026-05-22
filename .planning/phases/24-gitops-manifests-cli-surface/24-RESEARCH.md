# Phase 24: GitOps Manifests & CLI Surface - Research

**Researched:** 2026-05-19
**Domain:** Deterministic authored-state manifest export, offline validation/diff, and preview-first CLI automation for import and promotion. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Recommendation-First Posture
- **D-01:** Downstream research, planning, and execution for this phase should default to **recommendation-first** decisions rather than reopening routine tradeoffs. Re-ask only when a choice would materially change public contract, security posture, product scope, or release shape. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-02:** The coherent system matters more than local optimization. Manifest shape, CLI task family, output contract, and safety posture must be designed together and should not pull in opposite directions. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Manifest Shape and File Boundary
- **D-03:** Phase 24 ships a **single canonical JSON manifest per environment export**. Do not make YAML the canonical format in this phase. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-04:** The exported file boundary is **one environment bundle per file**, not one file per flag and not one multi-environment mega-document. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-05:** The manifest captures **published authored desired state only** for the selected environment:
  - top-level schema/version and manifest kind
  - `environment_key`
  - one semantic entry per `flag_key`
  - global authored flag metadata that is semantic and reviewable
  - the selected environment's authored overlay
  - the active published ruleset only
  - stable dependency references by semantic key such as `audience_key` [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-06:** The manifest must exclude:
  - database IDs / UUIDs
  - inserted / updated timestamps
  - runtime snapshots and cache or invalidation metadata
  - audit events, change requests, approval state, and scheduled execution state
  - kill-switch / operational override state
  - unpublished drafts
  - persisted compare tokens or fingerprints in the authored export itself [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-07:** The manifest is a deterministic authored-state automation artifact, **not** a full disaster-recovery dump of every runtime or governance concern. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### CLI Task Family and Invocation Style
- **D-08:** Phase 24 ships **five separate Mix tasks**:
  - `mix rulestead.export`
  - `mix rulestead.validate`
  - `mix rulestead.diff`
  - `mix rulestead.import`
  - `mix rulestead.promote` [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-09:** Do **not** introduce a bespoke `mix rulestead ...` subcommand shell. Separate tasks are more idiomatic for Mix, clearer in `mix help`, and more consistent with the repo's current task style. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html]
- **D-10:** `import` and `promote` use a **saved plan/apply workflow**:
  - preview or plan first
  - mutate only with explicit `--apply`
  - `--apply` consumes a previously generated plan artifact, not raw live inputs [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-11:** File and stream ergonomics should be Unix-friendly:
  - `-` means stdin or stdout where a file path is accepted
  - default text output for humans
  - explicit machine mode via `--format json` [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-12:** The task family should support explicit environment and scope flags rather than hidden defaults. Target environment must never be implicit for mutating commands. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-13:** Require an explicit operator reason for real mutation paths (`--reason` on apply). [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Output and Exit-Code Contract
- **D-14:** All Phase 24 tasks render from **one canonical result envelope**. Human-readable text is a renderer over the same semantic payload used for JSON output, not a second ad hoc contract. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-15:** Default human output is deterministic, line-oriented, and summary-first:
  - stable section order
  - stable sorting by flag key and finding severity/code
  - top-level status first
  - findings before deep detail [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-16:** `--format json` must print **only JSON to stdout**. Do not mix banners, prose, or warnings into machine-readable stdout. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-17:** Lock a small, explicit status vocabulary for JSON output:
  - `ok`
  - `no_changes`
  - `changes`
  - `governance_required`
  - `invalid`
  - `blocked`
  - `stale`
  - `applied`
  - `queued`
  - `error` [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-18:** Use the following exit-code policy consistently:
  - `0` — successful and clean
  - `1` — CLI usage, file I/O, JSON encoding, or unexpected internal/system failure
  - `2` — successful domain result with changes present and no blocker preventing preview
  - `3` — successful command execution but domain state is invalid, blocked, stale, or otherwise not applyable [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-19:** Command-specific expectations:
  - `export` returns `0` on successful write
  - `validate` returns `0` when valid and `3` on schema/dependency invalidity
  - `diff` returns `0` for no diff, `2` for applyable diff, and `3` for blocked/invalid comparison basis
  - `import --plan` and `promote --plan` return `0` for no-op, `2` for applyable changes, and `3` for blocked/invalid/stale previews
  - `import --apply` and `promote --apply` return `0` for applied/no-op/queued governed result and `3` for stale/blocked/invalid domain rejection [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-20:** Stale preview is a **domain rejection**, not a system crash. It should map to `3`, not `1`. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Import and Promote Safety Posture
- **D-21:** Phase 24 import and CLI promote use a **strict additive-only plan/apply posture**. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-22:** Omission from source manifest or source environment means **not managed by this apply**, not delete/archive/prune. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-23:** Mutation requires a fresh reviewed preview artifact contract:
  - promote reuses the Phase 23 compare token, source fingerprint, target fingerprint, and dependency closure keys
  - import mints an equivalent scoped preview contract from the manifest and target authored fingerprint [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-24:** Protected targets never mutate through a CLI side door. CLI apply must reuse the existing governed action path where protection requires it. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-25:** No destructive prune, archive, revive, or force mode ships in Phase 24. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-26:** Apply must **block** on:
  - stale preview/import token
  - source or target fingerprint mismatch
  - dependency closure drift or missing dependencies
  - archived dependency references
  - archive/revive lifecycle transitions through import/promote
  - direct protected-target mutation when governance is required [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-27:** Preview should **warn** on:
  - protected target posture
  - active operational override / kill-switch mismatch
  - unpublished drafts in the source side
  - missing target row that a valid apply can create [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-28:** Preview should **report only**:
  - target-only authored state absent from source/manifests
  - non-blocking authored drift
  - preview age badge when fingerprint contract is still fresh [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Idiomatic Ecosystem Fit
- **D-29:** Phase 24 should feel like an Elixir library with a mounted operator UI, not a standalone control plane awkwardly embedded in Phoenix. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-30:** The mounted admin remains the visual review console and source of operator clarity; Mix tasks are the deterministic automation surface for local use and CI. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **D-31:** Reuse the existing compare/apply/governance domain model instead of inventing a CLI-only workflow model. The admin UI and CLI should speak the same language: source, current target, proposed target, findings, tokens, fingerprints, and dependency closure. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Claude's Discretion
- Exact manifest field names beyond the locked semantics above, provided they stay stable, semantic, and JSON-first. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Exact task flag names where the intent is already locked (for example `--out` vs `--output`), provided the family stays consistent. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Exact text rendering layout, provided it remains deterministic, findings-first, and CI-friendly. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Exact plan artifact file naming, provided plan/apply stays explicit and reproducible. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

### Deferred Ideas (OUT OF SCOPE)
- YAML as a first-class authored manifest format. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Multi-environment mega-documents or per-flag file-tree manifests. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Bidirectional reconciliation or continuous sync. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Destructive prune mode. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Archive/revive lifecycle mutations via import/promote. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- `mix rulestead ...` bespoke umbrella subcommand shell. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- Partial-rule or cherry-pick promotion UX. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAN-01 | Team can export deterministic environment manifests with stable semantic keys suitable for code review and CI usage. [VERIFIED: `.planning/REQUIREMENTS.md`] | Export one JSON environment bundle built from published authored state only, with semantic `environment_key` and `flag_key` ownership, excluded runtime/governance fields, and a dedicated canonical serializer that sorts output deterministically because Elixir maps do not preserve order. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][CITED: https://hexdocs.pm/elixir/Map.html] |
| MAN-02 | Team can validate and diff manifests offline or in CI with stable human-readable and machine-readable output. [VERIFIED: `.planning/REQUIREMENTS.md`] | Render `validate` and `diff` from one canonical result envelope, keep text and JSON as two renderers over the same semantic payload, parse CLI switches with strict `OptionParser` rules, and reuse Phase 22 compare findings/tokens rather than inventing a second diff taxonomy. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| MAN-03 | Team can import manifests through a dry-run preview and an explicit apply step instead of a hidden one-shot mutation. [VERIFIED: `.planning/REQUIREMENTS.md`] | Model import as manifest -> normalized preview bundle -> reviewed plan artifact -> explicit `--apply`, with the same stale-preview, dependency-closure, protected-target, and additive-only guardrails already enforced by Phase 23 promotion apply. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| MAN-04 | The public automation surface includes `mix rulestead.export`, `mix rulestead.validate`, `mix rulestead.diff`, `mix rulestead.import`, and `mix rulestead.promote`. [VERIFIED: `.planning/REQUIREMENTS.md`] | Ship five separate public Mix tasks, each documented by its own task module, using thin `run/1` wrappers over domain services and `Mix.Task.run(\"app.start\")` bootstrapping, matching the repo’s current task style and Mix’s help/discoverability model. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html][CITED: https://hexdocs.pm/mix/Mix.Tasks.App.Start.html] |
</phase_requirements>

## Summary

Phase 24 should be planned as one CLI automation layer over the compare/apply contracts that already exist in `rulestead`, not as a second product surface and not as a Git-native reconciler. The repo already has the right domain substrate: authored-state compare with typed findings, compare tokens, dependency closure, and scoped fingerprints from Phase 22; bounded apply with stale-preview revalidation, immutable environment-version artifacts, and protected-target rejection from Phase 23; and thin Mix-task precedents that boot the app and delegate to domain code. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`]

The main planning risk is contract drift between export, diff, import preview, and promote preview. The planner should therefore keep one canonical authored-state document model and one canonical result envelope. `export` emits the canonical manifest. `validate` checks schema plus dependency realizability from that manifest. `diff` compares two canonical manifests or one manifest against live authored state without changing the finding taxonomy. `import --plan` converts the manifest into the same kind of reviewed intent bundle that `promote --plan` produces from live source/target compare. `--apply` then consumes only a saved plan artifact, never raw manifests or raw environment pairs. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`]

The most important implementation detail is determinism. Elixir maps are unordered, so the planner should reserve explicit work for canonical key ordering before emitting JSON. That means export order cannot be left to incidental map traversal, and human-readable output cannot be built as a separate ad hoc summary layer. The safest slice order is: first establish the manifest schema plus serializer/parser and result envelope in `rulestead`; then add validation/diff rendering and exit-code behavior; then add preview/apply Mix tasks for import and promote on top of the existing apply/governance paths. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `prompts/rulestead-release-engineering-and-ci.md`][CITED: https://hexdocs.pm/elixir/Map.html]

**Primary recommendation:** Plan Phase 24 as three slices:
1. canonical manifest schema + deterministic export/parser in `rulestead`
2. shared validation/diff/result-envelope rendering with text/json and exit-code coverage
3. `import` / `promote` plan-and-apply Mix tasks that reuse Phase 23 preview/apply/governance rules

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Canonical manifest projection | API / Backend | Database / Storage | The manifest is derived from authored state, published rulesets, and dependency references already owned by the core store layer. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`] |
| Deterministic JSON serialization and parsing | API / Backend | — | JSON ordering, schema versioning, and canonical field omission are core contract concerns, not UI concerns. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][CITED: https://hexdocs.pm/elixir/Map.html] |
| CLI task argument parsing and stdout/stderr/exit codes | Frontend Server (SSR) | API / Backend | Mix tasks are the operator-facing entrypoint, but they should stay thin wrappers over backend domain services. [VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Validation and diff result-envelope generation | API / Backend | Frontend Server (SSR) | Findings, status, tokens, and machine-readable payloads must come from the same core contract consumed by text and JSON renderers. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`] |
| Import preview contract generation | API / Backend | Database / Storage | Import preview needs authored-state normalization, dependency checks, target fingerprinting, and protected-target awareness. [VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`] |
| Promote preview/apply from CLI | API / Backend | Frontend Server (SSR) | The CLI is only an automation surface over the promotion bundle and apply path already enforced in core. [VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`] |
| Governed protected-target execution | API / Backend | Database / Storage | Protected-target mutations must continue to flow through stored change-request / schedule contracts, not task-local shortcuts. [VERIFIED: `rulestead/lib/rulestead/store/ecto.ex`][VERIFIED: `.planning/phases/23-governed-promotion-apply/23-RESEARCH.md`] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: `CLAUDE.md`]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: `CLAUDE.md`]
- Preserve the sibling-package layout. Do not collapse work into a single package shape for convenience. [VERIFIED: `CLAUDE.md`]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: `CLAUDE.md`]
- `rulestead_admin` is intentionally a guarded stub until later phases. Do not introduce early publish flows that bypass that rule. [VERIFIED: `CLAUDE.md`]
- Prefer narrow, auditable changes. [VERIFIED: `CLAUDE.md`]
- Use scripts-first CI surfaces where workflow logic gets non-trivial. [VERIFIED: `CLAUDE.md`][VERIFIED: `prompts/rulestead-release-engineering-and-ci.md`]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/ROADMAP.md`]
- Stay inside Phase 24 only; do not widen scope into Phase 25 tenancy helpers. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/ROADMAP.md`]
- Preserve the linked-version sibling-package release design and do not turn `rulestead_admin` into a standalone product. [VERIFIED: `AGENTS.md`][VERIFIED: `.planning/PROJECT.md`]

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Existing `Rulestead` facade + store command pattern | local code [VERIFIED: `rulestead/lib/rulestead.ex`][VERIFIED: `rulestead/lib/rulestead/store/command.ex`] | public manifest/preview/apply domain entrypoints | The repo already centralizes public domain behavior through key-first commands and facade verbs. |
| `Jason` | `1.4.4` [VERIFIED: `rulestead/mix.lock`] | JSON encoding/decoding for manifests and machine output | JSON is already part of the locked phase contract; the repo already depends on Jason. [VERIFIED: `rulestead/mix.exs`][CITED: https://hexdocs.pm/jason/1.4.3/Jason.html] |
| `OptionParser` | Elixir `1.19.5` [VERIFIED: local command `mix --version`] | strict parsing for five public Mix tasks | Official docs prefer `:strict` parsing for known switches, which matches a locked, explicit CLI surface. [VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| Existing compare/apply contracts | local code [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`] | canonical findings, tokens, fingerprints, and apply-time revalidation | Phase 24 should reuse these exact semantics instead of creating separate CLI-only DTOs. |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| Mix task modules | Elixir `1.19.5` [VERIFIED: local command `mix --version`] | five public task entrypoints with `mix help` discoverability | Use one task module per command, following the existing repo task shape. [VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`][CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| `Mix.Tasks.App.Start` pattern | Elixir `1.19.5` [VERIFIED: local command `mix --version`] | task bootstrapping before repo/config access | Use `Mix.Task.run("app.start")` when a task needs the application and repo started, as current tasks already do. [VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`][CITED: https://hexdocs.pm/mix/Mix.Tasks.App.Start.html] |
| `Rulestead.Fake` parity seam | local code [VERIFIED: `rulestead/lib/rulestead/fake.ex`] | contract-faithful tests for manifest/CLI workflows without DB-only coupling | Use for adapter parity and fast CLI contract tests. [VERIFIED: `rulestead/test/rulestead/store/compare_contract_test.exs`][VERIFIED: `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`] |
| `Phoenix.LiveViewTest` / `Phoenix.ConnTest` | `phoenix_live_view 1.1.28`, `phoenix 1.8.5` [VERIFIED: `rulestead_admin/mix.lock`] | only for mounted admin regression where CLI artifacts affect operator review copy or handoff links | Use sparingly; Phase 24 is core/CLI-heavy, not admin-led. [VERIFIED: `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One JSON manifest per environment | YAML or per-flag file trees | Locked context rejects those shapes in Phase 24 and they complicate deterministic review boundaries. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`] |
| Separate Mix tasks | One umbrella `mix rulestead ...` shell | Conflicts with current repo task style and worsens `mix help` discoverability. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Plan/apply artifacts for import and promote | One-shot mutating commands | Violates the locked preview-first safety posture and weakens stale-preview protection. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`] |
| Canonical sorted serializer layer | Plain map-to-JSON encoding with incidental key order | Elixir maps do not preserve order, so incidental traversal is not sufficient for deterministic review artifacts. [CITED: https://hexdocs.pm/elixir/Map.html] |

**Installation:** No new dependency is required for Phase 24. Reuse the existing `rulestead` / `rulestead_admin` stack. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`]

**Version verification:** Relevant locked project versions are `elixir 1.19.5`, `ecto_sql 3.13.5`, `jason 1.4.4`, `phoenix 1.8.5`, and `phoenix_live_view 1.1.28`. [VERIFIED: local command `mix --version`][VERIFIED: `rulestead/mix.lock`][VERIFIED: `rulestead_admin/mix.lock`]

## Architecture Patterns

### System Architecture Diagram

```text
live authored state or manifest file
  -> canonical manifest/parser layer
     -> export:
        fetch published authored state for one environment
        normalize semantic fields
        sort keys deterministically
        emit JSON manifest
     -> validate:
        parse manifest
        verify schema/kind/version
        verify dependency references and lifecycle safety
        emit canonical result envelope
     -> diff:
        compare manifest<->manifest or manifest<->live authored state
        reuse compare finding taxonomy
        emit canonical result envelope
     -> import --plan:
        parse manifest
        normalize proposed target bundle
        fingerprint target authored state
        build import preview token + findings
        write plan artifact
     -> promote --plan:
        run live compare source->target
        reuse compare token/fingerprints/dependency closure
        write plan artifact
  -> apply path (`import --apply` / `promote --apply`)
     -> read saved plan artifact
     -> revalidate token/fingerprints/dependency closure
     -> lower-risk target:
        apply through core store transaction
     -> protected target:
        submit governed action / queue execution
  -> stdout renderer
     -> text renderer for humans
     -> JSON renderer for machines
  -> exit code mapper
```

### Recommended Project Structure

```text
rulestead/
├── lib/rulestead/manifest/                  # schema, parser, serializer, diff/import plan helpers
├── lib/rulestead/promotion/compare.ex       # canonical compare payload reused by diff/promote
├── lib/rulestead/promotion/apply.ex         # stale-preview and protected-target rules
├── lib/rulestead/store/command.ex           # manifest/import/promote command structs
├── lib/rulestead/store/ecto.ex              # live authored reads and import/apply persistence
├── lib/rulestead/fake.ex                    # parity implementation for tests
├── lib/mix/tasks/rulestead.export.ex        # thin task wrapper
├── lib/mix/tasks/rulestead.validate.ex
├── lib/mix/tasks/rulestead.diff.ex
├── lib/mix/tasks/rulestead.import.ex
└── lib/mix/tasks/rulestead.promote.ex

rulestead/test/rulestead/
├── manifest/                                # schema + serializer + parser tests
├── mix/tasks/                               # CLI parsing, output, and exit-code tests
└── store/                                   # fake/ecto parity tests
```

### Pattern 1: Canonical Manifest Schema With Explicit Serializer

**What:** Build one manifest projection and one serializer/parser pair in `rulestead`; do not let each task assemble JSON ad hoc. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

**When to use:** Every export, validate, diff, and import path. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/REQUIREMENTS.md`]

**Example direction:**

```elixir
%{
  "schema_version" => 1,
  "kind" => "rulestead.environment_manifest",
  "environment_key" => "staging",
  "flags" => [
    %{
      "flag_key" => "checkout-redesign",
      "flag" => %{...semantic global metadata...},
      "flag_environment" => %{...selected environment overlay...},
      "active_ruleset" => %{...published rules only...}
    }
  ]
}
```

### Pattern 2: One Result Envelope, Two Renderers

**What:** Text output and JSON output should both render the same semantic result envelope with status, findings, and details. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

**When to use:** `validate`, `diff`, `import --plan`, and `promote --plan`. [VERIFIED: `.planning/ROADMAP.md`]

**Example direction:**

```elixir
%{
  status: :changes,
  summary: %{flag_count: 1, finding_count: 2},
  findings: [%{severity: :warning, class: :operational_override, code: "kill_switch_active"}],
  details: %{...task-specific payload...}
}
```

### Pattern 3: Promote Reuses Compare, Import Builds a Parallel Preview Contract

**What:** `promote --plan` should be a CLI wrapper over `Rulestead.compare_environments/3`; `import --plan` should mint an equivalent preview contract from a manifest plus current target authored fingerprint. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`]

**When to use:** Any preview path that can later be applied. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Pattern 4: Apply Consumes Saved Plan Artifacts Only

**What:** Apply tasks read a previously generated plan artifact, revalidate it, and then either apply directly or route through governance. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`]

**When to use:** `mix rulestead.import --apply` and `mix rulestead.promote --apply`. [VERIFIED: `.planning/ROADMAP.md`]

### Pattern 5: Thin Mix Tasks Over Domain Modules

**What:** Each public task should parse args, start the app, call a domain module, render output, and set exit semantics; the task should not own business rules. [VERIFIED: `rulestead/lib/mix/tasks/rulestead.install.ex`][VERIFIED: `rulestead/lib/mix/tasks/rulestead.redis.sync.ex`]

**When to use:** All five task modules. [VERIFIED: `.planning/REQUIREMENTS.md`]

### Anti-Patterns to Avoid

- **Task-local diff engines:** Do not compute a second finding taxonomy inside Mix tasks when Phase 22 already defines one. [VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`]
- **One-shot import/apply:** Do not allow raw manifest mutation without a saved reviewed plan. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **Incidental JSON determinism:** Do not rely on plain map traversal for review-stable output. [CITED: https://hexdocs.pm/elixir/Map.html]
- **Governance bypass for protected targets:** Do not treat CLI automation as an exception to the approval path. [VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]

## Risks and Planning Implications

- **Serializer determinism is a first-class task, not cleanup work.** The planner should reserve explicit implementation and test coverage for sorted canonical emission because MAN-01 fails if output order drifts between runs. [VERIFIED: `.planning/REQUIREMENTS.md`][CITED: https://hexdocs.pm/elixir/Map.html]
- **Import preview can drift from promote preview if they normalize findings differently.** The planner should keep shared status, finding, and exit-code mapping in one core module used by both paths. [VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`][VERIFIED: `rulestead/lib/rulestead/promotion/compare.ex`]
- **CLI ergonomics can accidentally become a public contract footgun.** Once the five task names, flags, and exit codes ship, they are automation-facing surface area. The planner should treat argument names and JSON envelope fields as release-contract decisions, not disposable implementation details. [VERIFIED: `.planning/REQUIREMENTS.md`][VERIFIED: `rulestead/test/rulestead/release_contract_test.exs`] 
- **Protected-target apply is easy to accidentally bypass in local workflows.** The planner should put governance reuse in the core apply path, not only in task code, so Ecto and Fake parity tests catch bypasses. [VERIFIED: `rulestead/lib/rulestead/promotion/apply.ex`][VERIFIED: `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`]
- **Scope creep into tenancy or reconciliation is the main product risk.** The planner should stop at deterministic manifests, diffing, and preview/apply automation and explicitly avoid tenant-sensitive validation or continuous sync engines in this phase. [VERIFIED: `.planning/ROADMAP.md`][VERIFIED: `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md`]
- **Non-trivial CI logic should not live inline in YAML or task modules.** If plan/apply artifact fixtures, golden outputs, or cross-command smoke checks become substantial, prefer scripts-first helpers to preserve CI readability. [VERIFIED: `CLAUDE.md`][VERIFIED: `prompts/rulestead-release-engineering-and-ci.md`]

## Recommended Slice Boundary

### Slice 1
- canonical manifest schema module and schema-version contract
- deterministic export projection from published authored state
- parser + serializer round-trip coverage
- fake/ecto parity for exported authored content
- manifest contract tests for excluded fields and stable ordering

### Slice 2
- shared validation/diff result envelope
- text renderer + JSON renderer from one payload
- exit-code mapper
- `mix rulestead.export`, `mix rulestead.validate`, and `mix rulestead.diff`
- CLI parsing tests and human/machine output tests

### Slice 3
- import preview contract and saved plan artifact
- CLI promote plan artifact over Phase 22 compare
- explicit `--apply` path for import and promote
- governed protected-target routing reuse
- stale-plan, dependency-drift, and governance contract tests

## Validation Notes

- Reuse the existing Fake/Ecto parity strategy for new manifest and CLI domain contracts. [VERIFIED: `rulestead/test/rulestead/store/compare_contract_test.exs`][VERIFIED: `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`]
- Add Mix-task focused tests under `rulestead/test/rulestead/mix/tasks/` for argument parsing, stdout/stderr separation, and exit-code behavior. Existing task tests already live under that tree. [VERIFIED: `rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs`]
- Keep admin regression narrow: only add `rulestead_admin` tests if the phase introduces operator-facing handoff links or copy that must stay aligned with CLI plan/apply semantics. [VERIFIED: `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs`]

## Sources

### Primary
- `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md` - locked decisions, task family, output contract, and safety posture
- `.planning/ROADMAP.md` - Phase 24 scope, success criteria, and plan slices
- `.planning/REQUIREMENTS.md` - `MAN-01` through `MAN-04`
- `rulestead/lib/rulestead/promotion/compare.ex` - canonical findings, fingerprints, and compare-token contract
- `rulestead/lib/rulestead/promotion/apply.ex` - stale-preview and protected-target apply rules
- `rulestead/lib/rulestead/store/command.ex` - key-first command normalization pattern
- `rulestead/lib/rulestead/store/ecto.ex` - compare/apply persistence path
- `rulestead/lib/rulestead/fake.ex` - parity expectations for new contract coverage
- `rulestead/lib/mix/tasks/rulestead.install.ex` and `rulestead/lib/mix/tasks/rulestead.redis.sync.ex` - current Mix-task style
- `rulestead/test/rulestead/store/compare_contract_test.exs`, `rulestead/test/rulestead/store/promotion_apply_contract_test.exs`, `rulestead/test/rulestead/release_contract_test.exs` - contract coverage posture

### Secondary
- `prompts/rulestead-domain-language-field-guide.md` - canonical use of manifest/export/import/diff/promote vocabulary
- `prompts/rulestead-release-engineering-and-ci.md` - deterministic artifact and scripts-first CI posture
- `prompts/rulestead-testing-and-e2e-strategy.md` - test layering and Fake-first guidance
- `prompts/rulestead-security-privacy-and-threat-model.md` - fail-closed, protected-target, and audit-first posture
- `prompts/rulestead-host-app-integration-seam.md` - Mix-task/operator boundary posture
- https://hexdocs.pm/mix/Mix.Task.html - task module discoverability and public task behavior
- https://hexdocs.pm/mix/Mix.Tasks.App.Start.html - `app.start` semantics
- https://hexdocs.pm/elixir/OptionParser.html - strict switch parsing
- https://hexdocs.pm/elixir/Map.html - unordered map semantics relevant to deterministic export
- https://hexdocs.pm/jason/1.4.3/Jason.html - JSON encode/decode surface already in stack

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommendations reuse current dependencies and local code seams already present in the repo.
- Architecture: HIGH - Phase 24 context locks the public contract tightly and Phase 22/23 already define the core preview/apply substrate.
- Pitfalls: HIGH - major failure modes are visible directly in the locked context plus existing compare/apply tests.

**Research date:** 2026-05-19
**Valid until:** 2026-06-18

---
*Phase 24 research completed: 2026-05-19*
