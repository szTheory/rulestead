# Rulestead Security, Privacy & Threat Model

> **Purpose:** Lay out the security posture, privacy controls, authz seams, and STRIDE threat analysis for rulestead. The threat model for a feature-flag lib is unusual — it's a small surface with high blast radius: a compromised flag can ship buggy or malicious code to every user instantly. Getting this right is non-negotiable.
>
> **Read alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.7, `rulestead-telemetry-observability-and-audit.md` §6 + §11, `rulestead-host-app-integration-seam.md` (`Rulestead.Admin.Policy`).

---

## 1. Principles

1. **Default deny in admin; default evaluate in runtime.** Admin mutations require explicit authorization; runtime evaluation is zero-friction (already in the hot path).
2. **No hardcoded auth opinions.** Host owns identity + sessions. We consume, we don't issue.
3. **Least-privilege data surfaces.** Evaluation context is explicit + minimal. No "just pass `conn`" anti-patterns.
4. **Environment-sensitive authz.** Actions allowed in `staging` are not automatically allowed in `prod`.
5. **Redact at the boundary.** PII never reaches logs, audit, or debug surfaces without going through the redactor.
6. **Fail closed on security-critical paths.** Admin policy errors deny. Signature verification failures reject. Malformed webhooks reject.
7. **Immutable audit is a security control.** Append-only by app + DB trigger; any bypass attempt is itself a P0.
8. **No secrets in flag values.** We explicitly document this and provide guardrails; secrets belong in your vault, not in a flag's JSON payload.
9. **Supply-chain hygiene.** SHA-pinned actions, signed releases, SBOM, dependabot automerge (patch-only).
10. **Threat model lives in repo.** `docs/threat-model.md` versioned alongside code. STRIDE pass updated per minor release.

---

## 2. Trust boundaries

```
┌──────────────────────────────────────────────────────────────┐
│ External: end users, untrusted input                         │
└───┬──────────────────────────────────────────────────────────┘
    │   ↓ HTTPS (host-owned TLS)
┌───▼──────────────────────────────────────────────────────────┐
│ Host app (BEAM node)                                         │
│  Trust:  host's authenticated session                        │
│  Owns:   endpoint auth, sessions, CSRF                       │
│  Passes: context to rulestead via explicit struct            │
└───┬──────────────────────────────────────────────────────────┘
    │   Rulestead.Context (explicit, typed)
┌───▼──────────────────────────────────────────────────────────┐
│ Rulestead runtime (evaluator)                                │
│  Trust:  context authenticity (host has already verified)    │
│  Owns:   evaluation determinism, redaction, telemetry        │
└───┬──────────────────────────────────────────────────────────┘
    │   Store protocol
┌───▼──────────────────────────────────────────────────────────┐
│ Rulestead store (Postgres adapter)                           │
│  Trust:  DB credentials (host-managed)                       │
│  Owns:   atomic Multi + audit writes, partial-unique indexes │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Admin UI (mounted LiveView)                                  │
│  Trust:  host's authenticated+authorized session             │
│  Owns:   rendering; mutations delegate through Context +     │
│          Rulestead.Admin.Policy behaviour                    │
└──────────────────────────────────────────────────────────────┘
```

Contracts across boundaries:
- Host → Rulestead runtime: `%Rulestead.Context{}` (well-typed, carries identity + env + trace).
- Host → Rulestead admin: auth/authz done by host + policy callback.
- Rulestead → Store: `Rulestead.Store` behaviour; adapters vetted (Postgres is the ref impl).
- Rulestead → Hooks: host-provided; treated as potentially-faulty but trusted-enough to call.

---

## 3. Identity + authorization

### 3.1 No opinion on identity

Rulestead does not issue sessions, manage passwords, or verify tokens. The host has already authenticated the request. `%Rulestead.Context{actor: %Rulestead.Actor{...}}` is produced by a host-provided `Rulestead.ActorResolver` callback.

### 3.2 Admin policy

Every admin mutation and query goes through `Rulestead.Admin.Policy`:

```elixir
defmodule Rulestead.Admin.Policy do
  @type action ::
    :view_flag | :create_flag | :update_flag | :archive_flag |
    :view_ruleset | :draft_ruleset | :publish_ruleset | :revert_ruleset |
    :view_rollout | :advance_rollout | :hold_rollout | :rollback_rollout |
    :engage_killswitch | :release_killswitch |
    :view_audit | :export_audit |
    :submit_change_request | :approve_change_request | :reject_change_request |
    :manage_settings

  @callback authorize(action(), %Rulestead.Context{}, resource :: map() | nil) ::
    :ok | {:error, :forbidden | atom()}
end
```

Implementation lives in host; we provide two reference impls:

- `Rulestead.Admin.Policy.AllowAll` — dev-only, loud warning at boot if used outside `:dev`.
- `Rulestead.Admin.Policy.RoleBased` — role list + per-env overrides (e.g., `:publisher` can publish in `staging` but needs `:prod_publisher` in `prod`).

Host-declared policy example:

```elixir
defmodule MyApp.RulesteadAdminPolicy do
  @behaviour Rulestead.Admin.Policy

  def authorize(:engage_killswitch, %Rulestead.Context{env: :prod, actor: %{roles: roles}}, _res) do
    if :incident_commander in roles, do: :ok, else: {:error, :forbidden}
  end

  def authorize(action, %Rulestead.Context{env: :prod, actor: %{roles: roles}}, _res)
      when action in [:publish_ruleset, :advance_rollout, :rollback_rollout] do
    if :prod_publisher in roles, do: :ok, else: {:error, :forbidden}
  end

  def authorize(_action, %Rulestead.Context{env: env}, _res) when env != :prod, do: :ok
  def authorize(_action, _ctx, _res), do: {:error, :forbidden}
end
```

### 3.3 Change-request workflow (v0.4+)

For high-impact actions in prod, policy can require change-request approval rather than direct mutation:

- Operator A drafts + submits a CR (includes simulate result).
- Operator B reviews + approves.
- System merges (executes the mutation within the approving operator's scope).
- Both actions recorded with the same `correlation_id` in the audit ledger.

`Rulestead.Admin.Policy` can declare CR-required actions per env:

```elixir
def change_request_required?(:publish_ruleset, %Rulestead.Context{env: :prod}, _res), do: true
def change_request_required?(_action, _ctx, _res), do: false
```

### 3.4 Self-approval guard

Default policies prevent the CR submitter from approving their own request. Host can override, but `Rulestead.Admin.Policy.RoleBased` warns loudly if self-approval is enabled for prod.

---

## 4. Environment-sensitive authorization

Critical pattern: **the same action has different authz profiles per environment**.

| Action | `:dev` | `:staging` | `:prod` |
|---|---|---|---|
| `:publish_ruleset` | any dev | any dev | `:prod_publisher` + CR |
| `:engage_killswitch` | any dev | `:on_call` | `:incident_commander` |
| `:advance_rollout` | any dev | any dev | `:prod_publisher` |
| `:rollback_rollout` | any dev | `:on_call` | `:on_call` or `:incident_commander` |
| `:export_audit` | any dev | `:auditor` | `:auditor` + MFA |
| `:manage_settings` | any dev | `:admin` | `:admin` + CR |

The `RoleBased` reference impl ships with this matrix as a default; hosts override as needed.

---

## 5. Secure context attributes

### 5.1 What goes in context

```elixir
%Rulestead.Context{
  tenant_id: "acme",
  env: :prod,
  actor: %Rulestead.Actor{id: "u_123", role: :app, roles: [:user], display_name: "Alice"},
  traits: %{country: "US", plan: "pro"},     # evaluation inputs — sanitized
  target_key: "u_123",                         # explicit bucketing key
  trace_id: "01HXY...",
  correlation_id: nil,
  request_id: "req_...",
  now: ~U[2026-04-23 12:00:00Z]
}
```

### 5.2 What does NOT go in context

- `Plug.Conn` or full HTTP request. Too easy to leak headers/cookies into logs.
- Raw session tokens. Ever.
- Arbitrary `params` blobs. Require explicit mapping via `Rulestead.ActorResolver`.

### 5.3 `traits` sanitization

Every attribute in `traits` is runs through `Rulestead.ContextRedactor` before it touches telemetry, audit, or debug surfaces. Default redactor drops/hashes known PII keys (`:email`, `:phone`, `:ssn`, `:ip`, `:address`, etc.) and host-configured regexes.

```elixir
config :rulestead, :context_redactor,
  drop_keys: [:email, :phone, :ssn, :ip, :address, :user_agent],
  hash_keys: [:actor_id],           # replace with sha256
  regex_patterns: [
    ~r/^[A-Fa-f0-9]{32,}$/,         # hash-y strings (might be secrets)
    ~r/^sk-/                         # OpenAI-style keys
  ]
```

Redaction is applied before any event is emitted, not at the consumer.

### 5.4 Evaluation never mutates context

`Rulestead.evaluate/3` is pure with respect to `ctx`. It does not write to `traits`, does not store `ctx` anywhere, does not include `ctx` in telemetry unredacted.

---

## 6. Server-side-only flag values

### 6.1 Why

Flag values that drive server-side behavior can safely contain structured policy (percentages, rules, variant names). They must NOT contain:
- Secrets, API keys, database credentials.
- User PII.
- Arbitrary code or scripts.

### 6.2 Guardrails

- **Schema validation on flag value:** each flag declares a type (`boolean | string | number | json`) and json-typed flags go through a configurable JSON Schema validation. Rulestead ships a default schema that rejects strings matching secret-looking patterns unless explicitly allowlisted.
- **Admin UI lint:** on save, scan variant values for:
  - strings looking like secrets (`sk-*`, long hex/base64 runs, `BEGIN {PRIVATE|RSA} KEY`, known vendor prefixes).
  - email-looking strings.
  - known secret-key name patterns (`aws_access_key`, `api_token`, etc.).
- **Export scrubbing:** audit exports and snapshot exports run the same scanner and mark any matches as `<redacted>`.
- **Explicit opt-out:** `flag.allow_sensitive_values: true` disables the lint but logs a warning on save + requires operator reason.

### 6.3 Client SDK boundary (future)

If rulestead ever ships a client SDK (browser/mobile), server-side-only flags MUST NOT be shipped to clients. Enforcement:
- Flag has `exposure: :server | :client | :both`.
- Client-facing snapshot endpoint filters by `exposure`.
- Default is `:server`.

---

## 7. Threat model (STRIDE)

### 7.1 Spoofing

| Threat | Impact | Mitigation |
|---|---|---|
| Attacker impersonates an operator | Flag changes in prod | Host auth; `Rulestead.Admin.Policy` enforces role checks. Rulestead trusts the authenticated identity host provides but logs the host-supplied `actor_id` in every audit row — any impersonation is forensically recoverable. |
| Attacker spoofs an evaluation context (e.g., sets `country: "US"` for a geo-gated flag) | Bypass geo-gating | Host is responsible for authenticated traits. Rulestead can't know if a trait is "authenticated" vs user-supplied. Document this clearly. Provide `Rulestead.Context.secure_trait/3` helper that only accepts traits from a host-provided server-signed blob. |
| Attacker spoofs a webhook | Unauthorized snapshot-reload / flag mutation | All webhooks verify HMAC signature with replay-protection (timestamp window). Failed verification → 401 + telemetry. |

### 7.2 Tampering

| Threat | Impact | Mitigation |
|---|---|---|
| DB admin edits flag row directly | Bypass audit | Audit trigger logs every write via separate mechanism? No — we can't prevent superuser writes. **We document this as out-of-scope for defense-in-depth and recommend per-tenant encryption at rest + DB audit extensions at the Postgres layer.** Audit ledger itself has append-only triggers; direct tampering raises `SQLSTATE 45A01`. |
| Attacker modifies cache in memory | Change evaluation result | Cache is in-process; attacker with BEAM node access already owns everything. N/A. |
| MITM on snapshot distribution | Poisoned snapshot | All snapshot distribution over TLS (host-managed); snapshots include a content digest + optional HMAC. |
| Tampering with audit bundle in transit | Undetected loss | HMAC signing (§6.5 in telemetry doc) + canonical JSON + verify on import. |

### 7.3 Repudiation

| Threat | Impact | Mitigation |
|---|---|---|
| Operator denies making a change | Accountability gap | Every mutation has `actor_id` + `actor_display` + `reason` + `trace_id` in audit ledger. Append-only. Optional HMAC signing for compliance tenants. |
| Operator deletes audit row | Evidence loss | DB trigger prevents DELETE (raises `45A01`). App API has no delete function. |

### 7.4 Information disclosure

| Threat | Impact | Mitigation |
|---|---|---|
| PII in logs | Privacy violation | `Rulestead.ContextRedactor` at telemetry emission. Default drops known PII keys. |
| PII in audit | Privacy violation | Redaction applies to `prior_state` / `next_state` / `diff` too. `actor_id` hashable per tenant config. |
| Secrets in flag values | Credential leak | Lint on save + export scrubbing + server-side-only enforcement (see §6). |
| `/health` endpoint leaks internal topology | Recon aid | Health endpoint returns opaque booleans + aggregate counters; never raw connection strings, node names, or flag keys. |
| Admin UI shows other tenants' data | Cross-tenant leak | Every admin query scoped by `tenant_id` in `Ecto.Query`. Policy callback receives `ctx` — unit tests assert cross-tenant access returns `:forbidden`. |
| Error responses include stack traces | Recon aid | Production responses never include stack traces. Structured errors only. |

### 7.5 Denial of service

| Threat | Impact | Mitigation |
|---|---|---|
| Expensive rule evaluation (regex catastrophic backtracking) | CPU exhaustion | `Rulestead.RuleEngine.Default` rejects regex operators that don't pass a safety check (ReDoS-vulnerable patterns blocked). Rule eval bounded by a timeout (`:timeout` config). |
| Huge JSON flag value | Memory / CPU | Size cap on flag values (configurable, default 64KB). Enforced at changeset. |
| Admin list-all query | DB pressure | Keyset pagination enforced. Max page size 100. |
| Audit export of entire history | DB + disk | Streaming export with rate limit + max event count per call. |
| Hook that blocks forever | Evaluator stall | Hooks timeout-bounded; exceeding timeout → hook exception telemetry + eval proceeds. |
| PubSub flood (snapshot invalidation loop) | Cluster-wide thrash | Snapshot versions monotonic; duplicate `applied` events ignored; loop detection in `Rulestead.Snapshot.Distributor`. |
| Webhook replay flood | DB + queue pressure | Idempotency keys required; replay window + dedup. Rate limit per signing key. |

### 7.6 Elevation of privilege

| Threat | Impact | Mitigation |
|---|---|---|
| Low-priv operator self-approves high-impact CR | Bypass review | CR policy disallows self-approval by default; warning-on-override. |
| Dev env operator accesses prod flags | Cross-env escalation | Policy is env-aware; `ctx.env` is trusted (host-provided) but admin routes are gated at the router level + policy level. |
| Hook code runs with evaluator privileges | Arbitrary code via hook config | Hooks are host-compiled modules; no dynamic code loading from flag values or DB content. |
| SQL injection via rule condition | DB access | All rule evaluation is data-driven (no dynamic SQL); rule conditions are structured (attribute + operator + value), never raw SQL. |
| Policy bypass via a forgotten action | Unauthorized action | Policy calls use a strict `action` enum; new admin actions fail to compile unless added to the enum. Test suite asserts every public admin function goes through a policy check. |

---

## 8. Supply-chain hardening

- **SHA-pinned actions** in GitHub workflows (already in release-engineering doc).
- **`mix hex.audit`** in CI — fails on deps with published retractions.
- **Dependabot automerge** only for patch-level updates; majors + minors require review.
- **Signed releases** — Hex package integrity relies on Hex.pm; we publish via `mix hex.publish --yes` with `HEX_API_KEY` stored as a GitHub Actions environment secret.
- **SBOM** — generate + attach to each release via `mix` task or `syft` workflow step (planned v0.5+).
- **Reproducible builds** — `.tool-versions` pinned; Elixir + OTP versions locked; `mix.lock` committed.
- **`mix deps.audit`** (or equivalent `dep_audit` tool) planned for CI.

---

## 9. Secrets handling

### 9.1 Secrets that rulestead handles

- **DB credentials:** host-provided via standard Ecto config. We never log them.
- **HMAC keys for audit signing:** optional, host-provided via `{M, F, A}` secret provider — never stored in app config at rest.
- **Webhook signing keys:** host-provided per integration.
- **Hex.pm API key (for releases):** only in GitHub Actions secrets; never in repo.

### 9.2 What we tell hosts

- Store all secrets in your vault/secret-manager; pass via config providers or `{M, F, A}` tuples.
- Never commit `.env` files with secrets (shipped `.gitignore` covers `.env`, `.env.*`, `*.env`).
- Rotate HMAC keys via the `key_id` + `previous_key_id` pattern to support rolling rotation.

### 9.3 What we do not store

- We don't cache secrets across evaluations.
- We don't log secrets (redactor scans error messages + stack traces).
- We don't include secret values in telemetry metadata.

---

## 10. Privacy + compliance readiness

### 10.1 GDPR-style data subject workflows

- `Rulestead.Privacy.delete_actor/2` — deletes impressions/exposures for a target actor; does NOT delete audit events (they're evidence of policy decisions, not subject data).
- `Rulestead.Privacy.export_actor/2` — streams a subject-access package (impressions, exposures, any actor-tied metadata).
- `actor_id` hashing (config) meets pseudonymization requirements for analytics.

### 10.2 Data residency

- Rulestead is single-DB by default. Multi-region is a host concern (run separate deployments, use Ecto replicas).
- Audit export supports scoping by tenant + env for jurisdictional extracts.

### 10.3 Retention

- Impressions: configurable TTL + rollup (default 30d raw, aggregates indefinite).
- Exposures: configurable TTL (default retained for experiment duration + 90d).
- Audit: retained indefinitely by default; tenants with strict retention can configure rolling archive to cold storage.

---

## 11. Tenant isolation

- Every admin query + command is parameterized by `tenant_id`.
- Cross-tenant-capable operator roles are explicit (`:global_admin`) and policy-gated.
- Tests: for each admin query + command, there's a "tenant B cannot see tenant A" assertion.
- `Rulestead.Tenant.guard/2` helper ensures a resource belongs to the current ctx's tenant — used defensively in LiveView `handle_params`.

---

## 12. Disclosure policy

`SECURITY.md` at repo root:
- Reporting email: `security@rulestead.dev` (or host GitHub security advisories).
- Response SLA: 48h acknowledgement, 30d resolution target for high-severity.
- Scope: published versions on Hex.pm; main branch before release.
- Out of scope: PoCs that require root/DB superuser access.
- Acknowledgements: Hall of Fame in `SECURITY.md`.
- CVE process documented.

---

## 13. Security-relevant tests

Dedicated suite under `test/security/`:

- **Policy enforcement:** for every admin action, assert `authorize/3` is called and a forbidden result denies the mutation.
- **Cross-tenant isolation:** every query + command tested with (ctx_tenant_a, resource_tenant_b) → denied or not-found.
- **Audit immutability:** attempt DELETE/UPDATE on `rulestead_audit_events` → asserts `Postgrex.Error{postgres: %{code: "45A01"}}`.
- **Redaction:** every telemetry event emission validated against a golden fixture of what's allowed in metadata; fixture rejects PII-like keys.
- **Secret-scanning lint:** test suite with crafted flag values (JWT-like strings, AWS keys, etc.) — all must be rejected or warned.
- **HMAC verification:** tampering with signed audit bundle → verify returns error.
- **Webhook replay:** same idempotency key twice → second call rejected.
- **Env-aware policy:** dev-env operator attempting prod-env action → denied.
- **ReDoS protection:** pathological regex conditions rejected at changeset level.
- **Flag value size cap:** oversized JSON rejected.
- **Hook timeout:** slow hook → eval completes anyway; hook error emitted.

---

## 14. Reference implementations we provide

- `Rulestead.Admin.Policy.RoleBased` — defaults that pass the env-sensitive matrix in §4.
- `Rulestead.ContextRedactor.Default` — drops known PII + hashes configured keys.
- `Rulestead.FlagValueLinter` — scans for secret-looking content.
- `Rulestead.ActorResolver.Session` — extracts actor from `Plug.Conn` session (host configures session key).
- `Rulestead.Webhook.Verifier` — HMAC signature verification + replay protection helper.

All are replaceable. Hosts override where needed.

---

## 15. Do / Don't

**Do:**
- Run every admin mutation through `Rulestead.Admin.Policy`.
- Scope every query by `tenant_id`.
- Redact before emitting telemetry.
- Require `reason` on every mutation (already a runtime enforcement, not just a UI convention).
- Keep `docs/threat-model.md` updated per minor release.
- Ship secrets via `{M, F, A}` providers, never plain config.
- Sign audit bundles for compliance tenants.
- Write security regression tests when any security-relevant code changes.

**Don't:**
- Don't trust traits as authenticated unless marked via `secure_trait/3`.
- Don't stash `%Plug.Conn{}` in context.
- Don't log on evaluation by default (leakage surface).
- Don't allow self-approval of high-impact change requests by default.
- Don't ship a "god mode" switch without audit.
- Don't emit stack traces to end users.
- Don't expose internal node names / flag lists on `/health`.
- Don't ship dev-mode `AllowAll` policy into prod (boot-time loud warning).

---

## 16. TL;DR

- **Small surface, high blast radius** — feature flags can ship anything everywhere, so authz + audit + immutability are first-class controls, not afterthoughts.
- **Host owns identity; rulestead owns authorization.** `Rulestead.Admin.Policy` is the single choke point for every admin mutation; ref impls are env-aware.
- **Context is explicit + sanitized** — no `%Plug.Conn{}` leaks, no raw PII in telemetry/audit, no secrets in flag values (linted + scrubbed).
- **Append-only audit ledger is a security control** — app-level API + DB trigger + optional HMAC signing.
- **STRIDE threat model lives in `docs/threat-model.md`**, updated per minor release, with concrete mitigations mapped to code.
- **Security tests are a dedicated suite** (`test/security/**`) — policy enforcement, cross-tenant isolation, audit immutability, ReDoS protection, webhook replay, redaction.
- **Supply chain hardened**: SHA-pinned actions, `mix hex.audit`, SBOM-planned, patch-only dependabot automerge.
