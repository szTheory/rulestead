# Rulestead Host App Integration Seam

> **Purpose:** Specify the boundary between rulestead and the host Phoenix/Elixir application — the installer, generator, runtime config, Plug/LiveView/Oban integrations, admin mount, and umbrella handling. The goal is: **a greenfield Phoenix app becomes flag-capable in 15 minutes with a single `mix rulestead.install` run, and it's idempotent, opinionated about defaults but un-opinionated about the host's identity/session layer.**
>
> **Read alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.4, `rulestead-personas-jtbd-and-onboarding.md` (Alex's 15-min path), `rulestead-admin-ux-and-operator-ia.md` (admin mount shape), `rulestead-security-privacy-and-threat-model.md` (policy seam).

---

## 1. Principles

1. **One command, sane defaults.** `mix rulestead.install` works with zero flags on a fresh Phoenix project.
2. **Idempotent, always.** Re-running the installer must be safe. No corruption, no duplicate injections.
3. **Explicit over magic.** Every injection is announced in stdout. Conflicts write `.rulestead_conflict_*` sidecars and fail loudly (mailglass pattern).
4. **Host owns identity + layout.** We inject mounts + plugs; we never touch their auth or endpoint.
5. **Composable, feature-gated.** Installer has `--no-admin`, `--no-oban`, `--no-audit-sign`; each adds/removes a coherent slice.
6. **Migrations are generated into the host repo.** Timestamped properly; user commits alongside code.
7. **Config is layered.** Defaults in `config/config.exs`; overrides per-env; secrets via `{M, F, A}` providers.
8. **Works in umbrella projects.** Detects `apps/` layout; injects into the right child app (or main app if specified).
9. **Backward-compatible upgrades.** `mix rulestead.upgrade` between versions handles schema deltas + code rewrites.
10. **Removable.** `mix rulestead.uninstall` exists (with clear "this won't delete your data" warning).

---

## 2. `mix rulestead.install` UX

### 2.1 Defaults

```
$ mix rulestead.install
[rulestead] Detecting host application...
[rulestead] Found Phoenix app: MyApp @ /Users/jon/projects/myapp
[rulestead] Found Ecto repo: MyApp.Repo
[rulestead] Oban detected (v2.18.1)
[rulestead] LiveView detected (v1.1.11)

[rulestead] Features to enable:
  [x] Core runtime (Plug, Context, Store)
  [x] Admin UI (mountable LiveView at /admin/flags)
  [x] Oban integration (rollout scheduler + audit compactor)
  [x] Telemetry + OTel adapter wiring
  [x] Ecto migrations (5 tables + audit trigger)

Continue? [Y/n] y

[rulestead]  * injecting lib/my_app/application.ex
[rulestead]  * injecting lib/my_app_web/router.ex
[rulestead]  * injecting config/config.exs
[rulestead]  * creating lib/my_app/rulestead_admin_policy.ex
[rulestead]  * creating lib/my_app/rulestead_actor_resolver.ex
[rulestead]  * creating priv/repo/migrations/20260423140000_create_rulestead_flags.exs
[rulestead]  * creating priv/repo/migrations/20260423140001_create_rulestead_rulesets.exs
[rulestead]  * creating priv/repo/migrations/20260423140002_create_rulestead_audiences.exs
[rulestead]  * creating priv/repo/migrations/20260423140003_create_rulestead_rollouts.exs
[rulestead]  * creating priv/repo/migrations/20260423140004_create_rulestead_events.exs

[rulestead] Done. Next steps:
  1. mix ecto.migrate
  2. mix phx.server
  3. Open http://localhost:4000/admin/flags
  4. Read: https://hexdocs.pm/rulestead/introduction.html
```

### 2.2 Flags

```
mix rulestead.install [options]

  --yes                  Skip prompts; accept all defaults
  --no-admin             Don't mount admin UI
  --no-oban              Don't wire Oban workers
  --no-migrations        Don't generate migrations (for custom store adapters)
  --no-policy-scaffold   Don't create RulesteadAdminPolicy stub
  --app MyApp            Specify which umbrella child (default: auto-detect)
  --repo MyApp.Repo      Specify repo (default: auto-detect first Ecto.Repo)
  --admin-route "/flags" Custom admin mount path (default: /admin/flags)
  --dry-run              Print injections without writing files
```

### 2.3 Idempotent re-run

```
$ mix rulestead.install
[rulestead] ...

[rulestead]  ~ already injected: lib/my_app/application.ex
[rulestead]  ~ already injected: lib/my_app_web/router.ex
[rulestead]  ~ already injected: config/config.exs
[rulestead]  ~ already exists: lib/my_app/rulestead_admin_policy.ex
[rulestead]  ~ already exists: priv/repo/migrations/20260423140000_create_rulestead_flags.exs
...

[rulestead] No changes needed. Everything up to date.
```

### 2.4 Conflict handling (mailglass pattern)

When the installer detects an injection zone it doesn't recognize (e.g., user hand-edited), it:
1. Writes the intended content to `.rulestead_conflict_<path>` sidecar.
2. Emits a `~ conflict:` line in stdout with instructions.
3. Exits non-zero.

```
[rulestead]  ~ conflict: lib/my_app/application.ex
             Could not find expected injection zone.
             Wrote intended changes to:
               lib/my_app/application.ex.rulestead_conflict
             Please review + merge manually, then re-run the installer.
             See: https://hexdocs.pm/rulestead/troubleshooting/conflicts.html

[rulestead] 1 conflict(s). Aborting.
```

### 2.5 Injection zones

Use **marker comments** so re-runs can detect + update the zone:

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      # <rulestead:children>
      {Rulestead,
        repo: MyApp.Repo,
        actor_resolver: MyApp.RulesteadActorResolver,
        admin_policy: MyApp.RulesteadAdminPolicy,
        pubsub: MyApp.PubSub},
      # </rulestead:children>
      MyAppWeb.Endpoint
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
  end
end
```

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Rulestead.Router      # <rulestead:import>

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Rulestead.Plug         # <rulestead:plug>
  end

  # <rulestead:admin_mount>
  scope "/admin", MyAppWeb do
    pipe_through [:browser, :require_admin_user]   # host-declared auth pipeline
    rulestead_admin "/flags"
  end
  # </rulestead:admin_mount>
end
```

Markers are never shipped in generated stubs — only in injection zones. Generated stubs (like `RulesteadAdminPolicy`) are marked with a `@doc since: "..."` header and a "generated by mix rulestead.install — edit freely" moduledoc note.

---

## 3. Generator outputs

### 3.1 Stub: `Rulestead.ActorResolver` impl

```elixir
# lib/my_app/rulestead_actor_resolver.ex
defmodule MyApp.RulesteadActorResolver do
  @moduledoc """
  Resolves a `%Rulestead.Actor{}` from the current request context.

  Generated by `mix rulestead.install`. Edit to match your app's session/auth.

  Examples of what to return:

    * For authenticated users:
      %Rulestead.Actor{id: current_user.id, role: :app,
                       roles: current_user.roles, display_name: current_user.email}

    * For anonymous:
      %Rulestead.Actor{id: session_id, role: :anonymous, roles: [], display_name: "anon"}

    * For background jobs (no conn):
      %Rulestead.Actor{id: "system:oban", role: :system, roles: [:system], display_name: "system"}
  """

  @behaviour Rulestead.ActorResolver

  @impl true
  def resolve(%Plug.Conn{} = conn) do
    case conn.assigns[:current_user] do
      nil ->
        %Rulestead.Actor{id: session_anon_id(conn), role: :anonymous, roles: []}

      user ->
        %Rulestead.Actor{id: user.id, role: :app, roles: user.roles || [],
                         display_name: user.email}
    end
  end

  def resolve(%Phoenix.LiveView.Socket{} = socket) do
    case socket.assigns[:current_user] do
      nil -> %Rulestead.Actor{id: "anon", role: :anonymous, roles: []}
      user -> %Rulestead.Actor{id: user.id, role: :app, roles: user.roles || [],
                               display_name: user.email}
    end
  end

  def resolve(%Oban.Job{args: args}) do
    %Rulestead.Actor{id: "system:oban:#{args["worker"] || "unknown"}",
                     role: :system, roles: [:system]}
  end

  def resolve(_), do: %Rulestead.Actor{id: "system", role: :system, roles: [:system]}

  defp session_anon_id(conn) do
    Plug.Conn.get_session(conn, :rulestead_anon_id) ||
      (Base.encode16(:crypto.strong_rand_bytes(8)) |> String.downcase())
  end
end
```

### 3.2 Stub: `Rulestead.Admin.Policy` impl

```elixir
# lib/my_app/rulestead_admin_policy.ex
defmodule MyApp.RulesteadAdminPolicy do
  @moduledoc """
  Authorization policy for the rulestead admin surface.

  Generated by `mix rulestead.install`. Reference implementation:
  `Rulestead.Admin.Policy.RoleBased`. Override actions below to encode
  your team's rules.
  """

  use Rulestead.Admin.Policy.RoleBased

  # Example: require :incident_commander role to engage prod kill switches.
  @impl Rulestead.Admin.Policy
  def authorize(:engage_killswitch, %Rulestead.Context{env: :prod, actor: %{roles: roles}}, _res) do
    if :incident_commander in roles, do: :ok, else: {:error, :forbidden}
  end

  def authorize(action, ctx, res), do: super(action, ctx, res)

  # Example: require change-request for prod ruleset publishes.
  @impl Rulestead.Admin.Policy
  def change_request_required?(:publish_ruleset, %Rulestead.Context{env: :prod}, _), do: true
  def change_request_required?(action, ctx, res), do: super(action, ctx, res)
end
```

### 3.3 Migrations

5 sequential migrations with timestamps offset by 1 second to guarantee ordering:

```
priv/repo/migrations/20260423140000_create_rulestead_flags.exs
priv/repo/migrations/20260423140001_create_rulestead_rulesets.exs
priv/repo/migrations/20260423140002_create_rulestead_audiences.exs
priv/repo/migrations/20260423140003_create_rulestead_rollouts.exs
priv/repo/migrations/20260423140004_create_rulestead_events.exs   # includes append-only trigger
```

Each migration module delegates to `Rulestead.Migrations.up/0` / `down/0`:

```elixir
defmodule MyApp.Repo.Migrations.CreateRulesteadFlags do
  use Ecto.Migration
  def up, do: Rulestead.Migrations.V1.Flags.up()
  def down, do: Rulestead.Migrations.V1.Flags.down()
end
```

This lets us ship migration logic in the lib (versioned, `hex`-distributed) while still generating host-repo-visible migrations.

### 3.4 Config

```elixir
# config/config.exs (appended inside <rulestead:config> markers)
import Config

# <rulestead:config>
config :rulestead,
  repo: MyApp.Repo,
  pubsub: MyApp.PubSub,
  actor_resolver: MyApp.RulesteadActorResolver,
  admin_policy: MyApp.RulesteadAdminPolicy,
  snapshot: [
    refresh_interval_ms: 5_000,
    stale_threshold_ms: 30_000
  ]
# </rulestead:config>
```

Per-env overrides are **not** injected by default — the user adds them where needed (principle of explicit > magic).

---

## 4. Runtime config patterns

### 4.1 `config :rulestead` keys

| Key | Type | Default | Description |
|---|---|---|---|
| `:repo` | module | required | Host's `Ecto.Repo` |
| `:pubsub` | module | required | Host's `Phoenix.PubSub` |
| `:actor_resolver` | module | required | Implements `Rulestead.ActorResolver` |
| `:admin_policy` | module | required | Implements `Rulestead.Admin.Policy` |
| `:store` | module | `Rulestead.Store.Postgres` | Pluggable store |
| `:rule_engine` | module | `Rulestead.RuleEngine.Default` | Pluggable rule engine |
| `:evaluation_cache` | module | `Rulestead.EvaluationCache.ETS` | Pluggable cache |
| `:audit_store` | module | `Rulestead.AuditStore.Postgres` | Pluggable audit store |
| `:hooks` | list of modules | `[]` | Registered hooks |
| `:context_redactor` | module | `Rulestead.ContextRedactor.Default` | PII redaction |
| `:telemetry` | keyword list | `[]` | Sampling + metrics config |
| `:snapshot` | keyword list | see below | Snapshot refresh + distribution |
| `:impressions` | keyword list | see below | Impression sampling + shipping |
| `:webhooks` | keyword list | `[]` | Incoming webhook signers |
| `:tenant_scope` | `:required | :optional | :disabled` | `:optional` | Tenant isolation mode |

Documented + schema-validated via `NimbleOptions`.

### 4.2 Nested defaults

```elixir
config :rulestead, :snapshot,
  refresh_interval_ms: 5_000,
  stale_threshold_ms: 30_000,
  distributor: Rulestead.Snapshot.Distributor.PubSub,
  distributor_opts: []

config :rulestead, :impressions,
  default_sample_rate: 0.01,
  per_flag_overrides: %{},
  shipper: Rulestead.Impressions.PubSubShipper,
  shipper_opts: [topic: "rulestead:impressions"]

config :rulestead, :telemetry,
  sample_rate: %{
    [:rulestead, :eval, :decide, :stop] => 1.0,
    [:rulestead, :eval, :impression] => 0.01
  }
```

### 4.3 Config schema validation

At boot, `Rulestead.Config.validate!/0` runs `NimbleOptions.validate!/2` and fails fast with actionable messages:

```
** (Rulestead.ConfigError) invalid configuration for :rulestead

    config :rulestead, actor_resolver: MyApp.NonExistent

    expected :actor_resolver to be a module implementing Rulestead.ActorResolver,
    got: MyApp.NonExistent (module not loaded)
```

---

## 5. Plug integration

```elixir
# lib/my_app_web/endpoint.ex or router pipeline
plug Rulestead.Plug, env: :prod         # optional override
```

What it does:

1. Resolves actor via configured resolver.
2. Builds `%Rulestead.Context{}` with `actor`, `env`, `tenant_id`, `trace_id`, `request_id`, `now`.
3. Assigns to `conn.assigns[:rulestead_context]`.
4. Sets `Logger.metadata(rulestead_trace_id: ...)`.

Options:

- `:env` — override env (defaults to `Mix.env()` in dev/test, `Application.get_env(:rulestead, :env)` in prod).
- `:tenant_resolver` — optional MFA that extracts tenant from conn.
- `:skip_on` — predicate (MFA) to skip resolution (e.g., healthchecks).

Overhead: <5µs on warm cache.

---

## 6. LiveView integration

### 6.1 `on_mount` hook

```elixir
# In host's LiveView file
use MyAppWeb, :live_view
on_mount Rulestead.LiveView
```

Sets `socket.assigns[:rulestead_context]` from the session + actor resolver. Subscribes to flag-invalidation PubSub for the session's tenant + env.

### 6.2 `assign_flags/2` helper

```elixir
def mount(_params, _session, socket) do
  {:ok, Rulestead.LiveView.assign_flags(socket, [:checkout_v2, :pricing_exp])}
end
```

Result:
```elixir
socket.assigns[:rulestead_flags] == %{
  checkout_v2: %{value: true, variant: nil, reason: :rule_match},
  pricing_exp: %{value: "treatment", variant: "treatment", reason: :rule_match}
}
```

Re-evaluated on PubSub invalidation → pushes update via `assign`.

### 6.3 Template helper

```elixir
~H"""
<div :if={Rulestead.enabled?(:checkout_v2, @rulestead_context)}>
  <.new_checkout />
</div>
<div :if={Rulestead.variant(:pricing_exp, @rulestead_context) == "treatment"}>
  <.treatment_pricing />
</div>
"""
```

---

## 7. Oban integration

### 7.1 Middleware

```elixir
# config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  engine: Oban.Engines.Basic,
  plugins: [...],
  queues: [default: 10],
  middlewares: [{Rulestead.Oban.Middleware, []}]
```

What it does:
- On job execution, resolves `%Rulestead.Context{}` from `args[:rulestead_ctx]` (if present) or defaults.
- Assigns to process dictionary key `{:rulestead, :ctx}` for ergonomic access inside workers.
- Emits telemetry spans scoped to the job.

### 7.2 Worker API

```elixir
defmodule MyApp.Workers.CheckoutProcessor do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    ctx = Rulestead.Oban.context()           # convenience accessor
    if Rulestead.enabled?(:async_refund_flow, ctx) do
      # ...
    end
  end
end
```

### 7.3 Rulestead-owned workers

Installer schedules these via Oban:
- `Rulestead.Workers.RolloutAdvancer` — advances staged rollouts on schedule.
- `Rulestead.Workers.AuditCompactor` — optional cold-storage archival.
- `Rulestead.Workers.SnapshotRefresher` — periodic snapshot rebuild for high-traffic tenants.
- `Rulestead.Workers.StaleFlagDetector` — weekly sweep; produces report.

All workers have `:rulestead` queue prefix so hosts can isolate concurrency.

---

## 8. Admin UI mount

```elixir
# router.ex
scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_admin_user]
  rulestead_admin "/flags", opts: [session: {__MODULE__, :admin_session, []}]
end
```

`rulestead_admin/2` macro:
1. Registers scoped routes under the given path.
2. Mounts LiveView views with `on_mount Rulestead.Admin.OnMount`.
3. Loads admin layout into host's `put_root_layout`.
4. Respects host's CSP policy (sigra pattern — no inline styles/scripts in admin templates).

Session callback receives conn, returns session map merged into LiveView session. Host controls which assigns flow through.

---

## 9. Umbrella projects

### 9.1 Detection

Installer detects `mix.exs`'s `apps_path: "apps"` and:
1. Lists child apps.
2. Prompts: "Which app owns the admin UI?" (auto-selects the `*_web` app if unambiguous).
3. Prompts: "Which app owns the Repo?" (auto-selects unique `_ecto`-shaped app).
4. Generates into the correct children.

### 9.2 Config split

- `config/config.exs` (umbrella root): `:rulestead` config.
- Web app's `application.ex`: only the `Rulestead` supervisor child if no _db app exists.
- DB app's `application.ex`: `Rulestead` supervisor child (includes repo access).

### 9.3 Tests

Installer generates `test/example/` as a single app; umbrella hosts can symlink or use as reference.

---

## 10. Post-install next-steps guide

After install, stdout prints a curated next-steps list pointing to specific docs. Example:

```
[rulestead] Done. Next steps:

  1. Migrate the DB:        mix ecto.migrate
  2. Start the server:      mix phx.server
  3. Visit admin UI:        http://localhost:4000/admin/flags
  4. Add your first flag:   mix rulestead.add_flag my_feature --default false

  Docs:
    - Quickstart:   https://hexdocs.pm/rulestead/introduction.html
    - Testing:      https://hexdocs.pm/rulestead/guides/testing.html
    - Policy:       https://hexdocs.pm/rulestead/guides/policy-and-change-requests.html
    - Admin tour:   https://hexdocs.pm/rulestead/guides/operator-handbook.html

  Generated files to review + commit:
    - lib/my_app/rulestead_actor_resolver.ex   (customize to match your auth)
    - lib/my_app/rulestead_admin_policy.ex     (customize authz rules)
    - priv/repo/migrations/2026...              (standard ecto migrations)
    - lib/my_app_web/router.ex                  (admin mounted at /admin/flags)
    - config/config.exs                         (rulestead config block)
```

---

## 11. Upgrade path (`mix rulestead.upgrade`)

Between minor versions, schema deltas happen (new tables, new columns). Upgrade task:

1. Detects current rulestead version in user's `mix.lock` vs installed version.
2. Runs registered upgrade steps in order (code rewrites + new migrations).
3. Migration file names include version prefix (`v0_2_0_add_forced_variants.exs`).
4. Writes an upgrade report to stdout + `UPGRADE_REPORT.md` in project root for review.
5. Never overwrites user customizations in generated stubs (policy, resolver) — just adds marker-bounded amendments if behaviour signatures change.

---

## 12. Uninstall (`mix rulestead.uninstall`)

```
$ mix rulestead.uninstall
[rulestead] WARNING: This removes rulestead code + configuration.
           It does NOT drop database tables — your data is preserved.
           To drop tables, run: mix rulestead.drop_schema (destructive).

Continue? [y/N] y

[rulestead]  - removing lib/my_app_web/router.ex admin mount
[rulestead]  - removing lib/my_app/application.ex supervisor child
[rulestead]  - removing config/config.exs rulestead block
[rulestead]  ~ keeping (yours to delete):
             lib/my_app/rulestead_admin_policy.ex
             lib/my_app/rulestead_actor_resolver.ex
             priv/repo/migrations/2026*

[rulestead] Done. `mix deps.clean rulestead && mix deps.get` to complete removal.
```

---

## 13. Idempotency verification

Every installer change is paired with:

1. **Golden-diff test** (`test/install_golden/`) — post-install tree is byte-identical to fixture.
2. **Idempotency test** — 2nd `mix rulestead.install` run produces no changes + exits 0.
3. **Flag-matrix compile test** — every installer flag combination produces a compiling Phoenix app.

See `rulestead-testing-and-e2e-strategy.md` §6.

---

## 14. Error + failure modes

### 14.1 Common errors + messages

| Scenario | Installer behavior |
|---|---|
| Not a Phoenix project | Exit 1 with "mix.exs doesn't look like a Phoenix app. Did you mean to run `mix phx.new` first?" |
| No Ecto repo | Exit 1 with "No `Ecto.Repo` found. Rulestead needs a repo; add one via `mix ecto.gen.repo` or pass `--no-migrations` for custom stores." |
| Phoenix version too old | Warn + prompt to continue. Rulestead supports Phoenix 1.7+. |
| Elixir version too old | Exit 1. Rulestead floor: Elixir 1.18+. |
| Marker zone missing | Conflict file + non-zero exit (§2.4). |
| User said no to admin UI | Skip router injection + admin policy stub; still inject runtime + repo. |
| Destination file is git-dirty | Warn + prompt. `--yes` overrides. |

### 14.2 Rollback

Installer is atomic-per-file but not atomic across files. If injection fails mid-run:
1. Already-written files remain (user has git to recover).
2. Prints: "Partial install. Run `git status` to see changes; `git checkout .` to revert."
3. Exit non-zero.

---

## 15. Host-app integration checklist

What a host engineer should verify after running the installer:

- [ ] `mix ecto.migrate` succeeds.
- [ ] `mix phx.server` boots without warnings.
- [ ] `curl /rulestead/health` returns `200` + JSON.
- [ ] `/admin/flags` loads and requires auth (403 when logged out).
- [ ] `MyApp.RulesteadActorResolver` maps `current_user` correctly.
- [ ] `MyApp.RulesteadAdminPolicy` locks down `:engage_killswitch` in prod.
- [ ] First flag via `mix rulestead.add_flag` shows in admin UI.
- [ ] `Rulestead.enabled?/2` returns default `false` for unknown flag (with dev warning).
- [ ] `with_flag/3` in tests works without Postgres.
- [ ] Telemetry event appears in host's OTel collector.

---

## 16. What rulestead does NOT touch

- Host's `Endpoint` module (only through documented plug insertion).
- Host's session/auth configuration.
- Host's CSS/JS bundle (admin assets shipped separately).
- Host's Oban queue configuration (only adds `:rulestead` queue by default).
- Host's existing migrations (rulestead migrations are disjoint, prefixed `rulestead_`).
- Host's `config/runtime.exs` beyond documented pointers.
- Host's CI workflows (we ship `guides/ci-recipes.md`; host copies what they want).

---

## 17. Feature-walker pattern (sigra-DNA)

For each optional feature (`admin`, `oban`, `telemetry`, `audit_sign`), installer has a **walker module**:

```elixir
# lib/rulestead/install/features/admin.ex
defmodule Rulestead.Install.Features.Admin do
  @behaviour Rulestead.Install.Feature

  @impl true
  def applicable?(%{flags: flags}), do: "--no-admin" not in flags
  @impl true
  def description, do: "Admin UI (mountable LiveView at /admin/flags)"

  @impl true
  def apply(state) do
    state
    |> Rulestead.Install.Router.inject_admin_mount()
    |> Rulestead.Install.Policy.scaffold()
    |> Rulestead.Install.Assets.link_admin_static()
  end

  @impl true
  def rollback(state), do: state   # optional; used by uninstall
end
```

Installer driver:

```elixir
features = [
  Rulestead.Install.Features.Core,           # always runs
  Rulestead.Install.Features.Admin,
  Rulestead.Install.Features.Oban,
  Rulestead.Install.Features.Telemetry,
  Rulestead.Install.Features.AuditSign
]

Enum.reduce(features, initial_state, fn feature, state ->
  if feature.applicable?(state), do: feature.apply(state), else: state
end)
```

Each feature is independently testable + skippable. Adding a new feature = adding a new module + flag. Sigra-proven shape.

---

## 18. Do / Don't

**Do:**
- Use marker-bounded injection zones for every host-file mutation.
- Fail loudly on conflicts with sidecar files + clear resolution path.
- Ship generator stubs with generous moduledoc pointing to guides.
- Validate config at boot with NimbleOptions + actionable error messages.
- Detect umbrella layouts; prompt for child-app selection.
- Test every installer flag combination produces a compiling app.
- Include `mix rulestead.upgrade` from day 1 (even if it's a no-op initially).
- Document what the installer touches + doesn't touch.

**Don't:**
- Don't mutate `Endpoint` beyond documented plug insertions.
- Don't auto-commit changes (host owns git).
- Don't assume the user's auth library (authcore, pow, phx_gen_auth, etc.).
- Don't inject into `config/runtime.exs` — that's host's runtime secret zone.
- Don't hide conflicts to make the install "feel smoother" — fail loud + help recover.
- Don't generate a huge default config block — defaults live in the lib; users add only overrides.
- Don't install Oban workers if Oban isn't already in deps — skip + log.
- Don't mount admin UI without requiring host auth pipeline — admin mount macro errors if no `pipe_through` is present.

---

## 19. TL;DR

> `mix rulestead.install` makes a fresh Phoenix app flag-capable in 15 minutes, with marker-bounded idempotent injections, feature-walker modules for each optional slice (admin/oban/telemetry/audit), mailglass-style `.rulestead_conflict_*` sidecars on divergence, sigra-style golden-diff + idempotency tests, and generated stubs (`RulesteadActorResolver`, `RulesteadAdminPolicy`) that the host owns and customizes. Host owns identity, layout, and auth; rulestead owns runtime evaluation + admin UI + migrations. Upgrades + uninstall are first-class paths.
