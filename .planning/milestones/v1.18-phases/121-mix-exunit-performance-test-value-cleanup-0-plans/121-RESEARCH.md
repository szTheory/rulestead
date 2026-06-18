# Phase 121: Mix/ExUnit Performance + Test Value Cleanup - Research

**Researched:** 2026-06-16
**Domain:** Elixir/ExUnit test concurrency safety, Ecto SQL Sandbox isolation, scripts-first CI proof-scope wiring
**Confidence:** HIGH (all findings verified by reading the actual repo files; the one CITED claim is the ExUnit tag mechanism)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Evidence-gated, allowlist-style flip of `async: false → async: true` (NOT a broad sweep). A module qualifies only when it (a) uses `Rulestead.RepoCase` AND (b) has zero global-state hazards: no global `Rulestead.Fake` singleton use, no `:rulestead, :store`/`:admin_policy`/other app-env mutation, no named-process/ETS singletons, no telemetry attach, no log capture, no `System.cmd`, no filesystem writes.
- **D-02:** Expect a SMALL net-new-async count (0–3 modules); treat as success, not shortfall. Each flip must cite specific hazard-absence evidence; when in doubt, leave serial (correctness-first). Do NOT flip the known-serial trio: `oban/stale_flag_worker_test.exs`, `analytics/batcher_test.exs`, `webhooks/inbound_http_test.exs`.
- **D-03:** Gate `"admin consumer fixture compiles against published Hex packages"` (`verify_release_publish_test.exs:201-217`) behind an opt-in tag/env mirroring the `install_integration` pattern. Default `mix test` drops it (~42s → ~14s expected). The published-Hex proof MUST remain reachable under a named release/adopter scope (`post_ga_band_closure` and/or `adopter`), never deleted.
- **D-04:** NO blind retry on the live-hex.pm `System.cmd`. An explicit documented timeout is allowed.
- **D-05:** Split no modules in Phase 121.
- **D-06:** Explicitly REJECT `mix test --partitions` with evidence (single dominant serial network test; global Fake singleton + single Postgres sandbox; 18 schedulers; no partition config in mix.exs).
- **D-07:** No Dialyzer placement or PLT-key changes (Phase 120 already scoped the PLT key).
- **D-08:** Keep `scripts/ci/test.sh` structurally as-is — preserve `case "${TEST_SCOPE}"` dispatch and every scope's failure microcopy (category + boundary + exact `Rerun:` command + matrix-aware rerun output). The D-03 opt-in must keep the proof reachable via a named scope with intact microcopy and must not break the `release_gate` fan-in.
- **D-09:** Record before/after using the EXACT Phase 119 commands: `cd rulestead && mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25`, run with and without the dominant test. Baseline: ~42s real, 587 tests + 8 properties, dominant ~27.95s, 18 schedulers.
- **D-10:** Treat the length-47 compile-connected xref cycle centered on `lib/rulestead.ex` as architectural evidence only — note, do not refactor.

### Claude's Discretion
- Exact tag name/env var for D-03 (consistent with `install_integration` precedent).
- Exact module list for D-01/D-02 (each with hazard-absence evidence).
- Precise `scripts/ci/test.sh` scope wiring that keeps the published-Hex proof reachable.
- Wording of before/after notes.
- Sequencing into one or more plans, provided `release_gate` (and every named proof scope) stays green at each commit.
- Optional explicit documented timeout on the live-hex `System.cmd` (D-04 allows it; not silent retries).

### Deferred Ideas (OUT OF SCOPE)
- Refactoring the length-47 xref cycle (D-10 notes it only).
- `mix test --partitions` / sharding (D-06 rejects for this milestone).
- Module splitting (D-05 — none warranted now).
- Dialyzer placement / further PLT tuning (D-07).
- Browser/Playwright/demo/integration determinism (Phase 122).
- Contributor-command docs, closeout metrics, rollback notes (Phase 123).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CIDX-06 | Mix, ExUnit, Dialyzer, Playwright, demo, and release workflows use runner time efficiently without fragile over-sharding or hidden correctness risk. | The greppable hazard methodology + per-module verdicts (D-01/D-02) keep async flips evidence-gated; the D-03 opt-in tag relocates the ~28s dominant test off the hot loop while preserving the proof on the release lane; the D-06 partitioning rejection is evidenced; the D-09 measurement record proves the efficiency gain. Dialyzer is out of Phase 121's lever set (D-07); Playwright/demo are Phase 122. |
</phase_requirements>

## Summary

Phase 121 is a deliberately small, correctness-first test-efficiency phase. The research confirms every locked decision is implementable with concrete, greppable evidence already present in the repo, and surfaces the precise wiring facts the planner needs.

The two wall-clock levers are wholly asymmetric. The async flip (D-01/D-02) is **nearly empty**: of the 32 modules that `use Rulestead.RepoCase`, only ~22 are `async: false` candidates after removing the already-async ones and the do-not-flip trio, and **every one of those 22 carries at least one disqualifying hazard** (app-env mutation on shared `:rulestead` keys, global `Rulestead.Fake` singleton mutation, telemetry attach, or `capture_log`). The single module with no Fake/app-env/telemetry markers — `webhooks/code_refs_plug_test.exs` — issues `CREATE TABLE IF NOT EXISTS` DDL in its `setup`, which is exactly the "looks safe, is subtle" sandbox hazard the No-Go guardrails warn against. So the realistic outcome is **0 flips (recommended), or at most 1 if the planner accepts the DDL-in-setup judgment call**. This fully substantiates D-02's "0–3, plausibly 0."

The real lever is D-03: the dominant ~27.95s test runs live `System.cmd("mix", deps.get/compile)` against published Hex packages. Gating it behind a default-excluded ExUnit tag (mirroring `install_integration`) removes it from the default `all` lane. The critical wiring fact: this test currently runs in **exactly two** `scripts/ci/test.sh` paths — the default `all` scope (`test.sh:529`) and the `guarded_rollout_foundations` scope (`test.sh:181`, which runs the file explicitly). It does **not** run in `post_ga_band_closure`/`adopter` (those run `mix verify.phase82`, which does not list this file). The planner must therefore both (a) tag it so default `mix test` excludes it, and (b) wire a named scope to opt it back in so the proof stays reachable.

**Primary recommendation:** Implement D-03 (the high-impact, evidenced lever) as the core of the phase: add a default-excluded `@tag :published_hex_smoke` to the dominant test, mirror `test_helper.exs`'s env-conditional exclude, and add/extend a named `scripts/ci/test.sh` scope (preferably `post_ga_band_closure`, with `guarded_rollout_foundations` opting-in via `--include`) that runs it with full microcopy. Recommend **0 async flips** (or 1, `code_refs_plug_test.exs`, only if the planner explicitly accepts the DDL-in-setup risk with a justification). Reject partitioning with the evidenced rationale. Record before/after with the exact D-09 commands.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ExUnit per-test isolation | ExUnit + Ecto SQL Sandbox | `RepoCase` support module | `repo_case.ex` owns per-process sandbox checkout; the async path correctly omits `{:shared, self()}` |
| Global mutable test state | `Rulestead.Fake` named GenServer + `Application` env | `test_helper.exs` boot | Single named singleton + process-global app env; the dominant async blocker, not Ecto |
| Slow-test gating | ExUnit tags + `test_helper.exs` | `scripts/ci/test.sh` scope dispatch | Tag = inclusion control; scope script = where the proof actually runs |
| Release-trust proof reachability | `scripts/ci/test.sh` named scopes | `ci.yml` jobs → `release_gate` | The published-Hex proof must stay on a named lane the gate can reach |
| Wall-clock measurement | `mix test --slowest / --slowest-modules` | phase summary doc (Phase 123 consumes) | D-09 locks exact commands for comparability |

## Standard Stack

No new packages. This phase edits existing test files, `test_helper.exs`, and `scripts/ci/test.sh`. The relevant existing stack:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | bundled with Elixir `~> 1.17` (matrix: 1.17.3/OTP 26.2.5 and 1.19.2/OTP 28.4.3) | Test framework, async scheduling, tag exclude/include | Elixir's built-in; tag-based exclusion is the idiomatic slow-test gate `[CITED: ex-unit.hexdocs.pm/ExUnit.Case.html]` |
| Ecto SQL Sandbox | `ecto_sql ~> 3.14` `[VERIFIED: rulestead/mix.exs:51]` | Per-process DB isolation enabling `async: true` | `Ecto.Adapters.SQL.Sandbox` is the standard async-test isolation mechanism `[VERIFIED: rulestead/test/support/repo_case.ex:18-28]` |

**No `npm install` / `mix deps.get` additions.** Package Legitimacy Audit is therefore N/A (no new external packages).

## Package Legitimacy Audit

Not applicable — Phase 121 installs no external packages. It edits existing ExUnit test files, `test_helper.exs`, and `scripts/ci/test.sh` only. `[VERIFIED: 121-CONTEXT.md decisions D-01..D-10; rulestead/mix.exs:49-64 deps unchanged]`

## Architecture Patterns

### System Architecture Diagram

```
                         mix test (default `all` lane)
                                   |
                                   v
            test_helper.exs  ──>  ExUnit.start(exclude: [...])   <── env-conditional
              | (boots once)        |                                RULESTEAD_RUN_INSTALL_INTEGRATION
              |                     |                                (D-03: add a 2nd env+tag here)
              v                     v
   GLOBAL state set once:    per-test scheduling
   - Application.put_env(:rulestead,:store, Rulestead.Fake)   <─ process-global; blocks async
   - Application.put_env(:rulestead,:admin_policy, AllowPolicy)
   - Rulestead.Fake.Control.ensure_started/reset!  <─ single NAMED GenServer singleton
   - Supervisor.terminate_child(..Analytics.Batcher)
   - Sandbox.mode(Repo, :manual)
                                   |
            ┌──────────────────────┴───────────────────────┐
            v                                               v
   async:false module                              async:true module (RepoCase)
   RepoCase.setup:                                 RepoCase.setup:
   Sandbox.checkout(Repo)                          Sandbox.checkout(Repo)
   Sandbox.mode(Repo,{:shared,self()})  <─ SHARED  (no shared mode)  <─ ISOLATED per-process
   seed_default_audience_for_repo!()               seed_default_audience_for_repo!()
            |                                               |
   may mutate global Fake / app-env  (SAFE serial)  must NOT touch global Fake/app-env (else unsafe)


   scripts/ci/test.sh  case "${TEST_SCOPE}" in
     all)                       -> mix test --warnings-as-errors --exclude install_integration   (line 529; dominant test lives HERE today)
     guarded_rollout_foundations) -> mix test ... verify_release_publish_test.exs                  (line 181; dominant test ALSO runs here)
     post_ga_band_closure/adopter) -> mix verify.phase82  (does NOT include the dominant test)    (lines 471-498 / verify.adopter.ex)
```

### Pattern 1: Default-excluded ExUnit tag with env opt-in (the `install_integration` template — D-03)

**What:** Tag the slow test; exclude it by default in `test_helper.exs`; opt back in via an env var (and `--include` on the named scope).
**When to use:** A high-value but slow/network-bound test that must stay reachable but off the hot default loop.

The exact existing precedent (mirror this verbatim shape):
```elixir
# Source: rulestead/test/test_helper.exs:1-8 [VERIFIED]
exunit_opts =
  if System.get_env("RULESTEAD_RUN_INSTALL_INTEGRATION") == "1" do
    []
  else
    [exclude: [install_integration: true]]
  end

ExUnit.start(exunit_opts)
```

D-03 implementation shape (planner picks final names; suggested `published_hex_smoke` / `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`):
```elixir
# test_helper.exs — extend the exclude list, do not replace the existing pattern
default_excludes =
  [install_integration: true]
  |> then(fn ex ->
    if System.get_env("RULESTEAD_RUN_INSTALL_INTEGRATION") == "1", do: ex -- [install_integration: true], else: ex
  end)
  |> then(fn ex ->
    if System.get_env("RULESTEAD_RUN_PUBLISHED_HEX_SMOKE") == "1", do: ex, else: [{:published_hex_smoke, true} | ex]
  end)

ExUnit.start(exclude: default_excludes)
```
*(The planner may prefer a flatter two-branch form matching the existing style; the load-bearing requirement is: excluded by default, included when the env is set.)*

And on the test:
```elixir
# verify_release_publish_test.exs:201 [VERIFIED: current line 199-217]
@tag :published_hex_smoke
test "admin consumer fixture compiles against published Hex packages" do
```

**Tag-matching mechanics** `[CITED: ex-unit.hexdocs.pm/ExUnit.Case.html]`: `@tag :published_hex_smoke` is equivalent to `@tag published_hex_smoke: true`. `ExUnit.start(exclude: [published_hex_smoke: true])` blocks it. "all tests are included by default, so unless they are excluded first, the `include` option has no effect" — so the exclude in `test_helper.exs` is mandatory for `--include published_hex_smoke:true` (or the env) to be the only way to run it. The `all` lane already passes `--exclude install_integration` on the CLI (`test.sh:529`); the env-conditional `ExUnit.start` exclude is the cleaner home for the new tag because the `guarded_rollout_foundations` lane runs `mix test <file>` *without* `--exclude install_integration` and would otherwise re-run the slow test.

### Pattern 2: Keeping the proof reachable on a named scope (D-03 + D-08)

**What:** After default-excluding the test, a named `scripts/ci/test.sh` scope must opt it in so the release-trust proof still runs.
**Verified current reachability of the dominant test:**
- `all` scope: `run_mix rulestead test --warnings-as-errors --exclude install_integration` `[VERIFIED: scripts/ci/test.sh:529]` — runs it today; will stop running it once tagged+excluded (intended).
- `guarded_rollout_foundations` scope: explicitly lists `test/rulestead/mix/tasks/verify_release_publish_test.exs` `[VERIFIED: scripts/ci/test.sh:181]` — runs it today; **will stop running the slow test case** once it is tag-excluded by default, because this `mix test <file>` invocation inherits the `test_helper.exs` exclude. The other (fast) tests in that file will still run.
- `post_ga_band_closure` / `adopter`: run `mix verify.phase82` `[VERIFIED: scripts/ci/test.sh:479; lib/mix/tasks/verify.phase82.ex:13-77; lib/mix/tasks/verify.adopter.ex:14-16]`, whose `@phase82_core_tests` list does **NOT** include `verify_release_publish_test.exs`. So **the published-Hex proof does not currently run on the post-GA/adopter lane at all.**

**Implication for the planner:** to honor "the proof must stay reachable on a named release/adopter scope," you must add an opt-in invocation somewhere. Recommended option (least churn, most on-theme): add to the `guarded_rollout_foundations` scope (or a small dedicated invocation) a line that runs the test with the env/include set, e.g.:
```bash
# Source pattern: scripts/ci/test.sh run_guarded_rollout_foundations (lines 173-186) [VERIFIED]
RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix rulestead test --include published_hex_smoke \
  test/rulestead/mix/tasks/verify_release_publish_test.exs
```
Confirm with the maintainer-confirmed intent (CONTEXT D-03) which named scope owns it: `post_ga_band_closure` and/or `adopter` are named in D-03 as the release/adopter home, while `guarded_rollout_foundations` is where the file already runs. The cleanest single answer is to make `guarded_rollout_foundations` opt the slow case back in (the file is already there) AND/OR add it to `verify.phase82`'s list so the adopter lane gains the proof. Either keeps it reachable; pick one and document it in the scope's microcopy.

### Pattern 3: The proven-safe async template (what a clean flip looks like)

**What:** The 3 cleanly-async RepoCase modules show the only shape that qualifies under D-01.
```elixir
# Source: rulestead/test/rulestead/analytics/query_test.exs:1-11 [VERIFIED]
use Rulestead.RepoCase, async: true
# pure Repo.insert/Repo.all on schemas; NO Application.put_env, NO Fake, NO telemetry, NO ETS
```
`webhooks/inbound_contract_test.exs` and `webhooks/outbound_contract_test.exs` are the same shape (pure Ecto changeset/contract assertions, no global state). `[VERIFIED]`

### Anti-Patterns to Avoid
- **Flipping a module that uses `@adapters [Rulestead.Fake, StoreEcto]`:** this pattern parametrizes contract tests over the global `Rulestead.Fake` singleton, so it always mutates shared state. Every such module is async-unsafe. `[VERIFIED across 12+ candidate files]`
- **Flipping a module that mutates `Application.put_env(:rulestead, :store|:admin_policy|:guardrails_provider|:preview_evidence_*|:admin_lifecycle|:redis|:policy_test_pid, ...)`:** app env is process-global; concurrent tests would clobber each other.
- **Replacing the `test_helper.exs` exclude pattern instead of extending it:** would drop the existing `install_integration` gate. Extend it.
- **Adding a blind retry around the live-hex `System.cmd`:** forbidden by D-04 and the milestone's no-hide-flakes guardrail. An explicit `System.cmd(..., into:..., timeout via Task)` documented timeout is the only allowed hardening.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Excluding a slow test by default | A custom `if System.get_env(...)` skip inside the test body | ExUnit `@tag` + `ExUnit.start(exclude:)` | Idiomatic, composes with `--include`/`--only`, already the repo's `install_integration` precedent `[CITED: ExUnit docs]` |
| Per-test DB isolation for async | Manual transaction/cleanup logic | `Ecto.Adapters.SQL.Sandbox` (already in `RepoCase`) | The sandbox already does correct per-process ownership on the async path `[VERIFIED: repo_case.ex:18-28]` |
| Test partitioning across workers | `mix test --partitions` + per-partition DBs | Nothing (REJECT per D-06) | Single serial network test dominates; global Fake + single sandbox forces per-partition DB isolation = fragility with no payoff |
| Network-flake masking | Blind retry wrapper | Default-exclude tag (removes from hot loop) + optional explicit timeout | D-04; flakes must not be hidden |

**Key insight:** the dominant cost is one serial, network-bound test, not a parallelism shortfall. The correct lever is *relocation behind an opt-in tag*, not concurrency — async would buy ~nothing here because nearly every serial module is serial for global-state reasons a scheduler cannot fix.

## Runtime State Inventory

> Phase 121 edits test files, `test_helper.exs`, and `scripts/ci/test.sh`. It is not a rename/migration, but it does change *where tests run*, so the relevant "state" is CI-lane reachability and the published version pin.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no datastore keys/IDs change. Verified: no rename, no schema/migration touch (out of scope per CONTEXT domain). | None |
| Live service config | The published-Hex test pins `@published_smoke_version "0.1.4"` `[VERIFIED: verify_release_publish_test.exs:199]`, while `mix.exs @version` is `0.1.7` `[VERIFIED: rulestead/mix.exs:4]`. This is intentional (smoke against a known-good published version), but the planner should note the pin is a maintained constant, not auto-derived. | Note only — do NOT auto-bump in Phase 121 (out of scope; not a locked decision) |
| OS-registered state | None. | None — verified no OS registrations involved |
| Secrets/env vars | New env var introduced for D-03 opt-in (e.g. `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE`). Not a secret. Must be documented alongside `RULESTEAD_RUN_INSTALL_INTEGRATION` so the rerun catalog stays accurate. | Add to `scripts/ci/test.sh` scope wiring + MAINTAINING rerun catalog framing (D-08 keeps microcopy honest) |
| Build artifacts | None — no package rename or egg-info-style artifact. | None |

**The canonical question (lane reachability):** After tagging the dominant test default-excluded, which lanes still run the published-Hex proof? Answer (verified): NONE automatically, unless the planner explicitly opts it back in on a named scope. This is the single most important wiring fact for D-03/D-08.

## Common Pitfalls

### Pitfall 1: Tagging the test but leaving `guarded_rollout_foundations` silently broken
**What goes wrong:** `guarded_rollout_foundations` runs `mix test <file>` (`test.sh:181`). Once the test is default-excluded, this lane silently stops running the slow case — the published-Hex proof quietly disappears from a release-relevant lane with no error.
**Why it happens:** `mix test <file>` inherits `test_helper.exs`'s `ExUnit.start(exclude:)`.
**How to avoid:** explicitly opt the named scope back in (`--include published_hex_smoke` or the env). Verify post-change that at least one named scope actually executes the test case (not just the file).
**Warning signs:** the proof's elapsed time drops to ~0 on the `guarded_rollout_foundations`/release lane after the change.

### Pitfall 2: Assuming `post_ga_band_closure`/`adopter` already runs the proof
**What goes wrong:** D-03 names `post_ga_band_closure`/`adopter` as the proof home, but `mix verify.phase82` (which those scopes run) does NOT list `verify_release_publish_test.exs` today. `[VERIFIED: verify.phase82.ex @phase82_core_tests]` Wiring the tag without adding the test to that lane leaves the proof unreachable there.
**How to avoid:** if the adopter lane is chosen as the home, add the test (with `--include`) to `verify.phase82` or to the `post_ga_band_closure` scope in `test.sh`.

### Pitfall 3: Pre-existing async modules that touch the global Fake
**What goes wrong:** `store/webhook_adapter_contract_test.exs` and `store/webhook_outbound_contract_test.exs` are ALREADY `async: true` yet their concrete modules call `Rulestead.Fake.reset()` `[VERIFIED: webhook_adapter_contract_test.exs:114; webhook_outbound_contract_test.exs:92]`. These are latent shared-state risks, but they are PRE-EXISTING and OUT OF SCOPE to change (D-05/No-Go: narrow changes, no demote). Do not "fix" them by flipping to serial — that would be a demote without evidence of an actual failure.
**How to avoid:** note them as observations only; do not touch.

### Pitfall 4: DDL-in-setup masquerading as a safe async candidate
**What goes wrong:** `webhooks/code_refs_plug_test.exs` is the *only* `async: false` RepoCase module with no Fake/app-env/telemetry markers, so a naive grep flags it as flippable. But its `setup` runs `Repo.query!("CREATE TABLE IF NOT EXISTS code_reference_scans ...")` `[VERIFIED: code_refs_plug_test.exs:188-197]` — DDL on a sandbox connection for a table not in migrations.
**Why it's subtle:** under the shared (serial) sandbox path the table is created once on the shared connection; under async each test owns its own connection/transaction, so the DDL would run per-test inside the per-test transaction (idempotent via `IF NOT EXISTS`, rolled back with the transaction). It *may* work, but it is exactly the "DB ownership / filesystem-adjacent / subtle" hazard the No-Go guardrails name, and D-01 explicitly lists "DB ownership" as a disqualifier.
**How to avoid:** treat this as a judgment call. The correctness-first default (D-02: "when in doubt, leave serial") argues for **not** flipping it. If the planner flips it, require an explicit task note documenting the DDL-under-async analysis and a verification run, and confirm the table truly belongs in migrations or stays test-local.

## Code Examples

### Verified safe-async shape (template for any flip)
```elixir
# Source: rulestead/test/rulestead/webhooks/inbound_contract_test.exs:1-7 [VERIFIED]
use Rulestead.RepoCase, async: true
# pure Ecto changeset assertions; no Application.put_env, no Fake, no telemetry, no ETS, no System.cmd, no File.*
```

### The dominant test (D-03 target)
```elixir
# Source: rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs:199-217 [VERIFIED]
@published_smoke_version "0.1.4"

test "admin consumer fixture compiles against published Hex packages" do
  tmp_dir = tmp_dir()
  on_exit(fn -> File.rm_rf!(tmp_dir) end)
  consumer = ReleasePublishFixture.setup_admin_consumer!(tmp_dir, @published_smoke_version)
  for check <- consumer.checks do
    {output, status} =
      System.cmd(check.cmd, check.args, cd: consumer.app_dir, stderr_to_stdout: true)  # live deps.get/compile against hex.pm
    assert status == 0, "..."
  end
end
```

### D-09 before/after measurement commands (locked, exact)
```bash
# Source: 119-CI-CD-AUDIT.md:153-154 [VERIFIED] — use verbatim for comparability
cd rulestead && mix test --warnings-as-errors --slowest 25
cd rulestead && mix test --warnings-as-errors --slowest-modules 25
# With the dominant test included (baseline) vs excluded (after D-03 default exclude):
cd rulestead && mix test --warnings-as-errors --slowest 25                              # default after change = excluded
cd rulestead && RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --warnings-as-errors --slowest 25  # include = baseline-comparable
```
Capture `real` wall-clock and the slowest-test/slowest-module lines for each. Baseline to beat: ~42s real, 587 tests + 8 properties, dominant ~27.95s, 18 schedulers. `[VERIFIED: 119-CI-CD-AUDIT.md:144-154]`

## Per-Module Async Audit (D-01/D-02)

**Candidate universe:** 32 modules `use Rulestead.RepoCase` `[VERIFIED: grep]`. Of these, 5 are already `async: true` (3 cleanly: `analytics/query_test`, `webhooks/inbound_contract_test`, `webhooks/outbound_contract_test`; 2 with latent pre-existing Fake risk: `store/webhook_adapter_contract_test`, `store/webhook_outbound_contract_test`). That leaves **23** `async: false` RepoCase candidates (the `~28` in the brief minus already-async; one, `code_refs_plug_test.exs`, has no explicit flag so defaults to serial). Verdict for each below.

**Greppable hazard methodology (turn into a per-module audit checklist):**
```bash
# Run from rulestead/ on each candidate file; ANY hit = leave serial.
grep -nE "Application\.(put_env|delete_env)" FILE      # app-env mutation (process-global) -> SERIAL
grep -nE "Rulestead\.Fake|Fake\.Control|@adapters .*Fake|Fake\.reset" FILE  # global named singleton -> SERIAL
grep -nE ":telemetry\.(attach|attach_many)" FILE       # telemetry handler attach -> SERIAL
grep -nE "capture_log|capture_io" FILE                 # log/IO capture -> SERIAL
grep -nE "System\.cmd" FILE                            # subprocess -> SERIAL
grep -nE "File\.(write|mkdir|rm|cp|touch)" FILE        # filesystem write -> SERIAL (read-only File.read! is OK)
grep -nE ":ets\.|Process\.register|start_supervised!\(\{?[A-Z]" FILE  # named/ETS singleton -> SERIAL
grep -nE "CREATE TABLE|ALTER TABLE|DROP TABLE|Repo\.query!\(.*CREATE" FILE  # DDL on sandbox conn -> SERIAL (judgment)
```

| Module (`async: false` candidate) | Disqualifying hazard found | Verdict |
|---|---|---|
| `guarded_rollout_test.exs` | `@adapters [Rulestead.Fake, StoreEcto]`; `Fake.Control.reset!` (:354) | KEEP SERIAL |
| `admin_audit_kill_switch_test.exs` | `Application.put_env(:store/:admin_policy)`; `Fake.Control.reset!/set_now!` | KEEP SERIAL |
| `scheduled_execution_conflict_test.exs` | `@adapters [...Fake...]`; `Fake.Control.reset!` | KEEP SERIAL |
| `oban_scheduled_execution_test.exs` | `Application.put_env(:store, CapturingStore)` | KEEP SERIAL |
| `governance_threat_model_test.exs` | `Application.put_env(:store/:admin_policy)` | KEEP SERIAL |
| `rollout_auto_advance_orchestration_contract_test.exs` | `Application.put_env(:guardrails_provider/:admin_policy)`; `@adapters [...Fake...]` | KEEP SERIAL |
| `scheduled_execution_facade_contract_test.exs` | `Application.put_env(:admin_policy)`; `Fake.Control.reset!` | KEEP SERIAL |
| `scheduled_execution_threat_model_test.exs` | `Application.put_env(:store)` | KEEP SERIAL |
| `store_ecto_admin_test.exs` | `Application.put_env(:store/:admin_lifecycle)` | KEEP SERIAL |
| `rollout_auto_advance_contract_test.exs` | `@adapters [...Fake...]`; `Fake.Control.reset!` | KEEP SERIAL |
| `scheduled_execution_audit_contract_test.exs` | `:telemetry.attach_many` (:273) | KEEP SERIAL |
| `integration/runtime_hot_path_test.exs` | `Application.put_env(:store)`; `:telemetry.attach`; `start_supervised!`; `@moduletag :telemetry` | KEEP SERIAL |
| `redis/integration_test.exs` | `Application.put_env(:store/:redis)`; `start_supervised!(RedisClient/Publisher)` | KEEP SERIAL |
| `targeting/preview_evidence_contract_test.exs` | `Application.put_env(:preview_evidence_*)`; `@adapters [...Fake...]`; `Fake.Control.*` | KEEP SERIAL |
| `governance/preview_evidence_governance_contract_test.exs` | `Application.put_env(:preview_evidence_resolver)`; `@adapters [...Fake...]` | KEEP SERIAL |
| `governance/audience_mutation_change_request_contract_test.exs` | `Application.put_env(:admin_lifecycle)`; `@adapters [...Fake...]`; `Fake.Control.snapshot!/restore!` | KEEP SERIAL |
| `webhooks/inbound_threat_model_test.exs` | `Rulestead.Fake.reset()`; `:telemetry.attach` | KEEP SERIAL |
| `webhooks/outbound_delivery_test.exs` | `@moduletag capture_log: true` | KEEP SERIAL |
| `webhooks/inbound_governance_test.exs` | `Rulestead.Fake.reset()` | KEEP SERIAL |
| `store/webhook_outbound_adapter_contract_test.exs` | `Application.put_env(:admin_lifecycle)`; `@adapters [...Fake...]`; `Fake.Control.reset!` | KEEP SERIAL |
| `store/audience_impact_contract_test.exs` | `Application.put_env(:store/:admin_policy/:policy_test_pid/:preview_evidence_*)`; `@adapters [...Fake...]`; `Fake.Control.*` | KEEP SERIAL |
| `store/governance_adapter_contract_test.exs` | `Application.put_env(:admin_lifecycle)`; `@adapters [...Fake...]`; `Fake.Control.reset!` | KEEP SERIAL |
| `store/scheduled_execution_adapter_contract_test.exs` | `Application.put_env(:store)`; `@adapters [...Fake...]`; `Fake.Control.snapshot!/restore!` | KEEP SERIAL |
| `webhooks/code_refs_plug_test.exs` (no flag = serial) | No Fake/app-env/telemetry/capture — BUT `Repo.query!("CREATE TABLE IF NOT EXISTS ...")` DDL in `setup` (:188-197) | KEEP SERIAL (recommended) — or FLIP only with explicit DDL-under-async justification + verification run |

**Net recommended flips: 0** (correctness-first). **Maximum defensible flips: 1** (`code_refs_plug_test.exs`, only if the planner accepts and documents the DDL-in-setup judgment). This is exactly D-02's "0–3, plausibly 0" — record it as a success, not a shortfall.

**RepoCase async-path safety confirmation:** `repo_case.ex:18-28` `[VERIFIED]` checks out the sandbox and, **only on the non-async path**, sets `{:shared, self()}` mode. On the async path it relies on per-process connection ownership — the correct pattern. `seed_default_audience_for_repo!` `[VERIFIED: store_fixtures.ex:64-82]` does a `get_by`/`insert!` inside the per-test transaction (no Fake, no app-env) — async-safe. So RepoCase itself is NOT the blocker; the per-module global-state hazards are.

## Partitioning Rejection Evidence (D-06)

REJECT `mix test --partitions`. Verified evidence:
- **Single dominant serial test:** the ~27.95s cost is one network-bound `System.cmd` test `[VERIFIED: verify_release_publish_test.exs:201-217; 119-CI-CD-AUDIT.md:153]`. Partitions distribute *modules*, not work within a module — they cannot subdivide it. Once D-03 relocates it, the next-slowest module is ~1.6s `[VERIFIED: 119-CI-CD-AUDIT.md:154]`, leaving no partitionable wall-clock.
- **Suite is overwhelmingly serial by design:** 79 modules `async: false` `[VERIFIED: grep]`, driven by the single global `Rulestead.Fake` named GenServer + process-global `Application.put_env(:rulestead, :store/...)` `[VERIFIED: test_helper.exs:12-15; pervasive @adapters/put_env pattern]`. Each partition would still serialize its async:false modules.
- **Single Postgres sandbox + single named Fake:** partitions would require per-partition DB isolation (`MIX_TEST_PARTITION`-suffixed DBs) AND per-partition Fake singletons — fragility the No-Go guardrails caution against `[VERIFIED: 119-CI-CD-AUDIT.md:298]`.
- **No partition config exists:** `mix.exs` has no partition setup `[VERIFIED: rulestead/mix.exs:8-40]`; 18 schedulers already absorb the tiny async set `[VERIFIED: 119-CI-CD-AUDIT.md:144-147]`.
- Mapped to FUT-01 (deferred) `[VERIFIED: REQUIREMENTS.md:36]`: reversible later if the suite grows materially.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Skip slow tests with in-body `System.get_env` guards | ExUnit `@tag` + `ExUnit.start(exclude:)` + `--include` | Long-standing ExUnit idiom | Composes with CLI; the repo already uses it (`install_integration`) `[CITED: ExUnit docs]` |
| Hand-rolled DB cleanup per test | `Ecto.Adapters.SQL.Sandbox` ownership/async mode | ecto_sql modern | Already adopted in `RepoCase` `[VERIFIED]` |

**Deprecated/outdated:** none relevant — the repo already uses current idioms. No training-data version drift affects this phase (no new deps).

## Project Constraints (from CLAUDE.md)

- Preserve the sibling-package layout (`rulestead/` core + `rulestead_admin/`); do not collapse. `[VERIFIED: CLAUDE.md]`
- `.planning/` is the active source of truth; `prompts/` is the pattern/policy reference set.
- Prefer narrow, auditable changes — directly reinforces D-01's allowlist (no broad async sweep) and D-05 (no module splits).
- Use scripts-first CI surfaces where workflow logic gets non-trivial — D-08 keeps `scripts/ci/test.sh` the contributor/maintainer abstraction; the D-03 opt-in must live in the scope dispatcher, not in workflow YAML.
- Keep root docs honest about the current phase.
- Post-GA band (v1.1–v1.9) feature-complete; v1.18 is CI/CD reliability — no product runtime API/schema/UI/brand changes (matches CONTEXT domain exclusions).

## Open Questions (RESOLVED)

1. **Which named scope is the canonical home for the relocated published-Hex proof?** — **RESOLVED:** `guarded_rollout_foundations` (opt-in via `--include`, file already present, lowest churn). Locked in CONTEXT D-03 and Plan 121-01 Task 2.
   - What we know: D-03 names `post_ga_band_closure` and/or `adopter`; the file currently runs in `all` and `guarded_rollout_foundations`; `verify.phase82` (post_ga/adopter) does NOT include it today.
   - What's unclear: whether to (a) opt it back in on `guarded_rollout_foundations` (file already there), (b) add it to `verify.phase82`'s list so adopter gains it, or (c) both.
   - Recommendation: at minimum opt-in on `guarded_rollout_foundations` (lowest churn, file already present) and add a clear microcopy line; consider also adding to `verify.phase82` if the maintainer wants the adopter lane to own the release-trust proof. Confirm with maintainer at discuss/plan time — this is the one wiring choice CONTEXT left to planner discretion.

2. **Flip `code_refs_plug_test.exs` (1) or 0 modules?** — **RESOLVED:** 0 flips; `code_refs_plug_test.exs` stays serial (DDL-in-setup = DB-ownership hazard, correctness-first D-02). Locked in CONTEXT D-02 and Plan 121-02.
   - What we know: it is the only candidate with no Fake/app-env/telemetry hazard, but it runs `CREATE TABLE IF NOT EXISTS` DDL in `setup`.
   - What's unclear: whether the DDL is safe per-transaction under async in this repo's exact sandbox config (likely idempotent-safe, but D-01 lists "DB ownership" as a disqualifier).
   - Recommendation: default to 0 (correctness-first, D-02). If flipping, require a documented analysis + a verification run under `async: true` and confirm the table's provenance (test-local vs missing migration).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | running `mix test`, measurement | ✓ (repo builds on it) | matrix 1.17.3/26.2.5 + 1.19.2/28.4.3 `[VERIFIED: ci.yml via audit]` | — |
| PostgreSQL 15 | Ecto sandbox tests | ✓ in CI service; local needed for D-09 measurement | 15 `[VERIFIED: 119-CI-CD-AUDIT.md:67]` | — (required for measurement) |
| Network to hex.pm | the dominant published-Hex test only | conditional | — | The whole point of D-03 is to remove this from the default loop |
| 18 schedulers | async benefit ceiling | ✓ | 18 `[VERIFIED: 119-CI-CD-AUDIT.md:144-147]` | — |

**Missing dependencies with no fallback:** none for the code changes. **Note:** D-09 before/after measurement requires a local Postgres + (for the "with dominant test" run) network to hex.pm.

## Validation Architecture

> nyquist_validation status not separately read; included since absence = enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir `~> 1.17`), Ecto SQL Sandbox `[VERIFIED: mix.exs]` |
| Config file | `rulestead/test/test_helper.exs` `[VERIFIED]` |
| Quick run command | `cd rulestead && mix test` |
| Full suite command | `cd rulestead && mix test --warnings-as-errors` (default `all` scope: `bash scripts/ci/test.sh`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CIDX-06 | Default suite excludes the dominant slow test | smoke | `cd rulestead && mix test --slowest 5` (confirm dominant test absent) | ✅ existing |
| CIDX-06 | Published-Hex proof still runs on a named scope | integration | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --include published_hex_smoke test/rulestead/mix/tasks/verify_release_publish_test.exs` | ✅ existing |
| CIDX-06 | Any flipped module still green under async | unit | `cd rulestead && mix test <flipped_file> --warnings-as-errors` (run twice for flake check) | ✅ existing |
| CIDX-06 | `release_gate` aggregate stays green | gate | per Phase 120 fan-in; verify in CI | ✅ existing |

### Sampling Rate
- **Per task commit:** `cd rulestead && mix test --warnings-as-errors` (default lane, fast after D-03).
- **Per wave merge:** the affected named scope, e.g. `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh`.
- **Phase gate:** full `bash scripts/ci/local.sh` green + the published-Hex proof verified reachable on its named scope before `/gsd:verify-work`.

### Wave 0 Gaps
- None — existing ExUnit infrastructure covers all phase requirements. No new test files needed; the phase modifies tagging/wiring of existing tests. (If the planner flips `code_refs_plug_test.exs`, add a verification step that runs it under async twice — not a new file.)

## Security Domain

> security_enforcement status not separately confirmed; this phase is test-infrastructure only with no new attack surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | — (no auth code touched) |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | — (no input-handling code changed) |
| V6 Cryptography | no | — |
| V14 Configuration / supply chain | yes (indirect) | Preserve release-trust: the published-Hex proof must stay reachable so supply-chain installability is still proven (CIDX-09 boundary). The D-04 no-blind-retry rule prevents masking a real network/supply-chain signal. `[VERIFIED: 119-CI-CD-AUDIT.md:259-272]` |

### Known Threat Patterns for this change
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silently dropping the published-Hex installability proof | Repudiation / supply-chain blind spot | Keep proof on a named scope with microcopy; verify post-change it still executes (Pitfalls 1–2) |
| Hiding a real network/dependency flake behind retry | Tampering with signal | D-04: no blind retry; explicit documented timeout only |

## Sources

### Primary (HIGH confidence)
- `rulestead/test/test_helper.exs:1-24` — exclude pattern, global app-env/Fake boot, sandbox manual mode
- `rulestead/test/support/repo_case.ex:18-28` — async sandbox path (no `{:shared, self()}` on async)
- `rulestead/test/support/store_contract_case.ex:21-41` — app-env mutation serial reference
- `rulestead/test/support/store_fixtures.ex:64-82` — `seed_default_audience_for_repo!` (async-safe)
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs:199-217` — dominant test, `System.cmd`, version pin
- `scripts/ci/test.sh:181, 471-498, 523-575` — scope dispatch; where the dominant test runs
- `rulestead/lib/mix/tasks/verify.phase82.ex` + `verify.adopter.ex` — post-GA/adopter lane contents (no published-Hex test)
- `rulestead/mix.exs` — deps, preferred_envs, no partition config
- All 23 candidate test files + 5 already-async RepoCase modules — per-module hazard verdicts (grep + read)
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md:144-205, 284-324` — diagnostics, classification, No-Go, handoff
- `.planning/phases/121-.../121-CONTEXT.md` — locked decisions
- `.planning/REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `CLAUDE.md` — scope/sequence/constraints

### Secondary (MEDIUM confidence)
- `.planning/phases/120-.../120-CONTEXT.md` — Phase 120 boundary (async deferred to 121; release_gate fan-in stabilized)

### Tertiary (CITED external)
- `https://ex-unit.hexdocs.pm/ExUnit.Case.html` — `@tag`/`@moduletag` semantics, `exclude`/`include` precedence ("tests are included by default; include has no effect unless excluded first"), `@tag :key` == `key: true`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `code_refs_plug_test.exs`'s `CREATE TABLE IF NOT EXISTS` DDL would behave idempotently per-transaction under `async: true` | Per-Module Audit / Pitfall 4 | If wrong, a flip causes intermittent failures. Mitigated by the recommended verdict: KEEP SERIAL. |
| A2 | Suggested env/tag names (`RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` / `published_hex_smoke`) are acceptable | Pattern 1 | None — CONTEXT explicitly grants planner discretion over the name. |
| A3 | The network/Postgres availability assumptions for D-09 measurement hold on the maintainer's machine | Environment Availability | Measurement (with-dominant-test run) would fail offline; the exclude path still measurable offline. |

**Note:** Tags A1–A3 are the only `[ASSUMED]` items. Every async verdict and wiring fact is `[VERIFIED]` by reading the actual file/line cited.

## Metadata

**Confidence breakdown:**
- Async per-module verdicts: HIGH — every candidate read and grepped; hazards cited by line.
- D-03 tag mechanism + scope wiring: HIGH — `test_helper.exs`, `test.sh`, and `verify.phase82` all read directly; tag semantics CITED.
- Partitioning rejection: HIGH — every premise verified against repo + audit.
- DDL-under-async safety of the one borderline module: MEDIUM (A1) — recommended verdict avoids the risk.

**Research date:** 2026-06-16
**Valid until:** ~2026-07-16 (stable — internal test infra, no fast-moving external deps; re-verify only if test files change before planning)
