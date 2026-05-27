---
phase: 53-impact-preview-contract
reviewed: 2026-05-27T10:32:06Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - rulestead/lib/rulestead.ex
  - rulestead/lib/rulestead/admin/policy.ex
  - rulestead/lib/rulestead/audit_event.ex
  - rulestead/lib/rulestead/evaluator.ex
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/fake/control.ex
  - rulestead/lib/rulestead/runtime/snapshot.ex
  - rulestead/lib/rulestead/store.ex
  - rulestead/lib/rulestead/store/command.ex
  - rulestead/lib/rulestead/store/ecto.ex
  - rulestead/lib/rulestead/store/redis.ex
  - rulestead/lib/rulestead/targeting/audience_dependencies.ex
  - rulestead/lib/rulestead/targeting/impact_preview.ex
  - rulestead/test/rulestead/audience_mutation_audit_test.exs
  - rulestead/test/rulestead/release_contract_test.exs
  - rulestead/test/rulestead/runtime/audience_snapshot_test.exs
  - rulestead/test/rulestead/store/audience_impact_contract_test.exs
  - rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs
  - rulestead/test/rulestead/targeting/impact_preview_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 53: Code Review Report

**Reviewed:** 2026-05-27T10:32:06Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Reviewed the Phase 53 impact preview, audience mutation, runtime snapshot, store contract, Fake/Ecto/Redis adapter, and related test changes. The Ecto path now publishes audience definitions into runtime snapshots and the runtime compiler/evaluator consume them snapshot-locally, but the Fake adapter's runtime snapshot builder did not get the matching audience payload. That leaves Fake-backed runtime tests and consumers unable to exercise the new snapshot-local audience behavior through the same store contract.

## Warnings

### WR-01: Fake Runtime Snapshots Omit Compiled Audiences

**File:** `rulestead/lib/rulestead/fake.ex:4650`
**Issue:** `put_runtime_snapshot/2` publishes the Fake runtime snapshot payload with `schema_version`, `environment_key`, `generated_at`, and `flags`, but without the `audiences` map that Ecto includes at `rulestead/lib/rulestead/store/ecto.ex:2411`. `Rulestead.Runtime.Snapshot.compile/1` treats missing audiences as backward-compatible and returns `%{}`, so Fake-backed published snapshots silently lose audience definitions. Any `segment_match` rule evaluated from a Fake snapshot will report the audience as missing even when `Rulestead.Fake.Control.put_audience!/1` seeded it and preview/apply paths see it.

**Fix:** Add non-archived audience definitions to `build_environment_snapshot_payload/2` in the Fake adapter, mirroring the Ecto payload shape.

```elixir
defp build_environment_snapshot_payload(state, environment_key) do
  flags = ...

  audiences =
    state.audiences
    |> Map.values()
    |> Enum.reject(&Map.get(&1, :archived_at))
    |> Enum.sort_by(& &1.key)
    |> Map.new(fn audience ->
      {audience.key,
       %{
         definition: audience.definition,
         archived_at: Map.get(audience, :archived_at)
       }}
    end)

  %{
    schema_version: @snapshot_schema_version,
    environment_key: environment_key,
    generated_at: state.now,
    flags: flags,
    audiences: audiences
  }
end
```

Add a Fake-backed regression test that seeds an audience, publishes a `segment_match` ruleset, compiles `Rulestead.Fake.Control.latest_snapshot!/1`, and asserts `audience_keys` contains the seeded audience.

---

_Reviewed: 2026-05-27T10:32:06Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
