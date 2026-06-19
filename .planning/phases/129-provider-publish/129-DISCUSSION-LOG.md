# Phase 129: Provider Publish - Discussion Log (Assumptions Mode + Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-19
**Phase:** 129-provider-publish
**Mode:** assumptions (escalated to deep multi-agent research at user request)
**Areas analyzed:** Env-gated dep swap; Docs/HexDocs; Packaging (package/LICENSE/CHANGELOG);
Publish mechanics; Verification

## Process

1. Codebase-first assumptions analysis (gsd-assumptions-analyzer) surfaced 5 gray areas.
2. One external-research item (HexDocs rendering without ex_doc) resolved via WebSearch: confirmed
   `mix hex.publish` uploads no docs unless ex_doc generates `doc/` — ex_doc is required.
3. User requested deep subagent research on every area (pros/cons/tradeoffs, idiomatic Elixir/Hex
   ecosystem patterns, lessons from comparable libs, DX) for a one-shot coherent recommendation set.
4. Three parallel research agents (docs+packaging / dep-swap+publish / verification) returned decisive,
   mutually-consistent recommendations, cross-checked against `prompts/` and the live codebase.

## Assumptions Presented (post-research)

### Version & Env-Gated Dep Swap
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Bump @version 0.1.0→1.0.0; manual (not release-please) | Confident | release-please-config.json excludes provider |
| Add `OPEN_FEATURE_RULESTEAD_HEX_RELEASE` swap mirroring admin | Confident | rulestead_admin/mix.exs:47-53; accrue lineage |
| Published constraint = `~> 1.0` (NOT admin's `~> #{@version}`) | Confident (resolved) | criterion 1 literal; satellite floats vs stable post-1.0 semver core |

### Docs / HexDocs
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| ex_doc required; HexDocs blank without it | Confident | Hex publish docs; WebSearch |
| Lean docs, NO brand parity | Confident | upstream open_feature SDK precedent; brandbook has no per-companion mandate |
| source_ref → `open_feature_rulestead-v1.0.0` tag | Confident | include-component-in-tag convention (tag `rulestead_admin-v1.0.0`) |

### Packaging
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Tighten package(): explicit files, Changelog link, omit maintainers | Confident | siblings omit maintainers; Changelog path footgun |
| Create LICENSE (copy root MIT) | Confident | provider LICENSE missing; required by files: |
| Create CHANGELOG (keep-a-changelog 1.0.0) | Confident | CHANGELOG.md absent; criterion 4 |
| README needs no version-truth edits | Confident | check_version_truth.py green; README already v1.0.0 |

### Publish Mechanics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Local `mix hex.publish`, no new CI workflow | Confident | MAINTAINING.md "separate manual step" / "not a 3-package machine" |
| Guard script + runbook; dry-run dep-list inspection mandatory | Confident | Hex silently drops path deps (Hex docs) |

### Verification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 2 manual local proofs (fresh consumer + companion tests on Hex) | Likely→Confident | criterion 3 two clauses; test.sh:124-129 |
| "openfeature_companion contract tests" = existing CI scope, not missing | Confident | scripts/ci/test.sh:124-129; MAINTAINING.md:365-388 |
| Defer new automated smoke / verify-trio threading | Confident | manual satellite; disproportionate |

## Corrections Made

User did not correct individual assumptions; instead directed deep research before locking. The
research **refined** two original assumptions:
- **Version constraint:** original assumption left `~> 1.0` vs `~> #{@version}` open; research resolved
  decisively to `~> 1.0` (provider is an unlinked satellite; admin's tight pin doesn't transfer).
- **Docs scope:** original "lean ex_doc" expanded into concrete additions — `source_ref` via a
  dedicated component tag, `skip_undefined_reference_warnings_on`, filling stub `@moduledoc`s, plus
  **two newly-surfaced required artifacts**: creating `LICENSE` (missing) and pinning the `files:`
  whitelist (Hex would otherwise silently ship an incomplete tarball).

## External Research

- **HexDocs without ex_doc:** `mix hex.publish package` uploads no docs; HexDocs renders blank without
  ex_doc generating `doc/`. → ex_doc mandatory. (Source: hexdocs.pm/hex/Mix.Tasks.Hex.Publish)
- **Hex silently drops path deps:** non-Hex deps are excluded from resolution and not listed; a
  forgotten env var ships a `rulestead`-less tarball that uploads cleanly. → dry-run dep-list
  inspection is the non-negotiable catch. (Source: hex.pm/docs/usage)
- **OpenFeature independent versioning:** provider artifacts version independently of the SDK across
  ecosystems; `open_feature_rulestead 1.0.0` depending on `open_feature ~> 0.1.3` is idiomatic.
  (Sources: openfeature.dev provider concept + technical guidelines)
- **Fresh-consumer smoke:** no standard Hex tooling — community pattern is throwaway `mix new` →
  point at published version → `deps.get` → inspect lock/deps.tree. OpenFeature conformance/Gherkin
  testbed is SDK-level, not per-adapter. (Sources: hex.pm usage; open-feature/flagd-testbed)
