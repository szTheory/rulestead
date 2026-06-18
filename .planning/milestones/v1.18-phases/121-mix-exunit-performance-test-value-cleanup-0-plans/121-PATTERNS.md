# Phase 121: Mix/ExUnit Performance + Test Value Cleanup - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4 (3 firm edits + 1 conditional 0–1 async flip)
**Analogs found:** 4 / 4 (all in-repo, exact matches)

> This phase MODIFIES existing files; it creates none. Every planned change has a
> verbatim in-repo precedent, and RESEARCH.md already supplies copy-ready
> templates. This map cross-references each change to (a) its concrete analog
> with current line numbers and (b) the RESEARCH.md template the planner should
> reuse, so the planner does not re-derive anything.

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `rulestead/test/test_helper.exs` | config (test boot) | request-response (boot-time exclude wiring) | self — existing `install_integration` env-conditional exclude (lines 1–8) | exact (same file, same pattern) |
| `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` | test | transform / file-I/O + subprocess (`System.cmd` deps.get/compile) | `test/rulestead/integration/install_smoke_test.exs` `@moduletag :install_integration` (lines 2,6,7) | exact (same tag-gating idiom) |
| `scripts/ci/test.sh` | config (CI scope dispatcher) | event-driven (scope → mix invocation) | self — existing `run_guarded_rollout_foundations` (lines 173–186) + `case "${TEST_SCOPE}"` (523–575) + scope failure-microcopy fns (430–469) | exact (same dispatcher) |
| (conditional) `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` | test | CRUD (Ecto) — **DDL in setup** | clean async RepoCase header `analytics/query_test.exs:2` (and `webhooks/inbound_contract_test.exs`) | role-match; **research verdict: 0 flips recommended** |

---

## Pattern Assignments

### `rulestead/test/test_helper.exs` (config, boot-time exclude — D-03)

**Analog:** the same file's existing `install_integration` env-conditional exclude. Mirror this; do NOT replace it (replacing drops the existing gate — Anti-Pattern in RESEARCH.md:191).

**Existing pattern to extend** (`test_helper.exs:1-8`, VERIFIED current):
```elixir
exunit_opts =
  if System.get_env("RULESTEAD_RUN_INSTALL_INTEGRATION") == "1" do
    []
  else
    [exclude: [install_integration: true]]
  end

ExUnit.start(exunit_opts)
```

**Why this is the home for the new tag (load-bearing):** the `all` lane passes
`--exclude install_integration` on the CLI (`test.sh:529`), but the
`guarded_rollout_foundations` lane runs `mix test <file>` *without* any CLI
exclude (`test.sh:176-181`). Only a `test_helper.exs`-level exclude reliably
default-excludes the new slow tag across BOTH invocation styles. (RESEARCH.md:160)

**Template the planner should reuse:** RESEARCH.md Pattern 1 (lines 119–151)
gives a ready two-branch / `then`-chain extension producing
`exclude: [install_integration: true, published_hex_smoke: true]` by default,
each removed when its env (`RULESTEAD_RUN_INSTALL_INTEGRATION` /
`RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`) is `"1"`. The load-bearing requirement
(RESEARCH.md:151): **excluded by default, included only when the env is set.**
Planner has discretion over tag/env name (CONTEXT D-03 / RESEARCH A2); suggested
`published_hex_smoke` / `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`. Keep the flat style
of the existing block for auditability.

> Note: lines 10–23 of `test_helper.exs` set the process-global app env + named
> `Rulestead.Fake` singleton + `Sandbox.mode(:manual)`. Do NOT touch these — they
> are the documented reason most modules are correctly `async: false` (D-01/D-02).

---

### `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` (test, D-03/D-04)

**Analog:** `test/rulestead/integration/install_smoke_test.exs` — the existing
default-excluded slow integration test that pairs the tag with an explicit timeout.

**Tag + timeout pattern** (`install_smoke_test.exs:1-7`, VERIFIED):
```elixir
defmodule Rulestead.Integration.InstallSmokeTest do
  use ExUnit.Case, async: false

  import Rulestead.Test.InstallFixture

  @moduletag :install_integration
  @moduletag timeout: 300_000
```

**Target test (the dominant ~27.95s case)** (`verify_release_publish_test.exs:199-217`, VERIFIED):
```elixir
  @published_smoke_version "0.1.4"

  test "admin consumer fixture compiles against published Hex packages" do
    tmp_dir = tmp_dir()
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    consumer =
      ReleasePublishFixture.setup_admin_consumer!(tmp_dir, @published_smoke_version)

    for check <- consumer.checks do
      {output, status} =
        System.cmd(check.cmd, check.args, cd: consumer.app_dir, stderr_to_stdout: true)

      assert status == 0, """
      #{check.cmd} #{Enum.join(check.args, " ")} failed in #{consumer.app_dir}:
      #{output}
      """
    end
  end
```

**Change to make:** add a single `@tag :published_hex_smoke` (per-test, NOT
`@moduletag` — the module's other tests at :219+ are fast and must stay in the
default lane) immediately above the `test "admin consumer fixture compiles..."`
line (currently line 201). RESEARCH.md:153-158 gives this exact placement.

**D-04 (no blind retry):** Do NOT wrap the `System.cmd` (line 209-210) in a
retry. The `install_smoke_test.exs:7` `@moduletag timeout: 300_000` is the
sanctioned precedent if the planner wants an explicit documented timeout for
failure clarity — but apply it as a per-`@tag timeout:` on this one test (the
module's other tests should not inherit a 300s timeout). RESEARCH.md:192.

**Pin note (do not auto-bump):** `@published_smoke_version "0.1.4"` (line 199)
is a maintained constant ≠ `mix.exs @version 0.1.7`; intentional, out of scope to
change (RESEARCH.md:212).

---

### `scripts/ci/test.sh` (config, scope dispatcher — D-03/D-08)

**Analog:** the same file's existing scope structure. Three concrete sub-patterns to copy from:

**(a) Scope runner that lists explicit files** — `run_guarded_rollout_foundations` (`test.sh:173-186`, VERIFIED). This is where the dominant test file already runs:
```bash
run_guarded_rollout_foundations() {
  run_mix rulestead deps.get
  prepare_rulestead_test_db
  run_mix rulestead test \
    test/rulestead/guardrails/contract_test.exs \
    test/rulestead/guardrails/decision_test.exs \
    test/rulestead/guarded_rollout_test.exs \
    test/rulestead/release_contract_test.exs \
    test/rulestead/mix/tasks/verify_release_publish_test.exs
  run_mix rulestead_admin deps.get
  run_mix rulestead_admin test \
    test/rulestead_admin/live/flag_live/rollouts_test.exs \
    test/rulestead_admin/live/flag_live/timeline_test.exs
}
```

**Re-inclusion pattern to add (from RESEARCH.md:170-175):** because the `mix test
<file>` invocation on line 176-181 inherits the `test_helper.exs` exclude, after
tagging it will silently stop running the slow case (RESEARCH.md Pitfall 1).
Opt it back in with the env (matching the `install_integration` env idiom) and/or
`--include`:
```bash
RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke \
  test/rulestead/mix/tasks/verify_release_publish_test.exs
```

**(b) `case "${TEST_SCOPE}"` dispatch + Unknown-scope contract** (`test.sh:523-575`, VERIFIED). If the planner introduces a new named scope (not required — reusing `guarded_rollout_foundations` is lowest-churn), it must be added to BOTH the `case` arm AND the `Supported scopes:` microcopy list (line 572) to keep the contract honest (D-08).

**(c) Per-scope failure microcopy** — copy the shape of `post_ga_band_closure` (`test.sh:430-498`, VERIFIED): a `print_*_failure_guidance` fn (category + boundary + `Rerun:` command + `Remediation:`) plus a `*_failure_category` log-grep classifier, wired through a `run_*` fn that logs to a tempfile and prints guidance on non-zero status. Whichever scope owns the relocated proof must keep this microcopy intact and mention the `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1` rerun (D-08; RuntimeState §Secrets/env vars).

**Wiring decision left to planner (RESEARCH Open Q1, CONTEXT D-03):** canonical home for the relocated proof. Options: (a) opt-in on `guarded_rollout_foundations` (file already there, lowest churn — recommended minimum), (b) add the test to `verify.phase82`'s `@phase82_core_tests` so `post_ga_band_closure`/`adopter` gains it, or (c) both. CONTEXT D-03 names `post_ga_band_closure`/`adopter` as the release/adopter home — confirm at plan time. **Critical:** verify post-change that at least one named scope actually EXECUTES the test case (not just the file), or the supply-chain proof silently vanishes (RESEARCH Pitfalls 1–2).

> `all` scope (`test.sh:524-533`): line 529 currently runs the dominant test via
> `--exclude install_integration` (which does NOT exclude the new tag yet). After
> the `test_helper.exs` extension, the new tag is excluded here automatically —
> no edit needed in the `all` arm. Leave it as-is (D-08: keep test.sh structural).

---

### (Conditional) `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` (test async flip — D-01/D-02)

**Research verdict: 0 flips recommended (correctness-first). Maximum defensible: 1.**
Per the full per-module audit (RESEARCH.md:294-321), all 23 `async: false`
RepoCase candidates carry a disqualifying hazard EXCEPT this one — which instead
runs `Repo.query!("CREATE TABLE IF NOT EXISTS code_reference_scans ...")` DDL in
`setup` (:188-197), the "DB ownership" disqualifier D-01 names (RESEARCH Pitfall 4).

**If the planner flips anything, the target shape is this clean async RepoCase header:**

**Analog** (`rulestead/test/rulestead/analytics/query_test.exs:1-6`, VERIFIED):
```elixir
defmodule Rulestead.Analytics.QueryTest do
  use Rulestead.RepoCase, async: true
  # pure Repo.insert/Repo.all on schemas; NO Application.put_env, NO Fake,
  # NO telemetry, NO ETS, NO System.cmd, NO File.*
```
(Identical shape: `webhooks/inbound_contract_test.exs`, `webhooks/outbound_contract_test.exs`.)

**Why RepoCase async is safe** (`repo_case.ex:18-28`, VERIFIED): `setup` checks
out the sandbox and sets `{:shared, self()}` ONLY `unless tags[:async]` — the
async path is per-process-isolated. RepoCase is not the blocker; per-module
global state is.
```elixir
  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rulestead.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, {:shared, self()})
    end

    Rulestead.StoreFixtures.seed_default_audience_for_repo!()
    :ok
  end
```

**Greppable hazard gate (run before any flip)** — RESEARCH.md:282-292: ANY hit =
leave serial. If the planner flips `code_refs_plug_test.exs`, it MUST attach a
documented DDL-under-async analysis + a verification run (`mix test <file>
--warnings-as-errors` run twice for flake check). Default = leave serial (D-02).

**Do NOT flip the known-serial trio** (CONTEXT D-02): `oban/stale_flag_worker_test.exs`,
`analytics/batcher_test.exs`, `webhooks/inbound_http_test.exs`.

---

## Shared Patterns

### Default-excluded slow-test tag (cross-cutting for D-03)
**Source:** `rulestead/test/test_helper.exs:1-8` (env-conditional exclude) + `install_smoke_test.exs:6-7` (`@moduletag :install_integration` + explicit timeout).
**Apply to:** the `test_helper.exs` exclude list AND the dominant test tag — the two halves of the same idiom. Tag semantics: `@tag :x` == `@tag x: true`; `exclude` must precede any `include` (RESEARCH CITED, lines 160/198).

### Scripts-first scope dispatch + failure microcopy (cross-cutting for D-08)
**Source:** `scripts/ci/test.sh` `case "${TEST_SCOPE}"` (523-575), `run_*` fns (e.g. 173-186, 471-498), `print_*_failure_guidance` + `*_failure_category` pairs (430-469).
**Apply to:** any scope wiring change for the relocated proof. Preserve the
contract: scope arm + `Supported scopes:` list + category/boundary/`Rerun:`/`Remediation:`
microcopy + matrix-aware rerun output. Never put the opt-in in workflow YAML
(CLAUDE.md scripts-first; RESEARCH.md:348).

### Correctness-first async conservatism (cross-cutting for D-01/D-02)
**Source:** RESEARCH per-module audit (294-321) + greppable hazard methodology (282-292) + clean header `analytics/query_test.exs:2`.
**Apply to:** every async decision — cite hazard-absence evidence per flip; when in doubt, leave serial. Net recommended flips: 0.

### Before/after measurement (cross-cutting for D-09)
**Source:** `119-CI-CD-AUDIT.md:153-154` locked commands (reproduced RESEARCH.md:266-275).
**Apply to:** the phase measurement record (feeds Phase 123). Use verbatim:
`cd rulestead && mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25`,
run default (excluded) vs `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 ...` (included).
Baseline to beat: ~42s real, 587 tests + 8 properties, dominant ~27.95s, 18 schedulers.

---

## No Analog Found

None. Every planned change has an exact in-repo precedent. No file needs to fall
back to RESEARCH.md generic templates — though RESEARCH.md Patterns 1–3 already
provide copy-ready code for each change above.

---

## Metadata

**Analog search scope:** `rulestead/test/` (test_helper, RepoCase support, candidate test modules, install_integration tag users), `scripts/ci/test.sh` (scope dispatcher + microcopy fns).
**Files scanned (read or grepped):** `test_helper.exs`, `verify_release_publish_test.exs`, `repo_case.ex`, `analytics/query_test.exs`, `install_smoke_test.exs`, `install_golden_test.exs`, `scripts/ci/test.sh` (4 ranges) — plus the full 23-module async audit pre-verified in RESEARCH.md.
**Pattern extraction date:** 2026-06-16
**Note:** RESEARCH.md already supplies templates for all three firm edits (Pattern 1 = test_helper + tag; Pattern 2 = test.sh re-inclusion; Pattern 3 = clean async header). This map ties each to its current-line in-repo analog so the planner can copy directly.
