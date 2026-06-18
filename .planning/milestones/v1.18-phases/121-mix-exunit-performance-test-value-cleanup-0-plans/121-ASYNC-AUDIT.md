# 121-ASYNC-AUDIT.md — Evidence-Gated Async Audit

**Phase:** 121 — Mix/ExUnit Performance + Test Value Cleanup
**Plan:** 121-02
**Date:** 2026-06-16
**Governing decisions:** D-01, D-02 (121-CONTEXT.md); RESEARCH.md Per-Module Async Audit (lines 277-323)

---

## 1. Candidate Universe

**Method:** `grep -rn "use Rulestead.RepoCase" test/ | grep -v "async: true"` run from `rulestead/`.

**Already-async RepoCase modules (5, out of scope for this audit):**
- `analytics/query_test.exs` — clean async: true (pure Repo.insert/all, no hazards)
- `webhooks/inbound_contract_test.exs` — clean async: true
- `webhooks/outbound_contract_test.exs` — clean async: true
- `store/webhook_adapter_contract_test.exs` — async: true (latent Fake.reset risk, see §5)
- `store/webhook_outbound_contract_test.exs` — async: true (latent Fake.reset risk, see §5)

**Async-false (or no-flag = serial) RepoCase candidates: 23 modules**

These are the subjects of this audit. (The count reconciles against RESEARCH.md:279 which states "23 async: false RepoCase candidates" from the full 27 listed `use Rulestead.RepoCase` grep; 5 already async = 27 − 4 in the original grep output minus already-async = 23 serial. The grep output above lists 27 matches; minus the 4 already-async inner modules = 23 serial candidates. See note: webhook_adapter_contract_test.exs has both outer `use ExUnit.Case, async: true` and an inner `use Rulestead.RepoCase, async: true` at line 99.)

---

## 2. Greppable Hazard Gate

The following commands were run from `rulestead/` on each candidate. **Any hit = KEEP SERIAL.**

```bash
grep -nE "Application\.(put_env|delete_env)" FILE          # process-global app env -> SERIAL
grep -nE "Rulestead\.Fake|Fake\.Control|@adapters .*Fake|Fake\.reset" FILE  # global named singleton -> SERIAL
grep -nE ":telemetry\.(attach|attach_many)" FILE           # telemetry handler attach -> SERIAL
grep -nE "capture_log|capture_io" FILE                     # log/IO capture -> SERIAL
grep -nE "System\.cmd" FILE                                # subprocess -> SERIAL
grep -nE "File\.(write|mkdir|rm|cp|touch)" FILE            # filesystem write -> SERIAL
grep -nE ":ets\.|Process\.register|start_supervised!\(\{?[A-Z]" FILE  # named/ETS singleton -> SERIAL
grep -nE "CREATE TABLE|ALTER TABLE|DROP TABLE|Repo\.query!\(.*CREATE" FILE  # DDL -> SERIAL (judgment)
```

---

## 3. Per-Module Verdict Table

| Module (async: false candidate) | Disqualifying hazard with file:line | Verdict |
|---|---|---|
| `guarded_rollout_test.exs` | `@adapters [Rulestead.Fake, StoreEcto]` line 9; `Rulestead.Fake.Control.reset!()` line 354 | **KEEP SERIAL** |
| `admin_audit_kill_switch_test.exs` | `Application.put_env(:rulestead, :store, Rulestead.Fake)` line 11; `Application.put_env(:rulestead, :admin_policy, ...)` line 12; `Rulestead.Fake.Control.reset!()` line 13 | **KEEP SERIAL** |
| `scheduled_execution_conflict_test.exs` | `@adapters [Rulestead.Fake, StoreEcto]` line 9; `Rulestead.Fake.Control.reset!()` line 170 | **KEEP SERIAL** |
| `oban_scheduled_execution_test.exs` | `Application.delete_env(:rulestead, :store)` line 106; `Application.put_env(:rulestead, :store, CapturingStore)` line 107 | **KEEP SERIAL** |
| `governance_threat_model_test.exs` | `Application.put_env(:rulestead, :store, StoreEcto)` line 12; `Application.put_env(:rulestead, :admin_policy, ...)` line 13 | **KEEP SERIAL** |
| `rollout_auto_advance_orchestration_contract_test.exs` | `Application.put_env(:rulestead, :guardrails_provider, ...)` line 22; `Application.delete_env(:rulestead, :admin_policy)` line 23; `@adapters [Rulestead.Fake, StoreEcto]` line 11; `Rulestead.Fake.Control.reset!()` line 194 | **KEEP SERIAL** |
| `scheduled_execution_facade_contract_test.exs` | `Application.put_env(:rulestead, :admin_policy, ...)` line 19; `Application.delete_env(:rulestead, :admin_policy)` line 23; `Rulestead.Fake.Control.reset!()` line 258 | **KEEP SERIAL** |
| `scheduled_execution_threat_model_test.exs` | `Application.put_env(:rulestead, :store, StoreEcto)` line 20; `Application.delete_env(:rulestead, :store)` line 27 | **KEEP SERIAL** |
| `store_ecto_admin_test.exs` | `Application.put_env(:rulestead, :store, StoreEcto)` line 13; `Application.put_env(:rulestead, :admin_lifecycle, ...)` line 15 | **KEEP SERIAL** |
| `rollout_auto_advance_contract_test.exs` | `@adapters [Rulestead.Fake, StoreEcto]` line 9; `Rulestead.Fake.Control.reset!()` line 442 | **KEEP SERIAL** |
| `scheduled_execution_audit_contract_test.exs` | `:telemetry.attach_many(...)` line 273 | **KEEP SERIAL** |
| `integration/runtime_hot_path_test.exs` | `Application.put_env(:rulestead, :store, Rulestead.Store.Ecto)` line 50; `Application.delete_env(:rulestead, :store)` line 56; `:telemetry.attach(...)` line 106 | **KEEP SERIAL** |
| `redis/integration_test.exs` | `Application.put_env(:rulestead, :store, ...)` line 32; `Application.put_env(:rulestead, :redis, ...)` line 34; `start_supervised!({RedisClient, ...})` line 29; `start_supervised!(Publisher)` line 30 | **KEEP SERIAL** |
| `targeting/preview_evidence_contract_test.exs` | `Application.put_env(:rulestead, :preview_evidence_resolver, ...)` line 30; `Application.delete_env(:rulestead, :preview_evidence_resolver)` line 38; `@adapters [Rulestead.Fake, StoreEcto]` line 23; `Rulestead.Fake` reference line 225 | **KEEP SERIAL** |
| `governance/preview_evidence_governance_contract_test.exs` | `Application.put_env(:rulestead, :preview_evidence_resolver, ...)` line 18; `Application.delete_env(:rulestead, :preview_evidence_resolver)` line 26; `@adapters [Rulestead.Fake, StoreEcto]` line 13; `Rulestead.Fake.PreviewEvidenceResolver` line 21 | **KEEP SERIAL** |
| `governance/audience_mutation_change_request_contract_test.exs` | `Application.put_env(:rulestead, :admin_lifecycle, ...)` line 17; `@adapters [Rulestead.Fake, StoreEcto]` line 14; `Rulestead.Fake.Control.snapshot!/restore!` (adapter loop) | **KEEP SERIAL** |
| `webhooks/inbound_threat_model_test.exs` | `Rulestead.Fake.reset()` line 6; `:telemetry.attach(...)` line 18 | **KEEP SERIAL** |
| `webhooks/outbound_delivery_test.exs` | `@moduletag capture_log: true` line 9 | **KEEP SERIAL** |
| `webhooks/inbound_governance_test.exs` | `Rulestead.Fake.reset()` line 6 | **KEEP SERIAL** |
| `store/webhook_outbound_adapter_contract_test.exs` | `Application.put_env(:rulestead, :admin_lifecycle, ...)` line 13; `@adapters [Rulestead.Fake, StoreEcto]` line 10; `Rulestead.Fake.Control.reset!()` line 108 | **KEEP SERIAL** |
| `store/audience_impact_contract_test.exs` | `Application.put_env(:rulestead, :store, ...)` line 22; `Application.put_env(:rulestead, :admin_policy, ...)` line 23; `@adapters [Rulestead.Fake, StoreEcto]` line 15; `Rulestead.Fake.PreviewEvidenceResolver` line 151 | **KEEP SERIAL** |
| `store/governance_adapter_contract_test.exs` | `Application.put_env(:rulestead, :admin_lifecycle, ...)` line 13; `@adapters [Rulestead.Fake, StoreEcto]` line 10; `Rulestead.Fake.Control.reset!()` line 226 | **KEEP SERIAL** |
| `store/scheduled_execution_adapter_contract_test.exs` | `Application.put_env(:rulestead, :store, adapter)` line 19; `Application.delete_env(:rulestead, :store)` line 25; `@adapters [Rulestead.Fake, StoreEcto]` line 10 | **KEEP SERIAL** |
| `webhooks/code_refs_plug_test.exs` (no flag = serial) | No Fake/app-env/telemetry/capture/ETS/System.cmd hazard — BUT `Repo.query!("CREATE TABLE IF NOT EXISTS code_reference_scans ...")` DDL in `defp ensure_scan_receipts_schema!` called from setup, line 190 | **KEEP SERIAL** (recommended) — see §4 |

---

## 4. Special Case: `webhooks/code_refs_plug_test.exs`

This is the sole candidate that clears all hazard gates except the DDL-in-setup pattern:

- **No** `Application.put_env/delete_env`
- **No** `Rulestead.Fake`, `Fake.Control`, `@adapters Fake`, or `Fake.reset`
- **No** `:telemetry.attach/attach_many`
- **No** `capture_log` or `capture_io`
- **No** `System.cmd`
- **No** `File.write/mkdir/rm/cp/touch`
- **No** `:ets.`, `Process.register`, or `start_supervised!({Module, ...})` pattern

**DDL hazard (line 190):**
```elixir
defp ensure_scan_receipts_schema! do
  Repo.query!("""
  CREATE TABLE IF NOT EXISTS code_reference_scans (
    id uuid PRIMARY KEY,
    received_at timestamp(6) with time zone NOT NULL,
    reference_count integer NOT NULL DEFAULT 0,
    inserted_at timestamp(6) with time zone NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL
  )
  """)
end
```

**Analysis:**
- The `CREATE TABLE IF NOT EXISTS` DDL runs outside the per-test Ecto Sandbox transaction; DDL statements in PostgreSQL cause an implicit transaction commit.
- This means the table creation persists beyond the test's transaction rollback boundary, violating the sandbox's per-test isolation contract.
- Under `async: true` (per-process connection ownership), multiple concurrent tests attempting DDL on the same table name creates a race between setup calls.
- Additionally, the table is NOT part of the standard migration set — it is created ad-hoc in setup, making it a test-local DDL artifact without a schema-level owner.
- Per D-01 (CONTEXT.md): "DB ownership hazard" is an explicit disqualifier.
- Per D-02 (CONTEXT.md): "when in doubt, leave serial" is the correctness-first default.

**Verdict: KEEP SERIAL** — the DDL-in-setup pattern is a genuine DB-ownership hazard that D-01 names as disqualifying. The `IF NOT EXISTS` idiom provides idempotency for re-runs but does not resolve the concurrent-DDL or transaction-isolation issue under async. No flip is made.

---

## 5. Do-Not-Flip Trio Confirmation

The following modules are explicitly preserved as serial and NOT flipped. Their hazards are cited below for completeness:

| Module | Primary hazard | Status |
|---|---|---|
| `oban/stale_flag_worker_test.exs` | `Cache.start_link([])` line 11 starts the named `Rulestead.Telemetry.Cache` GenServer (a named singleton); `Cache.clear()` line 12 operates on the shared ETS table backing it | **NOT FLIPPED — KEEP SERIAL** |
| `analytics/batcher_test.exs` | `:ets.delete(:rulestead_analytics_batcher)` line 17 deletes the global Analytics.Batcher ETS table; `start_supervised!({Batcher, ...})` line 22 starts the supervised global batcher | **NOT FLIPPED — KEEP SERIAL** |
| `webhooks/inbound_http_test.exs` | Relies on shared sandbox mode for DB visibility across `IngressPlug` → `list_webhook_records` (cross-process transaction, no explicit hazard grep hits but correctness depends on the serial `{:shared, self()}` connection mode per CONTEXT D-02 conservatism; RESEARCH.md correctly-serial reference at line 73) | **NOT FLIPPED — KEEP SERIAL** |

All three remain `async: false`. No source file change was made to any of them.

---

## 6. Latent Risk Observations (Out of Scope — Note Only)

Two modules that are **already async: true** call `Rulestead.Fake.reset()` in their setup blocks. These are pre-existing issues, noted per RESEARCH.md Pitfall 3 (lines 231-238), and are explicitly out of scope for this plan to change:

- `store/webhook_adapter_contract_test.exs` — outer module is `use ExUnit.Case, async: true` (line 5); line 114: `Rulestead.Fake.reset()` in setup. (Inner `use Rulestead.RepoCase, async: true` at line 99 is separate.)
- `store/webhook_outbound_contract_test.exs` — `use ExUnit.Case, async: true`; line 92: `Rulestead.Fake.reset()` in setup.

These call `reset()` on the global `Rulestead.Fake` singleton from an async test context, which is a latent concurrency hazard if async tests run concurrently with serial tests that also use the Fake. Demoting these is explicitly out of scope for Phase 121 (RESEARCH.md Pitfall 3: "do not demote already-async modules"). They are recorded here for future awareness only.

---

## 7. Net Flip Count and Success Framing

**Net-new async modules: 0**

This is the recommended outcome per D-02 (CONTEXT.md): "Expect a SMALL net-new-async count (plausibly 0–3 modules), and treat that as a success, not a shortfall."

The audit confirms: every one of the 23 `async: false` RepoCase candidates carries at least one disqualifying hazard (global `Rulestead.Fake` singleton, process-global `Application.put_env`, telemetry handler attach, `capture_log`, named ETS/process singleton, or DDL-in-setup). The evidence-gated allowlist (D-01) produced an empty allow set. This is a correct, expected outcome — the suite is overwhelmingly serial by design due to the single global `Rulestead.Fake` named GenServer.

**0 flips is a success per D-02, not a shortfall.**

---

## Decision

**Zero source files were modified.**

The audit is complete. No module was flipped to `async: true`. The correctness-first posture (D-02) is honored: async is marked true only where proven free of global-state/DB-ownership/ports/filesystem/logger/telemetry/app-env hazards. No such module was found among the 23 candidates.

**This satisfies success criterion #1:** "Async marked true only where proven free of global state / DB ownership / ports / filesystem / logger / telemetry / app-env mutation."

**The do-not-flip trio (oban/stale_flag_worker_test.exs, analytics/batcher_test.exs, webhooks/inbound_http_test.exs) is preserved.**

**The borderline case (webhooks/code_refs_plug_test.exs) is decided: KEEP SERIAL** on DDL-in-setup grounds per D-01/D-02.

---

## RepoCase Async-Path Safety Confirmation

`repo_case.ex:18-28` (VERIFIED) correctly isolates the async path:

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

The `{:shared, self()}` shared ownership mode is set ONLY on the non-async path. The async path uses per-process connection ownership — the correct pattern for concurrent sandbox usage. **RepoCase itself is NOT the blocker; per-module global-state hazards are the blocker for every candidate.**
